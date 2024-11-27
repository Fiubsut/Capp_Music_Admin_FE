import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:mime/mime.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;

class TrackManagementPage extends StatefulWidget {
  @override
  _TrackManagementPageState createState() => _TrackManagementPageState();
}

class _TrackManagementPageState extends State<TrackManagementPage> {
  List<Track> _tracks = [];
  List<Artist> _artists = [];
  List<Genre> _genres = [];
  // ignore: unused_field
  File? _mp3File;

  @override
  void initState() {
    super.initState();
    fetchTracks();
    fetchArtists();
    fetchGenres();
  }

  Future<void> fetchTracks() async {
    final response = await http.get(Uri.parse('http://localhost:3000/api/tracks'));

    if (response.statusCode == 200) {
      List<dynamic> data = json.decode(response.body);
      setState(() {
        _tracks = data.map((track) => Track.fromJson(track)).toList();
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to load tracks')));
    }
  }

  Future<void> fetchArtists() async {
    final response = await http.get(Uri.parse('http://localhost:3000/api/artists'));

    if (response.statusCode == 200) {
      List<dynamic> data = json.decode(response.body);
      setState(() {
        _artists = data.map((artist) => Artist.fromJson(artist)).toList();
      });
    }
  }

  Future<void> fetchGenres() async {
    final response = await http.get(Uri.parse('http://localhost:3000/api/genres'));

    if (response.statusCode == 200) {
      List<dynamic> data = json.decode(response.body);
      setState(() {
        _genres = data.map((genre) => Genre.fromJson(genre)).toList();
      });
    }
  }

  Future<void> createTrack(String trackName, String artistId, List<String> genreIds, String? trackUrl) async {
    // Khởi tạo body với các giá trị bắt buộc
    Map<String, dynamic> body = {
      'trackName': trackName,
      'artistID': artistId,
      'genreIDs': genreIds,
    };

    // Thêm trackURL nếu không trống
    if (trackUrl != null && trackUrl.isNotEmpty) {
      body['trackURL'] = trackUrl;
    }

    final response = await http.post(
      Uri.parse('http://localhost:3000/api/tracks'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(body),
    );

    if (response.statusCode == 201) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Track created successfully')));
      fetchTracks();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to create track')));
    }
  }


  Future<void> updateTrack(String trackId, String trackName, String artistId, List<String> genreIds, String trackUrl) async {


    final response = await http.put(
      Uri.parse('http://localhost:3000/api/tracks/$trackId'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'trackName': trackName,
        'artistID': artistId,
        'genreIDs': genreIds,
        'trackURL': trackUrl,
      }),
    );

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Track updated successfully')));
      fetchTracks();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to update track')));
    }
  }

  Future<void> deleteTrack(String trackId) async {
    final response = await http.delete(
      Uri.parse('http://localhost:3000/api/tracks/$trackId'),
    );

    if (response.statusCode == 200) {
      // Nếu xoá thành công, cập nhật lại danh sách track
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Track deleted successfully')));
      fetchTracks(); // Tải lại danh sách track
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to delete track')));
    }
  }

  void _showCreateTrackDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return CreateTrackDialog(
          artists: _artists,
          genres: _genres,
          onCreateTrack: (trackName, artistId,  genreIds, trackUrl) {
            createTrack(trackName, artistId,  genreIds, trackUrl);
          },
        );
      },
    );
  }

  void _showUpdateTrackDialog(Track track) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return CreateTrackDialog(
          artists: _artists,
          genres: _genres,
          initialTrack: track,
          onCreateTrack: (trackName, artistId, genreIds, trackUrl) {
            updateTrack(track.id, trackName, artistId, genreIds, trackUrl);
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
        title: const Center(child: Text('Quản lý Tracks')),
        actions: [
          IconButton(
            icon: Icon(Icons.add),
            onPressed: () {
              _showCreateTrackDialog();
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView.builder(
          itemCount: _tracks.length,
          itemBuilder: (context, index) {
            final track = _tracks[index];

            // ignore: unused_local_variable
            final artist = _artists.firstWhere((artist) => artist.id == track.artistId, orElse: () => Artist(id: '', artistName: 'Unknown'));
            // ignore: unused_local_variable
            final genreNames = track.genreIds.map((genreId) {
              final genre = _genres.firstWhere((genre) => genre.id == genreId, orElse: () => Genre(id: '', genreName: 'Unknown'));
              return genre.genreName;
            }).join(', ');

            return Card(
              margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 8),
              color: Colors.grey[200],
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                leading: track.trackUrl.isNotEmpty && track.trackUrl.endsWith('.mp3')
                    ? const Icon(Icons.music_note, size: 25)
                    : const Icon(Icons.music_off, size: 25),
                title: Text(
                  track.trackName,
                  style: TextStyle(fontSize: 14),
                ),
                subtitle: Text(
                  'Artist: ${artist.artistName}',
                  style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(Icons.edit, size: 20),
                      onPressed: () => _showUpdateTrackDialog(track),
                    ),
                    IconButton(
                      icon: Icon(Icons.delete, size: 20),
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            return AlertDialog(
                              title: Text('Confirm Delete'),
                              content: Text('Are you sure you want to delete this track?'),
                              actions: [
                                TextButton(
                                  onPressed: () {
                                    Navigator.of(context).pop();
                                  },
                                  child: Text('Cancel'),
                                ),
                                TextButton(
                                  onPressed: () {
                                    deleteTrack(track.id);
                                    Navigator.of(context).pop();
                                  },
                                  child: Text('Delete'),
                                ),
                              ],
                            );
                          },
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

class CreateTrackDialog extends StatefulWidget {
  final List<Artist> artists;
  final List<Genre> genres;
  final Track? initialTrack;
  final Function(String trackName, String artistId, List<String> genreIds, String trackUrl) onCreateTrack;

  CreateTrackDialog({
    required this.artists,
    required this.genres,
    required this.onCreateTrack,
    this.initialTrack,
  });

  @override
  _CreateTrackDialogState createState() => _CreateTrackDialogState();
}

class _CreateTrackDialogState extends State<CreateTrackDialog> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _trackNameController = TextEditingController();
  String? _selectedArtistId;
  List<String> _selectedGenreIds = [];
  File? _mp3File;
  String _trackUrl = '';

  @override
  void initState() {
    super.initState();
    if (widget.initialTrack != null) {
      _trackNameController.text = widget.initialTrack!.trackName;
      _selectedArtistId = widget.initialTrack!.artistId;
      _trackUrl = widget.initialTrack!.trackUrl;
      _selectedGenreIds = widget.initialTrack!.genreIds.where((id) => widget.genres.any((genre) => genre.id == id)).toList();
    } else if (widget.artists.isNotEmpty) {
      _selectedArtistId = widget.artists[0].id;
    }
  }

  Future<void> _pickMP3File() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.audio,
      allowedExtensions: ['mp3'],
    );

    if (result != null) {
      final pickedFile = File(result.files.single.path!);
      setState(() {
        _mp3File = pickedFile;
      });
    } else {
      print("No file selected.");
    }
  }

  Future<String> uploadMP3File(File file) async {
    const String cloudName = 'dvpmjwcmh';
    const String uploadPreset = 'upload_img';
    const String folderName = 'track_file_mp3';
    final mimeTypeData = lookupMimeType(file.path, headerBytes: [0xFF, 0xD8])?.split('/');
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('https://api.cloudinary.com/v1_1/$cloudName/upload'),
    );

    request.files.add(await http.MultipartFile.fromPath('file', file.path, contentType: MediaType(mimeTypeData![0], mimeTypeData[1])));
    request.fields['upload_preset'] = uploadPreset;
    request.fields['folder'] = folderName;

    try {
      final response = await request.send();
      final responseData = await response.stream.toBytes();
      final result = json.decode(utf8.decode(responseData));

      if (response.statusCode == 200 && result.containsKey('secure_url')) {
        return result['secure_url'];
      } else {
        throw Exception('Failed to upload file to Cloudinary: $result');
      }
    } catch (e) {
      print('Upload error: $e');
      throw Exception('File upload failed');
    }
  }

  Future<void> _showGenreSelectionDialog() async {
    List<String> tempSelectedGenres = List.from(_selectedGenreIds);

    final result = await showDialog<List<String>>(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('Select Genres'),
              content: SingleChildScrollView(
                child: ListBody(
                  children: widget.genres.map((genre) {
                    return CheckboxListTile(
                      title: Text(genre.genreName),
                      value: tempSelectedGenres.contains(genre.id),
                      onChanged: (isSelected) {
                        setState(() {
                          if (isSelected!) {
                            tempSelectedGenres.add(genre.id);
                          } else {
                            tempSelectedGenres.remove(genre.id);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
              ),
              actions: [
                TextButton(
                  child: Text('Cancel'),
                  onPressed: () {
                    Navigator.of(context).pop(); // Đóng dialog mà không cập nhật
                  },
                ),
                TextButton(
                  child: Text('Done'),
                  onPressed: () {
                    Navigator.of(context).pop(tempSelectedGenres); // Trả về danh sách đã chọn
                  },
                ),
              ],
            );
          },
        );
      },
    );

    if (result != null) {
      setState(() {
        _selectedGenreIds = result;
      });
    }
  }


  void _resetForm() {
    _trackNameController.clear();
    setState(() {
      _selectedArtistId = widget.artists.isNotEmpty ? widget.artists[0].id : null;
      _selectedGenreIds = [];
      _mp3File = null;
      _trackUrl = '';
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.initialTrack != null ? 'Update Track' : 'Create Track'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _trackNameController,
                decoration: InputDecoration(labelText: 'Track Name'),
                validator: (value) => value!.isEmpty ? 'Please enter a track name' : null,
              ),
              DropdownButtonFormField<String>(
                value: _selectedArtistId,
                decoration: InputDecoration(labelText: 'Artist'),
                items: widget.artists.map((artist) {
                  return DropdownMenuItem(
                    value: artist.id,
                    child: Text(artist.artistName),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedArtistId = value;
                  });
                },
              ),
              const Divider(), // Added divider to separate Genre section
              // Display the selected genres
              if (_selectedGenreIds.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Text(
                    'Selected Genres: ${widget.genres.where((genre) => _selectedGenreIds.contains(genre.id)).map((genre) => genre.genreName).join(', ')}',
                    style: const TextStyle(
                      color: Colors.black, 
                      fontSize: 13,
                    ),
                    textAlign: TextAlign.left, // Căn lề trái
                  ),
                ),
              TextButton(
                onPressed: _showGenreSelectionDialog,
                style: TextButton.styleFrom(
                  backgroundColor: Colors.grey[300], // Màu nền xám nhạt
                ),
                child: Text(
                  'Select Genres (${_selectedGenreIds.length} selected)',
                  style: const TextStyle(color: Colors.blue),
                ),
              ),
              Divider(), // Divider to separate MP3 file section
              ElevatedButton(
                onPressed: _pickMP3File,
                child: const Text('Select MP3 File'),
              ),
              // Show the selected file name
              if (_mp3File != null)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Text(
                    'Selected file: ${p.basename(_mp3File!.path)}', // Lấy tên tệp từ đường dẫn đầy đủ
                    style: const TextStyle(color: Colors.black),
                  ),
                ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () async {
            if (_formKey.currentState!.validate()) {
              String trackUrl = _trackUrl;
              if (_mp3File != null) {
                trackUrl = await uploadMP3File(_mp3File!);
              }
              widget.onCreateTrack(
                _trackNameController.text,
                _selectedArtistId!,
                _selectedGenreIds,
                trackUrl,
              );
              Navigator.of(context).pop();
            }
          },
          child: Text(widget.initialTrack != null ? 'Update' : 'Create'),
        ),
        TextButton(
          onPressed: _resetForm,
          child: Text('Reset'),
        ),
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: Text('Cancel'),
        ),
      ],
    );
  }

}


class Track {
  final String id;
  final String trackName;
  final String artistId;
  final List<String> genreIds;
  final List<String> genreName;
  final String trackUrl;
  final String artistName;

  Track({
    required this.id,
    required this.trackName,
    required this.artistId,
    required this.genreIds,
    required this.genreName,
    required this.trackUrl,
    required this.artistName,
  });

  factory Track.fromJson(Map<String, dynamic> json) {
    return Track(
      id: json['_id'] ?? '',
      trackName: json['trackName'] ?? '',
      artistId: json['artistID']?['_id'] ?? '',
      genreIds: json['genreIDs'] != null 
          ? List<String>.from(json['genreIDs'].map((genre) => genre['_id'] ?? '')) 
          : [],
      genreName: json['genreIDs'] != null
          ? List<String>.from(json['genreIDs'].map((genre) => genre['genreName'] ?? '')) 
          : [],
      trackUrl: json['trackURL'] ?? '',
      artistName: json['artistID']?['artistName'] ?? '',
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
      artistName: json['artistName']);
  }
}

class Genre {
  final String id;
  final String genreName;

  Genre({required this.id, required this.genreName});

  factory Genre.fromJson(Map<String, dynamic> json) {
    return Genre(
      id: json['_id'], 
      genreName: json['genreName']);
  }
}
