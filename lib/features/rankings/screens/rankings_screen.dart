// lib/features/rankings/screens/rankings_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:unlock/core/constants/app_constants.dart';
import 'package:unlock/core/utils/logger.dart';
import 'package:unlock/features/home/widgets/modern_app_bar.dart';
import 'package:unlock/features/rankings/providers/ranking_provider.dart';
import 'package:unlock/features/rankings/widgets/ranking_category_selector.dart';
import 'package:unlock/features/rankings/widgets/ranking_list.dart';
import 'package:unlock/features/rankings/widgets/ranking_podium.dart';
import 'package:unlock/features/rankings/widgets/user_rank_card.dart';
import 'package:unlock/models/ranking_model.dart';
import 'package:unlock/providers/auth_provider.dart';

/// Tela principal de rankings com sistema completo de classificação
class RankingsScreen extends ConsumerStatefulWidget {
  const RankingsScreen({super.key});

  @override
  ConsumerState<RankingsScreen> createState() => _RankingsScreenState();
}

class _RankingsScreenState extends ConsumerState<RankingsScreen>
    with TickerProviderStateMixin {
  // Controladores de animação
  late AnimationController _animationController;
  late TabController _tabController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  // Estado da tela
  RankingCategory _selectedCategory = RankingCategory.xp;
  RankingPeriod _selectedPeriod = RankingPeriod.allTime;

  @override
  void initState() {
    super.initState();

    AppLogger.info('🏅 RankingsScreen: Iniciada');

    // Configurar controladores
    _animationController = AnimationController(
      duration: AppConstants.animationDuration,
      vsync: this,
    );

    _tabController = TabController(length: 4, vsync: this);

    // Configurar animações
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

    // Iniciar animação
    _animationController.forward();

    // Listener para mudanças de tab
    _tabController.addListener(_onTabChanged);
  }

  @override
  void dispose() {
    _animationController.dispose();
    _tabController.dispose();
    AppLogger.info('🧹 RankingsScreen: Disposed');
    super.dispose();
  }

  /// Handler para mudança de tab
  void _onTabChanged() {
    if (_tabController.indexIsChanging) {
      final scopeType = RankingScopeType.values[_tabController.index];
      AppLogger.debug('🏅 Tab mudou para: ${scopeType.name}');

      // Atualizar provider se necessário
      ref.read(rankingProvider.notifier).updateScope(scopeType);
    }
  }

  /// Handler para mudança de categoria
  void _onCategoryChanged(RankingCategory category) {
    setState(() {
      _selectedCategory = category;
    });

    ref.read(rankingProvider.notifier).updateCategory(category);
    AppLogger.debug('🏅 Categoria mudou para: ${category.name}');
  }

  /// Handler para mudança de período
  void _onPeriodChanged(RankingPeriod period) {
    setState(() {
      _selectedPeriod = period;
    });

    ref.read(rankingProvider.notifier).updatePeriod(period);
    AppLogger.debug('🏅 Período mudou para: ${period.name}');
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider.select((state) => state.user));

    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: Scaffold(
              // AppBar com gradiente
              appBar: ModernAppBarVariant(
                title: 'Rankings',
                showBackButton: true,
                actions: [
                  // Filtro de período
                  PopupMenuButton<RankingPeriod>(
                    icon: const Icon(Icons.schedule),
                    tooltip: 'Período',
                    onSelected: _onPeriodChanged,
                    itemBuilder: (context) =>
                        RankingPeriod.values.map((period) {
                          return PopupMenuItem(
                            value: period,
                            child: Row(
                              children: [
                                Icon(
                                  period.icon,
                                  size: 16,
                                  color: _selectedPeriod == period
                                      ? Theme.of(context).colorScheme.primary
                                      : null,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  period.label,
                                  style: TextStyle(
                                    fontWeight: _selectedPeriod == period
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                    color: _selectedPeriod == period
                                        ? Theme.of(context).colorScheme.primary
                                        : null,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                  ),
                ],
              ),

              body: Column(
                children: [
                  // Seletor de categoria
                  RankingCategorySelector(
                    selectedCategory: _selectedCategory,
                    onCategoryChanged: _onCategoryChanged,
                  ),

                  // Tabs de escopo
                  _buildTabBar(),

                  // Conteúdo principal
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _buildRankingTab(RankingScopeType.global),
                        _buildRankingTab(RankingScopeType.groups),
                        _buildRankingTab(RankingScopeType.friends),
                        _buildRankingTab(RankingScopeType.weekly),
                      ],
                    ),
                  ),

                  // Card com posição do usuário
                  if (user != null)
                    UserRankCard(
                      user: user,
                      category: _selectedCategory,
                      period: _selectedPeriod,
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  /// Construir tab bar
  Widget _buildTabBar() {
    return Container(
      color: Theme.of(context).colorScheme.surface,
      child: TabBar(
        controller: _tabController,
        tabs: [
          Tab(icon: Icon(Icons.public, size: 20), text: 'Global'),
          Tab(icon: Icon(Icons.groups, size: 20), text: 'Grupos'),
          Tab(icon: Icon(Icons.people, size: 20), text: 'Amigos'),
          Tab(
            icon: Icon(Icons.calendar_view_week_rounded, size: 20),
            text: 'Semanal',
          ),
        ],
        labelStyle: Theme.of(
          context,
        ).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w600),
        unselectedLabelStyle: Theme.of(context).textTheme.labelMedium,
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
      ),
    );
  }

  /// Construir tab de ranking
  Widget _buildRankingTab(RankingScopeType scopeType) {
    return Consumer(
      builder: (context, ref, child) {
        final rankingAsync = ref.watch(
          rankingDataProvider(
            RankingQuery(
              category: _selectedCategory,
              scope: scopeType,
              period: _selectedPeriod,
            ),
          ),
        );

        return rankingAsync.when(
          data: (rankings) => _buildRankingContent(rankings, scopeType),
          loading: () => _buildLoadingState(),
          error: (error, stack) => _buildErrorState(error, scopeType),
        );
      },
    );
  }

  /// Construir conteúdo do ranking
  Widget _buildRankingContent(
    List<RankingEntry> rankings,
    RankingScopeType scopeType,
  ) {
    if (rankings.isEmpty) {
      return _buildEmptyState(scopeType);
    }

    return RefreshIndicator(
      onRefresh: () => _refreshRankings(scopeType),
      child: CustomScrollView(
        slivers: [
          // Podium para top 3
          if (rankings.length >= 3)
            SliverToBoxAdapter(
              child: RankingPodium(
                topThree: rankings.take(3).toList(),
                category: _selectedCategory,
              ),
            ),

          const SliverToBoxAdapter(child: SizedBox(height: 24)),

          // Lista do 4º lugar em diante
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                rankings.length > 3 ? 'Outros Competidores' : 'Classificação',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 12)),

          // Lista de rankings
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: RankingList(
              rankings: rankings.length > 3
                  ? rankings.skip(3).toList()
                  : rankings,
              category: _selectedCategory,
              startIndex: rankings.length > 3 ? 4 : 1,
            ),
          ),

          // Espaço final
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }

  /// Construir estado de loading
  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Carregando rankings...'),
        ],
      ),
    );
  }

  /// Construir estado de erro
  Widget _buildErrorState(Object error, RankingScopeType scopeType) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
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
              'Erro ao carregar rankings',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              error.toString(),
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => _refreshRankings(scopeType),
              icon: const Icon(Icons.refresh),
              label: const Text('Tentar Novamente'),
            ),
          ],
        ),
      ),
    );
  }

  /// Construir estado vazio
  Widget _buildEmptyState(RankingScopeType scopeType) {
    String title;
    String message;
    IconData icon;

    switch (scopeType) {
      case RankingScopeType.friends:
        title = 'Nenhum amigo encontrado';
        message = 'Adicione amigos para ver o ranking entre vocês!';
        icon = Icons.person_add;
        break;
      case RankingScopeType.groups:
        title = 'Nenhum grupo encontrado';
        message = 'Participe de grupos para competir nos rankings!';
        icon = Icons.group_add;
        break;
      case RankingScopeType.weekly:
        title = 'Nenhuma atividade esta semana';
        message = 'Seja o primeiro a pontuar nesta semana!';
        icon = Icons.rocket_launch;
        break;
      default:
        title = 'Nenhum dado encontrado';
        message = 'Ainda não há classificações para mostrar.';
        icon = Icons.leaderboard;
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 40,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  /// Refresh dos rankings
  Future<void> _refreshRankings(RankingScopeType scopeType) async {
    AppLogger.info('🔄 Atualizando rankings para: ${scopeType.name}');

    ref.invalidate(
      rankingDataProvider(
        RankingQuery(
          category: _selectedCategory,
          scope: scopeType,
          period: _selectedPeriod,
        ),
      ),
    );

    // Simular delay para UX
    await Future.delayed(const Duration(milliseconds: 500));
  }
}
