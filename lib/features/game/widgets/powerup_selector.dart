// lib/features/game/widgets/powerup_selector.dart
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:unlock/core/theme/app_colors.dart';
import 'package:unlock/models/powerup_model.dart';
import 'package:unlock/providers/shop_provider.dart';

/// Widget para selecionar e usar power-ups durante o jogo
class PowerUpSelector extends ConsumerStatefulWidget {
  final String gameRoomId;
  final VoidCallback? onPowerUpUsed;
  final bool isPlayerTurn;

  const PowerUpSelector({
    super.key,
    required this.gameRoomId,
    this.onPowerUpUsed,
    this.isPlayerTurn = true,
  });

  @override
  ConsumerState<PowerUpSelector> createState() => _PowerUpSelectorState();
}

class _PowerUpSelectorState extends ConsumerState<PowerUpSelector>
    with TickerProviderStateMixin {
  bool _isExpanded = false;
  late AnimationController _animationController;
  late Animation<double> _expandAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _expandAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final inventoryState = ref.watch(powerUpInventoryProvider);
    final availablePowerUps = inventoryState.available;
    final theme = Theme.of(context);

    if (availablePowerUps.isEmpty) {
      return const SizedBox.shrink();
    }

    return Positioned(
      bottom: 100,
      right: 16,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Power-ups list (expandido)
          AnimatedBuilder(
            animation: _expandAnimation,
            builder: (context, child) {
              return SizeTransition(
                sizeFactor: _expandAnimation,
                child: Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  constraints: const BoxConstraints(maxHeight: 300),
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: availablePowerUps.take(5).map((userPowerUp) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: _PowerUpButton(
                            userPowerUp: userPowerUp,
                            gameRoomId: widget.gameRoomId,
                            isEnabled: widget.isPlayerTurn,
                            onUsed: () {
                              widget.onPowerUpUsed?.call();
                              _toggleExpanded();
                            },
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              );
            },
          ),

          // Main toggle button
          _MainToggleButton(
            isExpanded: _isExpanded,
            powerUpCount: availablePowerUps.length,
            onToggle: _toggleExpanded,
            isEnabled: widget.isPlayerTurn,
          ),
        ],
      ),
    );
  }

  void _toggleExpanded() {
    setState(() {
      _isExpanded = !_isExpanded;
    });

    if (_isExpanded) {
      _animationController.forward();
    } else {
      _animationController.reverse();
    }
  }
}

/// Botão principal para toggle do seletor
class _MainToggleButton extends StatelessWidget {
  final bool isExpanded;
  final int powerUpCount;
  final VoidCallback onToggle;
  final bool isEnabled;

  const _MainToggleButton({
    required this.isExpanded,
    required this.powerUpCount,
    required this.onToggle,
    required this.isEnabled,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
          onTap: isEnabled ? onToggle : null,
          child: Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isEnabled
                    ? [AppColors.primary, AppColors.secondary]
                    : [Colors.grey, Colors.grey.shade600],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: (isEnabled ? AppColors.primary : Colors.grey)
                      .withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Stack(
              children: [
                Center(
                  child: AnimatedRotation(
                    turns: isExpanded ? 0.125 : 0,
                    duration: const Duration(milliseconds: 300),
                    child: Icon(
                      isExpanded ? Icons.close : Icons.flash_on,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                ),

                // Badge com quantidade
                if (powerUpCount > 0)
                  Positioned(
                    top: -2,
                    right: -2,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: AppColors.warning,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      constraints: const BoxConstraints(minWidth: 20),
                      child: Text(
                        powerUpCount > 99 ? '99+' : powerUpCount.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        )
        .animate(
          onPlay: (controller) {
            if (isEnabled) {
              controller.repeat(reverse: true);
            }
          },
        )
        .scale(
          begin: const Offset(1.0, 1.0),
          end: const Offset(1.05, 1.05),
          duration: 2000.ms,
        );
  }
}

/// Botão individual de power-up
class _PowerUpButton extends ConsumerStatefulWidget {
  final UserPowerUp userPowerUp;
  final String gameRoomId;
  final bool isEnabled;
  final VoidCallback? onUsed;

  const _PowerUpButton({
    required this.userPowerUp,
    required this.gameRoomId,
    required this.isEnabled,
    this.onUsed,
  });

  @override
  ConsumerState<_PowerUpButton> createState() => _PowerUpButtonState();
}

class _PowerUpButtonState extends ConsumerState<_PowerUpButton> {
  bool _isUsing = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final powerUpData = PowerUpData.getPowerUpByType(widget.userPowerUp.type);

    if (powerUpData == null) return const SizedBox.shrink();

    return GestureDetector(
      onTap: widget.isEnabled && !_isUsing ? _usePowerUp : null,
      child: Container(
        width: 120,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Color(powerUpData.rarity.colorValue).withOpacity(0.3),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Color(powerUpData.rarity.colorValue).withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Emoji com efeito
            Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Color(
                      powerUpData.rarity.colorValue,
                    ).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    powerUpData.emoji,
                    style: const TextStyle(fontSize: 24),
                  ),
                )
                .animate(onPlay: (controller) => controller.repeat())
                .shimmer(
                  duration: 1500.ms,
                  color: Color(powerUpData.rarity.colorValue).withOpacity(0.3),
                ),

            const SizedBox(height: 8),

            // Nome
            Text(
              powerUpData.name,
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),

            const SizedBox(height: 4),

            // Quantidade
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'x${widget.userPowerUp.quantity}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                  fontSize: 10,
                ),
              ),
            ),

            const SizedBox(height: 8),

            // Botão usar
            SizedBox(
              width: double.infinity,
              height: 28,
              child: ElevatedButton(
                onPressed: widget.isEnabled && !_isUsing ? _usePowerUp : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(powerUpData.rarity.colorValue),
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: _isUsing
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        'USAR',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _usePowerUp() async {
    setState(() {
      _isUsing = true;
    });

    try {
      final success = await ref
          .read(powerUpInventoryProvider.notifier)
          .usePowerUp(widget.userPowerUp.type, widget.gameRoomId);

      if (success && mounted) {
        // Mostra feedback visual
        _showPowerUpEffect();

        // Callback de sucesso
        widget.onUsed?.call();

        // Mostra snackbar de confirmação
        if (context.mounted) {
          final powerUpData = PowerUpData.getPowerUpByType(
            widget.userPowerUp.type,
          );
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Text(powerUpData?.emoji ?? '⚡'),
                  const SizedBox(width: 8),
                  Text('${powerUpData?.name ?? 'Power-up'} ativado!'),
                ],
              ),
              backgroundColor: AppColors.success,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao usar power-up: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUsing = false;
        });
      }
    }
  }

  void _showPowerUpEffect() {
    // TODO: Implementar efeito visual específico do power-up
    // Por exemplo, mostrar overlay com efeito de partículas
  }
}

/// Dialog para explicar power-ups
class PowerUpInfoDialog extends StatelessWidget {
  final PowerUpType type;

  const PowerUpInfoDialog({super.key, required this.type});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final powerUpData = PowerUpData.getPowerUpByType(type);

    if (powerUpData == null) {
      return const SizedBox.shrink();
    }

    return AlertDialog(
      title: Row(
        children: [
          Text(powerUpData.emoji, style: const TextStyle(fontSize: 32)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              powerUpData.name,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: Color(powerUpData.rarity.colorValue),
              ),
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Raridade
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Color(powerUpData.rarity.colorValue).withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Color(powerUpData.rarity.colorValue).withOpacity(0.3),
              ),
            ),
            child: Text(
              powerUpData.rarity.displayName,
              style: theme.textTheme.bodySmall?.copyWith(
                color: Color(powerUpData.rarity.colorValue),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Descrição
          Text(
            powerUpData.description,
            style: theme.textTheme.bodyMedium?.copyWith(height: 1.4),
          ),

          const SizedBox(height: 16),

          // Detalhes técnicos
          _DetailRow(
            label: 'Uso máximo por jogo:',
            value: powerUpData.maxUses == -1
                ? 'Ilimitado'
                : '${powerUpData.maxUses}x',
          ),

          if (powerUpData.duration > 0)
            _DetailRow(label: 'Duração:', value: '${powerUpData.duration}s'),

          _DetailRow(
            label: 'Custo na loja:',
            value: '💰 ${powerUpData.coinsCost}',
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Entendi'),
        ),
      ],
    );
  }
}

/// Row de detalhes
class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

/// Widget compacto para mostrar power-ups ativos na tela de jogo
class ActivePowerUpsDisplay extends StatelessWidget {
  final List<GamePowerUpUsage> activePowerUps;

  const ActivePowerUpsDisplay({super.key, required this.activePowerUps});

  @override
  Widget build(BuildContext context) {
    if (activePowerUps.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.success.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.success.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.flash_on, color: AppColors.success, size: 16),
              const SizedBox(width: 8),
              Text(
                'Power-ups Ativos',
                style: TextStyle(
                  color: AppColors.success,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: activePowerUps.map((usage) {
              final powerUpData = PowerUpData.getPowerUpByType(usage.type);
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.success.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      powerUpData?.emoji ?? '⚡',
                      style: const TextStyle(fontSize: 12),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      powerUpData?.name ?? 'Power-up',
                      style: TextStyle(
                        color: AppColors.success,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

/// Widget para mostrar estatísticas de power-ups usados
class PowerUpStatsWidget extends StatelessWidget {
  final Map<PowerUpType, int> usageStats;

  const PowerUpStatsWidget({super.key, required this.usageStats});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (usageStats.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        child: Text(
          'Nenhum power-up usado ainda',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurface.withOpacity(0.6),
          ),
          textAlign: TextAlign.center,
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Power-ups Utilizados',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        ...usageStats.entries.map((entry) {
          final powerUpData = PowerUpData.getPowerUpByType(entry.key);
          if (powerUpData == null) return const SizedBox.shrink();

          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Text(powerUpData.emoji),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    powerUpData.name,
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${entry.value}x',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ],
    );
  }
}
