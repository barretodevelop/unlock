// lib/core/utils/level_calculator.dart
// Utilitário para cálculos de nível e XP - Fase 4 (Revisado para consistência de fórmula)

import 'dart:math' as math;

import 'package:unlock/core/constants/gamification_constants.dart';

/// Utilitário para cálculos relacionados a níveis e XP.
/// Esta classe fornece métodos para calcular o nível do usuário com base no XP,
/// o XP necessário para os próximos níveis, progresso, e outras métricas de gamificação.
class LevelCalculator {
  // ================================================================================================
  // CÁLCULOS DE NÍVEL
  // ================================================================================================

  /// Calcula o nível atual do usuário com base no seu XP total.
  ///
  /// A lógica itera a partir do nível 1 e calcula o XP necessário para cada nível
  /// sucessivo, parando quando o XP do usuário é menor que o XP necessário para
  /// o próximo nível.
  static int calculateLevel(int currentXP) {
    if (currentXP < 0)
      return 1; // XP negativo não é válido, retorna nível mínimo.

    int level = GamificationConstants.initialLevel;
    while (level < GamificationConstants.maxLevel) {
      final xpForNextLevel = calculateXPForLevel(level + 1);
      if (currentXP < xpForNextLevel) {
        break; // XP atual é menor que o necessário para o próximo nível.
      }
      level++;
    }
    return level;
  }

  /// Calcula o XP total acumulado necessário para alcançar um nível específico.
  ///
  /// Esta função utiliza uma progressão exponencial baseada no `baseXPRequired`
  /// e no `xpGrowthFactor` definidos em `GamificationConstants`.
  /// A fórmula é `baseXPRequired * (1 + xpGrowthFactor)^(level - 2)` para o XP *adicional* do nível,
  /// somado cumulativamente.
  ///
  /// Uma fórmula mais simples e comum para XP cumulativo:
  /// XP(level) = baseXPRequired * (1 + factor) + baseXPRequired * (1 + factor)^2 + ...
  /// Alternativa mais direta para XP acumulado:
  /// `XP_total = SUM (baseXPRequired * (i-1) * xpGrowthFactor)` de i=2 até level.
  ///
  /// Para usar `xpGrowthFactor` para definir o *crescimento* do XP por nível (não o total):
  /// `XP_necessario_para_proximo_nivel = XP_anterior_necessario * xpGrowthFactor`.
  /// Se a sua `GamificationConstants.calculateXPForLevel` já faz isso, podemos usar:
  /// `GamificationConstants.calculateXPForLevel(targetLevel)`
  static int calculateXPForLevel(int targetLevel) {
    // Redireciona para a constante que já implementa a lógica complexa de XP por nível
    return GamificationConstants.calculateXPForLevel(targetLevel);
  }

  /// Calcula a quantidade de XP que falta para o usuário alcançar o próximo nível.
  static int calculateXPToNextLevel(int currentXP) {
    final currentLevel = calculateLevel(currentXP);

    if (currentLevel >= GamificationConstants.maxLevel) {
      return 0; // Já está no nível máximo.
    }

    final nextLevelXP = calculateXPForLevel(currentLevel + 1);
    return nextLevelXP - currentXP;
  }

  /// Calcula o XP total acumulado até o início do nível atual.
  static int calculateXPForCurrentLevel(int currentXP) {
    final currentLevel = calculateLevel(currentXP);
    return calculateXPForLevel(currentLevel);
  }

  /// Calcula o progresso percentual do usuário no nível atual (0.0 - 1.0).
  ///
  /// Retorna a porcentagem de XP que o usuário ganhou dentro do seu nível atual,
  /// em relação ao total de XP necessário para completar este nível.
  static double calculateLevelProgress(int currentXP) {
    final currentLevel = calculateLevel(currentXP);

    if (currentLevel >= GamificationConstants.maxLevel) {
      return 1.0; // Nível máximo alcançado, progresso é 100%.
    }

    final currentLevelXP = calculateXPForLevel(currentLevel);
    final nextLevelXP = calculateXPForLevel(currentLevel + 1);

    // XP necessário para ir do início do nível atual ao início do próximo nível.
    final levelRangeXP = nextLevelXP - currentLevelXP;
    // XP que o usuário já ganhou dentro do nível atual.
    final progressXP = currentXP - currentLevelXP;

    if (levelRangeXP <= 0) {
      return 1.0; // Evita divisão por zero ou se o nível não tem progressão.
    }

    return (progressXP / levelRangeXP).clamp(
      0.0,
      1.0,
    ); // Garante que o valor esteja entre 0 e 1.
  }

  /// Verifica se o usuário subiu de nível comparando o XP antigo com o novo XP.
  static bool hasLeveledUp(int oldXP, int newXP) {
    return calculateLevel(oldXP) < calculateLevel(newXP);
  }

  /// Calcula quantos níveis o usuário subiu.
  static int levelsGained(int oldXP, int newXP) {
    return calculateLevel(newXP) - calculateLevel(oldXP);
  }

  // ================================================================================================
  // INFORMAÇÕES DE NÍVEL (Redirecionando para GamificationConstants)
  // ================================================================================================

  /// Obtém o título do usuário baseado no nível.
  /// Redireciona para `GamificationConstants`.
  static String getUserTitle(int level) {
    return GamificationConstants.getUserTitle(level);
  }

  /// Obtém as recompensas de level up para um nível específico.
  /// Redireciona para `GamificationConstants`.
  static Map<String, int>? getLevelUpRewards(int level) {
    return GamificationConstants.getLevelUpRewards(level);
  }

  /// Verifica se um nível tem recompensas especiais.
  static bool hasLevelUpRewards(int level) {
    return GamificationConstants.levelUpRewards.containsKey(level);
  }

  /// Obtém o próximo nível que terá recompensas, a partir do nível atual.
  static int? getNextRewardLevel(int currentLevel) {
    final rewardLevels =
        GamificationConstants.levelUpRewards.keys
            .where((level) => level > currentLevel)
            .toList()
          ..sort(); // Garante que a lista esteja ordenada.

    return rewardLevels.isEmpty ? null : rewardLevels.first;
  }

  // ================================================================================================
  // VALIDAÇÕES E LIMITES (Redirecionando para GamificationConstants ou lógica simples)
  // ================================================================================================

  /// Valida se o XP está dentro dos limites válidos (não negativo).
  static int validateXP(int xp) {
    return math.max(0, xp);
  }

  /// Valida se o nível está dentro dos limites válidos (mínimo 1, máximo `maxLevel`).
  static int validateLevel(int level) {
    return math.max(1, math.min(level, GamificationConstants.maxLevel));
  }

  /// Verifica se o usuário pode ganhar mais XP hoje, com base no limite diário.
  static bool canGainXPToday(int xpGainedToday) {
    return xpGainedToday < GamificationConstants.maxDailyXP;
  }

  /// Calcula o XP máximo que o usuário ainda pode ganhar hoje.
  static int maxXPRemainingToday(int xpGainedToday) {
    return math.max(0, GamificationConstants.maxDailyXP - xpGainedToday);
  }

  // ================================================================================================
  // ESTATÍSTICAS E ANÁLISES
  // ================================================================================================

  /// Calcula a velocidade média de progresso (XP por dia) do usuário.
  static double calculateProgressSpeed(int totalXP, DateTime accountCreatedAt) {
    final daysSinceCreation = DateTime.now()
        .difference(accountCreatedAt)
        .inDays;
    if (daysSinceCreation <= 0) return 0.0; // Evita divisão por zero.

    return totalXP / daysSinceCreation;
  }

  /// Estima quantos dias faltam para o usuário atingir o próximo nível,
  /// com base na sua média diária de XP.
  static int estimateDaysToNextLevel(int currentXP, double averageXPPerDay) {
    if (averageXPPerDay <= 0)
      return -1; // Não é possível calcular ou usuário não ganha XP.

    final xpToNext = calculateXPToNextLevel(currentXP);
    if (xpToNext <= 0) return 0; // Já no nível máximo ou próximo.

    return (xpToNext / averageXPPerDay).ceil(); // Arredonda para cima.
  }

  /// Estima quantos dias faltam para o usuário atingir um nível específico.
  static int estimateDaysToLevel(
    int currentXP,
    int targetLevel,
    double averageXPPerDay,
  ) {
    if (averageXPPerDay <= 0) return -1;

    final targetXP = calculateXPForLevel(targetLevel);
    final xpNeeded = targetXP - currentXP;

    if (xpNeeded <= 0) return 0; // Já atingiu ou ultrapassou o nível alvo.

    return (xpNeeded / averageXPPerDay).ceil();
  }

  /// Calcula o progresso geral do usuário em relação ao nível máximo do jogo.
  static double calculateOverallProgress(int currentXP) {
    final maxXP = calculateXPForLevel(GamificationConstants.maxLevel);
    if (maxXP <= 0) return 1.0; // Se não há XP máximo definido ou é 0.

    return (currentXP / maxXP).clamp(0.0, 1.0);
  }

  // ================================================================================================
  // BÔNUS E MULTIPLICADORES
  // ================================================================================================

  /// Aplica o multiplicador de XP baseado na sequência de login diário.
  static int applyLoginStreakMultiplier(int baseXP, int loginStreakDays) {
    double multiplier = 1.0;

    for (final entry in GamificationConstants.loginStreakXPMultiplier.entries) {
      if (loginStreakDays >= entry.key) {
        multiplier = entry.value;
      }
    }

    return (baseXP * multiplier).round();
  }

  /// Aplica o multiplicador de moedas com base no nível do usuário.
  static int applyLevelMultiplierToCoins(int baseCoins, int userLevel) {
    final multiplier = GamificationConstants.getCoinsMultiplierByLevel(
      userLevel,
    );
    return (baseCoins * multiplier).round();
  }

  /// Calcula o bônus de login diário.
  static int calculateDailyLoginBonus(int loginStreakDays) {
    return GamificationConstants.getLoginStreakBonus(loginStreakDays);
  }

  // ================================================================================================
  // FORMATAÇÃO E DISPLAY
  // ================================================================================================

  /// Formata um valor de XP para exibição, adicionando sufixos 'K' ou 'M'
  /// para milhares e milhões, respectivamente.
  static String formatXP(int xp) {
    if (xp < 1000) return xp.toString();
    if (xp < 1000000) return '${(xp / 1000).toStringAsFixed(1)}K';
    return '${(xp / 1000000).toStringAsFixed(1)}M';
  }

  /// Formata o progresso do nível para exibição (ex: "Nível 5 (75%)").
  static String formatLevelProgress(int currentXP) {
    final currentLevel = calculateLevel(currentXP);
    final progress = (calculateLevelProgress(currentXP) * 100).round();
    return 'Nível $currentLevel ($progress%)';
  }

  /// Obtém uma descrição textual do progresso do usuário no nível atual.
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

  /// Gera uma tabela de níveis para fins de debug ou documentação,
  /// mostrando XP necessário, XP para o próximo nível, título e se tem recompensas.
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

  /// Valida a consistência do sistema de níveis, verificando se os cálculos
  /// de nível e XP são inversos e se a progressão é crescente.
  static bool validateLevelSystem() {
    try {
      // Verificar se os cálculos são consistentes (XP de um nível retorna o próprio nível)
      for (int level = 1; level <= 10; level++) {
        // Testando os primeiros 10 níveis
        final xp = calculateXPForLevel(level);
        final calculatedLevel = calculateLevel(xp);

        if (calculatedLevel != level) {
          print(
            'Validação falhou: Nível $level XP $xp -> Nível calculado $calculatedLevel',
          );
          return false;
        }
      }

      // Verificar se a progressão de XP é sempre crescente
      for (int level = 1; level < 10; level++) {
        // Testando progressão até o nível 10
        final currentXPForLevel = calculateXPForLevel(level);
        final nextXPForLevel = calculateXPForLevel(level + 1);

        if (nextXPForLevel <= currentXPForLevel) {
          print(
            'Validação falhou: XP do nível ${level + 1} não é maior que o do nível $level',
          );
          return false;
        }
      }

      return true;
    } catch (e) {
      print('Erro durante a validação do sistema de níveis: $e');
      return false;
    }
  }
}
