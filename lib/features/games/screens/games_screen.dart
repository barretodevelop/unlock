// lib/features/games/screens/games_list_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:unlock/features/games/providers/games_provider.dart';
import 'package:unlock/features/games/widgets/game_card_widget.dart';
import 'package:unlock/models/game_model.dart';
import 'package:unlock/providers/auth_provider.dart';

/// Tela principal que exibe a lista de mini-games disponíveis.
///
/// Permite ao usuário navegar para diferentes jogos e visualizar
/// suas informações e recompensas.
class GamesListScreen extends ConsumerWidget {
  const GamesListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final games = ref.watch(gamesProvider);
    final userAsync = ref.watch(authProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mini-Games'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.goNamed('home'),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).colorScheme.primary.withOpacity(0.1),
              Theme.of(context).colorScheme.surface,
            ],
          ),
        ),
        // child: userAsync.when(
        //   loading: () => const Center(child: CircularProgressIndicator()),
        //   error: (error, stack) => Center(
        //     child: Column(
        //       mainAxisAlignment: MainAxisAlignment.center,
        //       children: [
        //         Icon(
        //           Icons.error_outline,
        //           size: 64,
        //           color: Theme.of(context).colorScheme.error,
        //         ),
        //         const SizedBox(height: 16),
        //         Text(
        //           'Erro ao carregar dados do usuário',
        //           style: Theme.of(context).textTheme.titleLarge,
        //         ),
        //         const SizedBox(height: 8),
        //         Text(
        //           'Verifique sua conexão e tente novamente',
        //           style: Theme.of(context).textTheme.bodyMedium,
        //         ),
        //         const SizedBox(height: 16),
        //         ElevatedButton(
        //           onPressed: () => ref.invalidate(authProvider),
        //           child: const Text('Tentar Novamente'),
        //         ),
        //       ],
        //     ),
        //   ),
        //   data: (user) => user == null
        //       ? const Center(child: Text('Usuário não autenticado'))
        //       : _buildGamesList(context, games, user),
        // ),
        child: _buildGamesList(context, games, userAsync),
      ),
    );
  }

  Widget _buildGamesList(BuildContext context, List<GameModel> games, user) {
    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.all(16),
          sliver: SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Escolha um jogo',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Complete os desafios e ganhe XP, moedas e gemas!',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.8,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            delegate: SliverChildBuilderDelegate((context, index) {
              final game = games[index];
              return GameCardWidget(
                game: game,
                onTap: () => _navigateToGame(context, game),
              );
            }, childCount: games.length),
          ),
        ),
        const SliverPadding(padding: EdgeInsets.only(bottom: 32)),
      ],
    );
  }

  void _navigateToGame(BuildContext context, GameModel game) {
    if (!game.isAvailable) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Este jogo ainda não está disponível'),
          backgroundColor: Theme.of(context).colorScheme.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    // Navega para a tela específica do jogo usando a rota definida no GameModel
    context.pushNamed(
      game.route.split('/').last, // Extrai o nome da rota do caminho
      extra: game, // Passa o GameModel como parâmetro extra
    );
  }
}
