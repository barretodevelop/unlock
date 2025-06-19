// lib/features/settings/widgets/settings_tile.dart
import 'package:flutter/material.dart';

/// Widget reutilizável para opções de configuração
class SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool enabled;
  final Color? iconColor;

  const SettingsTile({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.enabled = true,
    this.iconColor,
  });

  /// Construtor para tile com switch
  SettingsTile.switchTile({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    this.enabled = true,
    this.iconColor,
  }) : trailing = _SwitchWidget(
         value: value,
         onChanged: onChanged,
         enabled: enabled,
       ),
       onTap = null;

  /// Construtor para tile com navegação
  const SettingsTile.navigation({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    required this.onTap,
    this.enabled = true,
    this.iconColor,
  }) : trailing = const Icon(Icons.chevron_right, size: 20);

  /// Construtor para tile de ação (como logout)
  const SettingsTile.action({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    required this.onTap,
    this.enabled = true,
    this.iconColor,
  }) : trailing = null;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Material(
        color: enabled
            ? colorScheme.surface
            : colorScheme.surface.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
        elevation: 1,
        child: InkWell(
          onTap: enabled ? onTap : null,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                // Ícone
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: (iconColor ?? colorScheme.primary).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    icon,
                    color: enabled
                        ? (iconColor ?? colorScheme.primary)
                        : colorScheme.onSurface.withOpacity(0.4),
                    size: 20,
                  ),
                ),

                const SizedBox(width: 16),

                // Título e subtítulo
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: enabled
                              ? colorScheme.onSurface
                              : colorScheme.onSurface.withOpacity(0.4),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          subtitle!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: enabled
                                ? colorScheme.onSurface.withOpacity(0.7)
                                : colorScheme.onSurface.withOpacity(0.4),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                // Widget à direita (switch, seta, etc)
                if (trailing != null) ...[const SizedBox(width: 16), trailing!],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Widget interno para switch
class _SwitchWidget extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;
  final bool enabled;

  const _SwitchWidget({
    required this.value,
    required this.onChanged,
    required this.enabled,
  });

  @override
  Widget build(BuildContext context) {
    return Switch.adaptive(
      value: value,
      onChanged: enabled ? onChanged : null,
      activeColor: Theme.of(context).colorScheme.primary,
    );
  }
}

/// Widget para seção de configurações
class SettingsSection extends StatelessWidget {
  final String? title;
  final List<Widget> children;
  final EdgeInsets? padding;

  const SettingsSection({
    super.key,
    this.title,
    required this.children,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: padding ?? const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: Text(
                title!,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
          ...children,
        ],
      ),
    );
  }
}
