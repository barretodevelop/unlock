// lib/features/home/widgets/custom_app_bar.dart
// AppBar personalizada da home - Fase 3

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:unlock/features/home/providers/home_provider.dart';
import 'package:unlock/features/rewards/providers/rewards_provider.dart';
import 'package:unlock/providers/auth_provider.dart';
import 'package:unlock/core/theme/app_theme.dart';

/// AppBar personalizada com informações do usuário e economia
class CustomAppBar extends ConsumerWidget implements PreferredSizeWidget {
  const CustomAppBar({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final authState = ref.watch(authProvider);
    final homeState = ref.watch(homeProvider);
    final hasPendingRewards = ref.watch(hasPendingRewardsProvider);

    if (!authState.isAuthenticated || authState.user == null) {
      return AppBar(
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
        title: Text(
          'Unlock',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.primary,
          ),
        ),
      );
    }

    final user = authState.user!;
    final userStats = homeState.userStats;

    return AppBar(
      backgroundColor: theme.colorScheme.surface,
      elevation: 0,
      automaticallyImplyLeading: false,
      toolbarHeight: kToolbarHeight,
      title: Row(
        children: [
          // Avatar do usuário
          _buildUserAvatar(context, user),
          
          const SizedBox(width: 12),
          
          // Informações do usuário
          Expanded(
            child: _buildUserInfo(context, theme, user, userStats),
          ),
        ],
      ),
      actions: [
        // Indicadores de economia
        _buildEconomyIndicators(context, theme, user, hasPendingRewards),
        
        const SizedBox(width: 8),
        
        // Botão de configurações
        _buildSettingsButton(context, theme),
        
        const SizedBox(width: 16),
      ],
    );
  }

  /// Construir avatar do usuário
  Widget _buildUserAvatar(BuildContext context, user) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.primary,
            Theme.of(context).colorScheme.secondary,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipOval(
        child: user.avatar?.isNotEmpty == true
            ? (user.avatar!.startsWith('http')
                ? Image.network(
                    user.avatar!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _buildAvatarFallback(context),
                  )
                : _buildEmojiAvatar(context, user.avatar!))
            : _buildAvatarFallback(context),
      ),
    );
  }

  /// Avatar fallback
  Widget _buildAvatarFallback(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      color: Theme.of(context).colorScheme.primaryContainer,
      child: Icon(
        Icons.person,
        color: Theme.of(context).colorScheme.onPrimaryContainer,
        size: 24,
      ),
    );
  }

  /// Avatar emoji
  Widget _buildEmojiAvatar(BuildContext context, String emoji) {
    return Container(
      width: 40,
      height: 40,
      color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
      child: Center(
        child: Text(
          emoji,
          style: const TextStyle(fontSize: 20),
        ),
      ),
    );
  }

  /// Construir informações do usuário
  Widget _buildUserInfo(
    BuildContext context,
    ThemeData theme,
    user,
    Map<String, dynamic> userStats,
  ) {
    final level = userStats['level'] ?? 1;
    final title = userStats['title'] ?? 'Novato';
    final levelProgress = userStats['levelProgress'] ?? 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Nome e nível
        Row(
          children: [
            Flexible(
              child: Text(
                user.codinome?.isNotEmpty == true 
                    ? user.codinome! 
                    : user.displayName,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: theme.colorScheme.primary.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Text(
                'Nv $level',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 2),
        
        // Título e barra de progresso
        Row(
          children: [
            Text(
              title,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.7),
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Container(
                height: 4,
                decoration: BoxDecoration(
                  color: theme.colorScheme.onSurface.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(2),
                ),
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: levelProgress.clamp(0.0, 1.0),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          theme.colorScheme.primary,
                          theme.colorScheme.secondary,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Construir indicadores de economia
  Widget _buildEconomyIndicators(
    BuildContext context,
    ThemeData theme,
    user,
    bool hasPendingRewards,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant.withOpacity(0.5),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // XP
          _buildEconomyItem(
            context,
            '⚡',
            _formatNumber(user.xp),
            AppTheme.xpColor,
          ),
          
          const SizedBox(width: 8),
          
          // Coins
          _buildEconomyItem(
            context,
            '🪙',
            _formatNumber(user.coins),
            AppTheme.coinsColor,
          ),
          
          const SizedBox(width: 8),
          
          // Gems
          _buildEconomyItem(
            context,
            '💎',
            _formatNumber(user.gems),
            AppTheme.gemsColor,
          ),
          
          // Badge de recompensas pendentes
          if (hasPendingRewards) ...[
            const SizedBox(width: 8),
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: AppTheme.errorColor,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.errorColor.withOpacity(0.5),
                    blurRadius: 4,
                    spreadRadius: 1,
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Construir item individual da economia
  Widget _buildEconomyItem(
    BuildContext context,
    String icon,
    String value,
    Color color,
  ) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          icon,
          style: const TextStyle(fontSize: 12),
        ),
        const SizedBox(width: 2),
        Text(
          value,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  /// Construir botão de configurações
  Widget _buildSettingsButton(BuildContext context, ThemeData theme) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant.withOpacity(0.5),
        shape: BoxShape.circle,
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: IconButton(
        onPressed: () => _onSettingsPressed(context),
        icon: Icon(
          Icons.settings_outlined,
          color: theme.colorScheme.onSurface.withOpacity(0.7),
          size: 20,
        ),
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(),
      ),
    );
  }

  /// Ação do botão configurações
  void _onSettingsPressed(BuildContext context) {
    // Implementar navegação para configurações
    // Navigator.pushNamed(context, '/settings');
    
    // Por ora, mostrar bottom sheet simples
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.person_outline),
              title: const Text('Editar Perfil'),
              onTap: () {
                Navigator.pop(context);
                // Navigator.pushNamed(context, '/profile/edit');
              },
            ),
            ListTile(
              leading: const Icon(Icons.palette_outlined),
              title: const Text('Tema'),
              onTap: () {
                Navigator.pop(context);
                // Implementar troca de tema
              },
            ),
            ListTile(
              leading: const Icon(Icons.notifications_outlined),
              title: const Text('Notificações'),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.help_outline),
              title: const Text('Ajuda'),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: Icon(
                Icons.logout,
                color: Theme.of(context).colorScheme.error,
              ),
              title: Text(
                'Sair',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.error,
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                _showLogoutDialog(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  /// Mostrar diálogo de logout
  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sair do App'),
        content: const Text('Tem certeza que deseja sair?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // Implementar logout
              // ref.read(authProvider.notifier).signOut();
            },
            child: Text(
              'Sair',
              style: TextStyle(
                color: Theme.of(context).colorScheme.error,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Formatar números grandes
  String _formatNumber(int number) {
    if (number < 1000) return number.toString();
    if (number < 1000000) {
      final k = number / 1000;
      return k % 1 == 0 ? '${k.toInt()}K' : '${k.toStringAsFixed(1)}K';
    }
    final m = number / 1000000;
    return m % 1 == 0 ? '${m.toInt()}M' : '${m.toStringAsFixed(1)}M';
  }
}