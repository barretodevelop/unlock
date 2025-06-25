// lib/features/mini_games/screens/mini_games_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:unlock/core/constants/app_constants.dart';
import 'package:unlock/core/utils/logger.dart';
import 'package:unlock/features/home/widgets/modern_app_bar.dart';
import 'package:unlock/features/mini_games/widgets/game_card.dart';
import 'package:unlock/features/mini_games/widgets/personal_best_widget.dart';
import 'package:unlock/features/mini_games/widgets/recent_games_widget.dart';
import 'package:unlock/models/mini_game_model.dart';
import 'package:unlock/providers/auth_provider.dart';
import 'package:unlock/providers/mini_game_provider.dart';

/// Tela principal dos mini-games
class MiniGamesScreen extends ConsumerStatefulWidget {
  const MiniGamesScreen({super.key});

  @override
  ConsumerState<MiniGamesScreen> createState() => _MiniGamesScreenState();
}

class _MiniGamesScreenState extends ConsumerState<MiniGamesScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    AppLogger.info('🎮 MiniGamesScreen: Iniciada');

    // Configurar animações
    _animationController = AnimationController(
      duration: AppConstants.animationDuration,
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0.0, 0.3), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Curves.easeOutBack,
          ),
        );

    // Carregar dados
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(miniGameGlobalProvider.notifier).loadPersonalData();
    });

    // Iniciar animação
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    AppLogger.info('🧹 MiniGamesScreen: Disposed');
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider.select((state) => state.user));
    final globalState = ref.watch(miniGameGlobalProvider);

    if (user == null) {
      return _buildUnauthorizedScreen();
    }

    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: Scaffold(
              appBar: ModernAppBar(
                title: 'Mini Games',
                // subtitle: 'Teste suas habilidades',
                actions: [
                  IconButton(
                    icon: const Icon(Icons.leaderboard),
                    onPressed: () => _navigateToLeaderboard(),
                    tooltip: 'Rankings',
                  ),
                  IconButton(
                    icon: const Icon(Icons.history),
                    onPressed: () => _navigateToHistory(),
                    tooltip: 'Histórico',
                  ),
                ],
              ),
              body: RefreshIndicator(
                onRefresh: _refreshData,
                child: _buildBody(user.username, globalState),
              ),
            ),
          ),
        );
      },
    );
  }

  /// Corpo principal da tela
  Widget _buildBody(String username, MiniGameGlobalState globalState) {
    if (globalState.isLoading) {
      return _buildLoadingScreen();
    }

    if (globalState.error != null) {
      return _buildErrorScreen(globalState.error!);
    }

    return CustomScrollView(
      slivers: [
        // Header de boas-vindas
        SliverToBoxAdapter(child: _buildWelcomeHeader(username)),

        // Personal Bests
        SliverToBoxAdapter(
          child: PersonalBestWidget(personalBests: globalState.personalBests),
        ),

        const SliverToBoxAdapter(child: SizedBox(height: 24)),

        // Grid de jogos
        SliverToBoxAdapter(child: _buildGamesSection()),

        const SliverToBoxAdapter(child: SizedBox(height: 24)),

        // Jogos recentes
        SliverToBoxAdapter(
          child: RecentGamesWidget(recentGames: globalState.recentGames),
        ),

        // Espaço final
        const SliverToBoxAdapter(child: SizedBox(height: 100)),
      ],
    );
  }

  /// Header de boas-vindas
  Widget _buildWelcomeHeader(String username) {
    return Container(
      padding: const EdgeInsets.all(24),
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Theme.of(context).colorScheme.primary.withOpacity(0.1),
            Theme.of(context).colorScheme.secondary.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.videogame_asset,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Olá, $username! 🎮',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Pronto para alguns desafios de habilidade?',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildQuickStats(),
        ],
      ),
    );
  }

  /// Estatísticas rápidas
  Widget _buildQuickStats() {
    final globalState = ref.watch(miniGameGlobalProvider);

    return Row(
      children: [
        _buildStatItem(
          icon: Icons.emoji_events,
          label: 'Personal Bests',
          value: globalState.personalBests.length.toString(),
          color: Colors.amber,
        ),
        const SizedBox(width: 16),
        _buildStatItem(
          icon: Icons.trending_up,
          label: 'Jogos Hoje',
          value: _getTodayGamesCount(globalState).toString(),
          color: Colors.green,
        ),
        const SizedBox(width: 16),
        _buildStatItem(
          icon: Icons.star,
          label: 'Melhor Rank',
          value: _getBestRank(globalState),
          color: Colors.purple,
        ),
      ],
    );
  }

  /// Item de estatística
  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: color,
                fontSize: 16,
              ),
            ),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  /// Seção de jogos
  Widget _buildGamesSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
            'Escolha seu Jogo',
            'Cada jogo testa habilidades diferentes',
            Icons.sports_esports,
          ),
          const SizedBox(height: 16),
          _buildGamesGrid(),
        ],
      ),
    );
  }

  /// Grid de jogos
  Widget _buildGamesGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.85,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: GameType.values.length,
      itemBuilder: (context, index) {
        final gameType = GameType.values[index];
        final personalBest = ref.watch(
          miniGameGlobalProvider.select((s) => s.personalBests[gameType]),
        );

        return GameCard(
          gameType: gameType,
          personalBest: personalBest,
          onTap: () => _navigateToGame(gameType),
        );
      },
    );
  }

  /// Cabeçalho de seção
  Widget _buildSectionHeader(String title, String subtitle, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: Theme.of(context).colorScheme.primary,
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Tela de loading
  Widget _buildLoadingScreen() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Carregando seus jogos...'),
        ],
      ),
    );
  }

  /// Tela de erro
  Widget _buildErrorScreen(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Ops! Algo deu errado',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              error,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _refreshData,
              icon: const Icon(Icons.refresh),
              label: const Text('Tentar Novamente'),
            ),
          ],
        ),
      ),
    );
  }

  /// Tela não autorizada
  Widget _buildUnauthorizedScreen() {
    return Scaffold(
      appBar: AppBar(title: const Text('Mini Games')),
      body: const Center(child: Text('Você precisa estar logado para jogar.')),
    );
  }

  // ========== MÉTODOS AUXILIARES ==========

  /// Obter contagem de jogos hoje
  int _getTodayGamesCount(MiniGameGlobalState state) {
    final today = DateTime.now();
    int count = 0;

    for (final games in state.recentGames.values) {
      count += games.where((game) {
        return game.completedAt.year == today.year &&
            game.completedAt.month == today.month &&
            game.completedAt.day == today.day;
      }).length;
    }

    return count;
  }

  /// Obter melhor rank
  String _getBestRank(MiniGameGlobalState state) {
    String bestRank = 'D';

    for (final best in state.personalBests.values) {
      if (best != null && best.rank.compareTo(bestRank) < 0) {
        bestRank = best.rank;
      }
    }

    return bestRank;
  }

  // ========== NAVEGAÇÃO ==========

  /// Navegar para jogo específico
  void _navigateToGame(GameType gameType) {
    AppLogger.info('🎮 Navegando para jogo: ${gameType.name}');
    context.push('/mini-games/${gameType.id}');
  }

  /// Navegar para leaderboard
  void _navigateToLeaderboard() {
    AppLogger.info('🏆 Navegando para leaderboard');
    context.push('/mini-games/leaderboard');
  }

  /// Navegar para histórico
  void _navigateToHistory() {
    AppLogger.info('📜 Navegando para histórico');
    context.push('/mini-games/history');
  }

  /// Atualizar dados
  Future<void> _refreshData() async {
    AppLogger.info('🔄 Atualizando dados dos mini-games');
    await ref.read(miniGameGlobalProvider.notifier).loadPersonalData();
  }
}
