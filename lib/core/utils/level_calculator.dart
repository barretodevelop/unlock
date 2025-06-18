// lib/core/utils/level_calculator.dart
// Utilitário para cálculos de nível e XP - Fase 3

import 'dart:math' as math;

import 'package:unlock/core/constants/gamification_constants.dart';

/// Utilitário para cálculos relacionados a níveis e XP
class LevelCalculator {
  // ================================================================================================
  // CÁLCULOS DE NÍVEL
  // ================================================================================================

  /// Calcular nível baseado no XP atual do usuário
  static int calculateLevel(int currentXP) {
    if (currentXP < 0) return 1;

    // Usar fórmula quadrática otimizada para calcular nível
    // Level = floor(sqrt(XP / baseXPRequired))
    final level =
        (math.sqrt(currentXP / GamificationConstants.baseXPRequired)).floor() +
        1;
    return math.min(level, GamificationConstants.maxLevel);
  }

  /// Calcular XP total necessário para atingir um nível específico
  static int calculateXPForLevel(int targetLevel) {
    if (targetLevel <= 1) return 0;
    if (targetLevel > GamificationConstants.maxLevel) {
      targetLevel = GamificationConstants.maxLevel;
    }

    // Fórmula: XP = (level - 1)² × baseXPRequired
    return ((targetLevel - 1) * (targetLevel - 1)) *
        GamificationConstants.baseXPRequired;
  }

  /// Calcular XP necessário para o próximo nível
  static int calculateXPToNextLevel(int currentXP) {
    final currentLevel = calculateLevel(currentXP);

    if (currentLevel >= GamificationConstants.maxLevel) {
      return 0; // Já está no nível máximo
    }

    final nextLevelXP = calculateXPForLevel(currentLevel + 1);
    return nextLevelXP - currentXP;
  }

  /// Calcular XP necessário para o nível atual (início do nível)
  static int calculateXPForCurrentLevel(int currentXP) {
    final currentLevel = calculateLevel(currentXP);
    return calculateXPForLevel(currentLevel);
  }

  /// Calcular progresso percentual no nível atual (0.0 - 1.0)
  static double calculateLevelProgress(int currentXP) {
    final currentLevel = calculateLevel(currentXP);

    if (currentLevel >= GamificationConstants.maxLevel) {
      return 1.0; // Nível máximo alcançado
    }

    final currentLevelXP = calculateXPForLevel(currentLevel);
    final nextLevelXP = calculateXPForLevel(currentLevel + 1);
    final levelRangeXP = nextLevelXP - currentLevelXP;
    final progressXP = currentXP - currentLevelXP;

    if (levelRangeXP <= 0) return 1.0;

    return (progressXP / levelRangeXP).clamp(0.0, 1.0);
  }

  /// Verificar se o usuário subiu de nível
  static bool hasLeveledUp(int oldXP, int newXP) {
    return calculateLevel(oldXP) < calculateLevel(newXP);
  }

  /// Calcular quantos níveis o usuário subiu
  static int levelsGained(int oldXP, int newXP) {
    return calculateLevel(newXP) - calculateLevel(oldXP);
  }

  // ================================================================================================
  // INFORMAÇÕES DE NÍVEL
  // ================================================================================================

  /// Obter título do usuário baseado no nível
  static String getUserTitle(int level) {
    return GamificationConstants.getUserTitle(level);
  }

  /// Obter recompensas de level up para um nível específico
  static Map<String, int>? getLevelUpRewards(int level) {
    return GamificationConstants.getLevelUpRewards(level);
  }

  /// Verificar se um nível tem recompensas especiais
  static bool hasLevelUpRewards(int level) {
    return GamificationConstants.levelUpRewards.containsKey(level);
  }

  /// Obter próximo nível com recompensas
  static int? getNextRewardLevel(int currentLevel) {
    final rewardLevels =
        GamificationConstants.levelUpRewards.keys
            .where((level) => level > currentLevel)
            .toList()
          ..sort();

    return rewardLevels.isEmpty ? null : rewardLevels.first;
  }

  // ================================================================================================
  // VALIDAÇÕES E LIMITES
  // ================================================================================================

  /// Validar se XP está dentro dos limites válidos
  static int validateXP(int xp) {
    return math.max(0, xp);
  }

  /// Validar se nível está dentro dos limites válidos
  static int validateLevel(int level) {
    return math.max(1, math.min(level, GamificationConstants.maxLevel));
  }

  /// Verificar se usuário pode ganhar mais XP hoje
  static bool canGainXPToday(int xpGainedToday) {
    return xpGainedToday < GamificationConstants.maxDailyXP;
  }

  /// Calcular XP máximo que pode ser ganho hoje
  static int maxXPRemainingToday(int xpGainedToday) {
    return math.max(0, GamificationConstants.maxDailyXP - xpGainedToday);
  }

  // ================================================================================================
  // ESTATÍSTICAS E ANÁLISES
  // ================================================================================================

  /// Calcular velocidade de progresso (XP por dia)
  static double calculateProgressSpeed(int totalXP, DateTime accountCreatedAt) {
    final daysSinceCreation = DateTime.now()
        .difference(accountCreatedAt)
        .inDays;
    if (daysSinceCreation <= 0) return 0.0;

    return totalXP / daysSinceCreation;
  }

  /// Estimar dias para atingir próximo nível
  static int estimateDaysToNextLevel(int currentXP, double averageXPPerDay) {
    if (averageXPPerDay <= 0) return -1; // Impossível calcular

    final xpToNext = calculateXPToNextLevel(currentXP);
    if (xpToNext <= 0) return 0; // Já no nível máximo

    return (xpToNext / averageXPPerDay).ceil();
  }

  /// Estimar dias para atingir nível específico
  static int estimateDaysToLevel(
    int currentXP,
    int targetLevel,
    double averageXPPerDay,
  ) {
    if (averageXPPerDay <= 0) return -1;

    final targetXP = calculateXPForLevel(targetLevel);
    final xpNeeded = targetXP - currentXP;

    if (xpNeeded <= 0) return 0; // Já atingiu o nível

    return (xpNeeded / averageXPPerDay).ceil();
  }

  /// Calcular percentual de progresso até o nível máximo
  static double calculateOverallProgress(int currentXP) {
    final maxXP = calculateXPForLevel(GamificationConstants.maxLevel);
    if (maxXP <= 0) return 1.0;

    return (currentXP / maxXP).clamp(0.0, 1.0);
  }

  // ================================================================================================
  // BONUS E MULTIPLICADORES
  // ================================================================================================

  /// Aplicar multiplicador de login streak no XP
  static int applyLoginStreakMultiplier(int baseXP, int loginStreakDays) {
    double multiplier = 1.0;

    for (final entry in GamificationConstants.loginStreakXPMultiplier.entries) {
      if (loginStreakDays >= entry.key) {
        multiplier = entry.value;
      }
    }

    return (baseXP * multiplier).round();
  }

  /// Aplicar multiplicador de nível nas coins
  static int applyLevelMultiplierToCoins(int baseCoins, int userLevel) {
    final multiplier = GamificationConstants.getCoinsMultiplierByLevel(
      userLevel,
    );
    return (baseCoins * multiplier).round();
  }

  /// Calcular bonus de login diário
  static int calculateDailyLoginBonus(int loginStreakDays) {
    return GamificationConstants.getLoginStreakBonus(loginStreakDays);
  }

  // ================================================================================================
  // FORMATAÇÃO E DISPLAY
  // ================================================================================================

  /// Formatar XP para exibição (com separadores de milhares)
  static String formatXP(int xp) {
    if (xp < 1000) return xp.toString();
    if (xp < 1000000) return '${(xp / 1000).toStringAsFixed(1)}K';
    return '${(xp / 1000000).toStringAsFixed(1)}M';
  }

  /// Formatar progresso de nível para exibição
  static String formatLevelProgress(int currentXP) {
    final currentLevel = calculateLevel(currentXP);
    final progress = (calculateLevelProgress(currentXP) * 100).round();
    return 'Nível $currentLevel ($progress%)';
  }

  /// Obter descrição textual do progresso
  static String getProgressDescription(int currentXP) {
    final currentLevel = calculateLevel(currentXP);
    final xpToNext = calculateXPToNextLevel(currentXP);

    if (currentLevel >= GamificationConstants.maxLevel) {
      return 'Nível máximo atingido!';
    }

    return 'Faltam ${formatXP(xpToNext)} XP para o nível ${currentLevel + 1}';
  }

  // ================================================================================================
  // MÉTODOS DE TESTE E DEBUG
  // ================================================================================================

  /// Gerar tabela de níveis para debug (primeiros N níveis)
  static List<Map<String, dynamic>> generateLevelTable(int maxLevels) {
    final table = <Map<String, dynamic>>[];

    for (
      int level = 1;
      level <= math.min(maxLevels, GamificationConstants.maxLevel);
      level++
    ) {
      final xpRequired = calculateXPForLevel(level);
      final xpToNext = level < GamificationConstants.maxLevel
          ? calculateXPForLevel(level + 1) - xpRequired
          : 0;
      final title = getUserTitle(level);
      final hasRewards = hasLevelUpRewards(level);

      table.add({
        'level': level,
        'xpRequired': xpRequired,
        'xpToNext': xpToNext,
        'title': title,
        'hasRewards': hasRewards,
      });
    }

    return table;
  }

  /// Validar consistência do sistema de níveis
  static bool validateLevelSystem() {
    try {
      // Verificar se os cálculos são consistentes
      for (int level = 1; level <= 10; level++) {
        final xp = calculateXPForLevel(level);
        final calculatedLevel = calculateLevel(xp);

        if (calculatedLevel != level) {
          return false;
        }
      }

      // Verificar progressão crescente
      for (int level = 1; level < 10; level++) {
        final currentXP = calculateXPForLevel(level);
        final nextXP = calculateXPForLevel(level + 1);

        if (nextXP <= currentXP) {
          return false;
        }
      }

      return true;
    } catch (e) {
      return false;
    }
  }
}
