// lib/core/constants/gamification_constants.dart
// Constantes para sistema de gamificação - Fase 3

/// Configurações globais do sistema de gamificação
class GamificationConstants {
  // ================================================================================================
  // SISTEMA DE NÍVEIS E XP
  // ================================================================================================

  /// XP inicial ao criar conta
  static const int initialXP = 0;

  /// Nível inicial ao criar conta
  static const int initialLevel = 1;

  /// XP base necessário para subir do nível 1 para 2
  static const int baseXPRequired = 100;

  /// Fator de crescimento do XP necessário por nível (progressão exponencial)
  static const double xpGrowthFactor = 1.5;

  /// Nível máximo possível
  static const int maxLevel = 100;

  /// XP máximo que pode ser ganho por dia (anti-farm)
  static const int maxDailyXP = 1000;

  // ================================================================================================
  // ECONOMIA - COINS E GEMS
  // ================================================================================================

  /// Coins iniciais ao criar conta
  static const int initialCoins = 200;

  /// Gems iniciais ao criar conta
  static const int initialGems = 20;

  /// Máximo de coins que pode ser ganho por dia
  static const int maxDailyCoins = 500;

  /// Máximo de gems que pode ser ganho por semana
  static const int maxWeeklyGems = 50;

  /// Conversão gems para coins (1 gem = X coins)
  static const int gemsToCoinsRate = 10;

  /// Bonus de coins por login diário consecutivo
  static const Map<int, int> dailyLoginBonus = {
    1: 10, // 1 dia
    2: 15, // 2 dias
    3: 20, // 3 dias
    4: 25, // 4 dias
    5: 30, // 5 dias
    6: 35, // 6 dias
    7: 50, // 7 dias (reset)
  };

  // ================================================================================================
  // RECOMPENSAS POR NÍVEL
  // ================================================================================================

  /// Recompensas especiais ao subir de nível
  static const Map<int, Map<String, int>> levelUpRewards = {
    // Níveis iniciantes
    2: {'coins': 50, 'gems': 2},
    3: {'coins': 75, 'gems': 3},
    5: {'coins': 100, 'gems': 5},

    // Níveis intermediários
    10: {'coins': 200, 'gems': 10},
    15: {'coins': 300, 'gems': 15},
    20: {'coins': 500, 'gems': 25},

    // Níveis avançados
    25: {'coins': 750, 'gems': 40},
    30: {'coins': 1000, 'gems': 50},
    40: {'coins': 1500, 'gems': 75},
    50: {'coins': 2500, 'gems': 100},

    // Níveis expert
    75: {'coins': 5000, 'gems': 200},
    100: {'coins': 10000, 'gems': 500},
  };

  // ================================================================================================
  // TÍTULOS E CONQUISTAS
  // ================================================================================================

  /// Títulos desbloqueados por nível
  static const Map<int, String> levelTitles = {
    1: 'Novato',
    5: 'Explorador',
    10: 'Conectado',
    15: 'Socializador',
    20: 'Influente',
    25: 'Popular',
    30: 'Especialista',
    40: 'Mestre',
    50: 'Lenda',
    75: 'Ícone',
    100: 'Deus das Conexões',
  };

  /// Conquistas especiais baseadas em ações
  static const Map<String, Map<String, dynamic>> achievements = {
    'first_connection': {
      'title': 'Primeira Conexão',
      'description': 'Fez sua primeira conexão real',
      'xp': 100,
      'coins': 50,
      'gems': 5,
      'icon': '🤝',
    },
    'profile_complete': {
      'title': 'Perfil Completo',
      'description': 'Completou 100% do perfil',
      'xp': 75,
      'coins': 40,
      'gems': 3,
      'icon': '✅',
    },
    'mission_master': {
      'title': 'Mestre das Missões',
      'description': 'Completou 50 missões',
      'xp': 500,
      'coins': 250,
      'gems': 25,
      'icon': '🏆',
    },
    'social_butterfly': {
      'title': 'Borboleta Social',
      'description': 'Tem 10 conexões ativas',
      'xp': 1000,
      'coins': 500,
      'gems': 50,
      'icon': '🦋',
    },
    'minigame_champion': {
      'title': 'Campeão dos Jogos',
      'description': 'Venceu 25 minijogos',
      'xp': 750,
      'coins': 375,
      'gems': 35,
      'icon': '🎮',
    },
  };

  // ================================================================================================
  // MULTIPLICADORES E BONUS
  // ================================================================================================

  /// Multiplicador de XP por sequência de login diário
  static const Map<int, double> loginStreakXPMultiplier = {
    3: 1.1, // +10% XP por 3 dias seguidos
    7: 1.2, // +20% XP por 1 semana
    14: 1.3, // +30% XP por 2 semanas
    30: 1.5, // +50% XP por 1 mês
  };

  /// Multiplicador de coins por nível do usuário
  static double getCoinsMultiplierByLevel(int level) {
    if (level < 10) return 1.0;
    if (level < 20) return 1.1;
    if (level < 30) return 1.2;
    if (level < 50) return 1.3;
    return 1.5;
  }

  // ================================================================================================
  // LIMITES E PROTEÇÕES ANTI-FARM
  // ================================================================================================

  /// Cooldown em minutos entre ações que dão XP
  static const Map<String, int> actionCooldowns = {
    'profile_view': 1, // Ver perfil: 1 min
    'send_invite': 5, // Enviar convite: 5 min
    'complete_mission': 0, // Completar missão: sem cooldown
    'minigame_complete': 2, // Completar minijogo: 2 min
  };

  /// Máximo de XP por ação específica por dia
  static const Map<String, int> dailyXPLimits = {
    'profile_views': 150, // Máx 150 XP/dia vendo perfis
    'invites_sent': 300, // Máx 300 XP/dia enviando convites
    'minigames': 400, // Máx 400 XP/dia em minijogos
  };

  // ================================================================================================
  // CONFIGURAÇÕES DE NOTIFICAÇÕES
  // ================================================================================================

  /// Configurações para notificações de gamificação
  static const Map<String, bool> notificationSettings = {
    'level_up': true, // Notificar ao subir nível
    'achievement_unlock': true, // Notificar conquistas
    'daily_bonus': true, // Notificar bonus diário
    'mission_complete': true, // Notificar missão completa
    'weekly_summary': true, // Resumo semanal
  };

  // ================================================================================================
  // CORES E VISUAL
  // ================================================================================================

  /// Cores para diferentes elementos de gamificação (hex values)
  static const Map<String, int> gamificationColors = {
    'xp': 0xFF2196F3, // Azul para XP
    'coins': 0xFFFFD700, // Dourado para coins
    'gems': 0xFF9C27B0, // Roxo para gems
    'level': 0xFF4CAF50, // Verde para nível
    'achievement': 0xFFFF9800, // Laranja para conquistas
    'streak': 0xFFE91E63, // Rosa para sequências
  };

  /// Ícones emoji para diferentes elementos
  static const Map<String, String> gamificationIcons = {
    'xp': '⚡',
    'coins': '🪙',
    'gems': '💎',
    'level': '🏅',
    'achievement': '🏆',
    'streak': '🔥',
    'mission': '🎯',
  };

  // ================================================================================================
  // FÓRMULAS DE CÁLCULO
  // ================================================================================================

  /// Calcular XP necessário para um nível específico
  static int calculateXPForLevel(int level) {
    if (level <= 1) return 0;

    double totalXP = 0;
    for (int i = 2; i <= level; i++) {
      totalXP += baseXPRequired * (i - 1) * xpGrowthFactor;
    }
    return totalXP.round();
  }

  /// Calcular nível baseado no XP atual
  static int calculateLevelFromXP(int currentXP) {
    int level = 1;
    int requiredXP = 0;

    while (level < maxLevel) {
      int nextLevelXP = calculateXPForLevel(level + 1);
      if (currentXP < nextLevelXP) break;
      level++;
    }

    return level;
  }

  /// Calcular XP necessário para o próximo nível
  static int calculateXPToNextLevel(int currentXP) {
    int currentLevel = calculateLevelFromXP(currentXP);
    if (currentLevel >= maxLevel) return 0;

    int nextLevelXP = calculateXPForLevel(currentLevel + 1);
    return nextLevelXP - currentXP;
  }

  /// Calcular progresso percentual no nível atual
  static double calculateLevelProgress(int currentXP) {
    int currentLevel = calculateLevelFromXP(currentXP);
    if (currentLevel >= maxLevel) return 1.0;

    int currentLevelXP = calculateXPForLevel(currentLevel);
    int nextLevelXP = calculateXPForLevel(currentLevel + 1);
    int levelRangeXP = nextLevelXP - currentLevelXP;
    int progressXP = currentXP - currentLevelXP;

    return progressXP / levelRangeXP;
  }

  /// Verificar se usuário subiu de nível
  static bool didLevelUp(int oldXP, int newXP) {
    return calculateLevelFromXP(oldXP) < calculateLevelFromXP(newXP);
  }

  /// Obter título do usuário baseado no nível
  static String getUserTitle(int level) {
    // Encontrar o maior nível com título disponível
    int titleLevel = 1;
    for (int lvl in levelTitles.keys) {
      if (level >= lvl) titleLevel = lvl;
    }
    return levelTitles[titleLevel] ?? 'Novato';
  }

  /// Obter recompensas de level up
  static Map<String, int>? getLevelUpRewards(int level) {
    return levelUpRewards[level];
  }

  /// Verificar se usuário tem bonus de login streak
  static int getLoginStreakBonus(int streakDays) {
    return dailyLoginBonus[streakDays] ?? 0;
  }
}
