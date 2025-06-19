// lib/features/profile/widgets/profile_header.dart
import 'package:flutter/material.dart';
import 'package:unlock/models/user_model.dart';
import 'package:unlock/shared/widgets/user_avatar.dart';

/// Widget do cabeçalho do perfil com avatar e informações básicas
class ProfileHeader extends StatelessWidget {
  final UserModel user;
  final VoidCallback? onAvatarTap;
  final VoidCallback? onEditTap;
  final bool showEditButton;
  final bool showLevel;

  const ProfileHeader({
    super.key,
    required this.user,
    this.onAvatarTap,
    this.onEditTap,
    this.showEditButton = true,
    this.showLevel = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [colorScheme.primary, colorScheme.primary.withOpacity(0.8)],
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: Column(
        children: [
          // Avatar com botão de edição
          Stack(
            children: [
              UserAvatar.extraLarge(
                user: user,
                showBorder: true,
                onTap: onAvatarTap,
              ),

              // Botão de editar avatar
              if (onAvatarTap != null)
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: colorScheme.surface,
                      shape: BoxShape.circle,
                      border: Border.all(color: colorScheme.primary, width: 2),
                    ),
                    child: Icon(
                      Icons.camera_alt,
                      size: 16,
                      color: colorScheme.primary,
                    ),
                  ),
                ),
            ],
          ),

          const SizedBox(height: 16),

          // Nome/Codinome
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                child: Text(
                  _getDisplayName(),
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: colorScheme.onPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              if (showEditButton && onEditTap != null) ...[
                const SizedBox(width: 8),
                IconButton(
                  onPressed: onEditTap,
                  icon: Icon(
                    Icons.edit,
                    color: colorScheme.onPrimary.withOpacity(0.8),
                    size: 20,
                  ),
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ],
          ),

          const SizedBox(height: 8),

          // Email
          Text(
            user.email,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onPrimary.withOpacity(0.8),
            ),
            textAlign: TextAlign.center,
          ),

          if (showLevel) ...[
            const SizedBox(height: 12),

            // Level badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: colorScheme.onPrimary.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: colorScheme.onPrimary.withOpacity(0.3),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.military_tech,
                    color: colorScheme.onPrimary,
                    size: 16,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Level ${user.level}',
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: colorScheme.onPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _getDisplayName() {
    if (user.codinome?.isNotEmpty == true) {
      return user.codinome!;
    }
    return user.username.isNotEmpty ? user.username : 'Usuário';
  }
}

/// Header compacto para profile
class CompactProfileHeader extends StatelessWidget {
  final UserModel user;
  final VoidCallback? onTap;

  const CompactProfileHeader({super.key, required this.user, this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outline.withOpacity(0.2)),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Row(
          children: [
            UserAvatar.medium(user: user, showBorder: true),

            const SizedBox(width: 16),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.codinome?.isNotEmpty == true
                        ? user.codinome!
                        : user.username,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Level ${user.level} • ${user.xp} XP',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ),

            if (onTap != null)
              Icon(
                Icons.chevron_right,
                color: colorScheme.onSurface.withOpacity(0.5),
              ),
          ],
        ),
      ),
    );
  }
}

/// Header do perfil com estatísticas inline
class ProfileHeaderWithStats extends StatelessWidget {
  final UserModel user;
  final VoidCallback? onAvatarTap;
  final bool showEditButton;

  const ProfileHeaderWithStats({
    super.key,
    required this.user,
    this.onAvatarTap,
    this.showEditButton = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outline.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          // Linha principal com avatar e info
          Row(
            children: [
              UserAvatar.large(
                user: user,
                showBorder: true,
                onTap: onAvatarTap,
              ),

              const SizedBox(width: 16),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.codinome?.isNotEmpty == true
                          ? user.codinome!
                          : user.username,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      user.email,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: colorScheme.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Level ${user.level}',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Estatísticas em linha
          Row(
            children: [
              Expanded(
                child: _StatItem(
                  icon: Icons.auto_awesome,
                  label: 'XP',
                  value: _formatNumber(user.xp),
                  color: Colors.purple,
                ),
              ),
              Expanded(
                child: _StatItem(
                  icon: Icons.monetization_on,
                  label: 'Coins',
                  value: _formatNumber(user.coins),
                  color: Colors.orange,
                ),
              ),
              Expanded(
                child: _StatItem(
                  icon: Icons.diamond,
                  label: 'Gems',
                  value: _formatNumber(user.gems),
                  color: Colors.cyan,
                ),
              ),
            ],
          ),
        ],
      ),
    );
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

/// Widget interno para item de estatística
class _StatItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface.withOpacity(0.7),
          ),
        ),
      ],
    );
  }
}
