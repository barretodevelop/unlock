// lib/utils/currency_rewards_helper.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:unlock/core/utils/logger.dart';
import 'package:unlock/models/currency_model.dart';
import 'package:unlock/providers/currency_provider.dart';
import 'package:unlock/shared/widgets/currency_display.dart';

/// Helper para processar recompensas automáticas de moeda
class CurrencyRewardsHelper {
  /// Processa recompensa por login diário
  static Future<void> processLoginReward(WidgetRef ref) async {
    try {
      final currencyNotifier = ref.read(currencyProvider.notifier);
      await currencyNotifier.processAutomaticReward(CurrencyReason.dailyLogin);

      AppLogger.info('💰 Daily login reward processed');
    } catch (e, stackTrace) {
      AppLogger.error(
        '❌ Failed to process login reward',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Processa recompensa por sequência de login
  static Future<void> processStreakReward(WidgetRef ref, int streakDays) async {
    try {
      final currencyNotifier = ref.read(currencyProvider.notifier);

      // Recompensa baseada na sequência
      int bonusAmount = 0;
      if (streakDays >= 7)
        bonusAmount = 50;
      else if (streakDays >= 3)
        bonusAmount = 20;
      else if (streakDays >= 1)
        bonusAmount = 10;

      if (bonusAmount > 0) {
        await currencyNotifier.addCoins(bonusAmount, 'loginStreak');
        AppLogger.info(
          '🔥 Streak reward processed',
          data: {'streakDays': streakDays, 'bonus': bonusAmount},
        );
      }
    } catch (e, stackTrace) {
      AppLogger.error(
        '❌ Failed to process streak reward',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Processa recompensa semanal automática
  static Future<void> processWeeklyReward(WidgetRef ref) async {
    try {
      final currencyNotifier = ref.read(currencyProvider.notifier);
      await currencyNotifier.processAutomaticReward(CurrencyReason.weeklyBonus);

      AppLogger.info('💎 Weekly reward processed');
    } catch (e, stackTrace) {
      AppLogger.error(
        '❌ Failed to process weekly reward',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Mostra animação de recompensa na tela
  static void showRewardAnimation(
    BuildContext context, {
    required int amount,
    required CurrencyType type,
    Duration displayDuration = const Duration(seconds: 3),
  }) {
    if (!context.mounted) return;

    final overlay = Overlay.of(context);
    late OverlayEntry overlayEntry;

    overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: MediaQuery.of(context).size.height * 0.3,
        left: 0,
        right: 0,
        child: Center(
          child: CurrencyRewardAnimation(
            amount: amount,
            type: type,
            onCompleted: () {
              overlayEntry.remove();
            },
          ),
        ),
      ),
    );

    overlay.insert(overlayEntry);

    // Remove automaticamente após o tempo especificado
    Future.delayed(displayDuration, () {
      if (overlayEntry.mounted) {
        overlayEntry.remove();
      }
    });
  }

  /// Verifica se o usuário pode comprar algo
  static bool canAfford(WidgetRef ref, int amount, CurrencyType type) {
    final currencyState = ref.read(currencyProvider);
    return currencyState.canAfford(amount, type);
  }

  /// Processa uma compra
  static Future<bool> processPurchase(
    WidgetRef ref, {
    required int amount,
    required CurrencyType type,
    required String reason,
    String? gameId,
  }) async {
    try {
      final currencyNotifier = ref.read(currencyProvider.notifier);

      bool success = false;
      switch (type) {
        case CurrencyType.coins:
          success = await currencyNotifier.spendCoins(
            amount,
            reason,
            gameId: gameId,
          );
          break;
        case CurrencyType.gems:
          success = await currencyNotifier.spendGems(
            amount,
            reason,
            gameId: gameId,
          );
          break;
      }

      if (success) {
        AppLogger.info(
          '💸 Purchase completed',
          data: {'amount': amount, 'type': type.name, 'reason': reason},
        );
      }

      return success;
    } catch (e, stackTrace) {
      AppLogger.error('❌ Purchase failed', error: e, stackTrace: stackTrace);
      return false;
    }
  }

  /// Calcula recompensas baseadas na performance do jogo
  static Map<String, int> calculateGameRewards({
    required int totalQuestions,
    required int correctAnswers,
    required bool gameCompleted,
    required bool connectionFormed,
    required bool isFirstConnection,
  }) {
    Map<String, int> rewards = {};

    // Recompensa por respostas corretas (5 moedas cada)
    if (correctAnswers > 0) {
      rewards['correct_answers'] = correctAnswers * 5;
    }

    // Recompensa por completar o jogo (50 moedas)
    if (gameCompleted) {
      rewards['game_completed'] = 50;
    }

    // Recompensa por formar conexão (100 moedas)
    if (connectionFormed) {
      rewards['connection_formed'] = 100;
    }

    // Bônus especial para primeira conexão (200 moedas)
    if (isFirstConnection) {
      rewards['first_connection'] = 200;
    }

    // Bônus de performance para alta precisão
    if (totalQuestions > 0) {
      final accuracy = (correctAnswers / totalQuestions) * 100;
      if (accuracy >= 90) {
        rewards['perfect_score'] = 25;
      } else if (accuracy >= 80) {
        rewards['great_score'] = 15;
      } else if (accuracy >= 70) {
        rewards['good_score'] = 10;
      }
    }

    return rewards;
  }

  /// Aplica múltiplas recompensas de uma vez
  static Future<void> applyGameRewards(
    WidgetRef ref,
    Map<String, int> rewards, {
    String? gameId,
  }) async {
    try {
      final currencyNotifier = ref.read(currencyProvider.notifier);

      for (final entry in rewards.entries) {
        final reason = entry.key;
        final amount = entry.value;

        await currencyNotifier.addCoins(amount, reason, gameId: gameId);

        AppLogger.info(
          '🎁 Game reward applied',
          data: {'reason': reason, 'amount': amount, 'gameId': gameId},
        );
      }
    } catch (e, stackTrace) {
      AppLogger.error(
        '❌ Failed to apply game rewards',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Formata valor de moeda para exibição
  static String formatCurrency(int amount, CurrencyType type) {
    String formattedAmount;

    if (amount >= 1000000) {
      formattedAmount = '${(amount / 1000000).toStringAsFixed(1)}M';
    } else if (amount >= 1000) {
      formattedAmount = '${(amount / 1000).toStringAsFixed(1)}K';
    } else {
      formattedAmount = amount.toString();
    }

    return '${type.emoji} $formattedAmount';
  }

  /// Obtém cor baseada no tipo de moeda
  static Color getCurrencyColor(CurrencyType type) {
    switch (type) {
      case CurrencyType.coins:
        return const Color(0xFFFFB800); // Amarelo dourado
      case CurrencyType.gems:
        return const Color(0xFF8E44AD); // Roxo
    }
  }

  /// Retorna uma mensagem motivacional baseada no saldo
  static String getMotivationalMessage(int coins, int gems) {
    final total = coins + (gems * 10); // Gemas valem mais

    if (total >= 5000) {
      return '🤑 Você é um magnata das moedas!';
    } else if (total >= 2000) {
      return '💰 Rica(o) em recursos!';
    } else if (total >= 1000) {
      return '🎯 No caminho da riqueza!';
    } else if (total >= 500) {
      return '📈 Progredindo bem!';
    } else if (total >= 200) {
      return '🌱 Começando a crescer!';
    } else {
      return '🎮 Complete mais jogos para ganhar moedas!';
    }
  }

  /// Debug info das moedas
  static Map<String, dynamic> getDebugInfo(WidgetRef ref) {
    final currencyState = ref.read(currencyProvider);
    final currencyNotifier = ref.read(currencyProvider.notifier);

    return {
      'current_state': currencyState.toString(),
      'notifier_debug': currencyNotifier.getDebugInfo(),
      'can_afford_100_coins': currencyState.canAfford(100, CurrencyType.coins),
      'can_afford_10_gems': currencyState.canAfford(10, CurrencyType.gems),
      'motivational_message': getMotivationalMessage(
        currencyState.coins,
        currencyState.gems,
      ),
    };
  }
}

/// Widget helper para mostrar comparação de preços
class CurrencyComparisonWidget extends ConsumerWidget {
  final int coinsPrice;
  final int? gemsPrice;
  final String itemName;
  final bool enabled;
  final VoidCallback? onPurchase;

  const CurrencyComparisonWidget({
    super.key,
    required this.coinsPrice,
    this.gemsPrice,
    required this.itemName,
    this.enabled = true,
    this.onPurchase,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currencyState = ref.watch(currencyProvider);
    final theme = Theme.of(context);

    final canAffordCoins = currencyState.canAfford(
      coinsPrice,
      CurrencyType.coins,
    );
    final canAffordGems = gemsPrice != null
        ? currencyState.canAfford(gemsPrice!, CurrencyType.gems)
        : false;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              itemName,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),

            // Opção com moedas
            _PriceOption(
              type: CurrencyType.coins,
              price: coinsPrice,
              canAfford: canAffordCoins,
              enabled: enabled,
              onTap: canAffordCoins && enabled
                  ? () {
                      CurrencyRewardsHelper.processPurchase(
                        ref,
                        amount: coinsPrice,
                        type: CurrencyType.coins,
                        reason: 'purchase_$itemName',
                      ).then((success) {
                        if (success) onPurchase?.call();
                      });
                    }
                  : null,
            ),

            // Opção com gemas (se disponível)
            if (gemsPrice != null) ...[
              const SizedBox(height: 8),
              _PriceOption(
                type: CurrencyType.gems,
                price: gemsPrice!,
                canAfford: canAffordGems,
                enabled: enabled,
                onTap: canAffordGems && enabled
                    ? () {
                        CurrencyRewardsHelper.processPurchase(
                          ref,
                          amount: gemsPrice!,
                          type: CurrencyType.gems,
                          reason: 'purchase_$itemName',
                        ).then((success) {
                          if (success) onPurchase?.call();
                        });
                      }
                    : null,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Opção de preço individual
class _PriceOption extends StatelessWidget {
  final CurrencyType type;
  final int price;
  final bool canAfford;
  final bool enabled;
  final VoidCallback? onTap;

  const _PriceOption({
    required this.type,
    required this.price,
    required this.canAfford,
    required this.enabled,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isAvailable = canAfford && enabled;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isAvailable
              ? CurrencyRewardsHelper.getCurrencyColor(type).withOpacity(0.1)
              : theme.colorScheme.surfaceContainer,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isAvailable
                ? CurrencyRewardsHelper.getCurrencyColor(type).withOpacity(0.3)
                : theme.colorScheme.outline.withOpacity(0.2),
          ),
        ),
        child: Row(
          children: [
            Text(type.emoji, style: const TextStyle(fontSize: 20)),
            const SizedBox(width: 8),
            Text(
              price.toString(),
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: isAvailable
                    ? CurrencyRewardsHelper.getCurrencyColor(type)
                    : theme.colorScheme.onSurface.withOpacity(0.5),
              ),
            ),
            const Spacer(),
            if (!canAfford)
              Icon(
                Icons.lock_outline,
                color: theme.colorScheme.error,
                size: 20,
              ),
            if (canAfford && enabled)
              Icon(
                Icons.check_circle_outline,
                color: CurrencyRewardsHelper.getCurrencyColor(type),
                size: 20,
              ),
          ],
        ),
      ),
    );
  }
}
