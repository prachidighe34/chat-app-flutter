import 'dart:convert';
import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../services/socket_service.dart';
import 'chat_screen.dart';
import 'login_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  List<UserModel> _users = [];
  UserModel? _currentUser;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final userJson = await AuthService.getUser();
      print('Current user: $userJson');

      if (userJson != null) {
        final userMap = jsonDecode(userJson);
        _currentUser = UserModel.fromJson(userMap);
        SocketService.connect(_currentUser!.id);
        _setupSocketListeners();
      }

      final response = await ApiService.getUsers();
      print('Users response: $response');

      if (response['success'] == true) {
        final List usersData = response['users'];
        print('Users count: ${usersData.length}');
        setState(() {
          _users = usersData.map((u) => UserModel.fromJson(u)).toList();
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = response['message'];
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Dashboard error: $e');
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _setupSocketListeners() {
    SocketService.onUserOnline((data) {
      setState(() {
        final index = _users.indexWhere((u) => u.id == data['userId']);
        if (index != -1) {
          _users[index] = UserModel(
            id: _users[index].id,
            name: _users[index].name,
            email: _users[index].email,
            image: _users[index].image,
            isOnline: '1',
          );
        }
      });
    });

    SocketService.onUserOffline((data) {
      setState(() {
        final index = _users.indexWhere((u) => u.id == data['userId']);
        if (index != -1) {
          _users[index] = UserModel(
            id: _users[index].id,
            name: _users[index].name,
            email: _users[index].email,
            image: _users[index].image,
            isOnline: '0',
          );
        }
      });
    });
  }

  Future<void> _logout() async {
    SocketService.disconnect();
    await AuthService.clearAll();
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    }
  }

  @override
  void dispose() {
    SocketService.offUserOnline();
    SocketService.offUserOffline();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
        title: Text(
          _currentUser != null ? 'Hello ${_currentUser!.name}' : 'Dashboard',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(icon: const Icon(Icons.logout), onPressed: _logout),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 48),
                  const SizedBox(height: 16),
                  Text(
                    _error!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.red),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _loadData,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            )
          : _users.isEmpty
          ? const Center(
              child: Text(
                'No other users yet.\nInvite someone to join!',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey, fontSize: 16),
              ),
            )
          : RefreshIndicator(
              onRefresh: _loadData,
              child: ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: _users.length,
                itemBuilder: (context, index) {
                  final user = _users[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      leading: Stack(
                        children: [
                          CircleAvatar(
                            radius: 26,
                            backgroundColor: Colors.blueAccent.withOpacity(0.1),
                            backgroundImage: user.image.isNotEmpty
                                ? NetworkImage(user.image)
                                : null,
                            child: user.image.isEmpty
                                ? Text(
                                    user.name[0].toUpperCase(),
                                    style: const TextStyle(
                                      color: Colors.blueAccent,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                    ),
                                  )
                                : null,
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              width: 14,
                              height: 14,
                              decoration: BoxDecoration(
                                color: user.online ? Colors.green : Colors.grey,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 2,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      title: Text(
                        user.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                      subtitle: Text(
                        user.online ? 'Online' : 'Offline',
                        style: TextStyle(
                          color: user.online ? Colors.green : Colors.grey,
                          fontSize: 13,
                        ),
                      ),
                      trailing: const Icon(
                        Icons.chat_bubble_outline,
                        color: Colors.blueAccent,
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ChatScreen(
                              currentUser: _currentUser!,
                              receiverUser: user,
                            ),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
    );
  }
}
