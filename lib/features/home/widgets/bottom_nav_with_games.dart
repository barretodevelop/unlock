// lib/features/home/widgets/bottom_nav_with_games.dart
// ✅ BOTTOM NAVIGATION OTIMIZADA - SEM OVERFLOW

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Bottom Navigation Bar otimizada sem overflow
class BottomNavWithGames extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const BottomNavWithGames({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Determina se deve usar layout compacto baseado na largura
        final isCompact = constraints.maxWidth < 400;

        return NavigationBar(
          selectedIndex: currentIndex,
          onDestinationSelected: onTap,
          elevation: 4,
          backgroundColor: Theme.of(context).colorScheme.surface,
          labelBehavior: isCompact
              ? NavigationDestinationLabelBehavior.onlyShowSelected
              : NavigationDestinationLabelBehavior.alwaysShow,
          destinations: [
            // Home
            NavigationDestination(
              icon: const Icon(Icons.home_outlined, size: 22),
              selectedIcon: const Icon(Icons.home, size: 22),
              label: isCompact ? 'Home' : 'Home',
            ),

            // Desafios
            NavigationDestination(
              icon: const Icon(Icons.emoji_events_outlined, size: 22),
              selectedIcon: const Icon(Icons.emoji_events, size: 22),
              label: isCompact ? 'Desafios' : 'Desafios',
            ),

            // ✅ MINI-GAMES OTIMIZADO
            NavigationDestination(
              icon: _buildGamesIcon(context, false, isCompact),
              selectedIcon: _buildGamesIcon(context, true, isCompact),
              label: 'Games',
            ),

            // Rankings
            NavigationDestination(
              icon: const Icon(Icons.leaderboard_outlined, size: 22),
              selectedIcon: const Icon(Icons.leaderboard, size: 22),
              label: isCompact ? 'Rank' : 'Rankings',
            ),

            // Perfil
            NavigationDestination(
              icon: const Icon(Icons.person_outline, size: 22),
              selectedIcon: const Icon(Icons.person, size: 22),
              label: 'Perfil',
            ),
          ],
        );
      },
    );
  }

  /// Ícone dos mini-games otimizado
  Widget _buildGamesIcon(
    BuildContext context,
    bool isSelected,
    bool isCompact,
  ) {
    final size = isCompact ? 16.0 : 18.0;
    final iconSize = isCompact ? 16.0 : 18.0;

    return Container(
      width: size + 8,
      height: size + 8,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.purple.shade400, Colors.blue.shade400],
        ),
        borderRadius: BorderRadius.circular(6),
        boxShadow: isSelected
            ? [
                BoxShadow(
                  color: Colors.purple.withOpacity(0.2),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ]
            : null,
      ),
      child: Icon(
        isSelected ? Icons.videogame_asset : Icons.videogame_asset_outlined,
        color: Colors.white,
        size: iconSize,
      ),
    );
  }
}

/// Controller para a navegação bottom otimizado
class BottomNavController {
  /// Navegar baseado no índice
  static void navigateToIndex(BuildContext context, int index) {
    try {
      switch (index) {
        case 0: // Home
          context.go('/home');
          break;
        case 1: // Desafios
          context.go('/challenges');
          break;
        case 2: // ✅ MINI-GAMES
          context.go('/mini-games');
          break;
        case 3: // Rankings
          context.go('/rankings');
          break;
        case 4: // Perfil
          context.go('/profile');
          break;
        default:
          context.go('/home');
      }
    } catch (e) {
      // Fallback para home em caso de erro
      context.go('/home');
    }
  }

  /// Obter índice baseado na rota atual
  static int getIndexFromRoute(String route) {
    if (route.startsWith('/home')) return 0;
    if (route.startsWith('/challenges')) return 1;
    if (route.startsWith('/mini-games')) return 2;
    if (route.startsWith('/rankings')) return 3;
    if (route.startsWith('/profile')) return 4;
    return 0; // Default para home
  }
}

/// Layout principal com bottom navigation otimizada
class MainLayoutWithGames extends StatefulWidget {
  final Widget child;
  final String currentRoute;

  const MainLayoutWithGames({
    super.key,
    required this.child,
    required this.currentRoute,
  });

  @override
  State<MainLayoutWithGames> createState() => _MainLayoutWithGamesState();
}

class _MainLayoutWithGamesState extends State<MainLayoutWithGames> {
  @override
  Widget build(BuildContext context) {
    final currentIndex = BottomNavController.getIndexFromRoute(
      widget.currentRoute,
    );

    return Scaffold(
      body: widget.child,
      bottomNavigationBar: SafeArea(
        child: BottomNavWithGames(
          currentIndex: currentIndex,
          onTap: (index) => BottomNavController.navigateToIndex(context, index),
        ),
      ),
    );
  }
}

/// Bottom Navigation alternativa compacta
class CompactBottomNavWithGames extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const CompactBottomNavWithGames({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Container(
          constraints: BoxConstraints(
            maxHeight: 60,
            maxWidth: constraints.maxWidth,
          ),
          child: BottomNavigationBar(
            currentIndex: currentIndex,
            onTap: onTap,
            type: BottomNavigationBarType.fixed,
            selectedItemColor: Theme.of(context).colorScheme.primary,
            unselectedItemColor: Theme.of(
              context,
            ).colorScheme.onSurface.withOpacity(0.6),
            selectedFontSize: 10,
            unselectedFontSize: 9,
            iconSize: 20,
            items: [
              const BottomNavigationBarItem(
                icon: Icon(Icons.home),
                label: 'Home',
              ),
              BottomNavigationBarItem(
                icon: const Icon(Icons.emoji_events),
                label: constraints.maxWidth < 350 ? 'Desafios' : 'Desafios',
              ),
              // ✅ MINI-GAMES COM INDICADOR OTIMIZADO
              BottomNavigationBarItem(
                icon: _buildCompactGamesIcon(context),
                label: 'Games',
              ),
              BottomNavigationBarItem(
                icon: const Icon(Icons.leaderboard),
                label: constraints.maxWidth < 350 ? 'Rank' : 'Rankings',
              ),
              const BottomNavigationBarItem(
                icon: Icon(Icons.person),
                label: 'Perfil',
              ),
            ],
          ),
        );
      },
    );
  }

  /// Ícone compacto para games
  Widget _buildCompactGamesIcon(BuildContext context) {
    return SizedBox(
      width: 24,
      height: 24,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          const Center(child: Icon(Icons.videogame_asset, size: 20)),
          Positioned(
            right: 0,
            top: 0,
            child: Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: Colors.purple.shade400,
                shape: BoxShape.circle,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Bottom Navigation com badge otimizada
class OptimizedBadgedBottomNav extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;
  final int? gamesBadgeCount;

  const OptimizedBadgedBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
    this.gamesBadgeCount,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isVerySmall = constraints.maxWidth < 320;
        final badgeCount = gamesBadgeCount ?? 0;

        return Container(
          constraints: const BoxConstraints(maxHeight: 65),
          child: BottomNavigationBar(
            currentIndex: currentIndex,
            onTap: onTap,
            type: BottomNavigationBarType.fixed,
            selectedItemColor: Colors.purple.shade600,
            unselectedItemColor: Theme.of(
              context,
            ).colorScheme.onSurface.withOpacity(0.6),
            selectedFontSize: isVerySmall ? 10 : 12,
            unselectedFontSize: isVerySmall ? 9 : 11,
            iconSize: isVerySmall ? 18 : 22,
            items: [
              const BottomNavigationBarItem(
                icon: Icon(Icons.home),
                label: 'Home',
              ),
              BottomNavigationBarItem(
                icon: const Icon(Icons.emoji_events),
                label: isVerySmall ? 'Desafios' : 'Desafios',
              ),
              // ✅ MINI-GAMES COM BADGE CONTROLADO
              BottomNavigationBarItem(
                icon: _buildOptimizedBadge(context, badgeCount, isVerySmall),
                label: 'Games',
              ),
              BottomNavigationBarItem(
                icon: const Icon(Icons.leaderboard),
                label: isVerySmall ? 'Rank' : 'Rankings',
              ),
              const BottomNavigationBarItem(
                icon: Icon(Icons.person),
                label: 'Perfil',
              ),
            ],
          ),
        );
      },
    );
  }

  /// Badge otimizado que não causa overflow
  Widget _buildOptimizedBadge(BuildContext context, int count, bool isSmall) {
    if (count <= 0) {
      return Icon(Icons.videogame_asset, size: isSmall ? 18 : 22);
    }

    return SizedBox(
      width: isSmall ? 20 : 24,
      height: isSmall ? 20 : 24,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Center(child: Icon(Icons.videogame_asset, size: isSmall ? 18 : 22)),
          Positioned(
            right: -2,
            top: -2,
            child: Container(
              constraints: BoxConstraints(
                minWidth: isSmall ? 12 : 14,
                minHeight: isSmall ? 12 : 14,
                maxWidth: isSmall ? 16 : 20,
              ),
              decoration: BoxDecoration(
                color: Colors.purple.shade600,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Theme.of(context).colorScheme.surface,
                  width: 1,
                ),
              ),
              child: Center(
                child: Text(
                  count > 99 ? '99+' : count.toString(),
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: isSmall ? 8 : 9,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.clip,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Extensão para facilitar o uso
extension BottomNavExtensions on BuildContext {
  /// Navegar para mini-games
  void goToMiniGames() => BottomNavController.navigateToIndex(this, 2);

  /// Obter índice atual da rota
  int getCurrentNavIndex() {
    final route = GoRouterState.of(this).uri.toString();
    return BottomNavController.getIndexFromRoute(route);
  }
}

/// Widget wrapper que adiciona SafeArea automaticamente
class SafeBottomNavWithGames extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;
  final bool useBadge;
  final int? badgeCount;

  const SafeBottomNavWithGames({
    super.key,
    required this.currentIndex,
    required this.onTap,
    this.useBadge = false,
    this.badgeCount,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).shadowColor.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: useBadge
            ? OptimizedBadgedBottomNav(
                currentIndex: currentIndex,
                onTap: onTap,
                gamesBadgeCount: badgeCount,
              )
            : BottomNavWithGames(currentIndex: currentIndex, onTap: onTap),
      ),
    );
  }
}
