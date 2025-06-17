// lib/models/user_model.dart

import 'package:flutter/foundation.dart';

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

  // Novos campos para o cadastro
  final String? codinome;
  final List<String> interesses;
  final String? relationshipInterest;
  final bool onboardingCompleted;

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
    // Novos campos com valores padrão
    this.codinome,
    this.interesses = const [],
    this.relationshipInterest,
    this.onboardingCompleted = false,
  });

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
      'lastLoginAt': lastLoginAt.toIso8601String(),
      'aiConfig': aiConfig,
      // Novos campos
      'codinome': codinome,
      'interesses': interesses,
      'relationshipInterest': relationshipInterest,
      'onboardingCompleted': onboardingCompleted,
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
    // Novos campos
    String? codinome,
    List<String>? interesses,
    String? relationshipInterest,
    bool? onboardingCompleted,
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
      // Novos campos
      codinome: codinome ?? this.codinome,
      interesses: interesses ?? this.interesses,
      relationshipInterest: relationshipInterest ?? this.relationshipInterest,
      onboardingCompleted: onboardingCompleted ?? this.onboardingCompleted,
    );
  }

  // ✅ CORREÇÃO: UserModel.needsOnboarding mais robusto
  // Substitua o getter needsOnboarding no user_model.dart

  bool get needsOnboarding {
    // ✅ DEBUG: Log detalhado para diagnóstico
    if (kDebugMode) {
      print('🔍 UserModel.needsOnboarding para $uid:');
      print('  onboardingCompleted: $onboardingCompleted');
      print('  codinome: "$codinome" (isEmpty: ${codinome?.isEmpty ?? true})');
      print('  interesses: $interesses (length: ${interesses.length})');
      print(
        '  relationshipInterest: "$relationshipInterest" (isNull: ${relationshipInterest == null})',
      );
    }

    // ✅ CORREÇÃO: Lógica mais permissiva
    // Se onboardingCompleted for true, considerar como completo
    if (onboardingCompleted == true) {
      if (kDebugMode) {
        print(
          '  resultado: needsOnboarding = false (onboardingCompleted = true)',
        );
      }
      return false;
    }

    // ✅ CORREÇÃO: Verificação mais flexível dos campos obrigatórios
    final needsOnboard =
        codinome == null ||
        codinome!.trim().isEmpty ||
        interesses.isEmpty ||
        relationshipInterest == null ||
        relationshipInterest!.trim().isEmpty;

    if (kDebugMode) {
      print('  resultado: needsOnboarding = $needsOnboard');
    }

    return needsOnboard;
  }

  /// Cria uma instância a partir de um Map (ex: vindo de JSON ou Firebase)
  factory UserModel.fromJson(Map<String, dynamic> json) {
    // ✅ DEBUG: Log dos dados recebidos
    if (kDebugMode) {
      print('🔍 UserModel.fromJson:');
      print('  uid: ${json['uid']}');
      print(
        '  onboardingCompleted: ${json['onboardingCompleted']} (${json['onboardingCompleted'].runtimeType})',
      );
      print('  codinome: ${json['codinome']}');
      print('  interesses: ${json['interesses']}');
      print('  relationshipInterest: ${json['relationshipInterest']}');
    }

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
      // ✅ CONVERSÕES SEGURAS para novos campos
      codinome: json['codinome']?.toString(),
      interesses: json['interesses'] != null
          ? List<String>.from(json['interesses'])
          : const [],
      relationshipInterest: json['relationshipInterest']?.toString(),
      onboardingCompleted: json['onboardingCompleted'] == true, // Força boolean
    );
  }

  /// Obtém o nome de exibição preferido (codinome se disponível, senão displayName)
  String get preferredDisplayName {
    return codinome?.isNotEmpty == true ? codinome! : displayName;
  }
}
