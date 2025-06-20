// lib/features/missions/models/mission.dart

/// Define a estrutura de uma missão no jogo.
/// Inclui detalhes como ID, título, descrição, tipo, critérios de conclusão e recompensas.
class Mission {
  final String id;
  final String title;
  final String description;
  final String category; // Novo campo para categoria
  final MissionType type; // Ex: DAILY, WEEKLY, ONE_TIME, EVENT
  final MissionCriterion criterion;
  final MissionReward reward;

  /// Construtor para criar uma instância de Mission.
  Mission({
    required this.id,
    required this.title,
    required this.description,
    required this.category, // Adicionar ao construtor
    required this.type,
    required this.criterion,
    required this.reward,
  });

  /// Factory para criar uma instância de Mission a partir de um mapa JSON.
  /// Útil para desserialização de dados do backend ou armazenamento local.
  factory Mission.fromJson(Map<String, dynamic> json) {
    return Mission(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      category:
          json['category'] ?? 'Outras', // Desserializa a categoria com fallback
      // Converte a string do tipo de missão para o enum MissionType.
      type: MissionType.values.firstWhere(
        (e) => e.toString().split('.').last == json['type'],
      ),
      criterion: MissionCriterion.fromJson(json['criterion']),
      reward: MissionReward.fromJson(json['reward']),
    );
  }

  /// Converte a instância de Mission para um mapa JSON.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'category': category, // Serializa a categoria
      'type': type.toString().split('.').last,
      'criterion': criterion.toJson(),
      'reward': reward.toJson(),
    };
  }
}

/// Enumeração para definir os diferentes tipos de missões.
/// DAILY: Missões que resetam diariamente.
/// WEEKLY: Missões que resetam semanalmente.
/// ONE_TIME: Missões que podem ser concluídas apenas uma vez.
/// EVENT: Missões vinculadas a eventos específicos do jogo.
enum MissionType { DAILY, WEEKLY, ONE_TIME, EVENT }

/// Define os critérios necessários para completar uma missão.
/// eventType: O tipo de evento que aciona o progresso (ex: 'LOGIN_DIARIO', 'LIKE_PROFILE', 'CREATE_POST').
/// targetCount: O número de vezes que o evento deve ocorrer para a missão ser concluída.
class MissionCriterion {
  final String eventType;
  final int targetCount;

  /// Construtor para criar uma instância de MissionCriterion.
  MissionCriterion({required this.eventType, required this.targetCount});

  /// Factory para criar uma instância de MissionCriterion a partir de um mapa JSON.
  factory MissionCriterion.fromJson(Map<String, dynamic> json) {
    return MissionCriterion(
      eventType: json['eventType'],
      targetCount: json['targetCount'],
    );
  }

  /// Converte a instância de MissionCriterion para um mapa JSON.
  Map<String, dynamic> toJson() {
    return {'eventType': eventType, 'targetCount': targetCount};
  }
}

/// Define as recompensas que um jogador recebe ao completar uma missão.
/// xp: Pontos de experiência.
/// coins: Moedas virtuais.
/// gems: Gemas (moeda premium).
class MissionReward {
  final int xp;
  final int coins;
  final int gems;

  /// Construtor para criar uma instância de MissionReward.
  MissionReward({this.xp = 0, this.coins = 0, this.gems = 0});

  /// Factory para criar uma instância de MissionReward a partir de um mapa JSON.
  factory MissionReward.fromJson(Map<String, dynamic> json) {
    return MissionReward(
      xp: json['xp'] ?? 0,
      coins: json['coins'] ?? 0,
      gems: json['gems'] ?? 0,
    );
  }

  /// Converte a instância de MissionReward para um mapa JSON.
  Map<String, dynamic> toJson() {
    return {'xp': xp, 'coins': coins, 'gems': gems};
  }
}
