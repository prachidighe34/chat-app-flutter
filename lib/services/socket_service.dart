import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../constants/app_constant.dart';

class SocketService {
  static IO.Socket? _socket;

  // ─── Connect ──────────────────────────────────────────────────
  static void connect(String userId) {
    // If you want to use a namespace, include it in the URL instead of using
    // setNamespace (not available on OptionBuilder).
    final uri = '${AppConstant.baseUrl}/user-namespace';

    _socket = IO.io(
      uri,
      IO.OptionBuilder()
          .setTransports(['websocket', 'polling'])
          .setAuth({'token': userId})
          .enableAutoConnect()
          .enableReconnection()
          .build(),
    );

    _socket!.onConnect((_) {
      print('Socket connected');
    });

    _socket!.onDisconnect((_) {
      print('Socket disconnected');
    });

    _socket!.onConnectError((error) {
      print('Socket connection error: $error');
    });
  }

  // ─── Disconnect ───────────────────────────────────────────────
  static void disconnect() {
    _socket?.disconnect();
    _socket = null;
  }

  // ─── Emit events ──────────────────────────────────────────────

  static void sendMessage(Map<String, dynamic> data) {
    _socket?.emit('newChat', data);
  }

  static void loadExistingChats(String senderId, String receiverId) {
    _socket?.emit('existingChat', {
      'sender_id': senderId,
      'receiver_id': receiverId,
    });
  }

  static void deleteChat(String chatId) {
    _socket?.emit('chatDeleted', chatId);
  }

  static void updateChat(String chatId, String message) {
    _socket?.emit('chatUpdated', {'chatId': chatId, 'message': message});
  }

  static void sendGroupMessage(Map<String, dynamic> data) {
    _socket?.emit('newGroupChat', data);
  }

  static void deleteGroupChat(String chatId) {
    _socket?.emit('groupChatDeleted', chatId);
  }

  static void updateGroupChat(String chatId, String message) {
    _socket?.emit('groupChatUpdated', {'id': chatId, 'message': message});
  }

  // ─── Listen to events ─────────────────────────────────────────

  static void onNewMessage(Function(dynamic) callback) {
    _socket?.on('loadNewChat', callback);
  }

  static void onLoadChats(Function(dynamic) callback) {
    _socket?.on('loadChats', callback);
  }

  static void onMessageDeleted(Function(dynamic) callback) {
    _socket?.on('loadDeletedChat', callback);
  }

  static void onMessageUpdated(Function(dynamic) callback) {
    _socket?.on('loadUpdatedChat', callback);
  }

  static void onNewGroupMessage(Function(dynamic) callback) {
    _socket?.on('loadNewGroupChat', callback);
  }

  static void onGroupMessageDeleted(Function(dynamic) callback) {
    _socket?.on('groupChatMessageDeleted', callback);
  }

  static void onGroupMessageUpdated(Function(dynamic) callback) {
    _socket?.on('groupChatMessageUpdated', callback);
  }

  static void onUserOnline(Function(dynamic) callback) {
    _socket?.on('getOnlineUser', callback);
  }

  static void onUserOffline(Function(dynamic) callback) {
    _socket?.on('getOfflineUser', callback);
  }

  // ─── Remove listeners (call in dispose) ───────────────────────
  static void offNewMessage() => _socket?.off('loadNewChat');
  static void offLoadChats() => _socket?.off('loadChats');
  static void offNewGroupMessage() => _socket?.off('loadNewGroupChat');
  static void offUserOnline() => _socket?.off('getOnlineUser');
  static void offUserOffline() => _socket?.off('getOfflineUser');

  // ─── Getters ──────────────────────────────────────────────────
  static bool get isConnected => _socket?.connected ?? false;
  static IO.Socket? get socket => _socket;
}
