class UserModel {
  const UserModel({
    required this.id,
    required this.email,
    required this.name,
    required this.nickname,
    required this.role,
  });

  final int id;
  final String email;
  final String name;
  final String nickname;
  final String role;

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: (json['id'] as num?)?.toInt() ?? 0,
      email: json['email']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      nickname: json['nickname']?.toString() ?? '',
      role: json['role']?.toString() ?? '',
    );
  }
}

class LoginResponseModel {
  const LoginResponseModel({
    required this.tokenType,
    required this.accessToken,
    required this.user,
  });

  final String tokenType;
  final String accessToken;
  final UserModel user;

  factory LoginResponseModel.fromJson(Map<String, dynamic> json) {
    return LoginResponseModel(
      tokenType: json['tokenType']?.toString() ?? 'Bearer',
      accessToken: json['accessToken']?.toString() ?? '',
      user: UserModel.fromJson(json),
    );
  }
}
