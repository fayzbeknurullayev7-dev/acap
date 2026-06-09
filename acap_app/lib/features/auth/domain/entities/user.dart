import 'package:equatable/equatable.dart';

class User extends Equatable {
  final String id;
  final String email;
  final String name;
  final String? avatarUrl;
  final String tier;    // free | pro | team | enterprise
  final String role;    // user | admin
  final DateTime createdAt;

  const User({
    required this.id,
    required this.email,
    required this.name,
    this.avatarUrl,
    required this.tier,
    required this.role,
    required this.createdAt,
  });

  bool get isPro        => tier != 'free';
  bool get isTeam       => tier == 'team' || tier == 'enterprise';
  bool get isEnterprise => tier == 'enterprise';

  @override
  List<Object?> get props => [id, email, name, tier, role];
}

class AuthTokens extends Equatable {
  final String accessToken;
  final String refreshToken;
  final DateTime expiresAt;

  const AuthTokens({
    required this.accessToken,
    required this.refreshToken,
    required this.expiresAt,
  });

  bool get isExpired => DateTime.now().isAfter(expiresAt);

  @override
  List<Object?> get props => [accessToken, refreshToken];
}
