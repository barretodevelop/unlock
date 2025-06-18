// lib/features/navigation/widgets/custom_bottom_nav.dart
// Bottom navigation bar customizada - Fase 3

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:unlock/core/theme/app_theme.dart';
import 'package:unlock/features/navigation/providers/navigation_provider.dart';

/// Bottom navigation bar personalizada com design moderno
class CustomBottomNav extends ConsumerWidget {
  const CustomBottomNav({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final navigationState = ref.watch(navigationProvider);
    final currentIndex = navigationState.currentIndex;

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Container(
          height: 70, // Reduzido de 80 para 70
          padding: const EdgeInsets.symmetric(
            horizontal: 8,
            vertical: 4,
          ), // Reduzido padding
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: NavigationPage.values.map((page) {
              final isSelected = currentIndex == page.index;
              final isEnabled = navigationState.isPageEnabled(page.index);
              final badge = navigationState.getPageBadge(page.index);

              return Flexible(
                // Adicionado Flexible para evitar overflow
                child: _buildNavItem(
                  context,
                  theme,
                  ref,
                  page,
                  isSelected,
                  isEnabled,
                  badge,
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  /// Construir item de navegação individual
  Widget _buildNavItem(
    BuildContext context,
    ThemeData theme,
    WidgetRef ref,
    NavigationPage page,
    bool isSelected,
    bool isEnabled,
    int? badge,
  ) {
    final color = isSelected
        ? AppTheme.primaryColor
        : (isEnabled
              ? theme.colorScheme.onSurface.withOpacity(0.6)
              : theme.colorScheme.onSurface.withOpacity(0.3));

    return GestureDetector(
      onTap: isEnabled ? () => _onNavItemTap(ref, page.index) : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.primaryColor.withOpacity(0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // Conteúdo principal
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Ícone
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.all(4),
                  child: Icon(
                    page.icon,
                    color: color,
                    size: isSelected ? 26 : 24,
                  ),
                ),

                const SizedBox(height: 4),

                // Label
                AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 200),
                  style: theme.textTheme.labelSmall!.copyWith(
                    color: color,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    fontSize: isSelected ? 12 : 11,
                  ),
                  child: Text(page.label),
                ),
              ],
            ),

            // Badge de notificação
            if (badge != null && badge > 0)
              Positioned(top: -2, right: 8, child: _buildBadge(theme, badge)),

            // Indicador de seleção
            if (isSelected)
              Positioned(
                top: -4,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    width: 4,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// Construir badge de notificação
  Widget _buildBadge(ThemeData theme, int count) {
    return Container(
      constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppTheme.errorColor,
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: theme.colorScheme.surface, width: 2),
        boxShadow: [
          BoxShadow(
            color: AppTheme.errorColor.withOpacity(0.4),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Text(
        count > 99 ? '99+' : count.toString(),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  /// Ação ao tocar em item de navegação
  void _onNavItemTap(WidgetRef ref, int index) {
    // Feedback haptic
    // HapticFeedback.lightImpact();

    // Atualizar navegação
    ref.read(navigationProvider.notifier).navigateToPage(index);
  }
}

/// Bottom navigation bar com design materializado (alternativa)
class MaterialBottomNav extends ConsumerWidget {
  const MaterialBottomNav({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final navigationState = ref.watch(navigationProvider);
    final currentIndex = navigationState.currentIndex;

    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: (index) =>
          ref.read(navigationProvider.notifier).navigateToPage(index),
      type: BottomNavigationBarType.fixed,
      selectedItemColor: AppTheme.primaryColor,
      unselectedItemColor: Theme.of(
        context,
      ).colorScheme.onSurface.withOpacity(0.6),
      selectedFontSize: 12,
      unselectedFontSize: 11,
      items: NavigationPage.values.map((page) {
        final badge = navigationState.getPageBadge(page.index);

        return BottomNavigationBarItem(
          icon: Stack(
            clipBehavior: Clip.none,
            children: [
              Icon(page.icon),
              if (badge != null && badge > 0)
                Positioned(
                  top: -8,
                  right: -8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: AppTheme.errorColor,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      badge > 9 ? '9+' : badge.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 8,
                        fontWeight: FontWeight.w700,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
          label: page.label,
        );
      }).toList(),
    );
  }
}

/// Bottom navigation bar com design de tabs (alternativa)
class TabBottomNav extends ConsumerWidget {
  const TabBottomNav({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final navigationState = ref.watch(navigationProvider);
    final currentIndex = navigationState.currentIndex;

    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(25),
        child: BottomNavigationBar(
          currentIndex: currentIndex,
          onTap: (index) =>
              ref.read(navigationProvider.notifier).navigateToPage(index),
          type: BottomNavigationBarType.fixed,
          selectedItemColor: AppTheme.primaryColor,
          unselectedItemColor: theme.colorScheme.onSurface.withOpacity(0.6),
          backgroundColor: theme.colorScheme.surface,
          elevation: 0,
          selectedFontSize: 12,
          unselectedFontSize: 11,
          items: NavigationPage.values.map((page) {
            final badge = navigationState.getPageBadge(page.index);

            return BottomNavigationBarItem(
              icon: Stack(
                clipBehavior: Clip.none,
                children: [
                  Icon(page.icon),
                  if (badge != null && badge > 0)
                    Positioned(
                      top: -6,
                      right: -6,
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: AppTheme.errorColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                ],
              ),
              label: page.label,
            );
          }).toList(),
        ),
      ),
    );
  }
}

/// Bottom navigation bar adaptativa que escolhe o estilo baseado na plataforma
class AdaptiveBottomNav extends ConsumerWidget {
  const AdaptiveBottomNav({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Por ora, usar sempre o design customizado
    // No futuro, pode verificar Theme.of(context).platform para adaptar
    return const CustomBottomNav();
  }
}

/// Widget para preview do bottom navigation (útil para desenvolvimento)
class BottomNavPreview extends ConsumerWidget {
  final Widget Function(Widget bottomNav) builder;

  const BottomNavPreview({super.key, required this.builder});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Custom Bottom Nav',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 8),
        builder(const CustomBottomNav()),

        const SizedBox(height: 16),

        Text(
          'Material Bottom Nav',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 8),
        builder(const MaterialBottomNav()),

        const SizedBox(height: 16),

        Text('Tab Bottom Nav', style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 8),
        builder(const TabBottomNav()),
      ],
    );
  }
}
