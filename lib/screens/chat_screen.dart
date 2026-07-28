import 'dart:convert';
import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../models/chat_model.dart';
import '../services/api_service.dart';
import '../services/socket_service.dart';

class ChatScreen extends StatefulWidget {
  final UserModel currentUser;
  final UserModel receiverUser;

  const ChatScreen({
    super.key,
    required this.currentUser,
    required this.receiverUser,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  List<ChatModel> _messages = [];
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    _setupSocketListeners();
    _loadExistingChats();
  }

  void _loadExistingChats() {
    SocketService.loadExistingChats(
      widget.currentUser.id,
      widget.receiverUser.id,
    );
  }

  void _setupSocketListeners() {
    // load existing chat history
    SocketService.onLoadChats((data) {
      final List chats = data['chats'];
      setState(() {
        _messages = chats.map((c) => ChatModel.fromJson(c)).toList();
      });
      _scrollToBottom();
    });

    // receive new real-time message
    SocketService.onNewMessage((data) {
      final msg = ChatModel.fromJson(data);
      // only add if it's from the current receiver
      if (msg.senderId == widget.receiverUser.id &&
          msg.receiverId == widget.currentUser.id) {
        setState(() => _messages.add(msg));
        _scrollToBottom();
      }
    });

    // message deleted by other user
    SocketService.onMessageDeleted((id) {
      setState(() => _messages.removeWhere((m) => m.id == id));
    });

    // message updated by other user
    SocketService.onMessageUpdated((data) {
      setState(() {
        final index = _messages.indexWhere((m) => m.id == data['chatId']);
        if (index != -1) {
          _messages[index] = ChatModel(
            id: _messages[index].id,
            senderId: _messages[index].senderId,
            receiverId: _messages[index].receiverId,
            message: data['message'],
            createdAt: _messages[index].createdAt,
          );
        }
      });
    });
  }

  Future<void> _sendMessage() async {
    final message = _messageController.text.trim();
    if (message.isEmpty || _isSending) return;

    setState(() => _isSending = true);
    _messageController.clear();

    final response = await ApiService.saveChat(
      senderId: widget.currentUser.id,
      receiverId: widget.receiverUser.id,
      message: message,
    );

    if (response['success'] == true) {
      final newMsg = ChatModel.fromJson(response['data']);
      setState(() => _messages.add(newMsg));
      // emit to socket so receiver gets it in real time
      SocketService.sendMessage(response['data']);
      _scrollToBottom();
    }

    setState(() => _isSending = false);
  }

  Future<void> _deleteMessage(String chatId) async {
    final response = await ApiService.deleteChat(chatId);
    if (response['success'] == true) {
      setState(() => _messages.removeWhere((m) => m.id == chatId));
      SocketService.deleteChat(chatId);
    }
  }

  Future<void> _showEditDialog(ChatModel msg) async {
    final controller = TextEditingController(text: msg.message);
    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Edit Message'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'Enter new message'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              final newMsg = controller.text.trim();
              if (newMsg.isEmpty) return;

              final response = await ApiService.updateChat(
                chatId: msg.id,
                message: newMsg,
              );

              if (response['success'] == true) {
                setState(() {
                  final index = _messages.indexWhere((m) => m.id == msg.id);
                  if (index != -1) {
                    _messages[index] = ChatModel(
                      id: msg.id,
                      senderId: msg.senderId,
                      receiverId: msg.receiverId,
                      message: newMsg,
                      createdAt: msg.createdAt,
                    );
                  }
                });
                SocketService.updateChat(msg.id, newMsg);
              }
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    SocketService.offLoadChats();
    SocketService.offNewMessage();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: Colors.white.withOpacity(0.3),
              backgroundImage: widget.receiverUser.image.isNotEmpty
                  ? NetworkImage(widget.receiverUser.image)
                  : null,
              child: widget.receiverUser.image.isEmpty
                  ? Text(
                      widget.receiverUser.name[0].toUpperCase(),
                      style: const TextStyle(color: Colors.white),
                    )
                  : null,
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.receiverUser.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  widget.receiverUser.online ? 'Online' : 'Offline',
                  style: TextStyle(
                    fontSize: 12,
                    color: widget.receiverUser.online
                        ? Colors.greenAccent
                        : Colors.white70,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // messages list
          Expanded(
            child: _messages.isEmpty
                ? const Center(
                    child: Text(
                      'No messages yet.\nSay hello!',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey, fontSize: 16),
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(12),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final msg = _messages[index];
                      final isMe = msg.senderId == widget.currentUser.id;
                      return _ChatBubble(
                        message: msg,
                        isMe: isMe,
                        onDelete: () => _deleteMessage(msg.id),
                        onEdit: () => _showEditDialog(msg),
                      );
                    },
                  ),
          ),

          // message input
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            color: Colors.white,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: 'Type a message...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.grey[100],
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 8),
                CircleAvatar(
                  backgroundColor: Colors.blueAccent,
                  child: _isSending
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : IconButton(
                          icon: const Icon(Icons.send, color: Colors.white),
                          onPressed: _sendMessage,
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ChatBubble extends StatelessWidget {
  final ChatModel message;
  final bool isMe;
  final VoidCallback onDelete;
  final VoidCallback onEdit;

  const _ChatBubble({
    required this.message,
    required this.isMe,
    required this.onDelete,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPress: isMe
          ? () => showModalBottomSheet(
              context: context,
              builder: (_) => SafeArea(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ListTile(
                      leading: const Icon(Icons.edit),
                      title: const Text('Edit'),
                      onTap: () {
                        Navigator.pop(context);
                        onEdit();
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.delete, color: Colors.red),
                      title: const Text(
                        'Delete',
                        style: TextStyle(color: Colors.red),
                      ),
                      onTap: () {
                        Navigator.pop(context);
                        onDelete();
                      },
                    ),
                  ],
                ),
              ),
            )
          : null,
      child: Align(
        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.75,
          ),
          decoration: BoxDecoration(
            color: isMe ? Colors.blueAccent : Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(16),
              topRight: const Radius.circular(16),
              bottomLeft: Radius.circular(isMe ? 16 : 4),
              bottomRight: Radius.circular(isMe ? 4 : 16),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Text(
            message.message,
            style: TextStyle(
              color: isMe ? Colors.white : Colors.black87,
              fontSize: 15,
            ),
          ),
        ),
      ),
    );
  }
}
