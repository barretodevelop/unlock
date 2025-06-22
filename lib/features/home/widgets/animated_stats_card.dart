// lib/features/home/widgets/animated_stats_card.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:unlock/core/constants/app_constants.dart';
import 'package:unlock/models/user_model.dart';

/// Card de estatísticas do usuário com animações e micro-interações
class AnimatedStatsCard extends StatefulWidget {
  final UserModel user;
  final VoidCallback? onTap;

  const AnimatedStatsCard({super.key, required this.user, this.onTap});

  @override
  State<AnimatedStatsCard> createState() => _AnimatedStatsCardState();
}

class _AnimatedStatsCardState extends State<AnimatedStatsCard>
    with TickerProviderStateMixin {
  late AnimationController _mainController;
  late AnimationController _pulseController;
  late List<AnimationController> _itemControllers;

  late Animation<double> _cardAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _pulseAnimation;
  late List<Animation<double>> _itemAnimations;

  @override
  void initState() {
    super.initState();

    _mainController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    // Controllers para cada item de estatística
    _itemControllers = List.generate(
      4,
      (index) => AnimationController(
        duration: Duration(milliseconds: 300 + (index * 100)),
        vsync: this,
      ),
    );

    _setupAnimations();
    _startAnimations();
  }

  void _setupAnimations() {
    _cardAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.0, 0.6, curve: Curves.elasticOut),
      ),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _mainController,
            curve: const Interval(0.2, 0.8, curve: Curves.easeOut),
          ),
        );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _itemAnimations = _itemControllers.map((controller) {
      return Tween<double>(
        begin: 0.0,
        end: 1.0,
      ).animate(CurvedAnimation(parent: controller, curve: Curves.elasticOut));
    }).toList();
  }

  void _startAnimations() {
    _mainController.forward();
    _pulseController.repeat(reverse: true);

    // Animar itens sequencialmente
    for (int i = 0; i < _itemControllers.length; i++) {
      Future.delayed(Duration(milliseconds: 400 + (i * 150)), () {
        if (mounted) {
          _itemControllers[i].forward();
        }
      });
    }
  }

  @override
  void dispose() {
    _mainController.dispose();
    _pulseController.dispose();
    for (final controller in _itemControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AnimatedBuilder(
      animation: Listenable.merge([_mainController, _pulseController]),
      builder: (context, child) {
        return Transform.scale(
          scale: _cardAnimation.value * _pulseAnimation.value,
          child: SlideTransition(
            position: _slideAnimation,
            child: Opacity(
              opacity: _cardAnimation.value.clamp(0.0, 1.0),
              child: GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  widget.onTap?.call();
                },
                child: Container(
                  margin: const EdgeInsets.all(AppConstants.paddingMedium),
                  padding: const EdgeInsets.all(AppConstants.statsCardPadding),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        theme.colorScheme.primary,
                        theme.colorScheme.primary.withOpacity(0.8),
                        theme.colorScheme.secondary.withOpacity(0.6),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: theme.colorScheme.primary.withOpacity(0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(theme),
                      const SizedBox(height: AppConstants.spacingExtraLarge),
                      _buildStatsGrid(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Suas Conquistas',
              style: const TextStyle(
                color: Colors.white,
                fontSize: AppConstants.fontSizeExtraLarge,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Nível ${widget.user.level}',
              style: TextStyle(
                color: Colors.white.withOpacity(0.9),
                fontSize: AppConstants.fontSizeMedium,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(Icons.emoji_events, color: Colors.white, size: 24),
        ),
      ],
    );
  }

  Widget _buildStatsGrid() {
    final stats = [
      {
        'label': 'XP',
        'value': widget.user.xp?.toString() ?? '0',
        'icon': Icons.trending_up,
        'color': const Color(0xFF9C27B0),
      },
      {
        'label': 'Moedas',
        'value': widget.user.coins?.toString() ?? '0',
        'icon': Icons.monetization_on,
        'color': const Color(0xFFFFD700),
      },
      {
        'label': 'Gemas',
        'value': widget.user.gems?.toString() ?? '0',
        'icon': Icons.diamond,
        'color': const Color(0xFF2196F3),
      },
      {
        'label': 'Nível',
        'value': widget.user.level?.toString() ?? '1',
        'icon': Icons.star,
        'color': const Color(0xFFFF9800),
      },
    ];

    return Row(
      children: stats.asMap().entries.map((entry) {
        final index = entry.key;
        final stat = entry.value;

        return Expanded(
          child: AnimatedBuilder(
            animation: _itemAnimations[index],
            builder: (context, child) {
              return Transform.scale(
                scale: _itemAnimations[index].value,
                child: _buildStatItem(
                  stat['label'] as String,
                  stat['value'] as String,
                  stat['icon'] as IconData,
                  stat['color'] as Color,
                ),
              );
            },
          ),
        );
      }).toList(),
    );
  }

  Widget _buildStatItem(
    String label,
    String value,
    IconData icon,
    Color accentColor,
  ) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: accentColor.withOpacity(0.3), width: 1),
          ),
          child: ShaderMask(
            shaderCallback: (bounds) => LinearGradient(
              colors: [Colors.white, accentColor.withOpacity(0.8)],
            ).createShader(bounds),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
        ),

        const SizedBox(height: 8),

        // Animação de counter para os números
        TweenAnimationBuilder<double>(
          duration: Duration(milliseconds: 800 + (label.hashCode % 400)),
          tween: Tween<double>(begin: 0, end: double.tryParse(value) ?? 0),
          builder: (context, animatedValue, child) {
            return Text(
              animatedValue.toInt().toString(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            );
          },
        ),

        const SizedBox(height: 2),

        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.9),
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
