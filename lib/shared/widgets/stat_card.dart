// lib/shared/widgets/stat_card.dart - WIDGET CARD DE ESTATÍSTICAS
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// Widget para exibir estatísticas com animações
///
/// Características:
/// - Animações suaves de entrada
/// - Suporte a ícones e gradientes
/// - Diferentes variantes de layout
/// - Tap handlers opcionais
class StatCard extends StatelessWidget {
  final String title;
  final String value;
  final String? subtitle;
  final IconData? icon;
  final Color? color;
  final Gradient? gradient;
  final VoidCallback? onTap;
  final StatCardVariant variant;
  final bool showAnimation;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;

  const StatCard({
    super.key,
    required this.title,
    required this.value,
    this.subtitle,
    this.icon,
    this.color,
    this.gradient,
    this.onTap,
    this.variant = StatCardVariant.normal,
    this.showAnimation = true,
    this.padding,
    this.margin,
  });

  /// Construtor para estatística compacta
  factory StatCard.compact({
    required String title,
    required String value,
    IconData? icon,
    Color? color,
    VoidCallback? onTap,
  }) {
    return StatCard(
      title: title,
      value: value,
      icon: icon,
      color: color,
      onTap: onTap,
      variant: StatCardVariant.compact,
    );
  }

  /// Construtor para estatística destacada
  factory StatCard.featured({
    required String title,
    required String value,
    String? subtitle,
    IconData? icon,
    Gradient? gradient,
    VoidCallback? onTap,
  }) {
    return StatCard(
      title: title,
      value: value,
      subtitle: subtitle,
      icon: icon,
      gradient: gradient,
      onTap: onTap,
      variant: StatCardVariant.featured,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectiveColor = color ?? theme.colorScheme.primary;

    Widget card = Container(
      margin: margin,
      padding: padding ?? _getDefaultPadding(),
      decoration: _buildDecoration(context, effectiveColor),
      child: _buildContent(context, effectiveColor),
    );

    if (onTap != null) {
      card = InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(_getBorderRadius()),
        child: card,
      );
    }

    if (showAnimation) {
      card = card
          .animate()
          .fadeIn(duration: 300.ms, curve: Curves.easeOut)
          .slideY(begin: 0.2, end: 0, duration: 300.ms, curve: Curves.easeOut)
          .scale(
            begin: Offset(0.95, 0.95),
            end: Offset(1.0, 1.0),
            duration: 300.ms,
            curve: Curves.easeOut,
          );
    }

    return card;
  }

  /// Obter padding padrão baseado na variante
  EdgeInsetsGeometry _getDefaultPadding() {
    switch (variant) {
      case StatCardVariant.compact:
        return const EdgeInsets.all(12);
      case StatCardVariant.normal:
        return const EdgeInsets.all(16);
      case StatCardVariant.featured:
        return const EdgeInsets.all(20);
    }
  }

  /// Obter border radius
  double _getBorderRadius() {
    switch (variant) {
      case StatCardVariant.compact:
        return 8;
      case StatCardVariant.normal:
        return 12;
      case StatCardVariant.featured:
        return 16;
    }
  }

  /// Construir decoração do container
  BoxDecoration _buildDecoration(BuildContext context, Color effectiveColor) {
    final theme = Theme.of(context);

    return BoxDecoration(
      gradient: gradient,
      color: gradient == null ? theme.colorScheme.surface : null,
      borderRadius: BorderRadius.circular(_getBorderRadius()),
      border: Border.all(
        color: theme.colorScheme.outline.withOpacity(0.2),
        width: 1,
      ),
      boxShadow: [
        BoxShadow(
          color: theme.shadowColor.withOpacity(0.1),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ],
    );
  }

  /// Construir conteúdo do card
  Widget _buildContent(BuildContext context, Color effectiveColor) {
    switch (variant) {
      case StatCardVariant.compact:
        return _buildCompactContent(context, effectiveColor);
      case StatCardVariant.normal:
        return _buildNormalContent(context, effectiveColor);
      case StatCardVariant.featured:
        return _buildFeaturedContent(context, effectiveColor);
    }
  }

  /// Conteúdo compacto
  Widget _buildCompactContent(BuildContext context, Color effectiveColor) {
    final theme = Theme.of(context);
    final textColor = gradient != null
        ? Colors.white
        : theme.colorScheme.onSurface;

    return Row(
      children: [
        if (icon != null) ...[
          Icon(
            icon,
            color: gradient != null ? Colors.white : effectiveColor,
            size: 20,
          ),
          const SizedBox(width: 8),
        ],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: textColor.withOpacity(0.7),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: theme.textTheme.titleSmall?.copyWith(
                  color: textColor,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Conteúdo normal
  Widget _buildNormalContent(BuildContext context, Color effectiveColor) {
    final theme = Theme.of(context);
    final textColor = gradient != null
        ? Colors.white
        : theme.colorScheme.onSurface;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                color: gradient != null ? Colors.white : effectiveColor,
                size: 24,
              ),
              const SizedBox(width: 8),
            ],
            Expanded(
              child: Text(
                title,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: textColor.withOpacity(0.7),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: theme.textTheme.headlineSmall?.copyWith(
            color: textColor,
            fontWeight: FontWeight.bold,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 4),
          Text(
            subtitle!,
            style: theme.textTheme.bodySmall?.copyWith(
              color: textColor.withOpacity(0.6),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ],
    );
  }

  /// Conteúdo destacado
  Widget _buildFeaturedContent(BuildContext context, Color effectiveColor) {
    final theme = Theme.of(context);
    final textColor = gradient != null
        ? Colors.white
        : theme.colorScheme.onSurface;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            if (icon != null) ...[
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: (gradient != null ? Colors.white : effectiveColor)
                      .withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: gradient != null ? Colors.white : effectiveColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: textColor.withOpacity(0.8),
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          value,
          style: theme.textTheme.headlineMedium?.copyWith(
            color: textColor,
            fontWeight: FontWeight.bold,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 6),
          Text(
            subtitle!,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: textColor.withOpacity(0.7),
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ],
    );
  }
}

/// Variantes do StatCard
enum StatCardVariant { compact, normal, featured }
