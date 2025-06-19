// lib/core/constants/gamification_constants.dart
// Constantes para sistema de gamificação - Fase 3 (Atualizado com detalhes)

/// Configurações globais do sistema de gamificação
/// Esta classe centraliza todos os valores numéricos e de configuração
/// relacionados à progressão do jogador, economia e recompensas no jogo.
/// Isso facilita o ajuste e o balanceamento do jogo sem alterar a lógica principal.
class GamificationConstants {
  // ================================================================================================
  // SISTEMA DE NÍVEIS E XP
  // ================================================================================================

  /// XP inicial que um usuário possui ao criar uma conta.
  static const int initialXP = 0;

  /// Nível inicial que um usuário possui ao criar uma conta.
  static const int initialLevel = 1;

  /// XP base necessário para subir do nível 1 para 2.
  /// Serve como o ponto de partida para a curva de XP.
  static const int baseXPRequired = 100;

  /// Fator de crescimento que determina o quão rapidamente o XP necessário
  /// para o próximo nível aumenta. Um valor maior significa uma progressão
  /// de nível mais lenta em níveis mais altos (progressão exponencial).
  static const double xpGrowthFactor = 1.5;

  /// Nível máximo que um jogador pode alcançar no jogo.
  static const int maxLevel = 100;

  /// XP máximo que um jogador pode ganhar em um único dia.
  /// Implementado como uma medida anti-farm para evitar abuso.
  static const int maxDailyXP = 1000;

  // ================================================================================================
  // ECONOMIA - COINS E GEMS
  // ================================================================================================

  /// Quantidade de moedas (coins) iniciais concedidas ao criar uma conta.
  static const int initialCoins = 200;

  /// Quantidade de gemas (gems) iniciais concedidas ao criar uma conta.
  /// Gemas geralmente são a moeda premium.
  static const int initialGems = 20;

  /// Máximo de moedas que pode ser ganho por dia.
  static const int maxDailyCoins = 500;

  /// Máximo de gemas que pode ser ganho por semana.
  static const int maxWeeklyGems = 50;

  /// Taxa de conversão de gemas para moedas (ex: 1 gema = 10 moedas).
  static const int gemsToCoinsRate = 10;

  /// Bônus de moedas concedido por login diário consecutivo.
  /// A chave é o número de dias de sequência, e o valor é a quantidade de coins.
  static const Map<int, int> dailyLoginBonus = {
    1: 10, // 1 dia de sequência
    2: 15, // 2 dias de sequência
    3: 20, // 3 dias de sequência
    4: 25, // 4 dias de sequência
    5: 30, // 5 dias de sequência
    6: 35, // 6 dias de sequência
    7: 50, // 7 dias de sequência (pode ser um marco com bônus maior)
  };

  // ================================================================================================
  // RECOMPENSAS POR NÍVEL
  // ================================================================================================

  /// Recompensas especiais concedidas ao jogador quando ele atinge um novo nível.
  /// A chave é o nível, e o valor é um mapa com os tipos e quantidades de recompensas.
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

  /// Títulos especiais que são desbloqueados em níveis específicos.
  /// A chave é o nível, e o valor é o nome do título.
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

  /// Conquistas especiais que os jogadores podem desbloquear ao realizar
  /// certas ações ou marcos.
  /// A chave é um ID único da conquista, e o valor contém seus detalhes.
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

  /// Multiplicador de XP concedido com base na sequência de login diário.
  /// A chave é o número de dias de sequência, e o valor é o multiplicador de XP.
  static const Map<int, double> loginStreakXPMultiplier = {
    3: 1.1, // +10% XP por 3 dias seguidos
    7: 1.2, // +20% XP por 1 semana
    14: 1.3, // +30% XP por 2 semanas
    30: 1.5, // +50% XP por 1 mês
  };

  /// Calcula um multiplicador de moedas com base no nível atual do usuário.
  /// Isso incentiva a progressão de nível.
  static double getCoinsMultiplierByLevel(int level) {
    if (level < 10) return 1.0;
    if (level < 20) return 1.1;
    if (level < 30) return 1.2;
    if (level < 50) return 1.3;
    return 1.5; // Multiplicador máximo
  }

  // ================================================================================================
  // LIMITES E PROTEÇÕES ANTI-FARM
  // ================================================================================================

  /// Cooldowns em minutos para ações específicas que concedem XP.
  /// Isso previne que os usuários "farmem" XP rapidamente.
  static const Map<String, int> actionCooldowns = {
    'profile_view': 1, // Visualizar perfil: 1 minuto
    'send_invite': 5, // Enviar convite: 5 minutos
    'complete_mission': 0, // Completar missão: sem cooldown imediato
    'minigame_complete': 2, // Completar minijogo: 2 minutos
  };

  /// Limites diários de XP que podem ser obtidos de ações específicas.
  static const Map<String, int> dailyXPLimits = {
    'profile_views': 150, // Máximo 150 XP/dia por visualizações de perfil
    'invites_sent': 300, // Máximo 300 XP/dia por envio de convites
    'minigames': 400, // Máximo 400 XP/dia por minijogos
  };

  // ================================================================================================
  // CONFIGURAÇÕES DE NOTIFICAÇÕES
  // ================================================================================================

  /// Configurações para controlar quais notificações de gamificação são exibidas.
  static const Map<String, bool> notificationSettings = {
    'level_up': true, // Notificar ao subir de nível
    'achievement_unlock': true, // Notificar ao desbloquear conquistas
    'daily_bonus': true, // Notificar sobre o bônus diário
    'mission_complete': true, // Notificar ao completar missões
    'weekly_summary': true, // Resumo semanal de atividades/recompensas
  };

  // ================================================================================================
  // CORES E VISUAL
  // ================================================================================================

  /// Mapeamento de cores (valores hex) para diferentes elementos de gamificação.
  static const Map<String, int> gamificationColors = {
    'xp': 0xFF2196F3, // Azul para XP
    'coins': 0xFFFFD700, // Dourado para moedas
    'gems': 0xFF9C27B0, // Roxo para gemas
    'level': 0xFF4CAF50, // Verde para nível
    'achievement': 0xFFFF9800, // Laranja para conquistas
    'streak': 0xFFE91E63, // Rosa para sequências
  };

  /// Mapeamento de ícones emoji para diferentes elementos de gamificação.
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

  /// Calcula o XP total necessário para alcançar um nível específico.
  /// A fórmula usa uma progressão exponencial baseada em `baseXPRequired` e `xpGrowthFactor`.
  static int calculateXPForLevel(int level) {
    if (level <= 1) return 0; // Nível 1 exige 0 XP

    double totalXP = 0;
    // Soma o XP necessário para cada nível até o nível desejado
    for (int i = 2; i <= level; i++) {
      totalXP += baseXPRequired * ((i - 1) * xpGrowthFactor);
    }
    return totalXP.round(); // Arredonda para o número inteiro mais próximo
  }

  /// Calcula o nível atual de um usuário com base na sua quantidade total de XP.
  static int calculateLevelFromXP(int currentXP) {
    int level = 1;
    // Itera do nível 1 até o nível máximo
    while (level < maxLevel) {
      // Calcula o XP necessário para o próximo nível
      int nextLevelXP = calculateXPForLevel(level + 1);
      // Se o XP atual for menor que o necessário para o próximo nível,
      // o nível atual é o correto
      if (currentXP < nextLevelXP) break;
      level++; // Caso contrário, avança para o próximo nível
    }
    return level;
  }

  /// Calcula a quantidade de XP que falta para o usuário alcançar o próximo nível.
  static int calculateXPToNextLevel(int currentXP) {
    int currentLevel = calculateLevelFromXP(currentXP);
    if (currentLevel >= maxLevel) return 0; // Se já está no nível máximo

    int nextLevelXP = calculateXPForLevel(currentLevel + 1);
    return nextLevelXP - currentXP;
  }

  /// Calcula o progresso percentual do usuário no nível atual.
  /// Retorna um valor entre 0.0 e 1.0.
  static double calculateLevelProgress(int currentXP) {
    int currentLevel = calculateLevelFromXP(currentXP);
    if (currentLevel >= maxLevel)
      return 1.0; // Se já está no nível máximo, o progresso é 100%

    int currentLevelXP = calculateXPForLevel(currentLevel);
    int nextLevelXP = calculateXPForLevel(currentLevel + 1);

    int levelRangeXP = nextLevelXP - currentLevelXP; // XP total para este nível
    int progressXP = currentXP - currentLevelXP; // XP ganho dentro deste nível

    // Evita divisão por zero se o levelRangeXP for 0 (caso improvável)
    return levelRangeXP > 0 ? progressXP / levelRangeXP : 0.0;
  }

  /// Verifica se um usuário subiu de nível comparando o XP antigo com o novo XP.
  static bool didLevelUp(int oldXP, int newXP) {
    return calculateLevelFromXP(oldXP) < calculateLevelFromXP(newXP);
  }

  /// Obtém o título do usuário com base no seu nível.
  /// Retorna o título do maior nível que o usuário já atingiu.
  static String getUserTitle(int level) {
    // Encontra o maior nível com título definido que o nível atual do usuário atinge
    int effectiveLevel = 1;
    for (int lvl in levelTitles.keys) {
      if (level >= lvl) {
        effectiveLevel = lvl;
      }
    }
    return levelTitles[effectiveLevel] ?? 'Novato'; // Fallback para "Novato"
  }

  /// Obtém as recompensas associadas a um nível específico.
  static Map<String, int>? getLevelUpRewards(int level) {
    return levelUpRewards[level];
  }

  /// Obtém o bônus de moedas para o login diário com base na sequência de dias.
  static int getLoginStreakBonus(int streakDays) {
    return dailyLoginBonus[streakDays] ??
        0; // Retorna 0 se não houver bônus para aquela sequência
  }
}
