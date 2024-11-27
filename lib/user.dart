import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class UserManagementPage extends StatefulWidget {
  const UserManagementPage({super.key});

  @override
  _UserManagementPageState createState() => _UserManagementPageState();
}

class _UserManagementPageState extends State<UserManagementPage> {
  List<User> _users = [];
  bool _isLoading = true;
  String? _token;

  @override
  void initState() {
    super.initState();
    fetchToken().then((token) {
      if (token != null) {
        _token = token;
        fetchUsers();
      }
    });
  }

  Future<String?> fetchToken() async {
    final url = Uri.parse('http://localhost:3000/api/admin');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final jsonResponse = json.decode(response.body);
      return jsonResponse['token'];
    } else {
      throw Exception('Failed to fetch token');
    }
  }

  Future<void> fetchUsers() async {
    if (_token == null) return;

    final url = Uri.parse('http://localhost:3000/api/users');
    final response = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $_token',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> userJson = json.decode(response.body);
      setState(() {
        _users = userJson.map((json) => User.fromJson(json)).toList();
        _isLoading = false;
      });
    } else {
      setState(() {
        _isLoading = false;
      });
      throw Exception('Failed to load users');
    }
  }

  Future<void> updateUser(String userId, Map<String, String> updatedData, {String? oldPassword, String? newPassword}) async {
    if (_token == null) return;

    if (oldPassword != null && newPassword != null && oldPassword == newPassword) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'New password cannot be the same as the old password.',
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    // Thêm oldPassword và newPassword nếu có
    if (oldPassword != null) {
      updatedData['oldPassword'] = oldPassword;
    }
    if (newPassword != null) {
      updatedData['newPassword'] = newPassword;
    }

    final url = Uri.parse('http://localhost:3000/api/users/$userId');
    try {
      final response = await http.put(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_token',
        },
        body: json.encode(updatedData),
      );

      if (response.statusCode == 200) {
        fetchUsers();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User updated successfully')),
        );
      } else {
        final errorResponse = json.decode(response.body);
        final errorMessage = errorResponse['error'] ?? 'Unknown error';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $errorMessage')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to update user. Please try again later.')),
      );
    }
  }

  Future<void> deleteUser(String userId) async {
    if (_token == null) return;

    final url = Uri.parse('http://localhost:3000/api/users/$userId');
    final response = await http.delete(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $_token',
      },
    );

    if (response.statusCode == 200) {
      setState(() {
        _users.removeWhere((user) => user.id == userId);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User deleted successfully')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to delete user')),
      );
    }
  }

  void _showEditUserForm(User user) {
  final formKey = GlobalKey<FormState>();
  final userNameController = TextEditingController(text: user.userName);
  final emailController = TextEditingController(text: user.email);
  final passwordController = TextEditingController();
  final oldPasswordController = TextEditingController();
  final newPasswordController = TextEditingController();

  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: const Text('Edit User Information'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              TextFormField(
                controller: userNameController,
                decoration: const InputDecoration(labelText: 'Username'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a username';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: emailController,
                decoration: const InputDecoration(labelText: 'Email'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter an email';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: oldPasswordController,
                decoration: const InputDecoration(labelText: 'Old Password'),
                obscureText: true,
              ),
              TextFormField(
                controller: newPasswordController,
                decoration: const InputDecoration(labelText: 'New Password'),
                obscureText: true,
              ),
              TextFormField(
                controller: passwordController,
                decoration: const InputDecoration(labelText: 'Password (leave empty to keep current)'),
                obscureText: true,
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
                  'userName': userNameController.text,
                  'email': emailController.text,
                  if (passwordController.text.isNotEmpty) 'password': passwordController.text,
                };

                final oldPassword = oldPasswordController.text.isNotEmpty ? oldPasswordController.text : null;
                final newPassword = newPasswordController.text.isNotEmpty ? newPasswordController.text : null;

                updateUser(user.id, updatedData, oldPassword: oldPassword, newPassword: newPassword);
                Navigator.of(context).pop();
              }
            },
          ),
        ],
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
        title: const Text('Quản lý Users'),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: _users.length,
              itemBuilder: (context, index) {
                final user = _users[index];
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
                  color: Colors.grey[200],
                  child: ListTile(
                    leading: user.profilePicture.isNotEmpty
                        ? CircleAvatar(
                            backgroundImage: NetworkImage(user.profilePicture),
                          )
                        : const CircleAvatar(
                            child: Icon(Icons.person),
                          ),
                    title: Text(user.userName),
                    subtitle: Text(user.email),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit),
                          onPressed: () => _showEditUserForm(user),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete),
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('Xóa người dùng?'),
                                content: const Text('Bạn có chắc muốn xóa người dùng này không?'),
                                actions: <Widget>[
                                  TextButton(
                                    child: const Text('Hủy'),
                                    onPressed: () {
                                      Navigator.of(context).pop();
                                    },
                                  ),
                                  TextButton(
                                    child: const Text('Xóa'),
                                    onPressed: () {
                                      Navigator.of(context).pop();
                                      deleteUser(user.id); // Gọi hàm xóa
                                    },
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
    );
  }
}

class User {
  final String id;
  String userName;
  String email;
  final String profilePicture;

  User({
    required this.id,
    required this.userName,
    required this.email,
    required this.profilePicture,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['_id'],
      userName: json['userName'],
      email: json['email'],
      profilePicture: json['profilePicture'] ?? '',
    );
  }
}
