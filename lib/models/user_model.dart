// lib/models/user_model.dart

class UserModel {
  final String uid;
  final String username;
  final String displayName;
  final String avatar;
  final String email;
  final int level;
  final int xp;
  final int coins;
  final int gems;
  final DateTime createdAt;
  final DateTime lastLoginAt;
  final Map<String, dynamic> aiConfig;

  const UserModel({
    required this.uid,
    required this.username,
    required this.displayName,
    required this.avatar,
    required this.email,
    required this.level,
    required this.xp,
    required this.coins,
    required this.gems,
    required this.createdAt,
    required this.lastLoginAt,
    required this.aiConfig,
  });

  /// Cria uma instância a partir de um Map (ex: vindo de JSON ou Firebase)
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      uid: json['uid'] ?? '',
      username: json['username'] ?? '',
      displayName: json['displayName'] ?? '',
      avatar: json['avatar'] ?? '',
      email: json['email'] ?? '',
      level: json['level'] ?? 0,
      xp: json['xp'] ?? 0,
      coins: json['coins'] ?? 0,
      gems: json['gems'] ?? 0,
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
      lastLoginAt:
          DateTime.tryParse(json['lastLoginAt'] ?? '') ?? DateTime.now(),
      aiConfig: Map<String, dynamic>.from(json['aiConfig'] ?? {}),
    );
  }

  /// Converte a instância para JSON (ex: salvar no SharedPreferences ou Firebase)
  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'username': username,
      'displayName': displayName,
      'avatar': avatar,
      'email': email,
      'level': level,
      'xp': xp,
      'coins': coins,
      'gems': gems,
      'createdAt': createdAt.toIso8601String(),
      'lastLoginAt': createdAt.toIso8601String(),
      'aiConfig': aiConfig,
    };
  }

  /// Permite copiar a instância com modificações
  UserModel copyWith({
    String? uid,
    String? username,
    String? displayName,
    String? avatar,
    String? email,
    int? level,
    int? xp,
    int? coins,
    int? gems,
    DateTime? createdAt,
    DateTime? lastLoginAt,
    Map<String, dynamic>? aiConfig,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      username: username ?? this.username,
      displayName: displayName ?? this.displayName,
      avatar: avatar ?? this.avatar,
      email: email ?? this.email,
      level: level ?? this.level,
      xp: xp ?? this.xp,
      coins: coins ?? this.coins,
      gems: gems ?? this.gems,
      createdAt: createdAt ?? this.createdAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      aiConfig: aiConfig ?? this.aiConfig,
    );
  }
}
