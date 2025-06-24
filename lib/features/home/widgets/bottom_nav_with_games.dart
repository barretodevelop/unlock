// lib/features/home/widgets/bottom_nav_with_games.dart
// ✅ BOTTOM NAVIGATION ATUALIZADA COM MINI-GAMES

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Bottom Navigation Bar atualizada incluindo Mini-Games
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
    return NavigationBar(
      selectedIndex: currentIndex,
      onDestinationSelected: onTap,
      elevation: 8,
      backgroundColor: Theme.of(context).colorScheme.surface,
      destinations: [
        // Home
        const NavigationDestination(
          icon: Icon(Icons.home_outlined),
          selectedIcon: Icon(Icons.home),
          label: 'Home',
        ),

        // Desafios
        const NavigationDestination(
          icon: Icon(Icons.emoji_events_outlined),
          selectedIcon: Icon(Icons.emoji_events),
          label: 'Desafios',
        ),

        // ✅ NOVO: Mini-Games
        NavigationDestination(
          icon: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Colors.purple, Colors.blue],
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.videogame_asset_outlined,
              color: Colors.white,
              size: 16,
            ),
          ),
          selectedIcon: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Colors.purple, Colors.blue],
              ),
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.purple.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(
              Icons.videogame_asset,
              color: Colors.white,
              size: 16,
            ),
          ),
          label: 'Games',
        ),

        // Rankings
        const NavigationDestination(
          icon: Icon(Icons.leaderboard_outlined),
          selectedIcon: Icon(Icons.leaderboard),
          label: 'Rankings',
        ),

        // Perfil
        const NavigationDestination(
          icon: Icon(Icons.person_outline),
          selectedIcon: Icon(Icons.person),
          label: 'Perfil',
        ),
      ],
    );
  }
}

/// Controller para a navegação bottom
class BottomNavController {
  /// Navegar baseado no índice
  static void navigateToIndex(BuildContext context, int index) {
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
  }

  /// Obter índice baseado na rota atual
  static int getIndexFromRoute(String route) {
    if (route.startsWith('/home')) return 0;
    if (route.startsWith('/challenges')) return 1;
    if (route.startsWith('/mini-games')) return 2; // ✅ NOVO
    if (route.startsWith('/rankings')) return 3;
    if (route.startsWith('/profile')) return 4;
    return 0; // Default para home
  }
}

/// Layout principal com bottom navigation atualizada
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
      bottomNavigationBar: BottomNavWithGames(
        currentIndex: currentIndex,
        onTap: (index) => BottomNavController.navigateToIndex(context, index),
      ),
    );
  }
}

/// Bottom Navigation alternativa mais simples
class SimpleBottomNavWithGames extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const SimpleBottomNavWithGames({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: onTap,
      type: BottomNavigationBarType.fixed,
      selectedItemColor: Theme.of(context).colorScheme.primary,
      unselectedItemColor: Theme.of(
        context,
      ).colorScheme.onSurface.withOpacity(0.6),
      items: [
        const BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
        const BottomNavigationBarItem(
          icon: Icon(Icons.emoji_events),
          label: 'Desafios',
        ),
        // ✅ MINI-GAMES COM DESTAQUE
        BottomNavigationBarItem(
          icon: Stack(
            children: [
              const Icon(Icons.videogame_asset),
              Positioned(
                right: 0,
                top: 0,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Colors.purple,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ),
          label: 'Games',
        ),
        const BottomNavigationBarItem(
          icon: Icon(Icons.leaderboard),
          label: 'Rankings',
        ),
        const BottomNavigationBarItem(
          icon: Icon(Icons.person),
          label: 'Perfil',
        ),
      ],
    );
  }
}

/// Bottom Navigation com badge para mini-games
class BadgedBottomNavWithGames extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;
  final int? gamesBadgeCount;

  const BadgedBottomNavWithGames({
    super.key,
    required this.currentIndex,
    required this.onTap,
    this.gamesBadgeCount,
  });

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: onTap,
      type: BottomNavigationBarType.fixed,
      selectedItemColor: Colors.purple,
      items: [
        const BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
        const BottomNavigationBarItem(
          icon: Icon(Icons.emoji_events),
          label: 'Desafios',
        ),
        // ✅ MINI-GAMES COM BADGE
        BottomNavigationBarItem(
          icon: Badge(
            label: gamesBadgeCount != null && gamesBadgeCount! > 0
                ? Text(gamesBadgeCount.toString())
                : null,
            isLabelVisible: gamesBadgeCount != null && gamesBadgeCount! > 0,
            backgroundColor: Colors.purple,
            child: const Icon(Icons.videogame_asset),
          ),
          label: 'Games',
        ),
        const BottomNavigationBarItem(
          icon: Icon(Icons.leaderboard),
          label: 'Rankings',
        ),
        const BottomNavigationBarItem(
          icon: Icon(Icons.person),
          label: 'Perfil',
        ),
      ],
    );
  }
}

// /// ✅ EXEMPLO DE USO EM UMA TELA PRINCIPAL
// class MainAppWithGames extends StatefulWidget {
//   const MainAppWithGames({super.key});

//   @override
//   State<MainAppWithGames> createState() => _MainAppWithGamesState();
// }

// class _MainAppWithGamesState extends State<MainAppWithGames> {
//   int _currentIndex = 0;

//   final List<Widget> _screens = [
//     const HomeScreenWithMiniGames(), // ✅ HOME COM MINI-GAMES
//     const ChallengesScreen(),
//     const MiniGamesScreen(), // ✅ TELA PRINCIPAL DE GAMES
//     const RankingsScreen(),
//     const ProfileScreen(),
//   ];

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: IndexedStack(index: _currentIndex, children: _screens),
//       bottomNavigationBar: BottomNavWithGames(
//         currentIndex: _currentIndex,
//         onTap: (index) {
//           setState(() {
//             _currentIndex = index;
//           });
//         },
//       ),
//     );
//   }
// }

// // ✅ SCREENS PLACEHOLDER (SE NÃO EXISTIREM)
// class ChallengesScreen extends StatelessWidget {
//   const ChallengesScreen({super.key});

//   @override
//   Widget build(BuildContext context) =>
//       const Scaffold(body: Center(child: Text('Tela de Desafios')));
// }

// class RankingsScreen extends StatelessWidget {
//   const RankingsScreen({super.key});

//   @override
//   Widget build(BuildContext context) =>
//       const Scaffold(body: Center(child: Text('Tela de Rankings')));
// }

// class ProfileScreen extends StatelessWidget {
//   const ProfileScreen({super.key});

//   @override
//   Widget build(BuildContext context) =>
//       const Scaffold(body: Center(child: Text('Tela de Perfil')));
// }
