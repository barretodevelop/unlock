// lib/features/profile/screens/profile_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:unlock/core/utils/logger.dart';
import 'package:unlock/features/profile/providers/profile_provider.dart';
import 'package:unlock/shared/widgets/stat_card.dart';
import 'package:unlock/shared/widgets/user_avatar.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final profileState = ref.watch(profileProvider);

    if (profileState.user == null) {
      return Scaffold(
        backgroundColor: colorScheme.background,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final user = profileState.user!;

    return Scaffold(
      backgroundColor: colorScheme.background,
      body: CustomScrollView(
        slivers: [
          // AppBar expansível
          SliverAppBar(
            expandedHeight: 200,
            floating: false,
            pinned: true,
            backgroundColor: colorScheme.primary,
            leading: IconButton(
              icon: Icon(Icons.arrow_back, color: colorScheme.onPrimary),
              onPressed: () => context.pop(),
            ),
            actions: [
              IconButton(
                icon: Icon(Icons.settings, color: colorScheme.onPrimary),
                onPressed: () => context.push('/settings'),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      colorScheme.primary,
                      colorScheme.primary.withOpacity(0.8),
                    ],
                  ),
                ),
                child: SafeArea(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 40),
                      // Avatar principal
                      UserAvatar.extraLarge(
                        user: user,
                        showBorder: true,
                        onTap: () => _showAvatarOptions(context, ref),
                      ),
                      const SizedBox(height: 12),
                      // Nome/Codinome
                      Text(
                        user.codinome?.isNotEmpty == true
                            ? user.codinome!
                            : user.username,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          color: colorScheme.onPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      // Level
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: colorScheme.onPrimary.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'Level ${user.level}',
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: colorScheme.onPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Conteúdo principal
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Estatísticas
                  _buildStatsSection(context, user, ref),

                  const SizedBox(height: 24),

                  // Progresso XP
                  _buildXPProgressSection(context, user, ref),

                  const SizedBox(height: 24),

                  // Informações pessoais
                  _buildPersonalInfoSection(context, user, theme),

                  const SizedBox(height: 24),

                  // Interesses
                  _buildInterestsSection(context, user, theme),

                  const SizedBox(height: 24),

                  // Ações rápidas
                  _buildQuickActionsSection(context, ref, theme),

                  // Espaçamento inferior
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Seção de estatísticas
  Widget _buildStatsSection(BuildContext context, user, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Estatísticas',
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 16),
        StatsRow(
          level: user.level,
          xp: user.xp,
          coins: user.coins,
          gems: user.gems,
          isAnimated: true,
          onXpTap: () => _showXPDetails(context, user),
          onCoinsTap: () => _showCoinsDetails(context, user),
          onGemsTap: () => _showGemsDetails(context, user),
          onLevelTap: () => _showLevelDetails(context, user),
        ),
      ],
    );
  }

  /// Seção de progresso XP
  Widget _buildXPProgressSection(BuildContext context, user, WidgetRef ref) {
    final profileNotifier = ref.read(profileProvider.notifier);
    final progress = profileNotifier.progressToNextLevel;
    final xpNeeded = profileNotifier.xpNeededForNextLevel;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outline.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Progresso para Level ${user.level + 1}',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                '${(progress * 100).toInt()}%',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: progress,
            backgroundColor: colorScheme.surfaceVariant,
            valueColor: AlwaysStoppedAnimation(colorScheme.primary),
            minHeight: 8,
          ),
          const SizedBox(height: 8),
          Text(
            'Faltam $xpNeeded XP para o próximo level',
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  /// Seção de informações pessoais
  Widget _buildPersonalInfoSection(
    BuildContext context,
    user,
    ThemeData theme,
  ) {
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outline.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Informações',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),

          // Email
          _buildInfoRow(
            icon: Icons.email,
            label: 'Email',
            value: user.email,
            theme: theme,
          ),

          const SizedBox(height: 12),

          // Idade
          if (user.age != null)
            _buildInfoRow(
              icon: Icons.cake,
              label: 'Idade',
              value: '${user.age} anos',
              theme: theme,
            ),

          if (user.age != null) const SizedBox(height: 12),

          // Objetivo
          if (user.relationshipGoal?.isNotEmpty == true)
            _buildInfoRow(
              icon: Icons.favorite,
              label: 'Objetivo',
              value: user.relationshipGoal!,
              theme: theme,
            ),

          if (user.relationshipGoal?.isNotEmpty == true)
            const SizedBox(height: 12),

          // Membro desde
          _buildInfoRow(
            icon: Icons.calendar_today,
            label: 'Membro desde',
            value: _formatDate(user.createdAt),
            theme: theme,
          ),
        ],
      ),
    );
  }

  /// Seção de interesses
  Widget _buildInterestsSection(BuildContext context, user, ThemeData theme) {
    final colorScheme = theme.colorScheme;

    if (user.interesses.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outline.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Interesses',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: user.interesses.map<Widget>((interesse) {
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: colorScheme.primary.withOpacity(0.3),
                  ),
                ),
                child: Text(
                  interesse,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  /// Seção de ações rápidas
  Widget _buildQuickActionsSection(
    BuildContext context,
    WidgetRef ref,
    ThemeData theme,
  ) {
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outline.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Ações',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _editProfile(context, ref),
                  icon: const Icon(Icons.edit, size: 18),
                  label: const Text('Editar'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.primary,
                    foregroundColor: colorScheme.onPrimary,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _refreshProfile(context, ref),
                  icon: const Icon(Icons.refresh, size: 18),
                  label: const Text('Atualizar'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Widget para linha de informação
  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    required ThemeData theme,
  }) {
    final colorScheme = theme.colorScheme;

    return Row(
      children: [
        Icon(icon, size: 20, color: colorScheme.primary),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
              Text(
                value,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Formatar data
  String _formatDate(DateTime date) {
    final months = [
      'Jan',
      'Fev',
      'Mar',
      'Abr',
      'Mai',
      'Jun',
      'Jul',
      'Ago',
      'Set',
      'Out',
      'Nov',
      'Dez',
    ];

    return '${months[date.month - 1]} ${date.year}';
  }

  /// Mostrar opções de avatar
  void _showAvatarOptions(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Escolher emoji'),
              onTap: () {
                Navigator.pop(context);
                _showEmojiPicker(context, ref);
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Tirar foto'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Implementar captura de foto
              },
            ),
          ],
        ),
      ),
    );
  }

  /// Mostrar seletor de emoji
  void _showEmojiPicker(BuildContext context, WidgetRef ref) {
    final emojis = [
      '😀',
      '😎',
      '🤔',
      '😴',
      '🥳',
      '🤓',
      '😇',
      '🙃',
      '😊',
      '🤗',
      '👨‍💻',
      '👩‍💻',
      '🧙‍♂️',
      '🧙‍♀️',
      '🦸‍♂️',
      '🦸‍♀️',
    ];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Escolha um emoji'),
        content: Wrap(
          children: emojis.map((emoji) {
            return GestureDetector(
              onTap: () {
                ref.read(profileProvider.notifier).updateAvatar(emoji);
                Navigator.pop(context);
              },
              child: Container(
                margin: const EdgeInsets.all(4),
                padding: const EdgeInsets.all(8),
                child: Text(emoji, style: const TextStyle(fontSize: 24)),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  /// Editar perfil
  void _editProfile(BuildContext context, WidgetRef ref) {
    ref.read(profileProvider.notifier).startEditing();
    // TODO: Navegar para tela de edição
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Edição de perfil em desenvolvimento')),
    );
  }

  /// Atualizar perfil
  Future<void> _refreshProfile(BuildContext context, WidgetRef ref) async {
    try {
      await ref.read(profileProvider.notifier).refresh();
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Perfil atualizado')));
      }
    } catch (e) {
      AppLogger.error('❌ ProfileScreen: Erro ao atualizar: $e');
    }
  }

  /// Mostrar detalhes de XP
  void _showXPDetails(BuildContext context, user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Experience Points'),
        content: Text('Você tem ${user.xp} XP total.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  /// Mostrar detalhes de moedas
  void _showCoinsDetails(BuildContext context, user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Coins'),
        content: Text('Você tem ${user.coins} moedas.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  /// Mostrar detalhes de gemas
  void _showGemsDetails(BuildContext context, user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Gems'),
        content: Text('Você tem ${user.gems} gemas.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  /// Mostrar detalhes de level
  void _showLevelDetails(BuildContext context, user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Level'),
        content: Text('Você está no level ${user.level}.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
