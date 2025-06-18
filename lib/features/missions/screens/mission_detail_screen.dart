// lib/features/missions/screens/mission_detail_screen.dart
// Tela de detalhes da missão - Fase 3

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:unlock/core/theme/app_theme.dart';
import 'package:unlock/features/missions/models/mission_model.dart';
import 'package:unlock/features/missions/providers/missions_provider.dart';
import 'package:unlock/features/missions/widgets/progress_indicator.dart';
import 'package:unlock/providers/auth_provider.dart';

/// Tela de detalhes de uma missão específica
class MissionDetailScreen extends ConsumerStatefulWidget {
  final String missionId;

  const MissionDetailScreen({super.key, required this.missionId});

  @override
  ConsumerState<MissionDetailScreen> createState() =>
      _MissionDetailScreenState();
}

class _MissionDetailScreenState extends ConsumerState<MissionDetailScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _fadeController, curve: Curves.easeOut));

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.5), end: Offset.zero).animate(
          CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
        );

    // Iniciar animações
    _fadeController.forward();
    _slideController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final missionsState = ref.watch(missionsProvider);
    final authState = ref.watch(authProvider);

    // Encontrar a missão específica
    final mission = missionsState.allMissions
        .where((m) => m.id == widget.missionId)
        .firstOrNull;

    if (mission == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Missão'),
          backgroundColor: theme.colorScheme.surface,
        ),
        body: const Center(child: Text('Missão não encontrada')),
      );
    }

    final progress = missionsState.getMissionProgress(mission.id);
    final userProgress = missionsState.getProgress(mission.id);
    final isCompleted = progress >= 1.0;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // App Bar com gradiente
          _buildSliverAppBar(context, theme, mission, isCompleted),

          // Conteúdo principal
          SliverToBoxAdapter(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Seção de progresso
                      _buildProgressSection(
                        context,
                        theme,
                        mission,
                        progress,
                        userProgress,
                      ),

                      const SizedBox(height: 24),

                      // Descrição detalhada
                      _buildDescriptionSection(context, theme, mission),

                      const SizedBox(height: 24),

                      // Recompensas
                      _buildRewardsSection(context, theme, mission),

                      const SizedBox(height: 24),

                      // Requisitos (se houver)
                      if (mission.requirements.isNotEmpty) ...[
                        _buildRequirementsSection(context, theme, mission),
                        const SizedBox(height: 24),
                      ],

                      // Informações técnicas
                      _buildTechnicalInfoSection(context, theme, mission),

                      const SizedBox(height: 24),

                      // Ações
                      _buildActionsSection(
                        context,
                        theme,
                        ref,
                        mission,
                        isCompleted,
                      ),

                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Construir SliverAppBar com design gradiente
  Widget _buildSliverAppBar(
    BuildContext context,
    ThemeData theme,
    MissionModel mission,
    bool isCompleted,
  ) {
    return SliverAppBar(
      expandedHeight: 200,
      floating: false,
      pinned: true,
      backgroundColor: Colors.transparent,
      elevation: 0,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isCompleted
                  ? [
                      AppTheme.successColor,
                      AppTheme.successColor.withOpacity(0.8),
                    ]
                  : [
                      Color(mission.difficultyColor),
                      Color(mission.difficultyColor).withOpacity(0.8),
                    ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  // Ícone da categoria
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      mission.categoryIcon,
                      style: const TextStyle(fontSize: 32),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Título da missão
                  Text(
                    mission.title,
                    style: theme.textTheme.headlineMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      shadows: [
                        Shadow(
                          offset: const Offset(0, 2),
                          blurRadius: 4,
                          color: Colors.black.withOpacity(0.3),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Badges
                  Row(
                    children: [
                      _buildHeaderBadge(
                        mission.type.displayName,
                        Colors.white.withOpacity(0.3),
                      ),
                      const SizedBox(width: 8),
                      _buildHeaderBadge(
                        mission.difficultyText,
                        Colors.white.withOpacity(0.3),
                      ),
                      if (isCompleted) ...[
                        const SizedBox(width: 8),
                        _buildHeaderBadge(
                          'Completada',
                          AppTheme.successColor.withOpacity(0.3),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      leading: IconButton(
        icon: Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
      actions: [
        IconButton(
          icon: Icon(Icons.share, color: Colors.white),
          onPressed: () => _shareMission(context, mission),
        ),
      ],
    );
  }

  /// Construir badge do header
  Widget _buildHeaderBadge(String text, Color backgroundColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  /// Construir seção de progresso
  Widget _buildProgressSection(
    BuildContext context,
    ThemeData theme,
    MissionModel mission,
    double progress,
    UserMissionProgress? userProgress,
  ) {
    final isCompleted = progress >= 1.0;
    final currentValue = userProgress?.currentProgress ?? 0;
    final targetValue = mission.targetValue;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header da seção
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Progresso',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (isCompleted)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.successColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.check_circle,
                          color: AppTheme.successColor,
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Completada',
                          style: TextStyle(
                            color: AppTheme.successColor,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 20),

            // Progresso visual
            Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      // Indicador circular
                      CircularMissionProgress(
                        progress: progress,
                        size: 80,
                        strokeWidth: 8,
                        progressColor: isCompleted
                            ? AppTheme.successColor
                            : Color(mission.difficultyColor),
                        child: Text(
                          '$currentValue/$targetValue',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: isCompleted
                                ? AppTheme.successColor
                                : Color(mission.difficultyColor),
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),

                      const SizedBox(height: 12),

                      Text(
                        '${(progress * 100).round()}% Completo',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.onSurface.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 24),

                // Estatísticas
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildStatItem(
                        context,
                        theme,
                        'Meta',
                        '$targetValue',
                        Icons.flag,
                        AppTheme.primaryColor,
                      ),
                      const SizedBox(height: 12),
                      _buildStatItem(
                        context,
                        theme,
                        'Atual',
                        '$currentValue',
                        Icons.trending_up,
                        Color(mission.difficultyColor),
                      ),
                      const SizedBox(height: 12),
                      _buildStatItem(
                        context,
                        theme,
                        'Restante',
                        '${targetValue - currentValue}',
                        Icons.schedule,
                        theme.colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Barra de progresso linear
            MissionProgressIndicator(
              progress: progress,
              color: isCompleted
                  ? AppTheme.successColor
                  : Color(mission.difficultyColor),
              height: 8,
              label: 'Progresso Geral',
              showPercentage: true,
            ),
          ],
        ),
      ),
    );
  }

  /// Construir item de estatística
  Widget _buildStatItem(
    BuildContext context,
    ThemeData theme,
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 16),
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
            Text(
              value,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Construir seção de descrição
  Widget _buildDescriptionSection(
    BuildContext context,
    ThemeData theme,
    MissionModel mission,
  ) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Descrição',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),

            const SizedBox(height: 12),

            Text(
              mission.description,
              style: theme.textTheme.bodyLarge?.copyWith(
                height: 1.6,
                color: theme.colorScheme.onSurface.withOpacity(0.8),
              ),
            ),

            const SizedBox(height: 16),

            // Informações adicionais
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceVariant.withOpacity(0.5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: theme.colorScheme.primary,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _getMissionTip(mission),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.7),
                      ),
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

  /// Construir seção de recompensas
  Widget _buildRewardsSection(
    BuildContext context,
    ThemeData theme,
    MissionModel mission,
  ) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.card_giftcard,
                  color: AppTheme.warningColor,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  'Recompensas',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Lista de recompensas
            Row(
              children: [
                if (mission.xpReward > 0)
                  Expanded(
                    child: _buildRewardCard(
                      context,
                      theme,
                      '⚡',
                      '${mission.xpReward} XP',
                      'Experiência',
                      AppTheme.xpColor,
                    ),
                  ),
                if (mission.coinsReward > 0) ...[
                  if (mission.xpReward > 0) const SizedBox(width: 12),
                  Expanded(
                    child: _buildRewardCard(
                      context,
                      theme,
                      '🪙',
                      '${mission.coinsReward} Coins',
                      'Moedas',
                      AppTheme.coinsColor,
                    ),
                  ),
                ],
                if (mission.gemsReward > 0) ...[
                  if (mission.xpReward > 0 || mission.coinsReward > 0)
                    const SizedBox(width: 12),
                  Expanded(
                    child: _buildRewardCard(
                      context,
                      theme,
                      '💎',
                      '${mission.gemsReward} Gems',
                      'Gemas',
                      AppTheme.gemsColor,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Construir card de recompensa
  Widget _buildRewardCard(
    BuildContext context,
    ThemeData theme,
    String icon,
    String value,
    String label,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
      ),
      child: Column(
        children: [
          Text(icon, style: const TextStyle(fontSize: 24)),
          const SizedBox(height: 8),
          Text(
            value,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: color,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.7),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// Construir seção de requisitos
  Widget _buildRequirementsSection(
    BuildContext context,
    ThemeData theme,
    MissionModel mission,
  ) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Requisitos',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),

            const SizedBox(height: 12),

            ...mission.requirements.map((requirement) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Icon(
                      Icons.check_circle_outline,
                      color: AppTheme.successColor,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _getRequirementText(requirement),
                        style: theme.textTheme.bodyMedium,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  /// Construir seção de informações técnicas
  Widget _buildTechnicalInfoSection(
    BuildContext context,
    ThemeData theme,
    MissionModel mission,
  ) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Informações',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),

            const SizedBox(height: 16),

            _buildInfoRow(
              context,
              theme,
              'Categoria',
              mission.category.displayName,
            ),
            _buildInfoRow(
              context,
              theme,
              'Dificuldade',
              mission.difficultyText,
            ),
            _buildInfoRow(
              context,
              theme,
              'Criada em',
              _formatDate(mission.createdAt),
            ),
            _buildInfoRow(
              context,
              theme,
              'Expira em',
              _formatDate(mission.expiresAt),
            ),
            if (mission.hoursRemaining > 0)
              _buildInfoRow(
                context,
                theme,
                'Tempo restante',
                '${mission.hoursRemaining}h',
              ),
          ],
        ),
      ),
    );
  }

  /// Construir linha de informação
  Widget _buildInfoRow(
    BuildContext context,
    ThemeData theme,
    String label,
    String value,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
          Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  /// Construir seção de ações
  Widget _buildActionsSection(
    BuildContext context,
    ThemeData theme,
    WidgetRef ref,
    MissionModel mission,
    bool isCompleted,
  ) {
    return Column(
      children: [
        if (!isCompleted && !mission.isExpired) ...[
          // Botão principal de ação
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _startMission(context, ref, mission),
              icon: Icon(Icons.play_arrow),
              label: const Text('Começar Missão'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(mission.difficultyColor),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Botão secundário
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _showHelp(context, mission),
              icon: Icon(Icons.help_outline),
              label: const Text('Como Completar'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ] else if (isCompleted) ...[
          // Missão completada
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.successColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppTheme.successColor.withOpacity(0.3),
                width: 2,
              ),
            ),
            child: Column(
              children: [
                Icon(Icons.celebration, color: AppTheme.successColor, size: 48),
                const SizedBox(height: 12),
                Text(
                  'Missão Completada!',
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: AppTheme.successColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Parabéns! Você concluiu esta missão com sucesso.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.7),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ] else ...[
          // Missão expirada
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.errorColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppTheme.errorColor.withOpacity(0.3),
                width: 2,
              ),
            ),
            child: Column(
              children: [
                Icon(Icons.schedule, color: AppTheme.errorColor, size: 48),
                const SizedBox(height: 12),
                Text(
                  'Missão Expirada',
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: AppTheme.errorColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Esta missão expirou e não pode mais ser completada.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.7),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  /// Obter dica da missão
  String _getMissionTip(MissionModel mission) {
    switch (mission.category) {
      case MissionCategory.social:
        return 'Dica: Interaja com outros usuários para completar missões sociais mais rapidamente.';
      case MissionCategory.profile:
        return 'Dica: Mantenha seu perfil atualizado para desbloquear mais oportunidades.';
      case MissionCategory.exploration:
        return 'Dica: Explore diferentes seções do app para descobrir novos recursos.';
      case MissionCategory.gamification:
        return 'Dica: Complete missões diárias para maximizar seus ganhos de XP.';
    }
  }

  /// Obter texto do requisito
  String _getRequirementText(String requirement) {
    const requirementTexts = {
      'has_incomplete_profile': 'Perfil incompleto',
      'has_viewed_profiles': 'Já visualizou outros perfis',
      'has_connections': 'Possui conexões ativas',
      'has_unlocked_minigames': 'Minijogos desbloqueados',
      'has_shop_access': 'Acesso à loja liberado',
      'has_active_connection': 'Possui conexão ativa',
      'has_multiple_connections': 'Possui múltiplas conexões',
    };

    return requirementTexts[requirement] ?? requirement;
  }

  /// Formatar data
  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = date.difference(now);

    if (difference.inDays > 0) {
      return '${difference.inDays} dias';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} horas';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minutos';
    } else {
      return 'Agora';
    }
  }

  /// Compartilhar missão
  void _shareMission(BuildContext context, MissionModel mission) {
    // Implementar compartilhamento
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Compartilhamento de "${mission.title}" será implementado',
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  /// Iniciar missão
  void _startMission(
    BuildContext context,
    WidgetRef ref,
    MissionModel mission,
  ) {
    // Implementar lógica para iniciar missão
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Iniciando missão: ${mission.title}'),
        backgroundColor: Color(mission.difficultyColor),
        duration: const Duration(seconds: 2),
      ),
    );

    // Navegar de volta ou para tela específica da missão
    Navigator.pop(context);
  }

  /// Mostrar ajuda
  void _showHelp(BuildContext context, MissionModel mission) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Como Completar',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 16),
              Text(
                _getHelpText(mission),
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Entendi'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Obter texto de ajuda
  String _getHelpText(MissionModel mission) {
    switch (mission.category) {
      case MissionCategory.social:
        return 'Para completar missões sociais, você precisa interagir com outros usuários através de convites, mensagens ou minijogos colaborativos.';
      case MissionCategory.profile:
        return 'Missões de perfil requerem que você atualize ou personalize informações do seu perfil, como avatar, interesses ou descrição.';
      case MissionCategory.exploration:
        return 'Missões de exploração incentivam você a descobrir diferentes áreas do app e experimentar novos recursos disponíveis.';
      case MissionCategory.gamification:
        return 'Missões de gamificação focam em ganhar XP, completar outras missões ou atingir marcos específicos no jogo.';
    }
  }
}
