class UserModel {
  final String id;
  final String name;
  final String email;
  final String image;
  final String isOnline;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.image,
    required this.isOnline,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['_id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      image: json['image'] ?? '',
      isOnline: json['is_online'] ?? '0',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'name': name,
      'email': email,
      'image': image,
      'is_online': isOnline,
    };
  }

  bool get online => isOnline == '1';
}
