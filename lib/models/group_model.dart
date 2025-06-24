// lib/models/group_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// Modelo principal para grupos de amigos/competições
class GroupModel {
  final String id;
  final String name;
  final String description;
  final String avatar;
  final String creatorId;
  final DateTime createdAt;
  final List<String> memberIds;
  final List<String> adminIds;
  final Map<String, dynamic> settings;
  final GroupType type;
  final GroupPrivacy privacy;
  final int maxMembers;
  final bool isActive;
  final Map<String, dynamic> stats;
  final List<String> tags;
  final String? inviteCode;
  final DateTime? lastActivity;

  const GroupModel({
    required this.id,
    required this.name,
    required this.description,
    required this.avatar,
    required this.creatorId,
    required this.createdAt,
    this.memberIds = const [],
    this.adminIds = const [],
    this.settings = const {},
    this.type = GroupType.casual,
    this.privacy = GroupPrivacy.private,
    this.maxMembers = 50,
    this.isActive = true,
    this.stats = const {},
    this.tags = const [],
    this.inviteCode,
    this.lastActivity,
  });

  /// Getters úteis
  int get memberCount => memberIds.length;
  bool get isFull => memberIds.length >= maxMembers;
  bool get hasSpace => !isFull;

  /// Verificar se usuário é membro
  bool isMember(String userId) => memberIds.contains(userId);

  /// Verificar se usuário é admin
  bool isAdmin(String userId) => adminIds.contains(userId);

  /// Verificar se usuário é criador
  bool isCreator(String userId) => creatorId == userId;

  /// Factory para criar grupo inicial
  factory GroupModel.create({
    required String name,
    required String description,
    required String creatorId,
    String? avatar,
    GroupType? type,
    GroupPrivacy? privacy,
    int? maxMembers,
  }) {
    return GroupModel(
      id: '', // Será preenchido pelo Firestore
      name: name,
      description: description,
      avatar: avatar ?? '👥',
      creatorId: creatorId,
      createdAt: DateTime.now(),
      memberIds: [creatorId], // Criador é o primeiro membro
      adminIds: [creatorId], // Criador é admin
      type: type ?? GroupType.casual,
      privacy: privacy ?? GroupPrivacy.private,
      maxMembers: maxMembers ?? 50,
    );
  }

  /// Criar a partir de JSON/Firestore
  factory GroupModel.fromJson(Map<String, dynamic> json) {
    return GroupModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      avatar: json['avatar'] ?? '👥',
      creatorId: json['creatorId'] ?? '',
      createdAt: (json['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      memberIds: List<String>.from(json['memberIds'] ?? []),
      adminIds: List<String>.from(json['adminIds'] ?? []),
      settings: Map<String, dynamic>.from(json['settings'] ?? {}),
      type: GroupType.values.firstWhere(
        (t) => t.name == json['type'],
        orElse: () => GroupType.casual,
      ),
      privacy: GroupPrivacy.values.firstWhere(
        (p) => p.name == json['privacy'],
        orElse: () => GroupPrivacy.private,
      ),
      maxMembers: json['maxMembers'] ?? 50,
      isActive: json['isActive'] ?? true,
      stats: Map<String, dynamic>.from(json['stats'] ?? {}),
      tags: List<String>.from(json['tags'] ?? []),
      inviteCode: json['inviteCode'],
      lastActivity: (json['lastActivity'] as Timestamp?)?.toDate(),
    );
  }

  /// Converter para JSON/Firestore
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'avatar': avatar,
      'creatorId': creatorId,
      'createdAt': Timestamp.fromDate(createdAt),
      'memberIds': memberIds,
      'adminIds': adminIds,
      'settings': settings,
      'type': type.name,
      'privacy': privacy.name,
      'maxMembers': maxMembers,
      'isActive': isActive,
      'stats': stats,
      'tags': tags,
      'inviteCode': inviteCode,
      'lastActivity': lastActivity != null
          ? Timestamp.fromDate(lastActivity!)
          : null,
    };
  }

  /// Método copyWith para atualizações
  GroupModel copyWith({
    String? name,
    String? description,
    String? avatar,
    List<String>? memberIds,
    List<String>? adminIds,
    Map<String, dynamic>? settings,
    GroupType? type,
    GroupPrivacy? privacy,
    int? maxMembers,
    bool? isActive,
    Map<String, dynamic>? stats,
    List<String>? tags,
    String? inviteCode,
    DateTime? lastActivity,
  }) {
    return GroupModel(
      id: id,
      name: name ?? this.name,
      description: description ?? this.description,
      avatar: avatar ?? this.avatar,
      creatorId: creatorId,
      createdAt: createdAt,
      memberIds: memberIds ?? this.memberIds,
      adminIds: adminIds ?? this.adminIds,
      settings: settings ?? this.settings,
      type: type ?? this.type,
      privacy: privacy ?? this.privacy,
      maxMembers: maxMembers ?? this.maxMembers,
      isActive: isActive ?? this.isActive,
      stats: stats ?? this.stats,
      tags: tags ?? this.tags,
      inviteCode: inviteCode ?? this.inviteCode,
      lastActivity: lastActivity ?? this.lastActivity,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is GroupModel &&
        other.id == id &&
        other.name == name &&
        other.creatorId == creatorId &&
        listEquals(other.memberIds, memberIds) &&
        listEquals(other.adminIds, adminIds);
  }

  @override
  int get hashCode {
    return Object.hash(id, name, creatorId, memberIds, adminIds);
  }

  @override
  String toString() {
    return 'GroupModel(id: $id, name: $name, members: ${memberIds.length}/$maxMembers)';
  }
}

/// Tipos de grupo
enum GroupType {
  casual('casual', '😊', 'Casual'),
  competitive('competitive', '🏆', 'Competitivo'),
  family('family', '👨‍👩‍👧‍👦', 'Família'),
  work('work', '💼', 'Trabalho'),
  hobby('hobby', '🎨', 'Hobby'),
  study('study', '📚', 'Estudo');

  const GroupType(this.id, this.icon, this.label);
  final String id;
  final String icon;
  final String label;
}

/// Configurações de privacidade
enum GroupPrivacy {
  public('public', 'Público', 'Qualquer um pode encontrar e entrar'),
  private('private', 'Privado', 'Apenas por convite'),
  secret('secret', 'Secreto', 'Invisível nas buscas');

  const GroupPrivacy(this.id, this.label, this.description);
  final String id;
  final String label;
  final String description;
}
