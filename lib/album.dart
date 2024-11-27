import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http_parser/http_parser.dart';
import 'TrackInAlbumPage.dart';

class AlbumManagementPage extends StatefulWidget {
  @override
  _AlbumManagementPageState createState() => _AlbumManagementPageState();
}

class _AlbumManagementPageState extends State<AlbumManagementPage> {
  List<Artist> _artists = [];
  List<Album> _albums = [];
  // ignore: unused_field
  String? _selectedArtistId;

  // ignore: unused_field
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    fetchArtists();
    fetchAlbums();
  }

  Future<void> fetchArtists() async {
    try {
      final response = await http.get(Uri.parse('http://localhost:3000/api/artists'));
      if (response.statusCode == 200) {
        final List<dynamic> artistJson = json.decode(response.body);
        setState(() {
          _artists = artistJson.map((json) => Artist.fromJson(json)).toList();
          if (_artists.isNotEmpty) {
            _selectedArtistId = _artists.first.id;
          }
        });
      } else {
        throw Exception('Failed to load artists');
      }
    } catch (e) {
      print("Error fetching artists: $e");
    }
  }

  Future<void> fetchAlbums() async {
    try {
      final response = await http.get(Uri.parse('http://localhost:3000/api/albums'));
      if (response.statusCode == 200) {
        final List<dynamic> albumJson = json.decode(response.body);
        setState(() {
          _albums = albumJson.map((json) => Album.fromJson(json)).toList();
        });
      } else {
        throw Exception('Failed to load albums');
      }
    } catch (e) {
      print("Error fetching albums: $e");
    }
  }

  Future<void> createAlbum(String albumName, String releaseDate, String artistId, String imageUrl) async {
    final response = await http.post(
      Uri.parse('http://localhost:3000/api/albums'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'albumName': albumName,
        'releaseDate': releaseDate,
        'artistID': artistId,
        'coverImage': imageUrl,
      }),
    );

    if (response.statusCode == 201) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Album created successfully')),
      );
      fetchAlbums();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to create album')),
      );
    }
  }

  Future<void> updateAlbum(String albumId, String albumName, String releaseDate, String artistId, String imageUrl) async {
    final response = await http.put(
      Uri.parse('http://localhost:3000/api/albums/$albumId'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'albumName': albumName,
        'releaseDate': releaseDate,
        'artistID': artistId,
        'coverImage': imageUrl,
      }),
    );

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Album updated successfully')),
      );
      fetchAlbums();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update album')),
      );
    }
  }

  Future<void> deleteAlbum(String albumId) async {
    final response = await http.delete(Uri.parse('http://localhost:3000/api/albums/$albumId'));

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Album deleted successfully')),
      );
      fetchAlbums();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete album')),
      );
    }
  }

  void _showCreateAlbumDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return CreateAlbumDialog(
          artists: _artists,
          onCreateAlbum: (albumName, releaseDate, artistId, imageUrl) {
            createAlbum(albumName, releaseDate, artistId, imageUrl);
          },
        );
      },
    );
  }

  void _showUpdateAlbumDialog(Album album) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return CreateAlbumDialog(
          artists: _artists,
          initialAlbum: album,
          onCreateAlbum: (albumName, releaseDate, artistId, imageUrl) {
            updateAlbum(album.id, albumName, releaseDate, artistId, imageUrl);
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Center(child: Text('Album Management')),
        actions: [
          IconButton(
            icon: Icon(Icons.add),
            onPressed: _showCreateAlbumDialog,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView.builder(
          itemCount: _albums.length,
          itemBuilder: (context, index) {
            final album = _albums[index];
            final formattedDate = DateFormat('dd/MM/yyyy').format(DateTime.parse(album.releaseDate));
            return Card(
              margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
              color: Colors.grey[200],
              child: ListTile(
                leading: album.imageUrl.isNotEmpty
                    ? Image.network(album.imageUrl, width: 50, height: 50)
                    : Icon(Icons.album, size: 50),
                title: Text(album.albumName),
                subtitle: Text('Artist: ${album.artistName}\nRelease Date: $formattedDate'),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => TrackInAlbumPage(albumId: album.id),
                    ),
                  );
                },
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(Icons.edit),
                      onPressed: () => _showUpdateAlbumDialog(album),
                    ),
                    IconButton(
                      icon: Icon(Icons.delete),
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: Text('Delete Album'),
                            content: Text('Are you sure you want to delete this album?'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.of(context).pop(),
                                child: Text('Cancel'),
                              ),
                              TextButton(
                                onPressed: () {
                                  deleteAlbum(album.id);
                                  Navigator.of(context).pop();
                                },
                                child: Text('Delete'),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class CreateAlbumDialog extends StatefulWidget {
  final List<Artist> artists;
  final Album? initialAlbum;
  final Function(String albumName, String releaseDate, String artistId, String imageUrl) onCreateAlbum;

  CreateAlbumDialog({required this.artists, required this.onCreateAlbum, this.initialAlbum});

  @override
  _CreateAlbumDialogState createState() => _CreateAlbumDialogState();
}

class _CreateAlbumDialogState extends State<CreateAlbumDialog> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _albumNameController = TextEditingController();
  final TextEditingController _releaseDateController = TextEditingController();
  String? _selectedArtistId;
  File? _imageFile;
  String _imageUrl = '';

  @override
  void initState() {
    super.initState();
    if (widget.initialAlbum != null) {
      _albumNameController.text = widget.initialAlbum!.albumName;
      _releaseDateController.text = widget.initialAlbum!.releaseDate;
      _selectedArtistId = widget.initialAlbum!.artistId;
      _imageUrl = widget.initialAlbum!.imageUrl;
    } else if (widget.artists.isNotEmpty) {
      _selectedArtistId = widget.artists.first.id;
    }
  }

  String basename(String filePath) {
    return filePath.split(Platform.pathSeparator).last;
  }

  Future<String> uploadImage(File file) async {
    const String cloudName = 'dvpmjwcmh';
    const String uploadPreset = 'upload_img';
    const String folderName = 'album_covers';
    const String url = 'https://api.cloudinary.com/v1_1/$cloudName/upload';

    final request = http.MultipartRequest('POST', Uri.parse(url))
      ..fields['tags'] = 'browser_upload'
      ..fields['upload_preset'] = uploadPreset
      ..fields['folder'] = folderName
      ..files.add(await http.MultipartFile.fromPath('file', file.path,
          filename: basename(file.path),
          contentType: MediaType('image', 'jpeg')));

    try {
      final response = await request.send();
      final responseBody = await response.stream.bytesToString();
      final responseData = jsonDecode(responseBody);

      if (response.statusCode == 200 && responseData['secure_url'] != null) {
        return responseData['secure_url'];
      } else {
        throw Exception("Upload failed: ${responseData['error']['message']}");
      }
    } catch (error) {
      print("Error uploading the file: $error");
      throw Exception("Failed to upload image");
    }
  }

  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  void _submitForm() async {
    if (_formKey.currentState!.validate()) {
      final albumName = _albumNameController.text;  
      final releaseDate = _releaseDateController.text;
      final artistId = _selectedArtistId!;

      String imageUrl = _imageUrl;
      if (_imageFile != null) {
        imageUrl = await uploadImage(_imageFile!); // Gọi hàm uploadImage và nhận link ảnh
      }

      if (mounted) {
        widget.onCreateAlbum(albumName, releaseDate, artistId, imageUrl);
        Navigator.of(context).pop();
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.initialAlbum == null ? 'Create Album' : 'Update Album'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            children: [
              TextFormField(
                controller: _albumNameController,
                decoration: InputDecoration(labelText: 'Album Name'),
                validator: (value) => value == null || value.isEmpty ? 'Please enter an album name' : null,
              ),
              TextFormField(
                controller: _releaseDateController,
                decoration: InputDecoration(labelText: 'Release Date'),
                validator: (value) => value == null || value.isEmpty ? 'Please enter a release date' : null,
              ),
              DropdownButtonFormField<String>(
                value: _selectedArtistId,
                onChanged: (value) {
                  setState(() {
                    _selectedArtistId = value;
                  });
                },
                items: widget.artists
                    .map((artist) => DropdownMenuItem(value: artist.id, child: Text(artist.artistName)))
                    .toList(),
                decoration: InputDecoration(labelText: 'Artist'),
                validator: (value) => value == null ? 'Please select an artist' : null,
              ),
              SizedBox(height: 10),
              _imageFile == null
                  ? ElevatedButton(
                      onPressed: _pickImage,
                      child: Text('Pick an image'),
                    )
                  : Image.file(_imageFile!, height: 100),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _submitForm,
          child: Text(widget.initialAlbum == null ? 'Create' : 'Update'),
        ),
      ],
    );
  }
}

class Album {
  final String id;
  final String albumName;
  final String artistId;
  final String artistName;
  final String releaseDate;
  final String imageUrl;

  Album({
    required this.id,
    required this.albumName,
    required this.artistId,
    required this.artistName,
    required this.releaseDate,
    required this.imageUrl,
  });

  factory Album.fromJson(Map<String, dynamic> json) {
    return Album(
      id: json['_id'],
      albumName: json['albumName'],
      artistId: json['artistID']['_id'],
      artistName: json['artistID']['artistName'],
      releaseDate: json['releaseDate'],
      imageUrl: json['coverImage'] ?? '',
    );
  }
}

class Artist {
  final String id;
  final String artistName;

  Artist({required this.id, required this.artistName});

  factory Artist.fromJson(Map<String, dynamic> json) {
    return Artist(
      id: json['_id'],
      artistName: json['artistName'],
    );
  }
}
  