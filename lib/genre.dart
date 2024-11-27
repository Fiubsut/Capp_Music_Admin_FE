import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class GenreManagementPage extends StatefulWidget {
  @override
  _GenreManagementPageState createState() => _GenreManagementPageState();
}

class _GenreManagementPageState extends State<GenreManagementPage> {
  List<dynamic> genres = [];
  final TextEditingController _genreNameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchGenres();
  }

  // Lấy danh sách genre từ backend
  Future<void> _fetchGenres() async {
    final response = await http.get(Uri.parse('http://localhost:3000/api/genres'));
    if (response.statusCode == 200) {
      setState(() {
        genres = json.decode(response.body);
      });
    } else {
      throw Exception('Failed to load genres');
    }
  }

  // Tạo genre mới
  Future<void> _createGenre() async {
    final genreName = _genreNameController.text;
    if (genreName.isEmpty) return;

    final response = await http.post(
      Uri.parse('http://localhost:3000/api/genres'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'genreName': genreName}),
    );

    if (response.statusCode == 201) {
      setState(() {
        genres.add(json.decode(response.body)['genre']);
      });
      _genreNameController.clear();
      Navigator.of(context).pop();
    } else {
      throw Exception('Failed to create genre');
    }
  }

  // Cập nhật genre
  Future<void> _updateGenre(String genreId) async {
    final genreName = _genreNameController.text;
    if (genreName.isEmpty) return;

    final response = await http.put(
      Uri.parse('http://localhost:3000/api/genres/$genreId'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'genreName': genreName}),
    );

    if (response.statusCode == 200) {
      setState(() {
        genres = genres.map((genre) {
          if (genre['_id'] == genreId) {
            genre['genreName'] = genreName;
          }
          return genre;
        }).toList();
      });
      _genreNameController.clear();
      Navigator.of(context).pop();
    } else {
      throw Exception('Failed to update genre');
    }
  }

  // Xóa genre với xác nhận
  Future<void> _deleteGenre(String genreId) async {
    bool? confirmDelete = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Confirm Delete'),
        content: Text('Are you sure you want to delete this Genre?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmDelete == true) {
      final response = await http.delete(
        Uri.parse('http://localhost:3000/api/genres/$genreId'),
      );

      if (response.statusCode == 200) {
        setState(() {
          genres.removeWhere((genre) => genre['_id'] == genreId);
        });
      } else {
        throw Exception('Failed to delete genre');
      }
    }
  }

  // Mở form tạo genre mới
  void showCreateGenreDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Create New Genre'),
        content: TextField(
          controller: _genreNameController,
          decoration: InputDecoration(labelText: 'Genre Name'),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: _createGenre,
            child: Text('Create'),
          ),
        ],
      ),
    );
  }

  // Mở form chỉnh sửa genre
  void _showUpdateGenreDialog(String genreId, String currentName) {
    _genreNameController.text = currentName;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Update Genre'),
        content: TextField(
          controller: _genreNameController,
          decoration: InputDecoration(labelText: 'Genre Name'),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              _updateGenre(genreId);
            },
            child: Text('Update'),
          ),
        ],
      ),
    );
  }

  // Hiển thị các genre trong danh sách
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text('Quản lý Genres'),
        actions: [
          IconButton(
            icon: Icon(Icons.add),
            onPressed: showCreateGenreDialog,
            tooltip: 'Create New Genre',
          ),
        ],
      ),
      body: genres.isEmpty
          ? Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: genres.length,
              itemBuilder: (context, index) {
                final genre = genres[index];
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
                  color: Colors.grey[200],
                  child: ListTile(
                    title: Text(genre['genreName']),
                    subtitle: Text('ID: ${genre['_id']}'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(Icons.edit),
                          onPressed: () {
                            _showUpdateGenreDialog(genre['_id'], genre['genreName']);
                          },
                        ),
                        IconButton(
                          icon: Icon(Icons.delete),
                          onPressed: () {
                            _deleteGenre(genre['_id']);
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
