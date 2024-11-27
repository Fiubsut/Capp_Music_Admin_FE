import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class TrackInAlbumPage extends StatefulWidget {
  final String albumId;

  const TrackInAlbumPage({required this.albumId, Key? key}) : super(key: key);

  @override
  _TrackInAlbumPageState createState() => _TrackInAlbumPageState();
}

class _TrackInAlbumPageState extends State<TrackInAlbumPage> {
  List<Track> _tracks = [];
  List<Track> _allTracks = [];
  bool _isLoading = true;
  bool _isAddingTrack = false;
  Album? _album;

  @override
  void initState() {
    super.initState();
    _fetchAlbumTracks();
    _fetchAllTracks();
  }

  Future<void> _fetchAlbumTracks() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final response = await http.get(Uri.parse('http://localhost:3000/api/albums/${widget.albumId}'));
      if (response.statusCode == 200) {
        final albumData = json.decode(response.body);
        final album = Album.fromJson(albumData);

        setState(() {
          _album = album;
          _tracks = album.tracks;
        });
      } else {
        throw Exception('Failed to load album tracks');
      }
    } catch (e) {
      print("Error fetching album tracks: $e");
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchAllTracks() async {
    try {
      final response = await http.get(Uri.parse('http://localhost:3000/api/tracks'));
      if (response.statusCode == 200) {
        List<dynamic> trackJson = json.decode(response.body);
        setState(() {
          _allTracks = trackJson.map((track) => Track.fromJson(track)).toList();
        });
      } else {
        throw Exception('Failed to load all tracks');
      }
    } catch (e) {
      print("Error fetching all tracks: $e");
    }
  }

  Future<void> _addTrackToAlbum(String trackId) async {
    setState(() {
      _isAddingTrack = true;
    });
    try {
      final response = await http.post(
        Uri.parse('http://localhost:3000/api/albums/${widget.albumId}/addtrack'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'trackIDs': [trackId]}),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Track added to album successfully')),
        );
        _fetchAlbumTracks();
      } else {
        print('Response status: ${response.statusCode}');
        print('Response body: ${response.body}');
        throw Exception('Failed to add track to album');
      }
    } catch (e) {
      print("Error adding track to album: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to add track to album')),
      );
    } finally {
      setState(() {
        _isAddingTrack = false;
      });
    }
  }

  Future<void> _removeTrackFromAlbum(String trackId) async {
    try {
      final response = await http.post(
        Uri.parse('http://localhost:3000/api/albums/${widget.albumId}/removetrack'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'trackIDs': [trackId]}), // Gửi trackIDs là mảng
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Track removed from album successfully')),
        );
        // Lấy lại danh sách track sau khi xóa
        _fetchAlbumTracks();
      } else {
        // Log thông tin lỗi chi tiết
        print('Response status: ${response.statusCode}');
        print('Response body: ${response.body}');
        throw Exception('Failed to remove track from album');
      }
    } catch (e) {
      print("Error removing track from album: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to remove track from album')),
      );
    }
  }

  Future<void> _showDeleteConfirmationDialog(String trackId) async {
    bool? confirmDelete = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Deletion'),
          content: const Text('Are you sure you want to delete this track from the album?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false), // Hủy xóa
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true), // Xác nhận xóa
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    // Nếu người dùng xác nhận xóa, gọi _removeTrackFromAlbum
    if (confirmDelete == true) {
      _removeTrackFromAlbum(trackId);
    }
  }
    
  

  void _showAddTrackDialog() {
    if (_allTracks.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No available tracks to add')),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AddTrackDialog(
          tracks: _allTracks,
          onAddTrack: (trackId) {
            _addTrackToAlbum(trackId);
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
        title: _album == null
            ? const Center(child: Text('Tracks in Album'))
            : Center(child: Text(_album!.albumName)),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _isAddingTrack ? null : _showAddTrackDialog,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _tracks.isEmpty
              ? const Center(
                  child: Text(
                    "Album is empty",
                    style: TextStyle(color: Colors.white),
                  ),
                )
              : ListView.builder(
                  itemCount: _tracks.length,
                  itemBuilder: (context, index) {
                    final track = _tracks[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
                      color: Colors.grey[200],
                      child: ListTile(
                        title: Text(track.trackName),
                        subtitle: Text('Artist: ${_album?.artistName ?? "Unknown"}'), // Lấy artistName từ album
                        trailing: IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: _isAddingTrack ? null : () => _showDeleteConfirmationDialog(track.id),
                      ),
                      ),
                    );
                  },
                ),
    );
  }
}

class AddTrackDialog extends StatefulWidget {
  final List<Track> tracks;
  final Function(String trackId) onAddTrack;

  const AddTrackDialog({required this.tracks, required this.onAddTrack, Key? key}) : super(key: key);

  @override
  _AddTrackDialogState createState() => _AddTrackDialogState();
}

class _AddTrackDialogState extends State<AddTrackDialog> {
  String? _selectedTrackId;

  @override
  void initState() {
    super.initState();
    if (widget.tracks.isNotEmpty) {
      _selectedTrackId = widget.tracks.first.id;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Track to Album'),
      content: DropdownButtonFormField<String>(
        value: _selectedTrackId,
        onChanged: (value) {
          setState(() {
            _selectedTrackId = value;
          });
        },
        items: widget.tracks
            .map((track) => DropdownMenuItem(value: track.id, child: Text(track.trackName)))
            .toList(),
        decoration: const InputDecoration(labelText: 'Track'),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _selectedTrackId != null
              ? () {
                  widget.onAddTrack(_selectedTrackId!);
                  Navigator.of(context).pop();
                }
              : null,
          child: const Text('Add'),
        ),
      ],
    );
  }
}

class Album {
  final String id;
  final String albumName;
  final String artistName;
  final List<Track> tracks;

  Album({
    required this.id,
    required this.albumName,
    required this.artistName,
    required this.tracks,
  });

  factory Album.fromJson(Map<String, dynamic> json) {
    return Album(
      id: json['_id'] ?? '',
      albumName: json['albumName'] ?? '',
      artistName: json['artistID']['artistName'] ?? 'Unknown',
      tracks: (json['trackIDs'] as List<dynamic>? ?? [])
          .map((trackJson) => Track.fromJson(trackJson))
          .toList(),
    );
  }
}

class Track {
  final String id;
  final String trackName;

  Track({
    required this.id,
    required this.trackName,
  });

  factory Track.fromJson(Map<String, dynamic> json) {
    return Track(
      id: json['_id'] ?? '',
      trackName: json['trackName'] ?? '',
    );
  }
}
