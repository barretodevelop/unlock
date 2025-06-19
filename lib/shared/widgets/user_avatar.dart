// lib/shared/widgets/user_avatar.dart
import 'package:flutter/material.dart';
import 'package:unlock/models/user_model.dart';

/// Widget reutilizável para exibir avatar do usuário
class UserAvatar extends StatelessWidget {
  final UserModel? user;
  final double size;
  final bool showBorder;
  final bool showOnlineIndicator;
  final VoidCallback? onTap;

  const UserAvatar({
    super.key,
    required this.user,
    this.size = 48,
    this.showBorder = false,
    this.showOnlineIndicator = false,
    this.onTap,
  });

  /// Construtor para avatar pequeno
  const UserAvatar.small({
    super.key,
    required this.user,
    this.showBorder = false,
    this.showOnlineIndicator = false,
    this.onTap,
  }) : size = 32;

  /// Construtor para avatar médio
  const UserAvatar.medium({
    super.key,
    required this.user,
    this.showBorder = false,
    this.showOnlineIndicator = false,
    this.onTap,
  }) : size = 48;

  /// Construtor para avatar grande
  const UserAvatar.large({
    super.key,
    required this.user,
    this.showBorder = true,
    this.showOnlineIndicator = false,
    this.onTap,
  }) : size = 80;

  /// Construtor para avatar extra grande (perfil)
  const UserAvatar.extraLarge({
    super.key,
    required this.user,
    this.showBorder = true,
    this.showOnlineIndicator = false,
    this.onTap,
  }) : size = 120;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: Stack(
        children: [
          // Avatar principal
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: showBorder
                  ? Border.all(
                      color: colorScheme.primary.withOpacity(0.3),
                      width: 2,
                    )
                  : null,
              boxShadow: showBorder
                  ? [
                      BoxShadow(
                        color: colorScheme.shadow.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
            child: ClipOval(child: _buildAvatarContent(context)),
          ),

          // Indicador online
          if (showOnlineIndicator)
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                width: size * 0.3,
                height: size * 0.3,
                decoration: BoxDecoration(
                  color: Colors.green,
                  shape: BoxShape.circle,
                  border: Border.all(color: colorScheme.surface, width: 2),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAvatarContent(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (user == null) {
      return _buildDefaultAvatar(context);
    }

    // Se tem avatar personalizado (emoji ou imagem)
    if (user!.avatar.isNotEmpty) {
      // Verificar se é emoji (1-2 caracteres)
      if (user!.avatar.length <= 2 && _isEmoji(user!.avatar)) {
        return Container(
          color: colorScheme.surfaceVariant,
          child: Center(
            child: Text(user!.avatar, style: TextStyle(fontSize: size * 0.4)),
          ),
        );
      }

      // Se é URL de imagem
      if (user!.avatar.startsWith('http')) {
        return Image.network(
          user!.avatar,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return _buildDefaultAvatar(context);
          },
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Container(
              color: colorScheme.surfaceVariant,
              child: Center(
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation(colorScheme.primary),
                ),
              ),
            );
          },
        );
      }
    }

    // Avatar baseado nas iniciais do nome
    return _buildInitialsAvatar(context);
  }

  Widget _buildDefaultAvatar(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      color: colorScheme.surfaceVariant,
      child: Icon(
        Icons.person,
        size: size * 0.5,
        color: colorScheme.onSurfaceVariant,
      ),
    );
  }

  Widget _buildInitialsAvatar(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    String initials = _getInitials();

    return Container(
      color: colorScheme.primary.withOpacity(0.1),
      child: Center(
        child: Text(
          initials,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontSize: size * 0.35,
            fontWeight: FontWeight.w600,
            color: colorScheme.primary,
          ),
        ),
      ),
    );
  }

  String _getInitials() {
    if (user == null) return '?';

    // Usar codinome se disponível
    String name = user!.codinome?.isNotEmpty == true
        ? user!.codinome!
        : user!.username;

    if (name.isEmpty) return '?';

    List<String> parts = name.split(' ');
    if (parts.isEmpty) return '?';

    if (parts.length == 1) {
      return parts[0][0].toUpperCase();
    }

    return (parts[0][0] + parts[1][0]).toUpperCase();
  }

  bool _isEmoji(String text) {
    // Verificação simples para emoji
    final emojiRegex = RegExp(
      r'[\u{1f300}-\u{1f5ff}\u{1f900}-\u{1f9ff}\u{1f600}-\u{1f64f}'
      r'\u{1f680}-\u{1f6ff}\u{2600}-\u{26ff}\u{2700}-\u{27bf}]',
      unicode: true,
    );
    return emojiRegex.hasMatch(text);
  }
}

/// Widget para avatar com nível
class UserAvatarWithLevel extends StatelessWidget {
  final UserModel user;
  final double size;
  final bool showBorder;

  const UserAvatarWithLevel({
    super.key,
    required this.user,
    this.size = 48,
    this.showBorder = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        UserAvatar(user: user, size: size, showBorder: showBorder),

        // Badge do nível
        Positioned(
          right: -4,
          top: -4,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: colorScheme.secondary,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: colorScheme.surface, width: 1),
            ),
            child: Text(
              '${user.level}',
              style: theme.textTheme.labelSmall?.copyWith(
                color: colorScheme.onSecondary,
                fontWeight: FontWeight.bold,
                fontSize: 10,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
