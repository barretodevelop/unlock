import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:unlock/core/theme/app_theme.dart';
import 'package:unlock/core/utils/logger.dart';
import 'package:unlock/features/missions/models/mission_model.dart';
import 'package:unlock/features/missions/providers/missions_provider.dart';
import 'package:unlock/features/navigation/widgets/custom_bottom_nav.dart';
import 'package:unlock/features/rewards/providers/rewards_provider.dart';
import 'package:unlock/models/user_model.dart';
import 'package:unlock/providers/auth_provider.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final authState = ref.watch(authProvider);
    final missionsState = ref.watch(missionsProvider);
    final hasPendingRewards = ref.watch(hasPendingRewardsProvider);

    if (!authState.isAuthenticated || authState.user == null) {
      return _buildLoadingScreen(theme);
    }

    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      extendBodyBehindAppBar: true,
      appBar: const ModernAppBar(),
      body: RefreshIndicator(
        onRefresh: () => _handleRefresh(ref),
        color: AppTheme.primaryColor,
        backgroundColor: theme.colorScheme.surface,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // Espaçamento para AppBar transparente
            const SliverToBoxAdapter(child: SizedBox(height: 100)),

            // Hero Stats Card
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                child: HeroStatsCard(
                  user: authState.user!,
                  hasPendingRewards: hasPendingRewards,
                  onRewardsTap: () => _handleClaimRewards(context, ref),
                ),
              ),
            ),

            // Quick Actions
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: QuickActionsGrid(),
              ),
            ),

            // Achievement Banner
            if (hasPendingRewards)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                  child: AchievementBanner(
                    // onTap: () => _handleClaimRewards(context, ref),
                  ),
                ),
              ),

            // Missions Section Header
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 32, 20, 16),
                child: _buildSectionHeader(
                  context,
                  'Missões Ativas',
                  'Ver Todas',
                  () => _showAllMissions(context, ref),
                ),
              ),
            ),

            // Missions Carousel
            SliverToBoxAdapter(
              child: MissionsCarousel(
                missions: missionsState.activeMissions,
                isLoading: missionsState.isLoading,
                onMissionTap: (mission) =>
                    _showMissionDetail(context, mission.id),
                onGenerateMissions: () =>
                    _generateMissions(ref, authState.user!),
              ),
            ),

            // Bottom Spacing
            const SliverToBoxAdapter(child: SizedBox(height: 120)),
          ],
        ),
      ),
      bottomNavigationBar: const CustomBottomNav(),
      floatingActionButton: _buildFloatingAction(context, theme),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }

  Widget _buildLoadingScreen(ThemeData theme) {
    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: theme.shadowColor.withOpacity(0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation(AppTheme.primaryColor),
                strokeWidth: 3,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Carregando...',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onBackground.withOpacity(0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(
    BuildContext context,
    String title,
    String actionText,
    VoidCallback onActionTap,
  ) {
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          title,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w800,
            color: theme.colorScheme.onBackground,
            letterSpacing: -0.5,
          ),
        ),
        GestureDetector(
          onTap: onActionTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppTheme.primaryColor.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  actionText,
                  style: TextStyle(
                    color: AppTheme.primaryColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 12,
                  color: AppTheme.primaryColor,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFloatingAction(BuildContext context, ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryColor,
            AppTheme.primaryColor.withOpacity(0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: FloatingActionButton(
        onPressed: () => _showQuickMenu(context),
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: const Icon(Icons.add, size: 28, color: Colors.white),
      ),
    );
  }

  // Event Handlers
  Future<void> _handleRefresh(WidgetRef ref) async {
    try {
      AppLogger.debug('🔄 Refreshing HomeScreen...');
      await Future.wait([
        ref.read(authProvider.notifier).refreshUser(),
        ref.read(missionsProvider.notifier).refresh(),
      ]);
      AppLogger.info('✅ HomeScreen refreshed');
    } catch (e) {
      AppLogger.error('❌ Error refreshing HomeScreen', error: e);
    }
  }

  void _handleClaimRewards(BuildContext context, WidgetRef ref) {
    ref.read(rewardsProvider.notifier).claimAllRewards();
    _showSuccessSnackBar(context, 'Recompensas coletadas! 🎉');
  }

  Future<void> _generateMissions(WidgetRef ref, UserModel user) async {
    try {
      AppLogger.debug('✨ Generating missions for ${user.uid}');
      final missionsNotifier = ref.read(missionsProvider.notifier);
      await Future.wait([
        missionsNotifier.generateDailyMissions(user),
        missionsNotifier.generateWeeklyMissions(user),
      ]);
      AppLogger.info('✅ Missions generated');
    } catch (e) {
      AppLogger.error('❌ Error generating missions', error: e);
    }
  }

  void _showSuccessSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.celebration, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Text(message, style: const TextStyle(fontWeight: FontWeight.w500)),
          ],
        ),
        backgroundColor: AppTheme.successColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _showAllMissions(BuildContext context, WidgetRef ref) {
    // Navigation implementation
  }

  void _showMissionDetail(BuildContext context, String missionId) {
    // Navigation implementation
  }

  void _showQuickMenu(BuildContext context) {
    // Quick menu implementation
  }
}

class HeroStatsCard extends StatelessWidget {
  final UserModel user;
  final bool hasPendingRewards;
  final VoidCallback onRewardsTap;

  const HeroStatsCard({
    super.key,
    required this.user,
    required this.hasPendingRewards,
    required this.onRewardsTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryColor,
            AppTheme.primaryColor.withOpacity(0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Background Pattern
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                gradient: LinearGradient(
                  colors: [Colors.white.withOpacity(0.1), Colors.transparent],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
          ),

          // Content
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Olá, ${user.displayName?.split(' ').first ?? 'Usuário'}! 👋',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _getGreetingMessage(),
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    if (hasPendingRewards)
                      GestureDetector(
                        onTap: onRewardsTap,
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          child: const Icon(
                            Icons.card_giftcard,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                      ),
                  ],
                ),

                const SizedBox(height: 24),

                // Stats Grid
                Row(
                  children: [
                    Expanded(
                      child: _buildStatItem(
                        'Nível',
                        user.level.toString(),
                        Icons.trending_up,
                        Colors.white,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildStatItem(
                        'Coins',
                        _formatNumber(user.coins),
                        Icons.monetization_on,
                        Colors.amber,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildStatItem(
                        'XP',
                        _formatNumber(user.xp),
                        Icons.star,
                        Colors.yellow,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // Level Progress
                _buildLevelProgress(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(
    String label,
    String value,
    IconData icon,
    Color iconColor,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.2), width: 1),
      ),
      child: Column(
        children: [
          Icon(icon, color: iconColor, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLevelProgress() {
    final currentXP = user.xp % 1000; // Assuming 1000 XP per level
    final progressValue = currentXP / 1000;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Progresso para Nível ${user.level + 1}',
              style: TextStyle(
                color: Colors.white.withOpacity(0.9),
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              '$currentXP/1000 XP',
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: LinearProgressIndicator(
            value: progressValue,
            backgroundColor: Colors.white.withOpacity(0.2),
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
            minHeight: 8,
          ),
        ),
      ],
    );
  }

  String _getGreetingMessage() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Bom dia! Pronto para conquistar?';
    if (hour < 18) return 'Boa tarde! Vamos às missões?';
    return 'Boa noite! Que tal uma missão?';
  }

  String _formatNumber(int number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    }
    return number.toString();
  }
}

class MissionsCarousel extends StatelessWidget {
  final List<MissionModel> missions;
  final bool isLoading;
  final Function(MissionModel) onMissionTap;
  final VoidCallback onGenerateMissions;

  const MissionsCarousel({
    super.key,
    required this.missions,
    required this.isLoading,
    required this.onMissionTap,
    required this.onGenerateMissions,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return _buildLoadingCarousel();
    }

    if (missions.isEmpty) {
      return _buildEmptyState(context);
    }

    return SizedBox(
      height: 200,
      child: PageView.builder(
        controller: PageController(viewportFraction: 0.85),
        physics: const BouncingScrollPhysics(),
        itemCount: missions.length,
        itemBuilder: (context, index) {
          return Padding(
            padding: EdgeInsets.only(
              left: index == 0 ? 20 : 8,
              right: index == missions.length - 1 ? 20 : 8,
            ),
            child: ModernMissionCard(
              mission: missions[index],
              onTap: () => onMissionTap(missions[index]),
            ),
          );
        },
      ),
    );
  }

  Widget _buildLoadingCarousel() {
    return SizedBox(
      height: 200,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: 3,
        itemBuilder: (context, index) {
          return Padding(
            padding: EdgeInsets.only(
              left: index == 0 ? 20 : 8,
              right: index == 2 ? 20 : 8,
            ),
            child: const MissionCardSkeleton(),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.assignment_outlined,
              size: 40,
              color: AppTheme.primaryColor,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Nenhuma missão ativa',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Gere novas missões para começar',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.7),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: onGenerateMissions,
            icon: const Icon(Icons.auto_awesome, size: 20),
            label: const Text('Gerar Missões'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }
}

class ModernMissionCard extends StatelessWidget {
  final MissionModel mission;
  final VoidCallback onTap;

  const ModernMissionCard({
    super.key,
    required this.mission,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final progress = (mission.currentProgress / mission.targetValue).clamp(
      0.0,
      1.0,
    );

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: theme.colorScheme.outline.withOpacity(0.1),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: theme.shadowColor.withOpacity(0.08),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Background Gradient
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: LinearGradient(
                  colors: [
                    _getMissionColor().withOpacity(0.05),
                    Colors.transparent,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),

            // Content
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: _getMissionColor().withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          _getMissionIcon(),
                          color: _getMissionColor(),
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              mission.title,
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: theme.colorScheme.onSurface,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              _getMissionTypeText(),
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: _getMissionColor(),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Description
                  Text(
                    mission.description,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.7),
                      height: 1.4,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),

                  const Spacer(),

                  // Progress and Rewards
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Progresso',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurface
                                        .withOpacity(0.6),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                Text(
                                  '${mission.currentProgress}/${mission.targetValue}',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurface,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: progress,
                                backgroundColor: theme.colorScheme.outline
                                    .withOpacity(0.1),
                                valueColor: AlwaysStoppedAnimation(
                                  _getMissionColor(),
                                ),
                                minHeight: 6,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.successColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.monetization_on,
                              size: 14,
                              color: AppTheme.successColor,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '+${mission.rewardCoins}',
                              style: TextStyle(
                                color: AppTheme.successColor,
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getMissionColor() {
    switch (mission.type) {
      case 'daily':
        return Colors.blue;
      case 'weekly':
        return Colors.purple;
      case 'special':
        return Colors.orange;
      default:
        return AppTheme.primaryColor;
    }
  }

  IconData _getMissionIcon() {
    switch (mission.category!) {
      case 'health':
        return Icons.favorite;
      case 'learning':
        return Icons.school;
      case 'social':
        return Icons.people;
      case 'productivity':
        return Icons.check_circle;
      default:
        return Icons.assignment;
    }
  }

  String _getMissionTypeText() {
    switch (mission.type) {
      case 'daily':
        return 'DIÁRIA';
      case 'weekly':
        return 'SEMANAL';
      case 'special':
        return 'ESPECIAL';
      default:
        return 'MISSÃO';
    }
  }
}

class MissionCardSkeleton extends StatelessWidget {
  const MissionCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: 280,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header skeleton
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: double.infinity,
                        height: 16,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        width: 80,
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

            const SizedBox(height: 16),

            // Description skeleton
            Container(
              width: double.infinity,
              height: 12,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 6),
            Container(
              width: 180,
              height: 12,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(4),
              ),
            ),

            const Spacer(),

            // Progress skeleton
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 60,
                        height: 10,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        width: double.infinity,
                        height: 6,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Container(
                  width: 60,
                  height: 24,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class QuickActionsGrid extends StatelessWidget {
  const QuickActionsGrid({super.key});

  @override
  Widget build(BuildContext context) {
    final actions = _getQuickActions();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.1),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).shadowColor.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Ações Rápidas',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 16),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              childAspectRatio: 1,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: actions.length,
            itemBuilder: (context, index) {
              final action = actions[index];
              return QuickActionButton(
                icon: action.icon,
                label: action.label,
                color: action.color,
                onTap: action.onTap,
              );
            },
          ),
        ],
      ),
    );
  }

  List<QuickActionData> _getQuickActions() {
    return [
      QuickActionData(
        icon: Icons.assignment_add,
        label: 'Nova\nMissão',
        color: Colors.blue,
        onTap: () => _handleCreateMission(),
      ),
      QuickActionData(
        icon: Icons.analytics,
        label: 'Estatís-\nticas',
        color: Colors.green,
        onTap: () => _handleViewStats(),
      ),
      QuickActionData(
        icon: Icons.emoji_events,
        label: 'Conquis-\ntas',
        color: Colors.amber,
        onTap: () => _handleViewAchievements(),
      ),
      QuickActionData(
        icon: Icons.group,
        label: 'Amigos',
        color: Colors.purple,
        onTap: () => _handleViewFriends(),
      ),
      QuickActionData(
        icon: Icons.shopping_bag,
        label: 'Loja',
        color: Colors.orange,
        onTap: () => _handleViewStore(),
      ),
      QuickActionData(
        icon: Icons.history,
        label: 'Histórico',
        color: Colors.teal,
        onTap: () => _handleViewHistory(),
      ),
      QuickActionData(
        icon: Icons.settings,
        label: 'Config.',
        color: Colors.grey,
        onTap: () => _handleSettings(),
      ),
      QuickActionData(
        icon: Icons.help_outline,
        label: 'Ajuda',
        color: Colors.indigo,
        onTap: () => _handleHelp(),
      ),
    ];
  }

  // Action handlers
  void _handleCreateMission() {
    // Navigate to create mission
  }

  void _handleViewStats() {
    // Navigate to statistics
  }

  void _handleViewAchievements() {
    // Navigate to achievements
  }

  void _handleViewFriends() {
    // Navigate to friends
  }

  void _handleViewStore() {
    // Navigate to store
  }

  void _handleViewHistory() {
    // Navigate to history
  }

  void _handleSettings() {
    // Navigate to settings
  }

  void _handleHelp() {
    // Navigate to help
  }
}

class QuickActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const QuickActionButton({
    super.key,
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.2), width: 1),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: color,
                fontWeight: FontWeight.w600,
                fontSize: 10,
                height: 1.2,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class QuickActionData {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  QuickActionData({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });
}

class ModernAppBar extends StatelessWidget implements PreferredSizeWidget {
  const ModernAppBar({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      automaticallyImplyLeading: false,
      systemOverlayStyle: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: theme.brightness == Brightness.dark
            ? Brightness.light
            : Brightness.dark,
        statusBarBrightness: theme.brightness,
      ),
      flexibleSpace: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              theme.colorScheme.background.withOpacity(0.9),
              theme.colorScheme.background.withOpacity(0.7),
              Colors.transparent,
            ],
            stops: const [0.0, 0.7, 1.0],
          ),
        ),
      ),
      title: Row(
        children: [
          // App Logo/Icon
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.primaryColor,
                  AppTheme.primaryColor.withOpacity(0.8),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryColor.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(Icons.lock_open, color: Colors.white, size: 20),
          ),

          const SizedBox(width: 12),

          // App Title
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Unlock',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: theme.colorScheme.onBackground,
                  letterSpacing: -0.5,
                ),
              ),
              Text(
                'Desbloqueie seu potencial',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onBackground.withOpacity(0.6),
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        // Notifications Button
        _buildActionButton(
          context,
          Icons.notifications_outlined,
          () => _handleNotifications(context),
          hasNotification: true,
        ),

        const SizedBox(width: 8),

        // Profile Button
        _buildProfileButton(context),

        const SizedBox(width: 16),
      ],
    );
  }

  Widget _buildActionButton(
    BuildContext context,
    IconData icon,
    VoidCallback onTap, {
    bool hasNotification = false,
  }) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface.withOpacity(0.8),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: theme.colorScheme.outline.withOpacity(0.1),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: theme.shadowColor.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Stack(
          children: [
            Icon(icon, color: theme.colorScheme.onSurface, size: 20),
            if (hasNotification)
              Positioned(
                right: 0,
                top: 0,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: theme.colorScheme.surface,
                      width: 1,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileButton(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: () => _handleProfile(context),
      child: Container(
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppTheme.primaryColor,
              AppTheme.primaryColor.withOpacity(0.8),
            ],
          ),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primaryColor.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(
              'https://via.placeholder.com/32x32/4F46E5/FFFFFF?text=U',
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  child: Icon(
                    Icons.person,
                    color: AppTheme.primaryColor,
                    size: 16,
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  void _handleNotifications(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildNotificationsSheet(context),
    );
  }

  void _handleProfile(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _buildProfileSheet(context),
    );
  }

  Widget _buildNotificationsSheet(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      height: 300,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
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
              color: theme.colorScheme.outline.withOpacity(0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Notificações',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                TextButton(
                  onPressed: () {},
                  child: Text(
                    'Marcar como lidas',
                    style: TextStyle(color: AppTheme.primaryColor),
                  ),
                ),
              ],
            ),
          ),

          // Notifications List
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: 3,
              itemBuilder: (context, index) {
                return _buildNotificationItem(context, index);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationItem(BuildContext context, int index) {
    final theme = Theme.of(context);
    final notifications = [
      {
        'title': 'Nova missão disponível!',
        'subtitle': 'Missão diária: Exercitar-se por 30 minutos',
        'time': '2m',
      },
      {
        'title': 'Recompensa coletada!',
        'subtitle': 'Você ganhou 50 coins por completar uma missão',
        'time': '1h',
      },
      {
        'title': 'Nível aumentado!',
        'subtitle': 'Parabéns! Você subiu para o nível 5',
        'time': '3h',
      },
    ];

    final notification = notifications[index];

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.notifications,
              color: AppTheme.primaryColor,
              size: 16,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  notification['title']!,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  notification['subtitle']!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
          Text(
            notification['time']!,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileSheet(BuildContext context) {
    final theme = Theme.of(context);

    return DraggableScrollableSheet(
      initialChildSize: 0.5,
      maxChildSize: 0.8,
      minChildSize: 0.3,
      builder: (context, scrollController) => Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
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
                color: theme.colorScheme.outline.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Profile Content
            Text(
              'Perfil do Usuário',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Implementar perfil do usuário',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

// lib/features/home/widgets/achievement_banner.dart
// Banner de conquistas para exibir na tela inicial

/// Banner animado para exibir conquistas recentes
class AchievementBanner extends ConsumerStatefulWidget {
  const AchievementBanner({super.key});

  @override
  ConsumerState<AchievementBanner> createState() => _AchievementBannerState();
}

class _AchievementBannerState extends ConsumerState<AchievementBanner>
    with TickerProviderStateMixin {
  late AnimationController _slideController;
  late AnimationController _fadeController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  PageController? _pageController;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();

    // Inicializar animações
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, -1), end: Offset.zero).animate(
          CurvedAnimation(parent: _slideController, curve: Curves.easeOutBack),
        );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _fadeController, curve: Curves.easeIn));

    // Iniciar animações
    _slideController.forward();
    _fadeController.forward();
  }

  @override
  void dispose() {
    _slideController.dispose();
    _fadeController.dispose();
    _pageController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final achievementsState = ref.watch(achievementsProvider);

    // Filtrar conquistas recentes (últimas 7 dias)
    final recentAchievements = achievementsState.unlockedAchievements
        .where(
          (achievement) =>
              achievement.unlockedAt != null &&
              DateTime.now().difference(achievement.unlockedAt!).inDays <= 7,
        )
        .take(3)
        .toList();

    if (recentAchievements.isEmpty) {
      return const SizedBox.shrink();
    }

    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          height: 120,
          child: recentAchievements.length == 1
              ? _buildSingleAchievement(recentAchievements.first, theme)
              : _buildMultipleAchievements(recentAchievements, theme),
        ),
      ),
    );
  }

  /// Construir banner para uma única conquista
  Widget _buildSingleAchievement(
    AchievementModel achievement,
    ThemeData theme,
  ) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryColor.withOpacity(0.1),
            AppTheme.accentColor.withOpacity(0.1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.primaryColor.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Stack(
        children: [
          // Padrão de fundo
          Positioned.fill(
            child: CustomPaint(
              painter: _AchievementPatternPainter(
                color: AppTheme.primaryColor.withOpacity(0.05),
              ),
            ),
          ),

          // Conteúdo
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Ícone da conquista
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppTheme.primaryColor, AppTheme.accentColor],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primaryColor.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(
                    _getAchievementIcon(achievement.type),
                    color: Colors.white,
                    size: 28,
                  ),
                ),

                const SizedBox(width: 16),

                // Informações
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.emoji_events,
                            size: 16,
                            color: AppTheme.accentColor,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Nova Conquista!',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: AppTheme.accentColor,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 4),

                      Text(
                        achievement.title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: theme.colorScheme.onSurface,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),

                      const SizedBox(height: 2),

                      Text(
                        achievement.description,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.7),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),

                // Botão de fechar
                IconButton(
                  onPressed: () => _dismissBanner(),
                  icon: Icon(
                    Icons.close,
                    size: 20,
                    color: theme.colorScheme.onSurface.withOpacity(0.5),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Construir banner para múltiplas conquistas
  Widget _buildMultipleAchievements(
    List<AchievementModel> achievements,
    ThemeData theme,
  ) {
    _pageController ??= PageController();

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryColor.withOpacity(0.1),
            AppTheme.accentColor.withOpacity(0.1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.primaryColor.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Stack(
        children: [
          // PageView das conquistas
          PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            itemCount: achievements.length,
            itemBuilder: (context, index) {
              final achievement = achievements[index];

              return Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    // Ícone da conquista
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [AppTheme.primaryColor, AppTheme.accentColor],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primaryColor.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Icon(
                        _getAchievementIcon(achievement.type),
                        color: Colors.white,
                        size: 28,
                      ),
                    ),

                    const SizedBox(width: 16),

                    // Informações
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.emoji_events,
                                size: 16,
                                color: AppTheme.accentColor,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Nova Conquista!',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: AppTheme.accentColor,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 4),

                          Text(
                            achievement.title,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: theme.colorScheme.onSurface,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),

                          const SizedBox(height: 2),

                          Text(
                            achievement.description,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurface.withOpacity(
                                0.7,
                              ),
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),

          // Indicadores de página
          if (achievements.length > 1)
            Positioned(
              bottom: 12,
              left: 16,
              child: Row(
                children: List.generate(
                  achievements.length,
                  (index) => Container(
                    margin: const EdgeInsets.only(right: 4),
                    width: _currentIndex == index ? 16 : 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: _currentIndex == index
                          ? AppTheme.primaryColor
                          : AppTheme.primaryColor.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
              ),
            ),

          // Botão de fechar
          Positioned(
            top: 8,
            right: 8,
            child: IconButton(
              onPressed: () => _dismissBanner(),
              icon: Icon(
                Icons.close,
                size: 20,
                color: theme.colorScheme.onSurface.withOpacity(0.5),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Obter ícone baseado no tipo de conquista
  IconData _getAchievementIcon(String type) {
    switch (type) {
      case 'mission':
        return Icons.assignment_turned_in;
      case 'level':
        return Icons.trending_up;
      case 'streak':
        return Icons.local_fire_department;
      case 'points':
        return Icons.stars;
      case 'special':
        return Icons.diamond;
      default:
        return Icons.emoji_events;
    }
  }

  /// Dispensar banner
  void _dismissBanner() {
    _fadeController.reverse().then((_) {
      if (mounted) {
        // Marcar conquistas como visualizadas
        ref.read(achievementsProvider.notifier).markAchievementsAsViewed();
      }
    });
  }
}

/// Painter para criar padrão de fundo
class _AchievementPatternPainter extends CustomPainter {
  final Color color;

  _AchievementPatternPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    // Criar padrão de estrelas
    final starSize = 8.0;
    final spacing = 24.0;

    for (double x = 0; x < size.width; x += spacing) {
      for (double y = 0; y < size.height; y += spacing) {
        _drawStar(canvas, paint, Offset(x, y), starSize);
      }
    }
  }

  void _drawStar(Canvas canvas, Paint paint, Offset center, double size) {
    final path = Path();
    final angle = (3.14159 * 2) / 5;

    for (int i = 0; i < 5; i++) {
      final x =
          center.dx +
          size *
              (i % 2 == 0 ? 1 : 0.5) *
              (i == 0 ? 1 : math.cos(i * angle - 3.14159 / 2));
      final y =
          center.dy +
          size *
              (i % 2 == 0 ? 1 : 0.5) *
              (i == 0 ? 0 : math.sin(i * angle - 3.14159 / 2));

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// lib/models/achievement_model.dart
// Modelo de dados para conquistas

/// Modelo de dados para conquistas do usuário
class AchievementModel {
  final String id;
  final String title;
  final String description;
  final String type; // mission, level, streak, points, special
  final String category;
  final int pointsReward;
  final String iconName;
  final String rarity; // common, rare, epic, legendary
  final Map<String, dynamic> requirements;
  final bool isHidden; // conquistas secretas
  final DateTime? unlockedAt;
  final bool isUnlocked;
  final double progress; // 0.0 a 1.0
  final int currentValue;
  final int targetValue;
  final DateTime createdAt;
  final DateTime updatedAt;

  const AchievementModel({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.category,
    required this.pointsReward,
    required this.iconName,
    required this.rarity,
    required this.requirements,
    this.isHidden = false,
    this.unlockedAt,
    this.isUnlocked = false,
    this.progress = 0.0,
    this.currentValue = 0,
    required this.targetValue,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Criar do Firestore
  factory AchievementModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return AchievementModel(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      type: data['type'] ?? 'general',
      category: data['category'] ?? 'general',
      pointsReward: data['pointsReward'] ?? 0,
      iconName: data['iconName'] ?? 'emoji_events',
      rarity: data['rarity'] ?? 'common',
      requirements: Map<String, dynamic>.from(data['requirements'] ?? {}),
      isHidden: data['isHidden'] ?? false,
      unlockedAt: data['unlockedAt']?.toDate(),
      isUnlocked: data['isUnlocked'] ?? false,
      progress: (data['progress'] ?? 0.0).toDouble(),
      currentValue: data['currentValue'] ?? 0,
      targetValue: data['targetValue'] ?? 1,
      createdAt: data['createdAt']?.toDate() ?? DateTime.now(),
      updatedAt: data['updatedAt']?.toDate() ?? DateTime.now(),
    );
  }

  /// Converter para Map para Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'description': description,
      'type': type,
      'category': category,
      'pointsReward': pointsReward,
      'iconName': iconName,
      'rarity': rarity,
      'requirements': requirements,
      'isHidden': isHidden,
      'unlockedAt': unlockedAt,
      'isUnlocked': isUnlocked,
      'progress': progress,
      'currentValue': currentValue,
      'targetValue': targetValue,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  /// Criar cópia com modificações
  AchievementModel copyWith({
    String? id,
    String? title,
    String? description,
    String? type,
    String? category,
    int? pointsReward,
    String? iconName,
    String? rarity,
    Map<String, dynamic>? requirements,
    bool? isHidden,
    DateTime? unlockedAt,
    bool? isUnlocked,
    double? progress,
    int? currentValue,
    int? targetValue,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AchievementModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      type: type ?? this.type,
      category: category ?? this.category,
      pointsReward: pointsReward ?? this.pointsReward,
      iconName: iconName ?? this.iconName,
      rarity: rarity ?? this.rarity,
      requirements: requirements ?? this.requirements,
      isHidden: isHidden ?? this.isHidden,
      unlockedAt: unlockedAt ?? this.unlockedAt,
      isUnlocked: isUnlocked ?? this.isUnlocked,
      progress: progress ?? this.progress,
      currentValue: currentValue ?? this.currentValue,
      targetValue: targetValue ?? this.targetValue,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Verificar se a conquista pode ser desbloqueada
  bool canUnlock() {
    return !isUnlocked && progress >= 1.0;
  }

  /// Atualizar progresso
  AchievementModel updateProgress(int newValue) {
    final newProgress = (newValue / targetValue).clamp(0.0, 1.0);
    final shouldUnlock = newProgress >= 1.0 && !isUnlocked;

    return copyWith(
      currentValue: newValue,
      progress: newProgress,
      isUnlocked: shouldUnlock ? true : null,
      unlockedAt: shouldUnlock ? DateTime.now() : null,
      updatedAt: DateTime.now(),
    );
  }

  /// Obter cor baseada na raridade
  Color get rarityColor {
    switch (rarity) {
      case 'common':
        return const Color(0xFF9E9E9E); // Cinza
      case 'rare':
        return const Color(0xFF2196F3); // Azul
      case 'epic':
        return const Color(0xFF9C27B0); // Roxo
      case 'legendary':
        return const Color(0xFFFF9800); // Laranja/Dourado
      default:
        return const Color(0xFF9E9E9E);
    }
  }

  /// Obter nome da raridade formatado
  String get rarityDisplayName {
    switch (rarity) {
      case 'common':
        return 'Comum';
      case 'rare':
        return 'Rara';
      case 'epic':
        return 'Épica';
      case 'legendary':
        return 'Lendária';
      default:
        return 'Comum';
    }
  }

  /// Obter progresso formatado
  String get progressText {
    if (isUnlocked) return 'Completa';
    return '$currentValue / $targetValue';
  }

  /// Verificar se é conquista recente (últimos 7 dias)
  bool get isRecent {
    if (unlockedAt == null) return false;
    return DateTime.now().difference(unlockedAt!).inDays <= 7;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AchievementModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'AchievementModel{id: $id, title: $title, isUnlocked: $isUnlocked, progress: $progress}';
  }
}

/// Estado das conquistas
class AchievementsState {
  final List<AchievementModel> allAchievements;
  final List<AchievementModel> unlockedAchievements;
  final List<AchievementModel> availableAchievements;
  final bool isLoading;
  final String? error;
  final int totalPoints;
  final int unlockedCount;

  const AchievementsState({
    this.allAchievements = const [],
    this.unlockedAchievements = const [],
    this.availableAchievements = const [],
    this.isLoading = false,
    this.error,
    this.totalPoints = 0,
    this.unlockedCount = 0,
  });

  /// Criar cópia com modificações
  AchievementsState copyWith({
    List<AchievementModel>? allAchievements,
    List<AchievementModel>? unlockedAchievements,
    List<AchievementModel>? availableAchievements,
    bool? isLoading,
    String? error,
    int? totalPoints,
    int? unlockedCount,
  }) {
    return AchievementsState(
      allAchievements: allAchievements ?? this.allAchievements,
      unlockedAchievements: unlockedAchievements ?? this.unlockedAchievements,
      availableAchievements:
          availableAchievements ?? this.availableAchievements,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      totalPoints: totalPoints ?? this.totalPoints,
      unlockedCount: unlockedCount ?? this.unlockedCount,
    );
  }

  /// Obter conquistas por categoria
  List<AchievementModel> getAchievementsByCategory(String category) {
    return allAchievements.where((a) => a.category == category).toList();
  }

  /// Obter conquistas por tipo
  List<AchievementModel> getAchievementsByType(String type) {
    return allAchievements.where((a) => a.type == type).toList();
  }

  /// Obter conquistas recentes
  List<AchievementModel> get recentAchievements {
    return unlockedAchievements.where((a) => a.isRecent).toList();
  }

  /// Obter taxa de progresso geral
  double get completionRate {
    if (allAchievements.isEmpty) return 0.0;
    return unlockedCount / allAchievements.length;
  }
}

/// Provider principal das conquistas
final achievementsProvider =
    StateNotifierProvider<AchievementsNotifier, AchievementsState>((ref) {
      return AchievementsNotifier(ref);
    });

/// Notifier para gerenciar estado das conquistas
class AchievementsNotifier extends StateNotifier<AchievementsState> {
  final Ref ref;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  AchievementsNotifier(this.ref) : super(const AchievementsState()) {
    _initializeAchievements();
  }

  /// Inicializar conquistas
  Future<void> _initializeAchievements() async {
    final user = ref.read(authProvider).user;
    if (user == null) return;

    state = state.copyWith(isLoading: true);

    try {
      await _loadUserAchievements(user.uid);
      await _createDefaultAchievements(user);
    } catch (e) {
      AppLogger.error('Erro ao inicializar conquistas', error: e);
      state = state.copyWith(
        isLoading: false,
        error: 'Erro ao carregar conquistas',
      );
    }
  }

  /// Carregar conquistas do usuário
  Future<void> _loadUserAchievements(String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('achievements')
          .orderBy('createdAt', descending: false)
          .get();

      final achievements = querySnapshot.docs
          .map((doc) => AchievementModel.fromFirestore(doc))
          .toList();

      final unlockedAchievements = achievements
          .where((a) => a.isUnlocked)
          .toList();
      final availableAchievements = achievements
          .where((a) => !a.isUnlocked && !a.isHidden)
          .toList();

      final totalPoints = unlockedAchievements.fold<int>(
        0,
        (sum, achievement) => sum + achievement.pointsReward,
      );

      state = state.copyWith(
        allAchievements: achievements,
        unlockedAchievements: unlockedAchievements,
        availableAchievements: availableAchievements,
        totalPoints: totalPoints,
        unlockedCount: unlockedAchievements.length,
        isLoading: false,
        error: null,
      );

      AppLogger.info('✅ Conquistas carregadas: ${achievements.length}');
    } catch (e) {
      AppLogger.error('Erro ao carregar conquistas do usuário', error: e);
      throw e;
    }
  }

  /// Criar conquistas padrão se não existirem
  Future<void> _createDefaultAchievements(UserModel user) async {
    try {
      if (state.allAchievements.isNotEmpty) return;

      AppLogger.debug('🎯 Criando conquistas padrão para ${user.uid}');

      final defaultAchievements = _getDefaultAchievements();
      final batch = _firestore.batch();

      for (final achievement in defaultAchievements) {
        final docRef = _firestore
            .collection('users')
            .doc(user.uid)
            .collection('achievements')
            .doc(achievement.id);

        batch.set(docRef, achievement.toFirestore());
      }

      await batch.commit();
      await _loadUserAchievements(user.uid);

      AppLogger.info('✅ Conquistas padrão criadas');
    } catch (e) {
      AppLogger.error('Erro ao criar conquistas padrão', error: e);
      throw e;
    }
  }

  /// Obter lista de conquistas padrão
  List<AchievementModel> _getDefaultAchievements() {
    final now = DateTime.now();

    return [
      // Conquistas de Missões
      AchievementModel(
        id: 'first_mission',
        title: 'Primeira Missão',
        description: 'Complete sua primeira missão',
        type: 'mission',
        category: 'iniciante',
        pointsReward: 100,
        iconName: 'assignment_turned_in',
        rarity: 'common',
        requirements: {'missions_completed': 1},
        targetValue: 1,
        createdAt: now,
        updatedAt: now,
      ),

      AchievementModel(
        id: 'mission_master',
        title: 'Mestre das Missões',
        description: 'Complete 50 missões',
        type: 'mission',
        category: 'experiente',
        pointsReward: 1000,
        iconName: 'military_tech',
        rarity: 'epic',
        requirements: {'missions_completed': 50},
        targetValue: 50,
        createdAt: now,
        updatedAt: now,
      ),

      AchievementModel(
        id: 'daily_warrior',
        title: 'Guerreiro Diário',
        description: 'Complete 10 missões diárias',
        type: 'mission',
        category: 'dedicado',
        pointsReward: 500,
        iconName: 'today',
        rarity: 'rare',
        requirements: {'daily_missions_completed': 10},
        targetValue: 10,
        createdAt: now,
        updatedAt: now,
      ),

      // Conquistas de Nível
      AchievementModel(
        id: 'level_up',
        title: 'Subindo de Nível',
        description: 'Alcance o nível 5',
        type: 'level',
        category: 'progresso',
        pointsReward: 250,
        iconName: 'trending_up',
        rarity: 'common',
        requirements: {'level': 5},
        targetValue: 5,
        createdAt: now,
        updatedAt: now,
      ),

      AchievementModel(
        id: 'high_level',
        title: 'Alto Nível',
        description: 'Alcance o nível 25',
        type: 'level',
        category: 'progresso',
        pointsReward: 1000,
        iconName: 'star',
        rarity: 'epic',
        requirements: {'level': 25},
        targetValue: 25,
        createdAt: now,
        updatedAt: now,
      ),

      AchievementModel(
        id: 'max_level',
        title: 'Nível Máximo',
        description: 'Alcance o nível 50',
        type: 'level',
        category: 'lendário',
        pointsReward: 2500,
        iconName: 'emoji_events',
        rarity: 'legendary',
        requirements: {'level': 50},
        targetValue: 50,
        createdAt: now,
        updatedAt: now,
      ),

      // Conquistas de Sequência
      AchievementModel(
        id: 'streak_starter',
        title: 'Começando a Sequência',
        description: 'Mantenha uma sequência de 7 dias',
        type: 'streak',
        category: 'consistência',
        pointsReward: 300,
        iconName: 'local_fire_department',
        rarity: 'common',
        requirements: {'streak_days': 7},
        targetValue: 7,
        createdAt: now,
        updatedAt: now,
      ),

      AchievementModel(
        id: 'on_fire',
        title: 'Pegando Fogo',
        description: 'Mantenha uma sequência de 30 dias',
        type: 'streak',
        category: 'consistência',
        pointsReward: 1500,
        iconName: 'whatshot',
        rarity: 'rare',
        requirements: {'streak_days': 30},
        targetValue: 30,
        createdAt: now,
        updatedAt: now,
      ),

      AchievementModel(
        id: 'unstoppable',
        title: 'Imparável',
        description: 'Mantenha uma sequência de 100 dias',
        type: 'streak',
        category: 'lendário',
        pointsReward: 5000,
        iconName: 'flash_on',
        rarity: 'legendary',
        requirements: {'streak_days': 100},
        targetValue: 100,
        createdAt: now,
        updatedAt: now,
      ),

      // Conquistas de Pontos
      AchievementModel(
        id: 'first_thousand',
        title: 'Primeiros Mil',
        description: 'Acumule 1.000 pontos',
        type: 'points',
        category: 'acumulador',
        pointsReward: 200,
        iconName: 'stars',
        rarity: 'common',
        requirements: {'total_points': 1000},
        targetValue: 1000,
        createdAt: now,
        updatedAt: now,
      ),

      AchievementModel(
        id: 'point_collector',
        title: 'Colecionador de Pontos',
        description: 'Acumule 10.000 pontos',
        type: 'points',
        category: 'acumulador',
        pointsReward: 1000,
        iconName: 'monetization_on',
        rarity: 'rare',
        requirements: {'total_points': 10000},
        targetValue: 10000,
        createdAt: now,
        updatedAt: now,
      ),

      AchievementModel(
        id: 'point_master',
        title: 'Mestre dos Pontos',
        description: 'Acumule 50.000 pontos',
        type: 'points',
        category: 'lendário',
        pointsReward: 3000,
        iconName: 'diamond',
        rarity: 'legendary',
        requirements: {'total_points': 50000},
        targetValue: 50000,
        createdAt: now,
        updatedAt: now,
      ),

      // Conquistas Especiais
      AchievementModel(
        id: 'early_bird',
        title: 'Madrugador',
        description: 'Complete uma missão antes das 6h',
        type: 'special',
        category: 'tempo',
        pointsReward: 500,
        iconName: 'wb_sunny',
        rarity: 'rare',
        requirements: {'early_completion': 1},
        targetValue: 1,
        createdAt: now,
        updatedAt: now,
      ),

      AchievementModel(
        id: 'night_owl',
        title: 'Coruja Noturna',
        description: 'Complete uma missão depois das 22h',
        type: 'special',
        category: 'tempo',
        pointsReward: 500,
        iconName: 'nights_stay',
        rarity: 'rare',
        requirements: {'late_completion': 1},
        targetValue: 1,
        createdAt: now,
        updatedAt: now,
      ),

      AchievementModel(
        id: 'perfectionist',
        title: 'Perfeccionista',
        description: 'Complete 5 missões com pontuação perfeita',
        type: 'special',
        category: 'qualidade',
        pointsReward: 750,
        iconName: 'workspace_premium',
        rarity: 'epic',
        requirements: {'perfect_missions': 5},
        targetValue: 5,
        createdAt: now,
        updatedAt: now,
      ),

      // Conquistas Ocultas
      AchievementModel(
        id: 'secret_explorer',
        title: '???',
        description: 'Descubra esta conquista secreta',
        type: 'special',
        category: 'secreto',
        pointsReward: 1000,
        iconName: 'help_outline',
        rarity: 'epic',
        requirements: {'secret_action': 1},
        isHidden: true,
        targetValue: 1,
        createdAt: now,
        updatedAt: now,
      ),
    ];
  }

  /// Atualizar progresso de uma conquista
  Future<void> updateAchievementProgress(
    String achievementId,
    int newValue, {
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      final user = ref.read(authProvider).user;
      if (user == null) return;

      final achievementIndex = state.allAchievements.indexWhere(
        (a) => a.id == achievementId,
      );

      if (achievementIndex == -1) return;

      final currentAchievement = state.allAchievements[achievementIndex];
      if (currentAchievement.isUnlocked) return;

      final updatedAchievement = currentAchievement.updateProgress(newValue);

      // Atualizar no Firestore
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('achievements')
          .doc(achievementId)
          .update(updatedAchievement.toFirestore());

      // Atualizar estado local
      final updatedAchievements = List<AchievementModel>.from(
        state.allAchievements,
      );
      updatedAchievements[achievementIndex] = updatedAchievement;

      final unlockedAchievements = updatedAchievements
          .where((a) => a.isUnlocked)
          .toList();
      final availableAchievements = updatedAchievements
          .where((a) => !a.isUnlocked && !a.isHidden)
          .toList();

      final totalPoints = unlockedAchievements.fold<int>(
        0,
        (sum, achievement) => sum + achievement.pointsReward,
      );

      state = state.copyWith(
        allAchievements: updatedAchievements,
        unlockedAchievements: unlockedAchievements,
        availableAchievements: availableAchievements,
        totalPoints: totalPoints,
        unlockedCount: unlockedAchievements.length,
      );

      // Se desbloqueou a conquista, mostrar notificação
      if (updatedAchievement.canUnlock() && !currentAchievement.isUnlocked) {
        _showAchievementUnlocked(updatedAchievement);
      }

      AppLogger.info(
        '✅ Progresso atualizado: $achievementId ($newValue/${updatedAchievement.targetValue})',
      );
    } catch (e) {
      AppLogger.error('Erro ao atualizar progresso da conquista', error: e);
    }
  }

  /// Processar eventos para atualizar conquistas
  Future<void> processEvent(String eventType, Map<String, dynamic> data) async {
    try {
      switch (eventType) {
        case 'mission_completed':
          await _processMissionCompleted(data);
          break;
        case 'level_up':
          await _processLevelUp(data);
          break;
        case 'streak_updated':
          await _processStreakUpdated(data);
          break;
        case 'points_earned':
          await _processPointsEarned(data);
          break;
        case 'special_action':
          await _processSpecialAction(data);
          break;
      }
    } catch (e) {
      AppLogger.error('Erro ao processar evento de conquista', error: e);
    }
  }

  /// Processar conclusão de missão
  Future<void> _processMissionCompleted(Map<String, dynamic> data) async {
    final missionType = data['type'] as String?;
    final completedAt = data['completedAt'] as DateTime?;
    final score = data['score'] as double?;

    // Atualizar conquistas gerais de missão
    await updateAchievementProgress('first_mission', 1);
    await updateAchievementProgress(
      'mission_master',
      data['totalMissions'] ?? 1,
    );

    // Atualizar conquistas de missão diária
    if (missionType == 'daily') {
      await updateAchievementProgress(
        'daily_warrior',
        data['dailyMissions'] ?? 1,
      );
    }

    // Conquistas especiais baseadas no horário
    if (completedAt != null) {
      final hour = completedAt.hour;
      if (hour < 6) {
        await updateAchievementProgress('early_bird', 1);
      } else if (hour >= 22) {
        await updateAchievementProgress('night_owl', 1);
      }
    }

    // Conquista de perfeccionista
    if (score != null && score >= 1.0) {
      await updateAchievementProgress(
        'perfectionist',
        data['perfectMissions'] ?? 1,
      );
    }
  }

  /// Processar subida de nível
  Future<void> _processLevelUp(Map<String, dynamic> data) async {
    final newLevel = data['level'] as int?;
    if (newLevel == null) return;

    await updateAchievementProgress('level_up', newLevel);
    await updateAchievementProgress('high_level', newLevel);
    await updateAchievementProgress('max_level', newLevel);
  }

  /// Processar atualização de sequência
  Future<void> _processStreakUpdated(Map<String, dynamic> data) async {
    final streakDays = data['streakDays'] as int?;
    if (streakDays == null) return;

    await updateAchievementProgress('streak_starter', streakDays);
    await updateAchievementProgress('on_fire', streakDays);
    await updateAchievementProgress('unstoppable', streakDays);
  }

  /// Processar ganho de pontos
  Future<void> _processPointsEarned(Map<String, dynamic> data) async {
    final totalPoints = data['totalPoints'] as int?;
    if (totalPoints == null) return;

    await updateAchievementProgress('first_thousand', totalPoints);
    await updateAchievementProgress('point_collector', totalPoints);
    await updateAchievementProgress('point_master', totalPoints);
  }

  /// Processar ação especial
  Future<void> _processSpecialAction(Map<String, dynamic> data) async {
    final actionType = data['actionType'] as String?;

    if (actionType == 'secret_discovered') {
      await updateAchievementProgress('secret_explorer', 1);
    }
  }

  /// Mostrar notificação de conquista desbloqueada
  void _showAchievementUnlocked(AchievementModel achievement) {
    // Esta função será implementada para mostrar notificações
    // Por ora, apenas log
    AppLogger.info('🏆 Conquista desbloqueada: ${achievement.title}');
  }

  /// Marcar conquistas como visualizadas
  Future<void> markAchievementsAsViewed() async {
    // Implementar lógica para marcar conquistas como visualizadas
    // se necessário para controlar notificações
  }

  /// Recarregar conquistas
  Future<void> refresh() async {
    final user = ref.read(authProvider).user;
    if (user == null) return;

    state = state.copyWith(isLoading: true);
    await _loadUserAchievements(user.uid);
  }

  /// Obter conquista por ID
  AchievementModel? getAchievementById(String id) {
    try {
      return state.allAchievements.firstWhere((a) => a.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Obter conquistas por categoria
  List<AchievementModel> getAchievementsByCategory(String category) {
    return state.allAchievements.where((a) => a.category == category).toList();
  }

  /// Obter conquistas por tipo
  List<AchievementModel> getAchievementsByType(String type) {
    return state.allAchievements.where((a) => a.type == type).toList();
  }

  /// Obter estatísticas de conquistas
  Map<String, int> getAchievementStats() {
    final achievements = state.allAchievements;
    final unlocked = state.unlockedAchievements;

    return {
      'total': achievements.length,
      'unlocked': unlocked.length,
      'common': unlocked.where((a) => a.rarity == 'common').length,
      'rare': unlocked.where((a) => a.rarity == 'rare').length,
      'epic': unlocked.where((a) => a.rarity == 'epic').length,
      'legendary': unlocked.where((a) => a.rarity == 'legendary').length,
    };
  }
}


// // lib/features/home/screens/home_screen.dart
// // Tela principal do app - Fase 3 (Corrigida)

// import 'package:flutter/material.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:unlock/core/theme/app_theme.dart';
// import 'package:unlock/core/utils/logger.dart';
// import 'package:unlock/features/home/providers/home_provider.dart';
// import 'package:unlock/features/home/widgets/custom_app_bar.dart';
// import 'package:unlock/features/home/widgets/economy_indicators.dart';
// import 'package:unlock/features/missions/providers/missions_provider.dart';
// import 'package:unlock/features/missions/widgets/mission_card.dart';
// import 'package:unlock/features/navigation/widgets/custom_bottom_nav.dart';
// import 'package:unlock/features/navigation/widgets/floating_action_center.dart';
// import 'package:unlock/features/rewards/providers/rewards_provider.dart';
// import 'package:unlock/models/user_model.dart';
// import 'package:unlock/providers/auth_provider.dart';

// /// Tela principal do aplicativo
// class HomeScreen extends ConsumerWidget {
//   const HomeScreen({super.key});

//   @override
//   Widget build(BuildContext context, WidgetRef ref) {
//     final theme = Theme.of(context);
//     final authState = ref.watch(authProvider);
//     final missionsState = ref.watch(missionsProvider);
//     final hasPendingRewards = ref.watch(hasPendingRewardsProvider);

//     if (!authState.isAuthenticated || authState.user == null) {
//       return const Scaffold(body: Center(child: CircularProgressIndicator()));
//     }

//     /// Refresh da tela
//     Future<void> _onRefresh(WidgetRef ref) async {
//       try {
//         AppLogger.debug('🔄 Atualizando HomeScreen...');

//         // Atualizar auth provider
//         await ref.read(authProvider.notifier).refreshUser();

//         // Atualizar missions provider
//         await ref.read(missionsProvider.notifier).refresh();

//         // Atualizar home provider
//         // await ref.read(homeProvider.notifier).refresh();

//         AppLogger.info('✅ HomeScreen atualizada');
//       } catch (e) {
//         AppLogger.error('❌ Erro ao atualizar HomeScreen', error: e);
//       }
//     }

//     /// Gerar missões manualmente
//     Future<void> _generateMissions(WidgetRef ref, UserModel user) async {
//       try {
//         AppLogger.debug('✨ Gerando missões manualmente para ${user.uid}');

//         final missionsNotifier = ref.read(missionsProvider.notifier);

//         // Gerar missões diárias e semanais
//         await Future.wait([
//           missionsNotifier.generateDailyMissions(user),
//           missionsNotifier.generateWeeklyMissions(user),
//         ]);

//         AppLogger.info('✅ Missões geradas manualmente');
//       } catch (e) {
//         AppLogger.error('❌ Erro ao gerar missões', error: e);
//       }
//     }

//     return Scaffold(
//       appBar: const CustomAppBar(),
//       body: RefreshIndicator(
//         onRefresh: () => _onRefresh(ref),
//         child: CustomScrollView(
//           slivers: [
//             // Header com economia detalhada
//             SliverToBoxAdapter(
//               child: Padding(
//                 padding: const EdgeInsets.all(20),
//                 child: EconomyIndicators(
//                   showDetailed: true,
//                   onTap: hasPendingRewards
//                       ? () => _claimAllRewards(context, ref)
//                       : null,
//                   showLevelProgress: false,
//                 ),
//               ),
//             ),

//             // Seção de Missões
//             SliverToBoxAdapter(
//               child: Padding(
//                 padding: const EdgeInsets.symmetric(horizontal: 20),
//                 child: Row(
//                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                   children: [
//                     Text(
//                       'Suas Missões',
//                       style: theme.textTheme.headlineSmall?.copyWith(
//                         fontWeight: FontWeight.w700,
//                         color: theme.colorScheme.onSurface,
//                       ),
//                     ),
//                     TextButton.icon(
//                       onPressed: () => _navigateToMissions(context),
//                       icon: Icon(
//                         Icons.arrow_forward,
//                         size: 18,
//                         color: AppTheme.primaryColor,
//                       ),
//                       label: Text(
//                         'Ver Todas',
//                         style: TextStyle(
//                           color: AppTheme.primaryColor,
//                           fontWeight: FontWeight.w600,
//                         ),
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ),

//             // Lista de Missões
//             if (missionsState.isLoading)
//               SliverToBoxAdapter(child: _buildLoadingMissions())
//             else if (missionsState.activeMissions.isEmpty)
//               SliverToBoxAdapter(child: _buildEmptyMissions(context, theme))
//             else
//               SliverPadding(
//                 padding: const EdgeInsets.symmetric(horizontal: 20),
//                 sliver: SliverList(
//                   delegate: SliverChildBuilderDelegate((context, index) {
//                     final mission = missionsState.activeMissions[index];
//                     return Padding(
//                       padding: EdgeInsets.only(
//                         bottom: index < missionsState.activeMissions.length - 1
//                             ? 12
//                             : 0,
//                       ),
//                       child: MissionCard(
//                         mission: mission,
//                         isCompact: true,
//                         onTap: () =>
//                             _navigateToMissionDetail(context, mission.id),
//                       ),
//                     );
//                   }, childCount: missionsState.activeMissions.length),
//                 ),
//               ),

//             // Espaçamento final
//             const SliverToBoxAdapter(child: SizedBox(height: 100)),
//           ],
//         ),
//       ),
//       bottomNavigationBar: const CustomBottomNav(),
//       floatingActionButton: const FloatingActionCenter(),
//       floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
//     );
//   }

//   /// Atualizar dados
//   Future<void> _onRefresh(WidgetRef ref) async {
//     await ref.read(homeProvider.notifier).refresh();
//   }

//   /// Coletar todas as recompensas
//   void _claimAllRewards(BuildContext context, WidgetRef ref) {
//     ref.read(rewardsProvider.notifier).claimAllRewards();

//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Row(
//           children: [
//             Icon(Icons.card_giftcard, color: Colors.white),
//             const SizedBox(width: 12),
//             const Text('Coletando recompensas...'),
//           ],
//         ),
//         backgroundColor: AppTheme.successColor,
//         behavior: SnackBarBehavior.floating,
//         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//       ),
//     );
//   }

//   /// Navegar para lista de missões
//   void _navigateToMissions(BuildContext context) {
//     // Navigator.pushNamed(context, '/missions');

//     // Por ora, mostrar as missões em bottom sheet
//     showModalBottomSheet(
//       context: context,
//       backgroundColor: Colors.transparent,
//       isScrollControlled: true,
//       builder: (context) => DraggableScrollableSheet(
//         initialChildSize: 0.7,
//         maxChildSize: 0.9,
//         minChildSize: 0.5,
//         builder: (context, scrollController) => Container(
//           decoration: BoxDecoration(
//             color: Theme.of(context).colorScheme.surface,
//             borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
//           ),
//           child: Column(
//             children: [
//               // Handle
//               Container(
//                 margin: const EdgeInsets.symmetric(vertical: 12),
//                 width: 40,
//                 height: 4,
//                 decoration: BoxDecoration(
//                   color: Theme.of(
//                     context,
//                   ).colorScheme.onSurface.withOpacity(0.3),
//                   borderRadius: BorderRadius.circular(2),
//                 ),
//               ),

//               // Header
//               Padding(
//                 padding: const EdgeInsets.symmetric(
//                   horizontal: 20,
//                   vertical: 10,
//                 ),
//                 child: Row(
//                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                   children: [
//                     Text(
//                       'Todas as Missões',
//                       style: Theme.of(context).textTheme.headlineSmall
//                           ?.copyWith(fontWeight: FontWeight.w700),
//                     ),
//                     IconButton(
//                       onPressed: () => Navigator.pop(context),
//                       icon: const Icon(Icons.close),
//                     ),
//                   ],
//                 ),
//               ),

//               // Lista de missões
//               Expanded(
//                 child: Consumer(
//                   builder: (context, ref, child) {
//                     final missionsState = ref.watch(missionsProvider);

//                     return ListView.builder(
//                       controller: scrollController,
//                       padding: const EdgeInsets.all(20),
//                       itemCount: missionsState.allMissions.length,
//                       itemBuilder: (context, index) {
//                         final mission = missionsState.allMissions[index];
//                         return Padding(
//                           padding: EdgeInsets.only(
//                             bottom: index < missionsState.allMissions.length - 1
//                                 ? 12
//                                 : 0,
//                           ),
//                           child: MissionCard(
//                             mission: mission,
//                             onTap: () {
//                               Navigator.pop(context);
//                               _navigateToMissionDetail(context, mission.id);
//                             },
//                           ),
//                         );
//                       },
//                     );
//                   },
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   /// Navegar para detalhes da missão
//   void _navigateToMissionDetail(BuildContext context, String missionId) {
//     // Navigator.pushNamed(context, '/mission/detail', arguments: missionId);

//     // Por ora, mostrar em dialog
//     showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: const Text('Detalhes da Missão'),
//         content: Text('Navegação para missão $missionId será implementada'),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(context),
//             child: const Text('OK'),
//           ),
//         ],
//       ),
//     );
//   }

//   /// Construir estado de carregamento das missões
//   Widget _buildLoadingMissions() {
//     return Padding(
//       padding: const EdgeInsets.symmetric(horizontal: 20),
//       child: Column(
//         children: List.generate(
//           3,
//           (index) => Padding(
//             padding: EdgeInsets.only(bottom: index < 2 ? 12 : 0),
//             child: _buildMissionSkeleton(),
//           ),
//         ),
//       ),
//     );
//   }

//   /// Construir skeleton de missão
//   Widget _buildMissionSkeleton() {
//     return Card(
//       elevation: 2,
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
//       child: Container(
//         height: 80,
//         padding: const EdgeInsets.all(16),
//         child: Row(
//           children: [
//             Container(
//               width: 40,
//               height: 40,
//               decoration: BoxDecoration(
//                 color: Colors.grey.shade300,
//                 borderRadius: BorderRadius.circular(10),
//               ),
//             ),
//             const SizedBox(width: 12),
//             Expanded(
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 children: [
//                   Container(
//                     width: double.infinity,
//                     height: 16,
//                     decoration: BoxDecoration(
//                       color: Colors.grey.shade300,
//                       borderRadius: BorderRadius.circular(4),
//                     ),
//                   ),
//                   const SizedBox(height: 8),
//                   Container(
//                     width: 120,
//                     height: 12,
//                     decoration: BoxDecoration(
//                       color: Colors.grey.shade300,
//                       borderRadius: BorderRadius.circular(4),
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   /// Construir estado vazio das missões
//   Widget _buildEmptyMissions(BuildContext context, ThemeData theme) {
//     return Padding(
//       padding: const EdgeInsets.all(40),
//       child: Column(
//         children: [
//           Container(
//             padding: const EdgeInsets.all(24),
//             decoration: BoxDecoration(
//               color: theme.colorScheme.primaryContainer.withOpacity(0.3),
//               shape: BoxShape.circle,
//             ),
//             child: Icon(
//               Icons.assignment_outlined,
//               size: 48,
//               color: theme.colorScheme.primary,
//             ),
//           ),

//           const SizedBox(height: 20),

//           Text(
//             'Nenhuma missão disponível',
//             style: theme.textTheme.titleLarge?.copyWith(
//               fontWeight: FontWeight.w600,
//               color: theme.colorScheme.onSurface,
//             ),
//           ),

//           const SizedBox(height: 8),

//           Text(
//             'Novas missões serão geradas automaticamente.\nVolte em breve!',
//             style: theme.textTheme.bodyMedium?.copyWith(
//               color: theme.colorScheme.onSurface.withOpacity(0.7),
//             ),
//             textAlign: TextAlign.center,
//           ),

//           const SizedBox(height: 20),

//           ElevatedButton.icon(
//             onPressed: () {},
//             // onPressed: () =>  _onRefresh(ref),
//             icon: const Icon(Icons.refresh),
//             label: const Text('Atualizar'),
//             style: ElevatedButton.styleFrom(
//               backgroundColor: theme.colorScheme.primary,
//               foregroundColor: theme.colorScheme.onPrimary,
//               shape: RoundedRectangleBorder(
//                 borderRadius: BorderRadius.circular(12),
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
 