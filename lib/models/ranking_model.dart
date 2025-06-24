// lib/models/ranking_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

/// Categorias de ranking disponíveis
enum RankingCategory {
  xp('xp', 'XP', 'Experiência total', Icons.star, Colors.amber),
  coins('coins', 'Faíscas', 'Moedas coletadas', Icons.bolt, Colors.orange),
  gems('gems', 'Gemas', 'Gemas conquistadas', Icons.diamond, Colors.purple),
  level('level', 'Nível', 'Nível alcançado', Icons.trending_up, Colors.blue),
  challenges(
    'challenges',
    'Desafios',
    'Desafios vencidos',
    Icons.emoji_events,
    Colors.green,
  ),
  streak(
    'streak',
    'Sequência',
    'Dias consecutivos',
    Icons.local_fire_department,
    Colors.red,
  ),
  groups('groups', 'Grupos', 'Grupos criados', Icons.groups, Colors.indigo),
  submissions(
    'submissions',
    'Envios',
    'Submissões realizadas',
    Icons.send,
    Colors.teal,
  );

  const RankingCategory(
    this.id,
    this.label,
    this.description,
    this.icon,
    this.color,
  );

  final String id;
  final String label;
  final String description;
  final IconData icon;
  final Color color;

  /// Obter valor do campo no UserModel
  int getValueFromUser(Map<String, dynamic> userData) {
    switch (this) {
      case RankingCategory.xp:
        return userData['xp'] ?? 0;
      case RankingCategory.coins:
        return userData['coins'] ?? 0;
      case RankingCategory.gems:
        return userData['gems'] ?? 0;
      case RankingCategory.level:
        return userData['level'] ?? 1;
      case RankingCategory.challenges:
        return (userData['stats']?['challengesWon'] as int?) ?? 0;
      case RankingCategory.streak:
        return userData['loginStreak'] ?? 0;
      case RankingCategory.groups:
        return (userData['stats']?['groupsCreated'] as int?) ?? 0;
      case RankingCategory.submissions:
        return (userData['stats']?['submissionsCount'] as int?) ?? 0;
    }
  }

  /// Formatar valor para exibição
  String formatValue(int value) {
    switch (this) {
      case RankingCategory.xp:
      case RankingCategory.coins:
      case RankingCategory.gems:
        return _formatLargeNumber(value);
      case RankingCategory.level:
        return 'Nv. $value';
      case RankingCategory.challenges:
      case RankingCategory.groups:
      case RankingCategory.submissions:
        return value.toString();
      case RankingCategory.streak:
        return '$value dias';
    }
  }

  /// Formatar números grandes
  String _formatLargeNumber(int number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    }
    return number.toString();
  }
}

/// Tipos de escopo para rankings
enum RankingScopeType {
  global('global', 'Global', 'Ranking mundial'),
  groups('groups', 'Grupos', 'Apenas seus grupos'),
  friends('friends', 'Amigos', 'Apenas seus amigos'),
  weekly('weekly', 'Semanal', 'Esta semana');

  const RankingScopeType(this.id, this.label, this.description);

  final String id;
  final String label;
  final String description;
}

/// Períodos de tempo para rankings
enum RankingPeriod {
  allTime('all_time', 'Todos os Tempos', Icons.all_inclusive),
  thisMonth('this_month', 'Este Mês', Icons.calendar_month),
  thisWeek('this_week', 'Esta Semana', Icons.calendar_view_month),
  today('today', 'Hoje', Icons.today);

  const RankingPeriod(this.id, this.label, this.icon);

  final String id;
  final String label;
  final IconData icon;

  /// Obter data de início do período
  DateTime getStartDate() {
    final now = DateTime.now();

    switch (this) {
      case RankingPeriod.allTime:
        return DateTime(2024, 1, 1); // Data de lançamento do app
      case RankingPeriod.thisMonth:
        return DateTime(now.year, now.month, 1);
      case RankingPeriod.thisWeek:
        final weekday = now.weekday;
        return now.subtract(Duration(days: weekday - 1));
      case RankingPeriod.today:
        return DateTime(now.year, now.month, now.day);
    }
  }
}

/// Entrada individual no ranking
class RankingEntry {
  final String userId;
  final String username;
  final String displayName;
  final String avatar;
  final int value;
  final int position;
  final DateTime lastUpdated;
  final Map<String, dynamic> metadata;

  const RankingEntry({
    required this.userId,
    required this.username,
    required this.displayName,
    required this.avatar,
    required this.value,
    required this.position,
    required this.lastUpdated,
    this.metadata = const {},
  });

  /// Criar a partir de dados do Firestore
  factory RankingEntry.fromFirestore(
    Map<String, dynamic> data,
    RankingCategory category,
    int position,
  ) {
    return RankingEntry(
      userId: data['uid'] ?? '',
      username: data['username'] ?? '',
      displayName: data['displayName'] ?? '',
      avatar: data['avatar'] ?? '',
      value: category.getValueFromUser(data),
      position: position,
      lastUpdated:
          (data['lastActivity'] as Timestamp?)?.toDate() ?? DateTime.now(),
      metadata: {
        'level': data['level'] ?? 1,
        'onboardingCompleted': data['onboardingCompleted'] ?? false,
        'createdAt': data['createdAt'],
      },
    );
  }

  /// Converter para JSON
  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'username': username,
      'displayName': displayName,
      'avatar': avatar,
      'value': value,
      'position': position,
      'lastUpdated': Timestamp.fromDate(lastUpdated),
      'metadata': metadata,
    };
  }

  /// Copiar com mudanças
  RankingEntry copyWith({
    String? userId,
    String? username,
    String? displayName,
    String? avatar,
    int? value,
    int? position,
    DateTime? lastUpdated,
    Map<String, dynamic>? metadata,
  }) {
    return RankingEntry(
      userId: userId ?? this.userId,
      username: username ?? this.username,
      displayName: displayName ?? this.displayName,
      avatar: avatar ?? this.avatar,
      value: value ?? this.value,
      position: position ?? this.position,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      metadata: metadata ?? this.metadata,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is RankingEntry &&
        other.userId == userId &&
        other.position == position &&
        other.value == value;
  }

  @override
  int get hashCode => Object.hash(userId, position, value);

  @override
  String toString() {
    return 'RankingEntry(userId: $userId, position: $position, value: $value)';
  }
}

/// Query para buscar rankings
class RankingQuery {
  final RankingCategory category;
  final RankingScopeType scope;
  final RankingPeriod period;
  final int limit;
  final String? groupId;
  final List<String>? userIds;

  const RankingQuery({
    required this.category,
    required this.scope,
    required this.period,
    this.limit = 100,
    this.groupId,
    this.userIds,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is RankingQuery &&
        other.category == category &&
        other.scope == scope &&
        other.period == period &&
        other.limit == limit &&
        other.groupId == groupId;
  }

  @override
  int get hashCode => Object.hash(category, scope, period, limit, groupId);

  @override
  String toString() {
    return 'RankingQuery(category: ${category.id}, scope: ${scope.id}, period: ${period.id})';
  }
}

/// Estatísticas de ranking do usuário
class UserRankingStats {
  final String userId;
  final Map<RankingCategory, int> globalRanks;
  final Map<RankingCategory, int> groupRanks;
  final Map<RankingCategory, int> friendRanks;
  final Map<RankingCategory, int> weeklyRanks;
  final DateTime lastUpdated;

  const UserRankingStats({
    required this.userId,
    required this.globalRanks,
    required this.groupRanks,
    required this.friendRanks,
    required this.weeklyRanks,
    required this.lastUpdated,
  });

  /// Obter rank para categoria e escopo específico
  int? getRank(RankingCategory category, RankingScopeType scope) {
    switch (scope) {
      case RankingScopeType.global:
        return globalRanks[category];
      case RankingScopeType.groups:
        return groupRanks[category];
      case RankingScopeType.friends:
        return friendRanks[category];
      case RankingScopeType.weekly:
        return weeklyRanks[category];
    }
  }

  /// Criar a partir de JSON
  factory UserRankingStats.fromJson(Map<String, dynamic> json) {
    return UserRankingStats(
      userId: json['userId'],
      globalRanks: Map<RankingCategory, int>.from(
        (json['globalRanks'] as Map).map(
          (k, v) => MapEntry(
            RankingCategory.values.firstWhere((cat) => cat.id == k),
            v as int,
          ),
        ),
      ),
      groupRanks: Map<RankingCategory, int>.from(
        (json['groupRanks'] as Map).map(
          (k, v) => MapEntry(
            RankingCategory.values.firstWhere((cat) => cat.id == k),
            v as int,
          ),
        ),
      ),
      friendRanks: Map<RankingCategory, int>.from(
        (json['friendRanks'] as Map).map(
          (k, v) => MapEntry(
            RankingCategory.values.firstWhere((cat) => cat.id == k),
            v as int,
          ),
        ),
      ),
      weeklyRanks: Map<RankingCategory, int>.from(
        (json['weeklyRanks'] as Map).map(
          (k, v) => MapEntry(
            RankingCategory.values.firstWhere((cat) => cat.id == k),
            v as int,
          ),
        ),
      ),
      lastUpdated: (json['lastUpdated'] as Timestamp).toDate(),
    );
  }

  /// Converter para JSON
  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'globalRanks': globalRanks.map((k, v) => MapEntry(k.id, v)),
      'groupRanks': groupRanks.map((k, v) => MapEntry(k.id, v)),
      'friendRanks': friendRanks.map((k, v) => MapEntry(k.id, v)),
      'weeklyRanks': weeklyRanks.map((k, v) => MapEntry(k.id, v)),
      'lastUpdated': Timestamp.fromDate(lastUpdated),
    };
  }
}

/// Histórico de rankings
class RankingHistory {
  final String userId;
  final RankingCategory category;
  final RankingScopeType scope;
  final List<RankingSnapshot> snapshots;

  const RankingHistory({
    required this.userId,
    required this.category,
    required this.scope,
    required this.snapshots,
  });

  /// Obter tendência (subindo, descendo, estável)
  RankingTrend getTrend() {
    if (snapshots.length < 2) return RankingTrend.stable;

    final current = snapshots.last.position;
    final previous = snapshots[snapshots.length - 2].position;

    if (current < previous) return RankingTrend.up;
    if (current > previous) return RankingTrend.down;
    return RankingTrend.stable;
  }
}

/// Snapshot de ranking em um momento específico
class RankingSnapshot {
  final int position;
  final int value;
  final DateTime timestamp;

  const RankingSnapshot({
    required this.position,
    required this.value,
    required this.timestamp,
  });
}

/// Tendência do ranking
enum RankingTrend {
  up('up', 'Subindo', Icons.trending_up, Colors.green),
  down('down', 'Descendo', Icons.trending_down, Colors.red),
  stable('stable', 'Estável', Icons.trending_flat, Colors.grey);

  const RankingTrend(this.id, this.label, this.icon, this.color);

  final String id;
  final String label;
  final IconData icon;
  final Color color;
}
