// lib/features/games/widgets/game_card.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Para HapticFeedback
import 'package:unlock/core/constants/app_constants.dart';
import 'package:unlock/models/game_model.dart';

/// Um card interativo para exibir um mini-game na lista.
///
/// Inclui ícone, nome, descrição e feedback visual/tátil.
class GameCard extends StatelessWidget {
  final GameModel game;
  final VoidCallback onTap;

  const GameCard({super.key, required this.game, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.symmetric(
        vertical: AppConstants.spacingMedium,
        horizontal: AppConstants.paddingMedium,
      ),
      elevation: AppConstants.cardElevation,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.cardBorderRadius),
      ),
      color: theme.colorScheme.surfaceVariant,
      child: InkWell(
        onTap: game.isAvailable
            ? () {
                HapticFeedback.lightImpact(); // Feedback tátil
                onTap();
              }
            : null, // Desabilita o tap se o jogo não estiver disponível
        borderRadius: BorderRadius.circular(AppConstants.cardBorderRadius),
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.cardPadding),
          child: Row(
            children: [
              Icon(
                game.icon,
                size: 48,
                color: game.isAvailable
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurfaceVariant.withOpacity(0.5),
              ),
              const SizedBox(width: AppConstants.spacingExtraLarge),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      game.name,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: game.isAvailable
                            ? theme.colorScheme.onSurface
                            : theme.colorScheme.onSurfaceVariant.withOpacity(
                                0.5,
                              ),
                      ),
                    ),
                    const SizedBox(height: AppConstants.spacingSmall),
                    Text(
                      game.description,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: game.isAvailable
                            ? theme.colorScheme.onSurfaceVariant
                            : theme.colorScheme.onSurfaceVariant.withOpacity(
                                0.5,
                              ),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (!game.isAvailable)
                Icon(
                  Icons.lock,
                  color: theme.colorScheme.onSurfaceVariant.withOpacity(0.5),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
