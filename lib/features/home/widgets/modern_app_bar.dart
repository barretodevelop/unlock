// lib/features/home/widgets/modern_app_bar.dart
import 'package:flutter/material.dart';
import 'package:unlock/core/constants/app_constants.dart';
import 'package:unlock/models/user_model.dart';
import 'package:unlock/shared/widgets/avatar_circle.dart';

/// AppBar moderna com elevação dinâmica e animações suaves
class ModernAppBar extends StatelessWidget implements PreferredSizeWidget {
  final UserModel user;
  final bool showElevated;
  final VoidCallback? onNotificationsTap;
  final VoidCallback? onProfileTap;

  const ModernAppBar({
    super.key,
    required this.user,
    required this.showElevated,
    this.onNotificationsTap,
    this.onProfileTap,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: AppConstants.animationDuration,
      curve: Curves.easeInOut,
      child: AppBar(
        // Título animado
        title: AnimatedOpacity(
          opacity: showElevated ? 1.0 : 0.0,
          duration: AppConstants.animationDuration,
          child: Row(
            children: [
              // Logo/ícone do app
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Theme.of(context).colorScheme.primary,
                      Theme.of(context).colorScheme.secondary,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.flash_on,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),

              // Título
              Text(
                'ClashUp',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),

        // Configurações de estilo
        backgroundColor: showElevated
            ? Theme.of(context).colorScheme.surface
            : Colors.transparent,
        elevation: showElevated ? 2 : 0,
        scrolledUnderElevation: 2,
        shadowColor: Theme.of(context).shadowColor.withOpacity(0.1),

        // Leading personalizado (opcional)
        leading: showElevated
            ? Padding(
                padding: const EdgeInsets.only(left: 16),
                child: Center(
                  child: AvatarCircle(
                    imageUrl: user.avatar.startsWith('http')
                        ? user.avatar
                        : null,
                    fallbackText: user.avatar.startsWith('http')
                        ? null
                        : user.avatar,
                    radius: 16,
                  ),
                ),
              )
            : null,

        // Actions na AppBar
        actions: [
          // Botão de notificações
          _buildNotificationButton(context),

          // Botão de perfil (quando não elevated)
          if (!showElevated) _buildProfileButton(context),

          const SizedBox(width: 8),
        ],

        // Configurações de sistema
        systemOverlayStyle: showElevated
            ? Theme.of(context).appBarTheme.systemOverlayStyle
            : null,
      ),
    );
  }

  /// Botão de notificações com badge
  Widget _buildNotificationButton(BuildContext context) {
    return Stack(
      children: [
        IconButton(
          onPressed: onNotificationsTap,
          icon: Icon(
            Icons.notifications_outlined,
            color: showElevated
                ? Theme.of(context).colorScheme.onSurface
                : Colors.white.withOpacity(0.9),
          ),
          tooltip: 'Notificações',
        ),

        // Badge de notificações não lidas
        if (_hasUnreadNotifications())
          Positioned(
            right: 8,
            top: 8,
            child: Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.error,
                shape: BoxShape.circle,
              ),
            ),
          ),
      ],
    );
  }

  /// Botão de perfil (quando AppBar não elevated)
  Widget _buildProfileButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: IconButton(
        onPressed: onProfileTap,
        icon: AvatarCircle(
          imageUrl: user.avatar.startsWith('http') ? user.avatar : null,
          fallbackText: user.avatar.startsWith('http') ? null : user.avatar,
          radius: 16,
        ),
        tooltip: 'Perfil',
      ),
    );
  }

  /// Verificar se há notificações não lidas (mock)
  bool _hasUnreadNotifications() {
    // TODO: Implementar lógica real de notificações
    return DateTime.now().second % 2 == 0; // Mock para demonstração
  }
}

/// Variante da AppBar para outras telas
class ModernAppBarVariant extends StatelessWidget
    implements PreferredSizeWidget {
  final String title;
  final bool showBackButton;
  final List<Widget>? actions;
  final Widget? leading;

  const ModernAppBarVariant({
    super.key,
    required this.title,
    this.showBackButton = true,
    this.actions,
    this.leading,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(
        title,
        style: Theme.of(
          context,
        ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
      ),

      leading: leading ?? (showBackButton ? _buildBackButton(context) : null),

      actions: actions,

      backgroundColor: Theme.of(context).colorScheme.surface,
      elevation: 1,
      shadowColor: Theme.of(context).shadowColor.withOpacity(0.1),

      centerTitle: true,
    );
  }

  /// Botão de voltar customizado
  Widget _buildBackButton(BuildContext context) {
    return IconButton(
      onPressed: () => Navigator.maybePop(context),
      icon: Icon(
        Icons.arrow_back_ios_new,
        color: Theme.of(context).colorScheme.onSurface,
        size: 20,
      ),
      tooltip: 'Voltar',
    );
  }
}

/// AppBar para telas secundárias com gradiente
class GradientAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Color>? gradientColors;
  final List<Widget>? actions;
  final bool showBackButton;

  const GradientAppBar({
    super.key,
    required this.title,
    this.gradientColors,
    this.actions,
    this.showBackButton = true,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final colors =
        gradientColors ??
        [
          Theme.of(context).colorScheme.primary,
          Theme.of(context).colorScheme.secondary,
        ];

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: colors,
        ),
      ),
      child: AppBar(
        title: Text(
          title,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),

        leading: showBackButton
            ? IconButton(
                onPressed: () => Navigator.maybePop(context),
                icon: const Icon(
                  Icons.arrow_back_ios_new,
                  color: Colors.white,
                  size: 20,
                ),
                tooltip: 'Voltar',
              )
            : null,

        actions: actions?.map((action) {
          if (action is IconButton) {
            return IconButton(
              onPressed: action.onPressed,
              icon: IconTheme(
                data: const IconThemeData(color: Colors.white),
                child: action.icon,
              ),
              tooltip: action.tooltip,
            );
          }
          return action;
        }).toList(),

        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
    );
  }
}
