class User {
  final int userId;
  final String username;
  final String fullname;
  final String? phone;
  final String? email;
  final int? roleId;
  final String? userImage;

  const User({
    required this.userId,
    required this.username,
    required this.fullname,
    this.phone,
    this.email,
    this.roleId,
    this.userImage,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      userId: json['user_id'] ?? 0,
      username: json['username'] ?? '',
      fullname: json['fullname'] ?? '',
      phone: json['phone'],
      email: json['email'],
      roleId: json['role_id'],
      userImage: json['user_image'],
    );
  }
}