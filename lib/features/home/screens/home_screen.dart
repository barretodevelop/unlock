import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:unlock/features/home/widgets/custom_app_bar.dart';
import 'package:unlock/features/matchmaking/providers/matchmaking_provider.dart';
import 'package:unlock/features/matchmaking/widgets/mystery_card_widget.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _selectedIndex = 0;

  // Widgets de placeholder para cada aba
  static const List<Widget> _widgetOptions = <Widget>[
    MatchmakingView(), // Substituído o placeholder
    Center(
      child: Text(
        'Página Explorar',
        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
      ),
    ),
    Center(
      child: Text(
        'Página Chat',
        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
      ),
    ),
    Center(
      child: Text(
        'Página Perfil',
        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
      ),
    ),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Widget _buildNavItem({
    required IconData icon,
    required int index,
    required String label,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final isSelected = _selectedIndex == index;
    final color = isSelected
        ? colorScheme.primary
        : colorScheme.onSurfaceVariant;

    return IconButton(
      icon: Icon(icon, color: color),
      tooltip: label,
      onPressed: () => _onItemTapped(index),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const PreferredSize(
        preferredSize: Size.fromHeight(kToolbarHeight + 16 + 60),
        child: CustomAppBar(),
      ),
      body: _widgetOptions.elementAt(_selectedIndex),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Botão flutuante pressionado!')),
          );
        },
        shape: const CircleBorder(),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        child: const Icon(Icons.add_rounded),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 8.0,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: <Widget>[
            _buildNavItem(icon: Icons.home_rounded, index: 0, label: 'Início'),
            _buildNavItem(
              icon: Icons.explore_rounded,
              index: 1,
              label: 'Explorar',
            ),
            const SizedBox(width: 40), // Espaço para o FAB
            _buildNavItem(icon: Icons.chat_rounded, index: 2, label: 'Chat'),
            _buildNavItem(
              icon: Icons.person_rounded,
              index: 3,
              label: 'Perfil',
            ),
          ],
        ),
      ),
    );
  }
}

class MatchmakingView extends ConsumerWidget {
  const MatchmakingView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final matchmakingAsync = ref.watch(matchmakingProvider);

    return matchmakingAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            'Erro ao buscar perfis: $err',
            textAlign: TextAlign.center,
          ),
        ),
      ),
      data: (matches) {
        if (matches.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.sentiment_dissatisfied,
                    size: 64,
                    color: Colors.grey,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Nenhum perfil encontrado.',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Volte amanhã para novas sugestões!',
                    style: TextStyle(color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }

        return PageView.builder(
          itemCount: matches.length,
          itemBuilder: (context, index) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: MysteryCardWidget(potentialMatch: matches[index]),
            );
          },
        );
      },
    );
  }
}
