// lib/screens/chat_screen.dart
import 'package:flutter/material.dart';
import '../models/user_model.dart';

class ChatScreen extends StatelessWidget {
  final UserModel currentUser;
  final UserModel receiverUser;

  const ChatScreen({
    super.key,
    required this.currentUser,
    required this.receiverUser,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(receiverUser.name)),
      body: const Center(child: Text('Chat coming soon')),
    );
  }
}
