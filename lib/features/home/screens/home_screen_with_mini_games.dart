// lib/features/home/screens/home_screen_with_mini_games.dart
// ✅ EXEMPLO PRÁTICO: Home Screen com Mini-Games Integrados

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:unlock/core/constants/app_constants.dart';
import 'package:unlock/core/utils/logger.dart';
import 'package:unlock/features/home/widgets/challenge_carousel.dart';
import 'package:unlock/features/home/widgets/featured_groups_widget.dart';
import 'package:unlock/features/home/widgets/home_header.dart';
import 'package:unlock/features/home/widgets/modern_app_bar.dart';
import 'package:unlock/features/home/widgets/quick_stats_widget.dart';
import 'package:unlock/features/home/widgets/recent_activity_widget.dart';
import 'package:unlock/features/mini_games/widgets/home_mini_games_section.dart';
import 'package:unlock/models/user_model.dart';
import 'package:unlock/providers/auth_provider.dart';

/// Home Screen ATUALIZADA com integração completa dos Mini-Games
class HomeScreenWithMiniGames extends ConsumerStatefulWidget {
  const HomeScreenWithMiniGames({super.key});

  @override
  ConsumerState<HomeScreenWithMiniGames> createState() =>
      _HomeScreenWithMiniGamesState();
}

class _HomeScreenWithMiniGamesState
    extends ConsumerState<HomeScreenWithMiniGames>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  final ScrollController _scrollController = ScrollController();
  bool _showElevatedAppBar = false;

  @override
  void initState() {
    super.initState();

    AppLogger.info('🏠 HomeScreenWithMiniGames: Iniciada');

    // Configurar animações
    _animationController = AnimationController(
      duration: AppConstants.animationDuration,
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0.0, 0.2), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Curves.easeOutBack,
          ),
        );

    // Listener para scroll
    _scrollController.addListener(_onScroll);

    // Iniciar animação
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _scrollController.dispose();
    AppLogger.info('🧹 HomeScreenWithMiniGames: Disposed');
    super.dispose();
  }

  void _onScroll() {
    final shouldShow = _scrollController.offset > 100;
    if (shouldShow != _showElevatedAppBar) {
      setState(() {
        _showElevatedAppBar = shouldShow;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider.select((state) => state.user));

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
                user: user,
                showElevated: _showElevatedAppBar,
                onNotificationsTap: () => _showNotifications(),
                onProfileTap: () => context.push('/mini-games'),
              ),
              body: _buildMainContent(user),

              // ✅ NOVO: FAB para acesso rápido aos mini-games
              floatingActionButton: _buildGamesFAB(),
              floatingActionButtonLocation:
                  FloatingActionButtonLocation.endFloat,
            ),
          ),
        );
      },
    );
  }

  /// Conteúdo principal da home ATUALIZADO
  Widget _buildMainContent(UserModel user) {
    return RefreshIndicator(
      onRefresh: () => _refreshData(),
      child: CustomScrollView(
        controller: _scrollController,
        slivers: [
          // Header com gradiente otimizado
          SliverToBoxAdapter(child: HomeHeader(user: user)),

          // Estatísticas rápidas
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: QuickStatsWidget(user: user),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 24)),

          // ✅ NOVO: Seção completa de Mini-Games
          const SliverToBoxAdapter(child: HomeMiniGamesSection()),

          const SliverToBoxAdapter(child: SizedBox(height: 24)),

          // Desafios em destaque
          SliverToBoxAdapter(
            child: _buildSection(
              context,
              title: 'Desafios em Destaque',
              subtitle: 'Competições acontecendo agora',
              icon: Icons.emoji_events,
              onSeeAll: () => context.push('/challenges'),
              child: const ChallengeCarousel(),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 24)),

          // Grupos em destaque
          SliverToBoxAdapter(
            child: _buildSection(
              context,
              title: 'Seus Grupos',
              subtitle: 'Conecte-se e compete',
              icon: Icons.group,
              onSeeAll: () => context.push('/groups'),
              child: const FeaturedGroupsWidget(),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 24)),

          // ✅ NOVO: Quick Actions para Games
          const SliverToBoxAdapter(child: MiniGamesQuickActions()),

          const SliverToBoxAdapter(child: SizedBox(height: 24)),

          // Atividade recente
          SliverToBoxAdapter(
            child: _buildSection(
              context,
              title: 'Atividade Recente',
              subtitle: 'O que está rolando',
              icon: Icons.timeline,
              child: const RecentActivityWidget(),
            ),
          ),

          // Espaço final para FAB
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }

  /// ✅ NOVO: FAB para mini-games
  Widget _buildGamesFAB() {
    return FloatingActionButton.extended(
      onPressed: () => _showGamesBottomSheet(),
      backgroundColor: Colors.purple,
      foregroundColor: Colors.white,
      icon: const Icon(Icons.videogame_asset),
      label: const Text('Jogar'),
      tooltip: 'Abrir Mini Games',
    );
  }

  /// ✅ NOVO: Mostrar bottom sheet com games
  void _showGamesBottomSheet() {
    MiniGamesBottomSheet.show(context);
  }

  /// Construir seção
  Widget _buildSection(
    BuildContext context, {
    required String title,
    String? subtitle,
    required IconData icon,
    required Widget child,
    VoidCallback? onSeeAll,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          _buildSectionHeader(context, title, subtitle, icon, onSeeAll),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  /// Cabeçalho da seção
  Widget _buildSectionHeader(
    BuildContext context,
    String title,
    String? subtitle,
    IconData icon,
    VoidCallback? onSeeAll,
  ) {
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
              if (subtitle != null)
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
        if (onSeeAll != null)
          TextButton(onPressed: onSeeAll, child: const Text('Ver Todos')),
      ],
    );
  }

  /// Tela não autorizada
  Widget _buildUnauthorizedScreen() {
    return Scaffold(
      appBar: AppBar(title: const Text('ClashUp')),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.lock_outline, size: 64),
            SizedBox(height: 16),
            Text('Você precisa estar logado para acessar o app.'),
          ],
        ),
      ),
    );
  }

  /// Atualizar dados
  Future<void> _refreshData() async {
    AppLogger.info('🔄 Atualizando dados da home');
    // Implementar refresh de dados
    await Future.delayed(const Duration(seconds: 1));
  }

  /// Mostrar notificações
  void _showNotifications() {
    AppLogger.info('🔔 Abrindo notificações');
    // Implementar tela de notificações
  }
}
