// lib/shared/widgets/themed_card.dart
import 'package:flutter/material.dart';

/// Card genérico que segue o tema do app
class ThemedCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final EdgeInsets? margin;
  final VoidCallback? onTap;
  final Color? backgroundColor;
  final Color? borderColor;
  final double? borderRadius;
  final double? elevation;
  final bool showBorder;
  final bool showShadow;

  const ThemedCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.onTap,
    this.backgroundColor,
    this.borderColor,
    this.borderRadius,
    this.elevation,
    this.showBorder = true,
    this.showShadow = true,
  });

  /// Construtor para card com padding padrão
  const ThemedCard.padded({
    super.key,
    required this.child,
    this.margin,
    this.onTap,
    this.backgroundColor,
    this.borderColor,
    this.borderRadius,
    this.elevation,
    this.showBorder = true,
    this.showShadow = true,
  }) : padding = const EdgeInsets.all(16);

  /// Construtor para card pequeno
  const ThemedCard.small({
    super.key,
    required this.child,
    this.margin,
    this.onTap,
    this.backgroundColor,
    this.borderColor,
    this.elevation,
    this.showBorder = true,
    this.showShadow = true,
  }) : padding = const EdgeInsets.all(12),
       borderRadius = 8;

  /// Construtor para card médio
  const ThemedCard.medium({
    super.key,
    required this.child,
    this.margin,
    this.onTap,
    this.backgroundColor,
    this.borderColor,
    this.elevation,
    this.showBorder = true,
    this.showShadow = true,
  }) : padding = const EdgeInsets.all(16),
       borderRadius = 12;

  /// Construtor para card grande
  const ThemedCard.large({
    super.key,
    required this.child,
    this.margin,
    this.onTap,
    this.backgroundColor,
    this.borderColor,
    this.elevation,
    this.showBorder = true,
    this.showShadow = true,
  }) : padding = const EdgeInsets.all(20),
       borderRadius = 16;

  /// Construtor para card sem bordas
  const ThemedCard.flat({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.onTap,
    this.backgroundColor,
    this.borderRadius,
    this.elevation,
  }) : borderColor = null,
       showBorder = false,
       showShadow = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final effectiveBackgroundColor = backgroundColor ?? colorScheme.surface;
    final effectiveBorderColor =
        borderColor ?? colorScheme.outline.withOpacity(0.2);
    final effectiveBorderRadius = borderRadius ?? 12.0;
    final effectiveElevation = elevation ?? (showShadow ? 1.0 : 0.0);
    final effectivePadding = padding ?? const EdgeInsets.all(16);

    Widget cardContent = Container(
      margin: margin,
      padding: effectivePadding,
      decoration: BoxDecoration(
        color: effectiveBackgroundColor,
        borderRadius: BorderRadius.circular(effectiveBorderRadius),
        border: showBorder
            ? Border.all(color: effectiveBorderColor, width: 1)
            : null,
        boxShadow: showShadow
            ? [
                BoxShadow(
                  color: colorScheme.shadow.withOpacity(0.08),
                  blurRadius: effectiveElevation * 4,
                  offset: Offset(0, effectiveElevation),
                ),
              ]
            : null,
      ),
      child: child,
    );

    // Se tem onTap, tornar clicável
    if (onTap != null) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(effectiveBorderRadius),
          child: cardContent,
        ),
      );
    }

    return cardContent;
  }
}

/// Card com header e conteúdo
class ThemedCardWithHeader extends StatelessWidget {
  final String? title;
  final Widget? titleWidget;
  final Widget? trailing;
  final Widget child;
  final EdgeInsets? padding;
  final EdgeInsets? margin;
  final VoidCallback? onTap;
  final VoidCallback? onHeaderTap;
  final Color? backgroundColor;
  final Color? borderColor;
  final double? borderRadius;
  final bool showBorder;
  final bool showShadow;

  const ThemedCardWithHeader({
    super.key,
    this.title,
    this.titleWidget,
    this.trailing,
    required this.child,
    this.padding,
    this.margin,
    this.onTap,
    this.onHeaderTap,
    this.backgroundColor,
    this.borderColor,
    this.borderRadius,
    this.showBorder = true,
    this.showShadow = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ThemedCard(
      padding: EdgeInsets.zero,
      margin: margin,
      onTap: onTap,
      backgroundColor: backgroundColor,
      borderColor: borderColor,
      borderRadius: borderRadius,
      showBorder: showBorder,
      showShadow: showShadow,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          if (title != null || titleWidget != null) ...[
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onHeaderTap,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(borderRadius ?? 12),
                  topRight: Radius.circular(borderRadius ?? 12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Expanded(
                        child:
                            titleWidget ??
                            Text(
                              title!,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                      ),
                      if (trailing != null) ...[
                        const SizedBox(width: 8),
                        trailing!,
                      ],
                    ],
                  ),
                ),
              ),
            ),

            // Divider
            Divider(
              height: 1,
              thickness: 1,
              color: theme.colorScheme.outline.withOpacity(0.1),
            ),
          ],

          // Conteúdo
          Padding(padding: padding ?? const EdgeInsets.all(16), child: child),
        ],
      ),
    );
  }
}

/// Card de status/informação
class ThemedInfoCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final Color? iconColor;
  final Color? backgroundColor;

  const ThemedInfoCard({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.iconColor,
    this.backgroundColor,
  });

  /// Construtor para card de sucesso
  const ThemedInfoCard.success({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
  }) : iconColor = Colors.green,
       backgroundColor = null;

  /// Construtor para card de aviso
  const ThemedInfoCard.warning({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
  }) : iconColor = Colors.orange,
       backgroundColor = null;

  /// Construtor para card de erro
  const ThemedInfoCard.error({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
  }) : iconColor = Colors.red,
       backgroundColor = null;

  /// Construtor para card de informação
  const ThemedInfoCard.info({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
  }) : iconColor = Colors.blue,
       backgroundColor = null;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final effectiveIconColor = iconColor ?? colorScheme.primary;

    return ThemedCard.medium(
      onTap: onTap,
      backgroundColor: backgroundColor,
      child: Row(
        children: [
          // Ícone
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: effectiveIconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: effectiveIconColor, size: 20),
          ),

          const SizedBox(width: 16),

          // Texto
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Trailing
          if (trailing != null) ...[const SizedBox(width: 16), trailing!],
        ],
      ),
    );
  }
}

/// Card de ação
class ThemedActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;
  final Color? color;
  final bool isDestructive;

  const ThemedActionCard({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    required this.onTap,
    this.color,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final effectiveColor = isDestructive
        ? colorScheme.error
        : (color ?? colorScheme.primary);

    return ThemedCard.medium(
      onTap: onTap,
      child: Row(
        children: [
          Icon(icon, color: effectiveColor, size: 24),

          const SizedBox(width: 16),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w500,
                    color: effectiveColor,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                ],
              ],
            ),
          ),

          Icon(
            Icons.chevron_right,
            color: effectiveColor.withOpacity(0.6),
            size: 20,
          ),
        ],
      ),
    );
  }
}
