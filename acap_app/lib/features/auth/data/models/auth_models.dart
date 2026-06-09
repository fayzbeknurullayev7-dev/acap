import '../../domain/entities/user.dart';

class UserModel extends User {
  const UserModel({
    required super.id,
    required super.email,
    required super.name,
    super.avatarUrl,
    required super.tier,
    required super.role,
    required super.createdAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id:         json['id'] as String,
      email:      json['email'] as String,
      name:       json['name'] as String,
      avatarUrl:  json['avatar_url'] as String?,
      tier:       json['tier'] as String? ?? 'free',
      role:       json['role'] as String? ?? 'user',
      createdAt:  DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
    'id':         id,
    'email':      email,
    'name':       name,
    'avatar_url': avatarUrl,
    'tier':       tier,
    'role':       role,
    'created_at': createdAt.toIso8601String(),
  };
}

class AuthTokensModel extends AuthTokens {
  const AuthTokensModel({
    required super.accessToken,
    required super.refreshToken,
    required super.expiresAt,
  });

  factory AuthTokensModel.fromJson(Map<String, dynamic> json) {
    return AuthTokensModel(
      accessToken:  json['access_token'] as String,
      refreshToken: json['refresh_token'] as String,
      expiresAt:    DateTime.parse(
        json['expires_at'] as String? ??
        DateTime.now().add(const Duration(hours: 1)).toIso8601String(),
      ),
    );
  }
}
