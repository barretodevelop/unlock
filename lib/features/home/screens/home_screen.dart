// lib/features/home/screens/home_screen.dart
// Tela principal do app - Fase 3 (Corrigida)

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:unlock/core/theme/app_theme.dart';
import 'package:unlock/core/utils/logger.dart';
import 'package:unlock/features/home/providers/home_provider.dart';
import 'package:unlock/features/home/widgets/custom_app_bar.dart';
import 'package:unlock/features/home/widgets/economy_indicators.dart';
import 'package:unlock/features/missions/providers/missions_provider.dart';
import 'package:unlock/features/missions/widgets/mission_card.dart';
import 'package:unlock/features/navigation/widgets/custom_bottom_nav.dart';
import 'package:unlock/features/navigation/widgets/floating_action_center.dart';
import 'package:unlock/features/rewards/providers/rewards_provider.dart';
import 'package:unlock/models/user_model.dart';
import 'package:unlock/providers/auth_provider.dart';

/// Tela principal do aplicativo
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final authState = ref.watch(authProvider);
    final missionsState = ref.watch(missionsProvider);
    final hasPendingRewards = ref.watch(hasPendingRewardsProvider);

    if (!authState.isAuthenticated || authState.user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    /// Refresh da tela
    Future<void> _onRefresh(WidgetRef ref) async {
      try {
        AppLogger.debug('🔄 Atualizando HomeScreen...');

        // Atualizar auth provider
        await ref.read(authProvider.notifier).refreshUser();

        // Atualizar missions provider
        await ref.read(missionsProvider.notifier).refresh();

        // Atualizar home provider
        // await ref.read(homeProvider.notifier).refresh();

        AppLogger.info('✅ HomeScreen atualizada');
      } catch (e) {
        AppLogger.error('❌ Erro ao atualizar HomeScreen', error: e);
      }
    }

    /// Gerar missões manualmente
    Future<void> _generateMissions(WidgetRef ref, UserModel user) async {
      try {
        AppLogger.debug('✨ Gerando missões manualmente para ${user.uid}');

        final missionsNotifier = ref.read(missionsProvider.notifier);

        // Gerar missões diárias e semanais
        await Future.wait([
          missionsNotifier.generateDailyMissions(user),
          missionsNotifier.generateWeeklyMissions(user),
        ]);

        AppLogger.info('✅ Missões geradas manualmente');
      } catch (e) {
        AppLogger.error('❌ Erro ao gerar missões', error: e);
      }
    }

    return Scaffold(
      appBar: const CustomAppBar(),
      body: RefreshIndicator(
        onRefresh: () => _onRefresh(ref),
        child: CustomScrollView(
          slivers: [
            // Header com economia detalhada
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: EconomyIndicators(
                  showDetailed: true,
                  onTap: hasPendingRewards
                      ? () => _claimAllRewards(context, ref)
                      : null,
                  showLevelProgress: false,
                ),
              ),
            ),

            // Seção de Missões
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Suas Missões',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () => _navigateToMissions(context),
                      icon: Icon(
                        Icons.arrow_forward,
                        size: 18,
                        color: AppTheme.primaryColor,
                      ),
                      label: Text(
                        'Ver Todas',
                        style: TextStyle(
                          color: AppTheme.primaryColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Lista de Missões
            if (missionsState.isLoading)
              SliverToBoxAdapter(child: _buildLoadingMissions())
            else if (missionsState.activeMissions.isEmpty)
              SliverToBoxAdapter(child: _buildEmptyMissions(context, theme))
            else
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final mission = missionsState.activeMissions[index];
                    return Padding(
                      padding: EdgeInsets.only(
                        bottom: index < missionsState.activeMissions.length - 1
                            ? 12
                            : 0,
                      ),
                      child: MissionCard(
                        mission: mission,
                        isCompact: true,
                        onTap: () =>
                            _navigateToMissionDetail(context, mission.id),
                      ),
                    );
                  }, childCount: missionsState.activeMissions.length),
                ),
              ),

            // Espaçamento final
            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
      bottomNavigationBar: const CustomBottomNav(),
      floatingActionButton: const FloatingActionCenter(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }

  /// Atualizar dados
  Future<void> _onRefresh(WidgetRef ref) async {
    await ref.read(homeProvider.notifier).refresh();
  }

  /// Coletar todas as recompensas
  void _claimAllRewards(BuildContext context, WidgetRef ref) {
    ref.read(rewardsProvider.notifier).claimAllRewards();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.card_giftcard, color: Colors.white),
            const SizedBox(width: 12),
            const Text('Coletando recompensas...'),
          ],
        ),
        backgroundColor: AppTheme.successColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  /// Navegar para lista de missões
  void _navigateToMissions(BuildContext context) {
    // Navigator.pushNamed(context, '/missions');

    // Por ora, mostrar as missões em bottom sheet
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        builder: (context, scrollController) => Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Handle
              Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Header
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Todas as Missões',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ),

              // Lista de missões
              Expanded(
                child: Consumer(
                  builder: (context, ref, child) {
                    final missionsState = ref.watch(missionsProvider);

                    return ListView.builder(
                      controller: scrollController,
                      padding: const EdgeInsets.all(20),
                      itemCount: missionsState.allMissions.length,
                      itemBuilder: (context, index) {
                        final mission = missionsState.allMissions[index];
                        return Padding(
                          padding: EdgeInsets.only(
                            bottom: index < missionsState.allMissions.length - 1
                                ? 12
                                : 0,
                          ),
                          child: MissionCard(
                            mission: mission,
                            onTap: () {
                              Navigator.pop(context);
                              _navigateToMissionDetail(context, mission.id);
                            },
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Navegar para detalhes da missão
  void _navigateToMissionDetail(BuildContext context, String missionId) {
    // Navigator.pushNamed(context, '/mission/detail', arguments: missionId);

    // Por ora, mostrar em dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Detalhes da Missão'),
        content: Text('Navegação para missão $missionId será implementada'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  /// Construir estado de carregamento das missões
  Widget _buildLoadingMissions() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: List.generate(
          3,
          (index) => Padding(
            padding: EdgeInsets.only(bottom: index < 2 ? 12 : 0),
            child: _buildMissionSkeleton(),
          ),
        ),
      ),
    );
  }

  /// Construir skeleton de missão
  Widget _buildMissionSkeleton() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        height: 80,
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: double.infinity,
                    height: 16,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: 120,
                    height: 12,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Construir estado vazio das missões
  Widget _buildEmptyMissions(BuildContext context, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer.withOpacity(0.3),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.assignment_outlined,
              size: 48,
              color: theme.colorScheme.primary,
            ),
          ),

          const SizedBox(height: 20),

          Text(
            'Nenhuma missão disponível',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface,
            ),
          ),

          const SizedBox(height: 8),

          Text(
            'Novas missões serão geradas automaticamente.\nVolte em breve!',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.7),
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 20),

          ElevatedButton.icon(
            onPressed: () {},
            // onPressed: () =>  _onRefresh(ref),
            icon: const Icon(Icons.refresh),
            label: const Text('Atualizar'),
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: theme.colorScheme.onPrimary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
