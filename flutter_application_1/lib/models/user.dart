class User {
  final int userId;
  final String username;
  final String fullname;
  final String? phone;
  final String? email;
  final int? roleId;
  final String? userImage;
  final String? authToken;
  final bool isActive;

  const User({
    required this.userId,
    required this.username,
    required this.fullname,
    this.phone,
    this.email,
    this.roleId,
    this.userImage,
    this.authToken,
    this.isActive = true,
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
      authToken: json['token'] ?? json['auth_token'],
      isActive: json['is_active'] == null ||
          json['is_active'] == true ||
          json['is_active'].toString() == '1',
    );
  }
}
