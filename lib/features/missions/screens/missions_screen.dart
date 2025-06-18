// lib/features/missions/screens/missions_screen.dart
// Tela principal de missões - Fase 3

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:unlock/core/theme/app_theme.dart';
import 'package:unlock/features/missions/models/mission_model.dart';
import 'package:unlock/features/missions/providers/missions_provider.dart';
import 'package:unlock/features/missions/widgets/mission_card.dart';
import 'package:unlock/features/missions/widgets/mission_category_tabs.dart';
import 'package:unlock/providers/auth_provider.dart';

/// Tela principal de missões
class MissionsScreen extends ConsumerStatefulWidget {
  const MissionsScreen({super.key});

  @override
  ConsumerState<MissionsScreen> createState() => _MissionsScreenState();
}

class _MissionsScreenState extends ConsumerState<MissionsScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  final ScrollController _scrollController = ScrollController();
  bool _showAppBarShadow = false;

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _fadeController, curve: Curves.easeOut));

    _scrollController.addListener(_onScroll);
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    final showShadow = _scrollController.offset > 10;
    if (showShadow != _showAppBarShadow) {
      setState(() {
        _showAppBarShadow = showShadow;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authState = ref.watch(authProvider);
    final missionsState = ref.watch(missionsProvider);
    final filteredMissions = ref.watch(filteredMissionsProvider);

    if (!authState.isAuthenticated) {
      return _buildUnauthenticatedScreen(theme);
    }

    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      body: NestedScrollView(
        controller: _scrollController,
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            // App Bar personalizada
            SliverAppBar(
              expandedHeight: 160,
              floating: false,
              pinned: true,
              elevation: _showAppBarShadow ? 4 : 0,
              backgroundColor: theme.colorScheme.surface,
              surfaceTintColor: Colors.transparent,
              foregroundColor: theme.colorScheme.onSurface,
              flexibleSpace: FlexibleSpaceBar(
                titlePadding: const EdgeInsets.only(left: 16, bottom: 16),
                title: Text(
                  'Missões',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                background: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppTheme.primaryColor.withOpacity(0.1),
                        AppTheme.secondaryColor.withOpacity(0.05),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Spacer(),
                          // Estatísticas rápidas
                          _buildQuickStats(theme, missionsState),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              actions: [
                IconButton(
                  onPressed: () => _showMissionsInfo(context),
                  icon: const Icon(Icons.info_outline),
                  tooltip: 'Informações sobre Missões',
                ),
                IconButton(
                  onPressed: () => _onRefresh(ref),
                  icon: const Icon(Icons.refresh),
                  tooltip: 'Atualizar Missões',
                ),
              ],
            ),

            // Tabs de categoria
            SliverPersistentHeader(
              pinned: true,
              delegate: _SliverTabDelegate(
                child: Container(
                  color: theme.colorScheme.surface,
                  child: const MissionCategoryTabs(),
                ),
                height: 60,
              ),
            ),
          ];
        },
        body: FadeTransition(
          opacity: _fadeAnimation,
          child: _buildMissionsContent(
            context,
            ref,
            theme,
            missionsState,
            filteredMissions,
          ),
        ),
      ),
      floatingActionButton: _buildFloatingActionButton(context, theme),
    );
  }

  /// Construir tela não autenticada
  Widget _buildUnauthenticatedScreen(ThemeData theme) {
    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      body: const Center(child: CircularProgressIndicator()),
    );
  }

  /// Construir estatísticas rápidas
  Widget _buildQuickStats(ThemeData theme, MissionsState missionsState) {
    return Row(
      children: [
        _buildStatChip(
          theme,
          '🎯',
          'Ativas',
          missionsState.activeMissions.length.toString(),
          AppTheme.primaryColor,
        ),
        const SizedBox(width: 12),
        _buildStatChip(
          theme,
          '✅',
          'Completas',
          missionsState.completedMissions.length.toString(),
          AppTheme.successColor,
        ),
        const SizedBox(width: 12),
        _buildStatChip(
          theme,
          '📅',
          'Hoje',
          missionsState.dailyMissionsCompleted.toString(),
          AppTheme.accentColor,
        ),
      ],
    );
  }

  /// Construir chip de estatística
  Widget _buildStatChip(
    ThemeData theme,
    String icon,
    String label,
    String value,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(icon, style: const TextStyle(fontSize: 14)),
          const SizedBox(width: 6),
          Text(
            value,
            style: theme.textTheme.labelMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  /// Construir conteúdo das missões
  Widget _buildMissionsContent(
    BuildContext context,
    WidgetRef ref,
    ThemeData theme,
    MissionsState missionsState,
    List<MissionModel> filteredMissions,
  ) {
    if (missionsState.isLoading) {
      return _buildLoadingContent(theme);
    }

    if (missionsState.error != null) {
      return _buildErrorContent(context, ref, theme, missionsState.error!);
    }

    if (filteredMissions.isEmpty) {
      return _buildEmptyContent(context, theme);
    }

    return RefreshIndicator(
      onRefresh: () => _onRefresh(ref),
      color: AppTheme.primaryColor,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: filteredMissions.length,
        itemBuilder: (context, index) {
          final mission = filteredMissions[index];

          return TweenAnimationBuilder<double>(
            duration: Duration(milliseconds: 200 + (index * 50)),
            tween: Tween(begin: 0.0, end: 1.0),
            curve: Curves.easeOutCubic,
            builder: (context, value, child) {
              return Transform.translate(
                offset: Offset(0, 20 * (1 - value)),
                child: Opacity(
                  opacity: value,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: MissionCard(
                      mission: mission,
                      onTap: () => _onMissionTap(context, mission),
                      showProgress: true,
                      isCompact: false,
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  /// Construir conteúdo de loading
  Widget _buildLoadingContent(ThemeData theme) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 6,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: const MissionCardSkeleton(),
        );
      },
    );
  }

  /// Construir conteúdo de erro
  Widget _buildErrorContent(
    BuildContext context,
    WidgetRef ref,
    ThemeData theme,
    String error,
  ) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.assignment_late_outlined,
              size: 64,
              color: AppTheme.errorColor,
            ),

            const SizedBox(height: 24),

            Text(
              'Erro ao carregar missões',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onBackground,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 12),

            Text(
              error,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onBackground.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 32),

            ElevatedButton.icon(
              onPressed: () => _onRefresh(ref),
              icon: const Icon(Icons.refresh),
              label: const Text('Tentar Novamente'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Construir conteúdo vazio
  Widget _buildEmptyContent(BuildContext context, ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.assignment_outlined,
              size: 64,
              color: theme.colorScheme.onBackground.withOpacity(0.4),
            ),

            const SizedBox(height: 24),

            Text(
              'Nenhuma missão disponível',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onBackground,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 12),

            Text(
              'Novas missões serão geradas automaticamente. Que tal verificar suas conexões?',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onBackground.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 32),

            ElevatedButton.icon(
              onPressed: () => Navigator.pushNamed(context, '/connections'),
              icon: const Icon(Icons.people),
              label: const Text('Ver Conexões'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Construir floating action button
  Widget? _buildFloatingActionButton(BuildContext context, ThemeData theme) {
    return FloatingActionButton.extended(
      onPressed: () => _showCreateMissionDialog(context),
      icon: const Icon(Icons.add),
      label: const Text('Nova Missão'),
      backgroundColor: AppTheme.primaryColor,
      foregroundColor: Colors.white,
    );
  }

  /// Ação ao tocar em uma missão
  void _onMissionTap(BuildContext context, MissionModel mission) {
    Navigator.pushNamed(context, '/mission/detail', arguments: mission);
  }

  /// Ação de refresh
  Future<void> _onRefresh(WidgetRef ref) async {
    try {
      await ref.read(missionsProvider.notifier).refresh();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white, size: 20),
                const SizedBox(width: 12),
                const Text('Missões atualizadas!'),
              ],
            ),
            backgroundColor: AppTheme.successColor,
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao atualizar: $e'),
            backgroundColor: AppTheme.errorColor,
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    }
  }

  /// Mostrar informações sobre missões
  void _showMissionsInfo(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            const SizedBox(height: 20),

            Text(
              'Como funcionam as Missões?',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
            ),

            const SizedBox(height: 16),

            _buildInfoItem(
              context,
              '🎯',
              'Missões Diárias',
              'Renovam a cada 24 horas. Complete para ganhar XP e Coins!',
            ),

            _buildInfoItem(
              context,
              '📅',
              'Missões Semanais',
              'Desafios maiores que duram uma semana. Recompensas especiais!',
            ),

            _buildInfoItem(
              context,
              '🤝',
              'Missões Colaborativas',
              'Complete junto com suas conexões para ganhar ainda mais!',
            ),

            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Entendi!'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Construir item de informação
  Widget _buildInfoItem(
    BuildContext context,
    String icon,
    String title,
    String description,
  ) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(icon, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Mostrar diálogo de criar missão personalizada
  void _showCreateMissionDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nova Missão'),
        content: const Text(
          'Funcionalidade de criar missões personalizadas será implementada em breve!',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Ok'),
          ),
        ],
      ),
    );
  }
}

/// Delegate para header persistente
class _SliverTabDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;
  final double height;

  _SliverTabDelegate({required this.child, required this.height});

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return child;
  }

  @override
  double get maxExtent => height;

  @override
  double get minExtent => height;

  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) {
    return false;
  }
}

/// Variação da tela de missões com layout de grid
class GridMissionsScreen extends ConsumerWidget {
  const GridMissionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final filteredMissions = ref.watch(filteredMissionsProvider);

    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      appBar: AppBar(
        title: const Text('Missões'),
        backgroundColor: theme.colorScheme.surface,
        actions: [
          IconButton(
            onPressed: () => ref.read(missionsProvider.notifier).refresh(),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Column(
        children: [
          const MissionCategoryTabs(),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 0.8,
              ),
              itemCount: filteredMissions.length,
              itemBuilder: (context, index) {
                final mission = filteredMissions[index];
                return MissionCard(
                  mission: mission,
                  isCompact: true,
                  onTap: () {
                    Navigator.pushNamed(
                      context,
                      '/mission/detail',
                      arguments: mission,
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
