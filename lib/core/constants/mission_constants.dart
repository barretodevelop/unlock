// lib/core/constants/mission_constants.dart
// Constantes para sistema de missões - Fase 3

/// Configurações globais do sistema de missões
class MissionConstants {
  // ================================================================================================
  // LIMITES E QUANTIDADES
  // ================================================================================================

  /// Número de missões diárias geradas por usuário
  static const int dailyMissionsCount = 3;

  /// Número de missões semanais geradas por usuário
  static const int weeklyMissionsCount = 2;

  /// Tempo em horas para reset das missões diárias (00:00)
  static const int dailyResetHour = 0;

  /// Dia da semana para reset das missões semanais (1 = Segunda-feira)
  static const int weeklyResetDay = 1;

  /// Máximo de missões colaborativas simultâneas
  static const int maxCollaborativeMissions = 1;

  /// Tempo limite em minutos para completar missão colaborativa
  static const int collaborativeMissionTimeoutMinutes = 30;

  // ================================================================================================
  // RECOMPENSAS POR TIPO DE MISSÃO
  // ================================================================================================

  /// Recompensas base para missões diárias
  static const Map<String, int> dailyRewards = {
    'xp_min': 30,
    'xp_max': 100,
    'coins_min': 15,
    'coins_max': 50,
    'gems': 0, // Missões diárias não dão gems
  };

  /// Recompensas base para missões semanais
  static const Map<String, int> weeklyRewards = {
    'xp_min': 150,
    'xp_max': 500,
    'coins_min': 75,
    'coins_max': 250,
    'gems_min': 5,
    'gems_max': 15,
  };

  /// Recompensas base para missões colaborativas
  static const Map<String, int> collaborativeRewards = {
    'xp_min': 200,
    'xp_max': 400,
    'coins_min': 100,
    'coins_max': 200,
    'gems_min': 2,
    'gems_max': 8,
  };

  // ================================================================================================
  // TIPOS DE MISSÃO
  // ================================================================================================

  /// Tipos disponíveis de missão
  static const List<String> missionTypes = [
    'daily',
    'weekly',
    'collaborative',
    'automatic',
    'special',
  ];

  /// Categorias de missão
  static const List<String> missionCategories = [
    'social', // Relacionadas a conexões
    'profile', // Personalização de perfil
    'exploration', // Descobrir novos usuários
    'gamification', // Ganhar XP, completar challenges
  ];

  // ================================================================================================
  // TEMPLATES DE MISSÕES DIÁRIAS
  // ================================================================================================

  /// Templates para geração automática de missões diárias
  static const List<Map<String, dynamic>> dailyMissionTemplates = [
    {
      'id': 'complete_profile',
      'title': 'Complete seu perfil',
      'description': 'Adicione mais informações ao seu perfil anônimo',
      'category': 'profile',
      'target': 1,
      'xp': 50,
      'coins': 25,
      'difficulty': 1,
      'requirements': ['has_incomplete_profile'],
    },
    {
      'id': 'view_profiles',
      'title': 'Explore novos perfis',
      'description': 'Visualize 3 perfis de outros usuários',
      'category': 'exploration',
      'target': 3,
      'xp': 30,
      'coins': 15,
      'difficulty': 1,
      'requirements': [],
    },
    {
      'id': 'send_invite',
      'title': 'Envie um convite',
      'description': 'Envie um convite de conexão para alguém interessante',
      'category': 'social',
      'target': 1,
      'xp': 100,
      'coins': 50,
      'difficulty': 2,
      'requirements': ['has_viewed_profiles'],
    },
    {
      'id': 'login_streak',
      'title': 'Mantenha a sequência',
      'description': 'Faça login por 3 dias consecutivos',
      'category': 'gamification',
      'target': 3,
      'xp': 75,
      'coins': 35,
      'difficulty': 2,
      'requirements': [],
    },
    {
      'id': 'answer_questions',
      'title': 'Responda perguntas',
      'description': 'Responda 5 perguntas de compatibilidade',
      'category': 'social',
      'target': 5,
      'xp': 60,
      'coins': 30,
      'difficulty': 2,
      'requirements': ['has_connections'],
    },
  ];

  // ================================================================================================
  // TEMPLATES DE MISSÕES SEMANAIS
  // ================================================================================================

  /// Templates para geração automática de missões semanais
  static const List<Map<String, dynamic>> weeklyMissionTemplates = [
    {
      'id': 'complete_daily_missions',
      'title': 'Mestre das missões',
      'description': 'Complete 5 missões diárias esta semana',
      'category': 'gamification',
      'target': 5,
      'xp': 200,
      'coins': 100,
      'gems': 5,
      'difficulty': 3,
      'requirements': [],
    },
    {
      'id': 'make_connections',
      'title': 'Conecte-se',
      'description': 'Faça 3 novas conexões esta semana',
      'category': 'social',
      'target': 3,
      'xp': 500,
      'coins': 250,
      'gems': 10,
      'difficulty': 4,
      'requirements': [],
    },
    {
      'id': 'win_minigames',
      'title': 'Jogador expert',
      'description': 'Vença 2 minijogos de conexão',
      'category': 'social',
      'target': 2,
      'xp': 300,
      'coins': 150,
      'gems': 8,
      'difficulty': 4,
      'requirements': ['has_unlocked_minigames'],
    },
    {
      'id': 'customize_profile',
      'title': 'Personalização única',
      'description': 'Compre e aplique 3 itens de personalização',
      'category': 'profile',
      'target': 3,
      'xp': 150,
      'coins': 75,
      'gems': 5,
      'difficulty': 3,
      'requirements': ['has_shop_access'],
    },
  ];

  // ================================================================================================
  // TEMPLATES DE MISSÕES COLABORATIVAS
  // ================================================================================================

  /// Templates para missões em dupla/grupo
  static const List<Map<String, dynamic>> collaborativeMissionTemplates = [
    {
      'id': 'duo_minigame',
      'title': 'Dupla dinâmica',
      'description': 'Complete um minijogo em dupla com sucesso',
      'category': 'social',
      'target': 1,
      'xp': 300,
      'coins': 150,
      'gems': 5,
      'difficulty': 3,
      'participants': 2,
      'requirements': ['has_active_connection'],
    },
    {
      'id': 'compatibility_test',
      'title': 'Teste de compatibilidade',
      'description': 'Complete um teste de compatibilidade em dupla',
      'category': 'social',
      'target': 1,
      'xp': 200,
      'coins': 100,
      'gems': 3,
      'difficulty': 2,
      'participants': 2,
      'requirements': ['has_active_connection'],
    },
    {
      'id': 'group_challenge',
      'title': 'Desafio em grupo',
      'description': 'Participe de um desafio com 4 jogadores',
      'category': 'social',
      'target': 1,
      'xp': 400,
      'coins': 200,
      'gems': 8,
      'difficulty': 5,
      'participants': 4,
      'requirements': ['has_multiple_connections'],
    },
  ];

  // ================================================================================================
  // CONFIGURAÇÕES DE DIFICULDADE
  // ================================================================================================

  /// Multiplicadores de recompensa por dificuldade (1-5)
  static const Map<int, double> difficultyMultipliers = {
    1: 1.0, // Fácil
    2: 1.2, // Normal
    3: 1.5, // Médio
    4: 1.8, // Difícil
    5: 2.0, // Expert
  };

  /// Cores associadas a cada dificuldade
  static const Map<int, int> difficultyColors = {
    1: 0xFF4CAF50, // Verde
    2: 0xFF2196F3, // Azul
    3: 0xFFFF9800, // Laranja
    4: 0xFFE91E63, // Rosa
    5: 0xFF9C27B0, // Roxo
  };

  // ================================================================================================
  // CONFIGURAÇÕES AUTOMÁTICAS
  // ================================================================================================

  /// Intervalo em minutos para verificar missões automáticas
  static const int autoMissionCheckIntervalMinutes = 15;

  /// Máximo de missões automáticas por usuário
  static const int maxAutoMissionsPerUser = 1;

  /// Probabilidade (0-100) de gerar missão automática
  static const int autoMissionGenerationChance = 25;

  // ================================================================================================
  // MÉTODOS UTILITÁRIOS
  // ================================================================================================

  /// Verificar se é hora de reset das missões diárias
  static bool isDailyResetTime(DateTime now) {
    return now.hour == dailyResetHour && now.minute == 0;
  }

  /// Verificar se é dia de reset das missões semanais
  static bool isWeeklyResetDay(DateTime now) {
    return now.weekday == weeklyResetDay && isDailyResetTime(now);
  }

  /// Obter multiplicador de recompensa por dificuldade
  static double getRewardMultiplier(int difficulty) {
    return difficultyMultipliers[difficulty] ?? 1.0;
  }

  /// Obter cor por dificuldade
  static int getDifficultyColor(int difficulty) {
    return difficultyColors[difficulty] ?? 0xFF757575;
  }

  /// Calcular recompensa final com multiplicador
  static int calculateFinalReward(int baseReward, int difficulty) {
    return (baseReward * getRewardMultiplier(difficulty)).round();
  }
}
