// lib/features/home/widgets/custom_bottom_nav.dart
import 'package:flutter/material.dart';
import 'package:unlock/core/constants/app_constants.dart';

/// Bottom Navigation customizada otimizada - SEM OVERFLOW
class CustomBottomNav extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const CustomBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 350;

        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            boxShadow: [
              BoxShadow(
                color: Theme.of(context).shadowColor.withOpacity(0.08),
                blurRadius: 6,
                offset: const Offset(0, -1),
              ),
            ],
          ),
          child: SafeArea(
            child: Container(
              constraints: BoxConstraints(
                minHeight: isCompact ? 60 : 65,
                maxHeight: isCompact ? 65 : 75,
              ),
              padding: EdgeInsets.symmetric(
                horizontal: isCompact ? 8 : 16,
                vertical: isCompact ? 6 : 8,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  // Home
                  _buildOptimizedNavItem(
                    context: context,
                    index: 0,
                    icon: Icons.home_outlined,
                    activeIcon: Icons.home,
                    label: 'Home',
                    isCompact: isCompact,
                  ),

                  // Grupos
                  _buildOptimizedNavItem(
                    context: context,
                    index: 1,
                    icon: Icons.groups_outlined,
                    activeIcon: Icons.groups,
                    label: isCompact ? 'Grupos' : 'Grupos',
                    isCompact: isCompact,
                  ),

                  // Espaço central para FAB - RESPONSIVO
                  SizedBox(width: isCompact ? 40 : 60),

                  // Rankings
                  _buildOptimizedNavItem(
                    context: context,
                    index: 3,
                    icon: Icons.leaderboard_outlined,
                    activeIcon: Icons.leaderboard,
                    label: isCompact ? 'Rank' : 'Rankings',
                    isCompact: isCompact,
                  ),

                  // Perfil
                  _buildOptimizedNavItem(
                    context: context,
                    index: 4,
                    icon: Icons.person_outline,
                    activeIcon: Icons.person,
                    label: 'Perfil',
                    isCompact: isCompact,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  /// Item de navegação otimizado sem overflow
  Widget _buildOptimizedNavItem({
    required BuildContext context,
    required int index,
    required IconData icon,
    required IconData activeIcon,
    required String label,
    required bool isCompact,
  }) {
    final isActive = currentIndex == index;
    final colorScheme = Theme.of(context).colorScheme;

    return Flexible(
      child: Container(
        constraints: BoxConstraints(
          minWidth: isCompact ? 35 : 45,
          maxWidth: isCompact ? 70 : 90,
        ),
        child: GestureDetector(
          onTap: () => onTap(index),
          behavior: HitTestBehavior.opaque,
          child: AnimatedContainer(
            duration: AppConstants.animationDuration,
            curve: Curves.easeInOut,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Ícone com animação controlada
                AnimatedContainer(
                  duration: AppConstants.animationDuration,
                  padding: EdgeInsets.all(isCompact ? 6 : 8),
                  constraints: BoxConstraints(
                    minWidth: isCompact ? 28 : 32,
                    maxWidth: isCompact ? 35 : 40,
                    minHeight: isCompact ? 28 : 32,
                    maxHeight: isCompact ? 35 : 40,
                  ),
                  decoration: BoxDecoration(
                    color: isActive
                        ? colorScheme.primary.withOpacity(0.1)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    isActive ? activeIcon : icon,
                    color: isActive
                        ? colorScheme.primary
                        : colorScheme.onSurface.withOpacity(0.6),
                    size: isCompact ? 18 : 22,
                  ),
                ),

                SizedBox(height: isCompact ? 2 : 4),

                // Label com proteção contra overflow
                AnimatedDefaultTextStyle(
                  duration: AppConstants.animationDuration,
                  style: Theme.of(context).textTheme.labelSmall!.copyWith(
                    color: isActive
                        ? colorScheme.primary
                        : colorScheme.onSurface.withOpacity(0.6),
                    fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                    fontSize: isCompact ? 10 : 11,
                  ),
                  child: Text(
                    label,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Bottom Navigation com badges otimizada
class CustomBottomNavWithBadges extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;
  final Map<int, int>? badges; // index -> count

  const CustomBottomNavWithBadges({
    super.key,
    required this.currentIndex,
    required this.onTap,
    this.badges,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 350;
        final isVerySmall = constraints.maxWidth < 300;

        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            border: Border(
              top: BorderSide(
                color: Theme.of(context).colorScheme.outline.withOpacity(0.15),
                width: 0.5,
              ),
            ),
          ),
          child: SafeArea(
            child: Container(
              constraints: BoxConstraints(
                minHeight: isVerySmall ? 55 : (isCompact ? 60 : 65),
                maxHeight: isVerySmall ? 60 : (isCompact ? 65 : 75),
              ),
              padding: EdgeInsets.symmetric(
                horizontal: isCompact ? 4 : 16,
                vertical: isCompact ? 4 : 8,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  // Home
                  _buildNavItemWithBadge(
                    context: context,
                    index: 0,
                    icon: Icons.home_outlined,
                    activeIcon: Icons.home,
                    label: 'Home',
                    isCompact: isCompact,
                    isVerySmall: isVerySmall,
                  ),

                  // Grupos
                  _buildNavItemWithBadge(
                    context: context,
                    index: 1,
                    icon: Icons.groups_outlined,
                    activeIcon: Icons.groups,
                    label: isVerySmall
                        ? 'Grup'
                        : (isCompact ? 'Grupo' : 'Grupos'),
                    isCompact: isCompact,
                    isVerySmall: isVerySmall,
                  ),

                  // Espaço central para FAB
                  SizedBox(width: isVerySmall ? 25 : (isCompact ? 35 : 60)),

                  // Rankings
                  _buildNavItemWithBadge(
                    context: context,
                    index: 3,
                    icon: Icons.leaderboard_outlined,
                    activeIcon: Icons.leaderboard,
                    label: isVerySmall
                        ? 'Rank'
                        : (isCompact ? 'Rank' : 'Rankings'),
                    isCompact: isCompact,
                    isVerySmall: isVerySmall,
                  ),

                  // Perfil
                  _buildNavItemWithBadge(
                    context: context,
                    index: 4,
                    icon: Icons.person_outline,
                    activeIcon: Icons.person,
                    label: 'Perfil',
                    isCompact: isCompact,
                    isVerySmall: isVerySmall,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  /// Item com badge anti-overflow
  Widget _buildNavItemWithBadge({
    required BuildContext context,
    required int index,
    required IconData icon,
    required IconData activeIcon,
    required String label,
    required bool isCompact,
    required bool isVerySmall,
  }) {
    final isActive = currentIndex == index;
    final colorScheme = Theme.of(context).colorScheme;
    final badgeCount = badges?[index];

    return Flexible(
      child: Container(
        constraints: BoxConstraints(
          minWidth: isVerySmall ? 25 : (isCompact ? 35 : 45),
          maxWidth: isVerySmall ? 55 : (isCompact ? 70 : 90),
        ),
        child: GestureDetector(
          onTap: () => onTap(index),
          behavior: HitTestBehavior.opaque,
          child: AnimatedContainer(
            duration: AppConstants.animationDuration,
            curve: Curves.easeInOut,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Ícone com badge controlado
                SizedBox(
                  width: isVerySmall ? 30 : (isCompact ? 35 : 40),
                  height: isVerySmall ? 30 : (isCompact ? 35 : 40),
                  child: Stack(
                    clipBehavior: Clip.hardEdge,
                    children: [
                      AnimatedContainer(
                        duration: AppConstants.animationDuration,
                        width: double.infinity,
                        height: double.infinity,
                        decoration: BoxDecoration(
                          color: isActive
                              ? colorScheme.primary.withOpacity(0.1)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          isActive ? activeIcon : icon,
                          color: isActive
                              ? colorScheme.primary
                              : colorScheme.onSurface.withOpacity(0.6),
                          size: isVerySmall ? 16 : (isCompact ? 18 : 20),
                        ),
                      ),

                      // Badge otimizado
                      if (badgeCount != null && badgeCount > 0)
                        Positioned(
                          right: 0,
                          top: 0,
                          child: _buildOptimizedBadge(
                            context,
                            badgeCount,
                            isVerySmall,
                            colorScheme,
                          ),
                        ),
                    ],
                  ),
                ),

                SizedBox(height: isVerySmall ? 1 : (isCompact ? 2 : 4)),

                // Label protegido
                AnimatedDefaultTextStyle(
                  duration: AppConstants.animationDuration,
                  style: Theme.of(context).textTheme.labelSmall!.copyWith(
                    color: isActive
                        ? colorScheme.primary
                        : colorScheme.onSurface.withOpacity(0.6),
                    fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                    fontSize: isVerySmall ? 9 : (isCompact ? 10 : 11),
                  ),
                  child: Text(
                    label,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Badge otimizado que nunca causa overflow
  Widget _buildOptimizedBadge(
    BuildContext context,
    int badgeCount,
    bool isVerySmall,
    ColorScheme colorScheme,
  ) {
    final badgeSize = isVerySmall ? 12.0 : 16.0;
    final fontSize = isVerySmall ? 7.0 : 9.0;

    return Container(
      constraints: BoxConstraints(
        minWidth: badgeSize,
        maxWidth: badgeSize + 8,
        minHeight: badgeSize,
        maxHeight: badgeSize,
      ),
      decoration: BoxDecoration(
        color: colorScheme.error,
        borderRadius: BorderRadius.circular(badgeSize / 2),
        border: Border.all(
          color: Theme.of(context).colorScheme.surface,
          width: 1,
        ),
      ),
      child: Center(
        child: Text(
          badgeCount > 99 ? '99+' : badgeCount.toString(),
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: fontSize,
            height: 1.0,
          ),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.clip,
        ),
      ),
    );
  }
}

/// Bottom Navigation compacta otimizada
class OptimizedCompactBottomNav extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const OptimizedCompactBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isVeryCompact = constraints.maxWidth < 300;

        return BottomAppBar(
          height: isVeryCompact ? 50 : 60,
          shape: const CircularNotchedRectangle(),
          notchMargin: isVeryCompact ? 4 : 8,
          color: Theme.of(context).colorScheme.surface,
          padding: EdgeInsets.symmetric(horizontal: isVeryCompact ? 4 : 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildCompactNavItem(
                context: context,
                index: 0,
                icon: Icons.home,
                isVeryCompact: isVeryCompact,
                onTap: () => onTap(0),
              ),
              _buildCompactNavItem(
                context: context,
                index: 1,
                icon: Icons.groups,
                isVeryCompact: isVeryCompact,
                onTap: () => onTap(1),
              ),
              SizedBox(width: isVeryCompact ? 30 : 40), // Espaço para FAB
              _buildCompactNavItem(
                context: context,
                index: 3,
                icon: Icons.leaderboard,
                isVeryCompact: isVeryCompact,
                onTap: () => onTap(3),
              ),
              _buildCompactNavItem(
                context: context,
                index: 4,
                icon: Icons.person,
                isVeryCompact: isVeryCompact,
                onTap: () => onTap(4),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCompactNavItem({
    required BuildContext context,
    required int index,
    required IconData icon,
    required bool isVeryCompact,
    required VoidCallback onTap,
  }) {
    final isActive = currentIndex == index;
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      constraints: BoxConstraints(
        minWidth: isVeryCompact ? 30 : 40,
        maxWidth: isVeryCompact ? 40 : 50,
        minHeight: isVeryCompact ? 30 : 40,
        maxHeight: isVeryCompact ? 40 : 50,
      ),
      child: IconButton(
        onPressed: onTap,
        iconSize: isVeryCompact ? 18 : 22,
        padding: EdgeInsets.all(isVeryCompact ? 4 : 8),
        constraints: BoxConstraints(
          minWidth: isVeryCompact ? 30 : 40,
          minHeight: isVeryCompact ? 30 : 40,
        ),
        icon: Icon(
          icon,
          color: isActive
              ? colorScheme.primary
              : colorScheme.onSurface.withOpacity(0.6),
        ),
      ),
    );
  }
}

/// Wrapper que escolhe automaticamente a melhor navegação
class AdaptiveCustomBottomNav extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;
  final Map<int, int>? badges;
  final bool useCompact;

  const AdaptiveCustomBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
    this.badges,
    this.useCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Auto-seleciona o tipo baseado na largura disponível
        if (constraints.maxWidth < 280) {
          return OptimizedCompactBottomNav(
            currentIndex: currentIndex,
            onTap: onTap,
          );
        } else if (badges != null) {
          return CustomBottomNavWithBadges(
            currentIndex: currentIndex,
            onTap: onTap,
            badges: badges,
          );
        } else {
          return CustomBottomNav(currentIndex: currentIndex, onTap: onTap);
        }
      },
    );
  }
}
