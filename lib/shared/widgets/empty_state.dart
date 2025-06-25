// lib/shared/widgets/empty_state.dart - WIDGET DE ESTADO VAZIO
import 'package:flutter/material.dart';

/// Widget para exibir estados vazios
///
/// Características:
/// - Ícone e mensagem customizáveis
/// - Ação opcional
/// - Diferentes variantes visuais
class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;
  final EmptyStateVariant variant;
  final Color? iconColor;
  final double iconSize;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.actionLabel,
    this.onAction,
    this.variant = EmptyStateVariant.normal,
    this.iconColor,
    this.iconSize = 64,
  });

  /// Construtor para estado de erro
  factory EmptyState.error({
    required String title,
    String? subtitle,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    return EmptyState(
      icon: Icons.error_outline,
      title: title,
      subtitle: subtitle,
      actionLabel: actionLabel,
      onAction: onAction,
      variant: EmptyStateVariant.error,
    );
  }

  /// Construtor para estado de busca vazia
  factory EmptyState.search({
    String title = 'Nenhum resultado encontrado',
    String? subtitle = 'Tente ajustar os filtros de busca',
  }) {
    return EmptyState(
      icon: Icons.search_off,
      title: title,
      subtitle: subtitle,
      variant: EmptyStateVariant.search,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectiveIconColor = iconColor ?? _getVariantColor(theme);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: effectiveIconColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: iconSize, color: effectiveIconColor),
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 8),
              Text(
                subtitle!,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.7),
                ),
                textAlign: TextAlign.center,
              ),
            ],
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 24),
              ElevatedButton(onPressed: onAction, child: Text(actionLabel!)),
            ],
          ],
        ),
      ),
    );
  }

  Color _getVariantColor(ThemeData theme) {
    switch (variant) {
      case EmptyStateVariant.normal:
        return theme.colorScheme.primary;
      case EmptyStateVariant.error:
        return theme.colorScheme.error;
      case EmptyStateVariant.search:
        return theme.colorScheme.outline;
    }
  }
}

/// Variantes do EmptyState
enum EmptyStateVariant { normal, error, search }
