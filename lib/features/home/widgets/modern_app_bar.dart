// lib/features/home/widgets/modern_app_bar.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:unlock/features/home/widgets/settings_bottom_sheet.dart';
import 'package:unlock/models/user_model.dart';
import 'package:unlock/providers/auth_provider.dart';
import 'package:unlock/shared/widgets/avatar_circle.dart';

/// 🎯 AppBar Moderna e Reutilizável com Animações
class ModernAppBar extends ConsumerWidget implements PreferredSizeWidget {
  final String? title;
  final String? subtitle;
  final bool showAvatar;
  final bool showNotifications;
  final bool showSettings;
  final bool isElevated;
  final List<Widget>? actions;
  final VoidCallback? onAvatarTap;
  final VoidCallback? onNotificationTap;
  final VoidCallback? onSettingsTap;

  const ModernAppBar({
    super.key,
    this.title,
    this.subtitle,
    this.showAvatar = true,
    this.showNotifications = true,
    this.showSettings = true,
    this.isElevated = false,
    this.actions,
    this.onAvatarTap,
    this.onNotificationTap,
    this.onSettingsTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider.select((state) => state.user));

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      child: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: isElevated
            ? Theme.of(context).colorScheme.surface.withOpacity(0.95)
            : Colors.transparent,
        elevation: isElevated ? 8 : 0,
        scrolledUnderElevation: 0,
        flexibleSpace: isElevated ? _buildGlassEffect(context) : null,

        // 👤 Leading com avatar do usuário
        leading: showAvatar && user != null
            ? _buildAvatarButton(context, user)
            : null,

        // 🏆 Título central
        title: _buildTitle(context, user),
        centerTitle: false,

        // ⚙️ Actions customizáveis
        actions: _buildActions(context),
      ),
    );
  }

  /// 👤 Botão do avatar
  Widget _buildAvatarButton(BuildContext context, UserModel user) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Hero(
        tag: 'user_avatar_${user.uid}',
        child: GestureDetector(
          onTap: onAvatarTap ?? () => context.push('/profile'),
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: AvatarCircle(imageUrl: user.avatar),
          ),
        ),
      ),
    );
  }

  /// 🏆 Widget do título
  Widget _buildTitle(BuildContext context, UserModel? user) {
    final displayTitle = title ?? 'ClashUp';
    final displaySubtitle =
        subtitle ??
        (user != null ? 'Olá, ${user.displayName.split(' ').first}! 👋' : null);

    return AnimatedOpacity(
      opacity: isElevated ? 1.0 : 0.9,
      duration: const Duration(milliseconds: 300),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            displayTitle,
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          if (displaySubtitle != null && !isElevated)
            Text(
              displaySubtitle,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
        ],
      ),
    );
  }

  /// ⚙️ Construir actions
  List<Widget> _buildActions(BuildContext context) {
    final List<Widget> actionWidgets = [];

    // Actions customizadas primeiro
    if (actions != null) {
      actionWidgets.addAll(actions!);
    }

    // 🔔 Botão de notificações
    if (showNotifications) {
      actionWidgets.add(
        _buildAnimatedIconButton(
          context: context,
          icon: Icons.notifications_outlined,
          tooltip: 'Notificações',
          onPressed: onNotificationTap ?? () => _showNotifications(context),
        ),
      );
    }

    // ⚙️ Botão de configurações
    if (showSettings) {
      actionWidgets.add(
        _buildAnimatedIconButton(
          context: context,
          icon: Icons.settings_outlined,
          tooltip: 'Configurações',
          onPressed: onSettingsTap ?? () => _showSettings(context),
        ),
      );
    }

    // Espaçamento final
    if (actionWidgets.isNotEmpty) {
      actionWidgets.add(const SizedBox(width: 8));
    }

    return actionWidgets;
  }

  /// 🎯 Botão de ícone animado
  Widget _buildAnimatedIconButton({
    required BuildContext context,
    required IconData icon,
    required String tooltip,
    required VoidCallback onPressed,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 600),
      curve: Curves.elasticOut,
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: Container(
            margin: const EdgeInsets.only(right: 4),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: Colors.transparent,
            ),
            child: IconButton(
              icon: Icon(icon),
              tooltip: tooltip,
              onPressed: onPressed,
              style: IconButton.styleFrom(
                backgroundColor: Colors.transparent,
                foregroundColor: Theme.of(context).colorScheme.onSurface,
                padding: const EdgeInsets.all(12),
              ),
            ),
          ),
        );
      },
    );
  }

  /// ✨ Efeito glass no AppBar
  Widget _buildGlassEffect(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Theme.of(context).colorScheme.surface.withOpacity(0.9),
            Theme.of(context).colorScheme.surface.withOpacity(0.7),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).shadowColor.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
    );
  }

  /// 🔔 Mostrar notificações
  void _showNotifications(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              Icons.notifications,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 12),
            const Text('Notificações'),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.info_outline, color: Colors.blue),
              title: Text('Sistema em desenvolvimento'),
              subtitle: Text('Notificações serão implementadas em breve!'),
              contentPadding: EdgeInsets.zero,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  /// ⚙️ Mostrar configurações
  void _showSettings(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const SettingsBottomSheet(),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

/// 🎯 Variantes específicas do AppBar

/// AppBar para Home
class HomeAppBar extends ModernAppBar {
  const HomeAppBar({super.key, bool isElevated = false})
    : super(
        title: 'ClashUp',
        isElevated: isElevated,
        showAvatar: true,
        showNotifications: true,
        showSettings: true,
      );
}

/// AppBar para páginas internas
class InternalAppBar extends ModernAppBar {
  const InternalAppBar({
    super.key,
    required String title,
    String? subtitle,
    bool showBack = true,
    List<Widget>? actions,
  }) : super(
         title: title,
         subtitle: subtitle,
         showAvatar: false,
         showNotifications: false,
         showSettings: false,
         actions: actions,
         isElevated: true,
       );
}

/// AppBar para perfil
class ProfileAppBar extends ModernAppBar {
  const ProfileAppBar({super.key, String? userName, bool isElevated = false})
    : super(
        title: userName ?? 'Perfil',
        isElevated: isElevated,
        showAvatar: false,
        showNotifications: true,
        showSettings: true,
      );
}

/// AppBar minimalista
class MinimalAppBar extends ModernAppBar {
  const MinimalAppBar({super.key, String? title, List<Widget>? actions})
    : super(
        title: title,
        showAvatar: false,
        showNotifications: false,
        showSettings: false,
        actions: actions,
        isElevated: false,
      );
}
