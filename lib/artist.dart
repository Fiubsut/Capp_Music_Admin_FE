import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class ArtistManagementPage extends StatefulWidget {
  const ArtistManagementPage({super.key});

  @override
  _ArtistManagementPageState createState() => _ArtistManagementPageState();
}

class _ArtistManagementPageState extends State<ArtistManagementPage> {
  List<Artist> _artists = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchArtists();
  }

  // Fetch artists from the backend
  Future<void> fetchArtists() async {
    final url = Uri.parse('http://localhost:3000/api/artists');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final List<dynamic> artistJson = json.decode(response.body);
      setState(() {
        _artists = artistJson.map((json) => Artist.fromJson(json)).toList();
        _isLoading = false;
      });
    } else {
      setState(() {
        _isLoading = false;
      });
      // Handle error
    }
  }

  // Delete an artist after confirmation
  Future<void> deleteArtist(String artistId) async {
    final url = Uri.parse('http://localhost:3000/api/artists/$artistId');
    final response = await http.delete(url);

    if (response.statusCode == 200) {
      setState(() {
        _artists.removeWhere((artist) => artist.id == artistId);
      });
      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Artist deleted successfully')),
      );
    } else {
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to delete artist')),
      );
    }
  }

  // Show a dialog to update an artist
  void _showEditArtistForm(Artist artist) {
    final formKey = GlobalKey<FormState>();
    final artistNameController = TextEditingController(text: artist.artistName);
    final genreController = TextEditingController(text: artist.genre);
    final countryController = TextEditingController(text: artist.country);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Edit Artist Information'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                TextFormField(
                  controller: artistNameController,
                  decoration: const InputDecoration(labelText: 'Artist Name'),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter an artist name';
                    }
                    return null;
                  },
                ),
                TextFormField(
                  controller: genreController,
                  decoration: const InputDecoration(labelText: 'Genre'),
                ),
                TextFormField(
                  controller: countryController,
                  decoration: const InputDecoration(labelText: 'Country'),
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Save'),
              onPressed: () {
                if (formKey.currentState?.validate() ?? false) {
                  final updatedData = {
                    'artistName': artistNameController.text,
                    'genre': genreController.text,
                    'country': countryController.text,
                  };
                  updateArtist(artist.id, updatedData);
                  Navigator.of(context).pop();
                }
              },
            ),
          ],
        );
      },
    );
  }

  // Update artist information
  Future<void> updateArtist(String artistId, Map<String, String> updatedData) async {
    final url = Uri.parse('http://localhost:3000/api/artists/$artistId');
    final response = await http.put(
      url,
      headers: {'Content-Type': 'application/json'},
      body: json.encode(updatedData),
    );

    if (response.statusCode == 200) {
      fetchArtists(); // Refresh the artist list
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Artist updated successfully')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to update artist')),
      );
    }
  }

  // Show a confirmation dialog before deleting an artist
  void _showDeleteConfirmationDialog(String artistId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Artist?'),
          content: const Text('Are you sure you want to delete this artist?'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Delete'),
              onPressed: () {
                Navigator.of(context).pop();
                deleteArtist(artistId); // Delete artist
              },
            ),
          ],
        );
      },
    );
  }

  // Show a form to create a new artist
  void _showCreateArtistForm() {
    final formKey = GlobalKey<FormState>();
    final artistNameController = TextEditingController();
    final genreController = TextEditingController();
    final countryController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Create New Artist'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                TextFormField(
                  controller: artistNameController,
                  decoration: const InputDecoration(labelText: 'Artist Name'),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter an artist name';
                    }
                    return null;
                  },
                ),
                TextFormField(
                  controller: genreController,
                  decoration: const InputDecoration(labelText: 'Genre'),
                ),
                TextFormField(
                  controller: countryController,
                  decoration: const InputDecoration(labelText: 'Country'),
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Create'),
              onPressed: () {
                if (formKey.currentState?.validate() ?? false) {
                  createArtist({
                    'artistName': artistNameController.text,
                    'genre': genreController.text,
                    'country': countryController.text,
                  });
                  Navigator.of(context).pop();
                }
              },
            ),
          ],
        );
      },
    );
  }

  // Create a new artist
  Future<void> createArtist(Map<String, String> artistData) async {
    final url = Uri.parse('http://localhost:3000/api/artists');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: json.encode(artistData),
    );

    if (response.statusCode == 201) {
      fetchArtists(); // Refresh the list after creating a new artist
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Artist created successfully')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to create artist')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text('Quản lý Artists'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _showCreateArtistForm,
            tooltip: 'Create Artist',
          ),
        ],
      ),
      body: Stack(
        children: [
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : ListView.builder(
                  itemCount: _artists.length,
                  itemBuilder: (context, index) {
                    final artist = _artists[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                      child: ListTile(
                        title: Text(artist.artistName),
                        subtitle: Text('${artist.genre} - ${artist.country}'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit),
                              onPressed: () => _showEditArtistForm(artist),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete),
                              onPressed: () => _showDeleteConfirmationDialog(artist.id),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ],
      ),
    );
  }
}

class Artist {
  final String id;
  final String artistName;
  final String genre;
  final String country;

  Artist({
    required this.id,
    required this.artistName,
    required this.genre,
    required this.country,
  });

  factory Artist.fromJson(Map<String, dynamic> json) {
    return Artist(
      id: json['_id'],
      artistName: json['artistName'],
      genre: json['genre'],
      country: json['country'],
    );
  }
}
