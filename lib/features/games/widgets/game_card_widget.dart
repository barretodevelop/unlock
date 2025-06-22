// lib/features/games/widgets/game_card_widget.dart

import 'package:flutter/material.dart';
import 'package:unlock/features/rewards/models/reward_model.dart';
import 'package:unlock/models/game_model.dart';

/// Widget que representa um card de jogo na lista de mini-games.
///
/// Exibe informações do jogo como nome, descrição, ícone e recompensas,
/// além de indicar se o jogo está disponível ou bloqueado.
class GameCardWidget extends StatelessWidget {
  final GameModel game;
  final VoidCallback onTap;

  const GameCardWidget({super.key, required this.game, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isAvailable = game.isAvailable;

    return Card(
      elevation: isAvailable ? 4 : 2,
      shadowColor: isAvailable
          ? theme.colorScheme.shadow
          : theme.colorScheme.shadow.withOpacity(0.3),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: isAvailable
                ? LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      theme.colorScheme.primaryContainer.withOpacity(0.7),
                      theme.colorScheme.secondaryContainer.withOpacity(0.5),
                    ],
                  )
                : null,
            color: !isAvailable
                ? theme.colorScheme.surfaceVariant.withOpacity(0.5)
                : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _buildGameIcon(theme, isAvailable),
                  const Spacer(),
                  if (!isAvailable) _buildLockedIndicator(theme),
                ],
              ),
              const SizedBox(height: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      game.name,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: isAvailable
                            ? theme.colorScheme.onPrimaryContainer
                            : theme.colorScheme.onSurfaceVariant.withOpacity(
                                0.6,
                              ),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      game.description,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: isAvailable
                            ? theme.colorScheme.onPrimaryContainer.withOpacity(
                                0.8,
                              )
                            : theme.colorScheme.onSurfaceVariant.withOpacity(
                                0.5,
                              ),
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              _buildRewards(theme, isAvailable),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGameIcon(ThemeData theme, bool isAvailable) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: isAvailable
            ? theme.colorScheme.primary.withOpacity(0.1)
            : theme.colorScheme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
        game.icon,
        size: 28,
        color: isAvailable
            ? theme.colorScheme.primary
            : theme.colorScheme.onSurfaceVariant.withOpacity(0.5),
      ),
    );
  }

  Widget _buildLockedIndicator(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: theme.colorScheme.error.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Icon(Icons.lock, size: 16, color: theme.colorScheme.error),
    );
  }

  Widget _buildRewards(ThemeData theme, bool isAvailable) {
    if (game.baseRewards.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isAvailable
            ? theme.colorScheme.surface.withOpacity(0.8)
            : theme.colorScheme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.emoji_events,
            size: 12,
            color: isAvailable
                ? theme.colorScheme.tertiary
                : theme.colorScheme.onSurfaceVariant.withOpacity(0.5),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              _buildRewardsText(),
              style: theme.textTheme.labelSmall?.copyWith(
                color: isAvailable
                    ? theme.colorScheme.onSurface
                    : theme.colorScheme.onSurfaceVariant.withOpacity(0.5),
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  String _buildRewardsText() {
    final rewards = <String>[];

    game.baseRewards.forEach((type, amount) {
      switch (type) {
        case RewardType.xp:
          rewards.add('${amount}XP');
          break;
        case RewardType.coins:
          rewards.add('${amount}🪙');
          break;
        case RewardType.gems:
          rewards.add('${amount}💎');
          break;
        case RewardType.achievement:
          // TODO: Handle this case.
          throw UnimplementedError();
        case RewardType.item:
          // TODO: Handle this case.
          throw UnimplementedError();
        case RewardType.title:
          // TODO: Handle this case.
          throw UnimplementedError();
        case RewardType.boost:
          // TODO: Handle this case.
          throw UnimplementedError();
      }
    });

    return rewards.join(' • ');
  }
}
