// lib/features/home/widgets/quick_actions_grid.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:unlock/core/constants/app_constants.dart';
import 'package:unlock/core/router/app_router.dart';

/// Grid de ações rápidas com animações e feedback visual melhorado
class QuickActionsGrid extends StatefulWidget {
  const QuickActionsGrid({super.key});

  @override
  State<QuickActionsGrid> createState() => _QuickActionsGridState();
}

class _QuickActionsGridState extends State<QuickActionsGrid>
    with TickerProviderStateMixin {
  late List<AnimationController> _controllers;
  late List<Animation<double>> _scaleAnimations;
  late List<Animation<double>> _fadeAnimations;

  static const List<Map<String, dynamic>> _actions = [
    {
      'id': 'profile',
      'title': 'Perfil',
      'subtitle': 'Seu perfil público',
      'icon': Icons.person_outline,
      'route': AppRoutes.profile,
      'color': Color(0xFF6366F1),
      'gradient': [Color(0xFF6366F1), Color(0xFF8B5CF6)],
    },
    {
      'id': 'connections',
      'title': 'Conexões',
      'subtitle': 'Encontrar pessoas',
      'icon': Icons.people_outline,
      'route': AppRoutes.connections,
      'color': Color(0xFF10B981),
      'gradient': [Color(0xFF10B981), Color(0xFF34D399)],
    },
    {
      'id': 'games',
      'title': 'Jogos',
      'subtitle': 'Minijogos divertidos',
      'icon': Icons.games_outlined,
      'route': AppRoutes.games,
      'color': Color(0xFFFF6B6B),
      'gradient': [Color(0xFFFF6B6B), Color(0xFFFF8E8E)],
    },
    {
      'id': 'missions',
      'title': 'Missões',
      'subtitle': 'Todas as missões',
      'icon': Icons.flag_outlined,
      'route': AppRoutes.missions,
      'color': Color(0xFFF59E0B),
      'gradient': [Color(0xFFF59E0B), Color(0xFFFBBF24)],
    },
  ];

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _startAnimations();
  }

  void _setupAnimations() {
    _controllers = List.generate(
      _actions.length,
      (index) => AnimationController(
        duration: Duration(milliseconds: 300 + (index * 100)),
        vsync: this,
      ),
    );

    _scaleAnimations = _controllers.map((controller) {
      return Tween<double>(
        begin: 0.0,
        end: 1.0,
      ).animate(CurvedAnimation(parent: controller, curve: Curves.elasticOut));
    }).toList();

    _fadeAnimations = _controllers.map((controller) {
      return Tween<double>(
        begin: 0.0,
        end: 1.0,
      ).animate(CurvedAnimation(parent: controller, curve: Curves.easeOut));
    }).toList();
  }

  void _startAnimations() {
    for (int i = 0; i < _controllers.length; i++) {
      Future.delayed(Duration(milliseconds: i * 150), () {
        if (mounted) {
          _controllers[i].forward();
        }
      });
    }
  }

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: AppConstants.paddingMedium,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Ações Rápidas',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppConstants.spacingLarge),
          _buildActionsGrid(theme),
        ],
      ),
    );
  }

  Widget _buildActionsGrid(ThemeData theme) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.4,
        crossAxisSpacing: AppConstants.spacingLarge,
        mainAxisSpacing: AppConstants.spacingLarge,
      ),
      itemCount: _actions.length,
      itemBuilder: (context, index) {
        final action = _actions[index];

        return AnimatedBuilder(
          animation: Listenable.merge([
            _scaleAnimations[index],
            _fadeAnimations[index],
          ]),
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnimations[index].value,
              child: Opacity(
                opacity: _fadeAnimations[index].value,
                child: _QuickActionCard(
                  action: action,
                  onTap: () => _handleActionTap(context, action),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _handleActionTap(BuildContext context, Map<String, dynamic> action) {
    HapticFeedback.lightImpact();

    // Navegar para a rota
    final route = action['route'] as String;
    if (route.isNotEmpty) {
      context.go(route);
    }
  }
}

/// Card individual de ação rápida
class _QuickActionCard extends StatefulWidget {
  final Map<String, dynamic> action;
  final VoidCallback onTap;

  const _QuickActionCard({required this.action, required this.onTap});

  @override
  State<_QuickActionCard> createState() => _QuickActionCardState();
}

class _QuickActionCardState extends State<_QuickActionCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _hoverController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _elevationAnimation;

  @override
  void initState() {
    super.initState();

    _hoverController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.05,
    ).animate(CurvedAnimation(parent: _hoverController, curve: Curves.easeOut));

    _elevationAnimation = Tween<double>(
      begin: 4.0,
      end: 12.0,
    ).animate(CurvedAnimation(parent: _hoverController, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _hoverController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final action = widget.action;
    final gradientColors = action['gradient'] as List<Color>;

    return AnimatedBuilder(
      animation: _hoverController,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: GestureDetector(
            onTapDown: (_) => _hoverController.forward(),
            onTapUp: (_) {
              _hoverController.reverse();
              widget.onTap();
            },
            onTapCancel: () => _hoverController.reverse(),
            child: Card(
              elevation: _elevationAnimation.value,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(
                  AppConstants.cardBorderRadius,
                ),
              ),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: gradientColors,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(
                    AppConstants.cardBorderRadius,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: gradientColors.first.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(AppConstants.paddingMedium),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Ícone
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          action['icon'] as IconData,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),

                      const Spacer(),

                      // Título
                      Text(
                        action['title'] as String,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 2),

                      // Subtítulo
                      Text(
                        action['subtitle'] as String,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
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
}
