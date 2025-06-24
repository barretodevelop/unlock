// lib/features/home/widgets/floating_action_menu.dart
import 'package:flutter/material.dart';
import 'package:unlock/core/constants/app_constants.dart';
import 'package:unlock/core/utils/logger.dart';
import 'package:unlock/shared/widgets/animated_fab.dart';

/// FAB central expansível com menu de ações rápidas
class FloatingActionMenu extends StatefulWidget {
  final AnimationController controller;
  final VoidCallback? onCreateGroup;
  final VoidCallback? onCreateChallenge;
  final VoidCallback? onInviteFriends;

  const FloatingActionMenu({
    super.key,
    required this.controller,
    this.onCreateGroup,
    this.onCreateChallenge,
    this.onInviteFriends,
  });

  @override
  State<FloatingActionMenu> createState() => _FloatingActionMenuState();
}

class _FloatingActionMenuState extends State<FloatingActionMenu>
    with SingleTickerProviderStateMixin {
  bool _isExpanded = false;
  late Animation<double> _expandAnimation;
  late Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();

    // Animações do menu
    _expandAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: widget.controller, curve: Curves.elasticOut),
    );

    _rotationAnimation =
        Tween<double>(
          begin: 0.0,
          end: 0.125, // 45 graus (1/8 de volta)
        ).animate(
          CurvedAnimation(parent: widget.controller, curve: Curves.easeInOut),
        );
  }

  /// Toggle do menu
  void _toggleMenu() {
    setState(() {
      _isExpanded = !_isExpanded;
    });

    if (_isExpanded) {
      widget.controller.forward();
    } else {
      widget.controller.reverse();
    }

    AppLogger.debug('🎯 FAB Menu ${_isExpanded ? 'expandido' : 'recolhido'}');
  }

  /// Executar ação e fechar menu
  void _executeAction(VoidCallback? action, String actionName) {
    AppLogger.info('🎯 FAB Action: $actionName');

    // Fechar menu
    if (_isExpanded) {
      _toggleMenu();
    }

    // Executar ação após animação
    Future.delayed(const Duration(milliseconds: 150), () {
      action?.call();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.bottomCenter,
      clipBehavior: Clip.none,
      children: [
        // Overlay para fechar menu
        if (_isExpanded)
          Positioned.fill(
            child: GestureDetector(
              onTap: _toggleMenu,
              child: AnimatedBuilder(
                animation: _expandAnimation,
                builder: (context, child) {
                  return Container(
                    color: Colors.black.withOpacity(
                      0.3 * _expandAnimation.value,
                    ),
                  );
                },
              ),
            ),
          ),

        // Menu items
        ..._buildMenuItems(),

        // FAB principal
        AnimatedFAB(
          onPressed: _toggleMenu,
          rotationAnimation: _rotationAnimation,
          isExpanded: _isExpanded,
        ),
      ],
    );
  }

  /// Construir itens do menu
  List<Widget> _buildMenuItems() {
    final items = [
      _FABMenuItem(
        index: 0,
        icon: Icons.group_add,
        label: 'Criar Grupo',
        color: Colors.blue,
        onTap: () => _executeAction(widget.onCreateGroup, 'create_group'),
      ),
      _FABMenuItem(
        index: 1,
        icon: Icons.add_task,
        label: 'Novo Desafio',
        color: Colors.orange,
        onTap: () =>
            _executeAction(widget.onCreateChallenge, 'create_challenge'),
      ),
      _FABMenuItem(
        index: 2,
        icon: Icons.share,
        label: 'Convidar Amigos',
        color: Colors.green,
        onTap: () => _executeAction(widget.onInviteFriends, 'invite_friends'),
      ),
    ];

    return items.map((item) {
      return _buildAnimatedMenuItem(item);
    }).toList();
  }

  /// Construir item animado do menu
  Widget _buildAnimatedMenuItem(_FABMenuItem item) {
    // Escalonamento da animação para cada item
    final itemAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: widget.controller,
        curve: Interval(
          item.index * 0.1,
          0.6 + (item.index * 0.1),
          curve: Curves.elasticOut,
        ),
      ),
    );

    // Animação de slide
    final slideAnimation =
        Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero).animate(
          CurvedAnimation(
            parent: widget.controller,
            curve: Interval(
              item.index * 0.1,
              0.6 + (item.index * 0.1),
              curve: Curves.easeOut,
            ),
          ),
        );

    return Positioned(
      bottom: 80 + (item.index * 60), // Espaçamento vertical
      child: AnimatedBuilder(
        animation: itemAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: itemAnimation.value,
            child: SlideTransition(
              position: slideAnimation,
              child: _buildMenuItem(item),
            ),
          );
        },
      ),
    );
  }

  /// Construir item individual do menu
  Widget _buildMenuItem(_FABMenuItem item) {
    return GestureDetector(
      onTap: item.onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Label
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Theme.of(context).shadowColor.withOpacity(0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Text(
              item.label,
              style: Theme.of(
                context,
              ).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),

          const SizedBox(width: 12),

          // Botão circular
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: item.color,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: item.color.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(item.icon, color: Colors.white, size: 24),
          ),
        ],
      ),
    );
  }
}

/// Item do menu FAB
class _FABMenuItem {
  final int index;
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _FABMenuItem({
    required this.index,
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });
}

/// FAB Menu simplificado (versão compacta)
class SimpleFABMenu extends StatefulWidget {
  final List<FABAction> actions;

  const SimpleFABMenu({super.key, required this.actions});

  @override
  State<SimpleFABMenu> createState() => _SimpleFABMenuState();
}

class _SimpleFABMenuState extends State<SimpleFABMenu>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() {
      _isExpanded = !_isExpanded;
    });

    if (_isExpanded) {
      _controller.forward();
    } else {
      _controller.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Ações
        ...widget.actions
            .asMap()
            .entries
            .map((entry) {
              final index = entry.key;
              final action = entry.value;

              return AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  final slideAnimation =
                      Tween<Offset>(
                        begin: const Offset(0, 1),
                        end: Offset.zero,
                      ).animate(
                        CurvedAnimation(
                          parent: _controller,
                          curve: Interval(
                            index * 0.1,
                            1.0,
                            curve: Curves.easeOut,
                          ),
                        ),
                      );

                  return SlideTransition(
                    position: slideAnimation,
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: FloatingActionButton.small(
                        onPressed: () {
                          _toggle();
                          action.onPressed();
                        },
                        backgroundColor: action.color,
                        child: Icon(action.icon, color: Colors.white),
                      ),
                    ),
                  );
                },
              );
            })
            .toList()
            .reversed
            .toList(),

        // FAB principal
        FloatingActionButton(
          onPressed: _toggle,
          child: AnimatedRotation(
            turns: _isExpanded ? 0.125 : 0,
            duration: AppConstants.animationDuration,
            child: const Icon(Icons.add),
          ),
        ),
      ],
    );
  }
}

/// Ação do FAB
class FABAction {
  final IconData icon;
  final Color color;
  final VoidCallback onPressed;

  const FABAction({
    required this.icon,
    required this.color,
    required this.onPressed,
  });
}
