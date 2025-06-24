// lib/features/rankings/screens/ranking_stats_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:unlock/core/constants/app_constants.dart';
import 'package:unlock/core/utils/logger.dart';
import 'package:unlock/features/home/widgets/modern_app_bar.dart';
import 'package:unlock/features/rankings/providers/ranking_provider.dart';
import 'package:unlock/features/rankings/widgets/ranking_category_selector.dart';
import 'package:unlock/models/ranking_model.dart';
import 'package:unlock/models/user_model.dart';
import 'package:unlock/providers/auth_provider.dart';
import 'package:unlock/shared/widgets/avatar_circle.dart';

/// Tela de estatísticas detalhadas de rankings
class RankingStatsScreen extends ConsumerStatefulWidget {
  final String? userId; // Se null, mostra do usuário atual

  const RankingStatsScreen({super.key, this.userId});

  @override
  ConsumerState<RankingStatsScreen> createState() => _RankingStatsScreenState();
}

class _RankingStatsScreenState extends ConsumerState<RankingStatsScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late TabController _tabController;
  late Animation<double> _fadeAnimation;

  RankingCategory _selectedCategory = RankingCategory.xp;

  @override
  void initState() {
    super.initState();

    AppLogger.info('📊 RankingStatsScreen: Iniciada');

    _animationController = AnimationController(
      duration: AppConstants.animationDuration,
      vsync: this,
    );

    _tabController = TabController(length: 3, vsync: this);

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _tabController.dispose();
    super.dispose();
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
          child: Scaffold(
            appBar: ModernAppBarVariant(
              title: 'Estatísticas de Ranking',
              actions: [
                // Menu de opções
                PopupMenuButton<String>(
                  onSelected: _onMenuSelected,
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'share',
                      child: Row(
                        children: [
                          Icon(Icons.share, size: 16),
                          SizedBox(width: 8),
                          Text('Compartilhar'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'refresh',
                      child: Row(
                        children: [
                          Icon(Icons.refresh, size: 16),
                          SizedBox(width: 8),
                          Text('Atualizar'),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),

            body: Column(
              children: [
                // Header com informações do usuário
                _buildUserHeader(user),

                // Seletor de categoria
                RankingCategorySelector(
                  selectedCategory: _selectedCategory,
                  onCategoryChanged: (category) {
                    setState(() {
                      _selectedCategory = category;
                    });
                  },
                  showDescription: false,
                ),

                // Tabs de estatísticas
                _buildTabBar(),

                // Conteúdo das tabs
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildOverviewTab(user),
                      _buildHistoryTab(user),
                      _buildComparisonTab(user),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Construir header do usuário
  Widget _buildUserHeader(UserModel user) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _selectedCategory.color.withOpacity(0.1),
            _selectedCategory.color.withOpacity(0.05),
          ],
        ),
      ),
      child: Row(
        children: [
          // Avatar com decoração
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: _selectedCategory.color, width: 3),
              boxShadow: [
                BoxShadow(
                  color: _selectedCategory.color.withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: AvatarCircle(
              imageUrl: user.avatar.startsWith('http') ? user.avatar : null,
              fallbackText: user.avatar.startsWith('http') ? null : user.avatar,
              radius: 40,
            ),
          ),

          const SizedBox(width: 20),

          // Informações do usuário
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.displayName,
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  '@${user.username}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
                const SizedBox(height: 8),
                _buildUserStats(user),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Construir estatísticas do usuário
  Widget _buildUserStats(UserModel user) {
    return Row(
      children: [
        _buildStatChip('Nível ${user.level}', Icons.trending_up),
        const SizedBox(width: 8),
        _buildStatChip(
          '${user.loginStreak ?? 0} dias',
          Icons.local_fire_department,
        ),
      ],
    );
  }

  /// Construir chip de estatística
  Widget _buildStatChip(String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _selectedCategory.color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _selectedCategory.color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: _selectedCategory.color),
          const SizedBox(width: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: _selectedCategory.color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  /// Construir tab bar
  Widget _buildTabBar() {
    return Container(
      color: Theme.of(context).colorScheme.surface,
      child: TabBar(
        controller: _tabController,
        tabs: const [
          Tab(icon: Icon(Icons.dashboard, size: 20), text: 'Visão Geral'),
          Tab(icon: Icon(Icons.timeline, size: 20), text: 'Histórico'),
          Tab(icon: Icon(Icons.compare_arrows, size: 20), text: 'Comparação'),
        ],
        labelStyle: Theme.of(
          context,
        ).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w600),
        unselectedLabelStyle: Theme.of(context).textTheme.labelMedium,
        indicatorSize: TabBarIndicatorSize.tab,
      ),
    );
  }

  /// Construir tab de visão geral
  Widget _buildOverviewTab(UserModel user) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cards de posições atuais
          _buildCurrentPositionsSection(user),

          const SizedBox(height: 24),

          // Estatísticas da categoria selecionada
          _buildCategoryStatsSection(user),

          const SizedBox(height: 24),

          // Conquistas e badges
          _buildAchievementsSection(user),
        ],
      ),
    );
  }

  /// Construir seção de posições atuais
  Widget _buildCurrentPositionsSection(UserModel user) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Posições Atuais',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),

        // Grid de posições por escopo
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.5,
          children: [
            _buildPositionCard('Global', RankingScopeType.global, user),
            _buildPositionCard('Grupos', RankingScopeType.groups, user),
            _buildPositionCard('Amigos', RankingScopeType.friends, user),
            _buildPositionCard('Semanal', RankingScopeType.weekly, user),
          ],
        ),
      ],
    );
  }

  /// Construir card de posição
  Widget _buildPositionCard(
    String title,
    RankingScopeType scope,
    UserModel user,
  ) {
    final query = RankingQuery(
      category: _selectedCategory,
      scope: scope,
      period: RankingPeriod.allTime,
    );

    final positionAsync = ref.watch(userPositionProvider(query));

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 8),
          positionAsync.when(
            data: (position) => Text(
              position != null ? '#$position' : '--',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: _selectedCategory.color,
              ),
            ),
            loading: () => const CircularProgressIndicator(),
            error: (_, __) => Icon(
              Icons.error_outline,
              color: Theme.of(context).colorScheme.error,
            ),
          ),
        ],
      ),
    );
  }

  /// Construir seção de estatísticas da categoria
  Widget _buildCategoryStatsSection(UserModel user) {
    final value = _selectedCategory.getValueFromUser({
      'xp': user.xp,
      'coins': user.coins,
      'gems': user.gems,
      'level': user.level,
      'loginStreak': user.loginStreak,
      'stats': {},
    });

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _selectedCategory.color.withOpacity(0.1),
            _selectedCategory.color.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _selectedCategory.color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                _selectedCategory.icon,
                color: _selectedCategory.color,
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                _selectedCategory.label,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Valor atual grande
          Text(
            _selectedCategory.formatValue(value),
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: _selectedCategory.color,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _selectedCategory.description,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// Construir seção de conquistas
  Widget _buildAchievementsSection(UserModel user) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Conquistas',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),

        // Placeholder para conquistas
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Icon(
                Icons.emoji_events_outlined,
                size: 48,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
              ),
              const SizedBox(height: 12),
              Text(
                'Sistema de Conquistas',
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                'Em desenvolvimento...',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Construir tab de histórico
  Widget _buildHistoryTab(UserModel user) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Placeholder para gráfico de histórico
          Container(
            height: 200,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.show_chart,
                    size: 48,
                    color: _selectedCategory.color,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Gráfico de Histórico',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Evolução do ${_selectedCategory.label.toLowerCase()} ao longo do tempo',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withOpacity(0.6),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Lista de marcos históricos
          _buildHistoryMilestones(user),
        ],
      ),
    );
  }

  /// Construir marcos históricos
  Widget _buildHistoryMilestones(UserModel user) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Marcos Históricos',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),

        // Placeholder para marcos
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Icon(
                Icons.timeline,
                size: 48,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
              ),
              const SizedBox(height: 12),
              Text(
                'Histórico de Marcos',
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                'Principais conquistas e mudanças de posição serão exibidas aqui',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withOpacity(0.6),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Construir tab de comparação
  Widget _buildComparisonTab(UserModel user) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Comparação com top players
          _buildTopPlayersComparison(user),

          const SizedBox(height: 24),

          // Comparação com amigos
          _buildFriendsComparison(user),
        ],
      ),
    );
  }

  /// Construir comparação com top players
  Widget _buildTopPlayersComparison(UserModel user) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Comparação com Top Players',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),

        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Icon(Icons.leaderboard, size: 48, color: _selectedCategory.color),
              const SizedBox(height: 12),
              Text(
                'Comparação Detalhada',
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                'Compare seu desempenho com os melhores players',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withOpacity(0.6),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Construir comparação com amigos
  Widget _buildFriendsComparison(UserModel user) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Comparação com Amigos',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),

        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Icon(
                Icons.people,
                size: 48,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
              ),
              const SizedBox(height: 12),
              Text(
                'Ranking entre Amigos',
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                'Sistema de amizades em desenvolvimento',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withOpacity(0.6),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Construir tela não autorizada
  Widget _buildUnauthorizedScreen() {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.lock_outline,
              size: 64,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Acesso Negado',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Você precisa estar logado para ver as estatísticas',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // ========== HANDLERS ==========

  void _onMenuSelected(String value) {
    switch (value) {
      case 'share':
        _shareStats();
        break;
      case 'refresh':
        _refreshStats();
        break;
    }
  }

  void _shareStats() {
    // TODO: Implementar compartilhamento
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Compartilhamento em desenvolvimento')),
    );
  }

  void _refreshStats() {
    AppLogger.info('🔄 Atualizando estatísticas de ranking');
    ref.invalidate(userPositionProvider);
  }
}
