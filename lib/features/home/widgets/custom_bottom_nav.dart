// lib/features/home/widgets/custom_bottom_nav.dart
import 'package:flutter/material.dart';
import 'package:unlock/core/constants/app_constants.dart';

/// Bottom Navigation customizada com 5 tabs e espaço central para FAB
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
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).shadowColor.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Container(
          height: 70,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              // Home
              _buildNavItem(
                context: context,
                index: 0,
                icon: Icons.home_outlined,
                activeIcon: Icons.home,
                label: 'Home',
              ),

              // Grupos
              _buildNavItem(
                context: context,
                index: 1,
                icon: Icons.groups_outlined,
                activeIcon: Icons.groups,
                label: 'Grupos',
              ),

              // Espaço central para FAB
              const SizedBox(width: 60),

              // Rankings
              _buildNavItem(
                context: context,
                index: 3,
                icon: Icons.leaderboard_outlined,
                activeIcon: Icons.leaderboard,
                label: 'Rankings',
              ),

              // Perfil
              _buildNavItem(
                context: context,
                index: 4,
                icon: Icons.person_outline,
                activeIcon: Icons.person,
                label: 'Perfil',
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Construir item de navegação
  Widget _buildNavItem({
    required BuildContext context,
    required int index,
    required IconData icon,
    required IconData activeIcon,
    required String label,
  }) {
    final isActive = currentIndex == index;
    final colorScheme = Theme.of(context).colorScheme;

    return Expanded(
      child: GestureDetector(
        onTap: () => onTap(index),
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: AppConstants.animationDuration,
          curve: Curves.easeInOut,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Ícone com animação
              AnimatedContainer(
                duration: AppConstants.animationDuration,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isActive
                      ? colorScheme.primary.withOpacity(0.1)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  isActive ? activeIcon : icon,
                  color: isActive
                      ? colorScheme.primary
                      : colorScheme.onSurface.withOpacity(0.6),
                  size: 24,
                ),
              ),

              const SizedBox(height: 4),

              // Label com animação
              AnimatedDefaultTextStyle(
                duration: AppConstants.animationDuration,
                style: Theme.of(context).textTheme.labelSmall!.copyWith(
                  color: isActive
                      ? colorScheme.primary
                      : colorScheme.onSurface.withOpacity(0.6),
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                ),
                child: Text(label),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Bottom Navigation alternativa com badges
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
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
            width: 0.5,
          ),
        ),
      ),
      child: SafeArea(
        child: Container(
          height: 70,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
              ),

              // Grupos
              _buildNavItemWithBadge(
                context: context,
                index: 1,
                icon: Icons.groups_outlined,
                activeIcon: Icons.groups,
                label: 'Grupos',
              ),

              // Espaço central para FAB
              const SizedBox(width: 60),

              // Rankings
              _buildNavItemWithBadge(
                context: context,
                index: 3,
                icon: Icons.leaderboard_outlined,
                activeIcon: Icons.leaderboard,
                label: 'Rankings',
              ),

              // Perfil
              _buildNavItemWithBadge(
                context: context,
                index: 4,
                icon: Icons.person_outline,
                activeIcon: Icons.person,
                label: 'Perfil',
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Construir item com badge
  Widget _buildNavItemWithBadge({
    required BuildContext context,
    required int index,
    required IconData icon,
    required IconData activeIcon,
    required String label,
  }) {
    final isActive = currentIndex == index;
    final colorScheme = Theme.of(context).colorScheme;
    final badgeCount = badges?[index];

    return Expanded(
      child: GestureDetector(
        onTap: () => onTap(index),
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: AppConstants.animationDuration,
          curve: Curves.easeInOut,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Ícone com badge
              Stack(
                clipBehavior: Clip.none,
                children: [
                  AnimatedContainer(
                    duration: AppConstants.animationDuration,
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isActive
                          ? colorScheme.primary.withOpacity(0.1)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      isActive ? activeIcon : icon,
                      color: isActive
                          ? colorScheme.primary
                          : colorScheme.onSurface.withOpacity(0.6),
                      size: 24,
                    ),
                  ),

                  // Badge
                  if (badgeCount != null && badgeCount > 0)
                    Positioned(
                      right: 0,
                      top: 0,
                      child: AnimatedContainer(
                        duration: AppConstants.animationDuration,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: colorScheme.error,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 18,
                          minHeight: 18,
                        ),
                        child: Text(
                          badgeCount > 99 ? '99+' : badgeCount.toString(),
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 10,
                              ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              ),

              const SizedBox(height: 4),

              // Label
              AnimatedDefaultTextStyle(
                duration: AppConstants.animationDuration,
                style: Theme.of(context).textTheme.labelSmall!.copyWith(
                  color: isActive
                      ? colorScheme.primary
                      : colorScheme.onSurface.withOpacity(0.6),
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                ),
                child: Text(label),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Bottom Navigation compacta
class CompactBottomNav extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const CompactBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return BottomAppBar(
      height: 60,
      shape: const CircularNotchedRectangle(),
      notchMargin: 8,
      color: Theme.of(context).colorScheme.surface,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildCompactNavItem(
            context: context,
            index: 0,
            icon: Icons.home,
            onTap: () => onTap(0),
          ),
          _buildCompactNavItem(
            context: context,
            index: 1,
            icon: Icons.groups,
            onTap: () => onTap(1),
          ),
          const SizedBox(width: 40), // Espaço para FAB
          _buildCompactNavItem(
            context: context,
            index: 3,
            icon: Icons.leaderboard,
            onTap: () => onTap(3),
          ),
          _buildCompactNavItem(
            context: context,
            index: 4,
            icon: Icons.person,
            onTap: () => onTap(4),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactNavItem({
    required BuildContext context,
    required int index,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    final isActive = currentIndex == index;
    final colorScheme = Theme.of(context).colorScheme;

    return IconButton(
      onPressed: onTap,
      icon: Icon(
        icon,
        color: isActive
            ? colorScheme.primary
            : colorScheme.onSurface.withOpacity(0.6),
      ),
    );
  }
}
