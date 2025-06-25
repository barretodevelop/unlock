// lib/shared/widgets/themed_card.dart - WIDGET CARD TEMÁTICO
import 'package:flutter/material.dart';

/// Widget de card que segue o tema da aplicação
///
/// Características:
/// - Adaptação automática ao tema claro/escuro
/// - Variações de elevação e estilo
/// - Padding e margin customizáveis
/// - Suporte a headers e footers
class ThemedCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Color? backgroundColor;
  final double? elevation;
  final BorderRadiusGeometry? borderRadius;
  final Border? border;
  final VoidCallback? onTap;
  final Widget? header;
  final Widget? footer;
  final bool showShadow;
  final ThemedCardVariant variant;

  const ThemedCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.backgroundColor,
    this.elevation,
    this.borderRadius,
    this.border,
    this.onTap,
    this.header,
    this.footer,
    this.showShadow = true,
    this.variant = ThemedCardVariant.normal,
  });

  /// Construtor para card elevado
  factory ThemedCard.elevated({
    required Widget child,
    EdgeInsetsGeometry? padding,
    EdgeInsetsGeometry? margin,
    VoidCallback? onTap,
    Widget? header,
    Widget? footer,
  }) {
    return ThemedCard(
      child: child,
      padding: padding,
      margin: margin,
      onTap: onTap,
      header: header,
      footer: footer,
      variant: ThemedCardVariant.elevated,
    );
  }

  /// Construtor para card plano
  factory ThemedCard.flat({
    required Widget child,
    EdgeInsetsGeometry? padding,
    EdgeInsetsGeometry? margin,
    VoidCallback? onTap,
    Widget? header,
    Widget? footer,
  }) {
    return ThemedCard(
      child: child,
      padding: padding,
      margin: margin,
      onTap: onTap,
      header: header,
      footer: footer,
      variant: ThemedCardVariant.flat,
      showShadow: false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    Widget cardContent = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (header != null) ...[header!, const Divider(height: 1)],
        Padding(padding: padding ?? _getDefaultPadding(), child: child),
        if (footer != null) ...[const Divider(height: 1), footer!],
      ],
    );

    Widget card = Container(
      margin: margin,
      decoration: _buildDecoration(context),
      child: cardContent,
    );

    if (onTap != null) {
      card = InkWell(
        onTap: onTap,
        borderRadius:
            borderRadius as BorderRadius? ??
            BorderRadius.circular(_getDefaultBorderRadius()),
        child: card,
      );
    }

    return card;
  }

  /// Obter padding padrão
  EdgeInsetsGeometry _getDefaultPadding() {
    switch (variant) {
      case ThemedCardVariant.flat:
        return const EdgeInsets.all(12);
      case ThemedCardVariant.normal:
        return const EdgeInsets.all(16);
      case ThemedCardVariant.elevated:
        return const EdgeInsets.all(20);
    }
  }

  /// Obter border radius padrão
  double _getDefaultBorderRadius() {
    switch (variant) {
      case ThemedCardVariant.flat:
        return 8;
      case ThemedCardVariant.normal:
        return 12;
      case ThemedCardVariant.elevated:
        return 16;
    }
  }

  /// Construir decoração
  BoxDecoration _buildDecoration(BuildContext context) {
    final theme = Theme.of(context);

    return BoxDecoration(
      color: backgroundColor ?? theme.colorScheme.surface,
      borderRadius:
          borderRadius ?? BorderRadius.circular(_getDefaultBorderRadius()),
      border:
          border ??
          Border.all(
            color: theme.colorScheme.outline.withOpacity(0.2),
            width: variant == ThemedCardVariant.flat ? 1 : 0,
          ),
      boxShadow: showShadow && variant != ThemedCardVariant.flat
          ? [
              BoxShadow(
                color: theme.shadowColor.withOpacity(
                  variant == ThemedCardVariant.elevated ? 0.15 : 0.08,
                ),
                blurRadius: variant == ThemedCardVariant.elevated ? 12 : 6,
                offset: Offset(
                  0,
                  variant == ThemedCardVariant.elevated ? 4 : 2,
                ),
              ),
            ]
          : null,
    );
  }
}

/// Variantes do ThemedCard
enum ThemedCardVariant { flat, normal, elevated }
