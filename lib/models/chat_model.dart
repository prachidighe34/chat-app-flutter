class ChatModel {
  final String id;
  final String senderId;
  final String receiverId;
  final String message;
  final DateTime? createdAt;

  ChatModel({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.message,
    this.createdAt,
  });

  factory ChatModel.fromJson(Map<String, dynamic> json) {
    return ChatModel(
      id: json['_id'] ?? '',
      senderId: json['sender_id'] ?? '',
      receiverId: json['receiver_id'] ?? '',
      message: json['message'] ?? '',
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'sender_id': senderId,
      'receiver_id': receiverId,
      'message': message,
      'createdAt': createdAt?.toIso8601String(),
    };
  }
}
