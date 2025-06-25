// lib/shared/widgets/loading_overlay.dart - WIDGET DE LOADING
import 'package:flutter/material.dart';

/// Widget de overlay de carregamento
///
/// Características:
/// - Overlay semitransparente
/// - Indicador de carregamento customizável
/// - Mensagens opcionais
/// - Cancelamento opcional
class LoadingOverlay extends StatelessWidget {
  final bool isLoading;
  final Widget child;
  final String? message;
  final Color? backgroundColor;
  final Color? indicatorColor;
  final bool canCancel;
  final VoidCallback? onCancel;
  final Widget? customIndicator;

  const LoadingOverlay({
    super.key,
    required this.isLoading,
    required this.child,
    this.message,
    this.backgroundColor,
    this.indicatorColor,
    this.canCancel = false,
    this.onCancel,
    this.customIndicator,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        if (isLoading) Positioned.fill(child: _buildLoadingOverlay(context)),
      ],
    );
  }

  Widget _buildLoadingOverlay(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      color: backgroundColor ?? theme.colorScheme.surface.withOpacity(0.8),
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: theme.shadowColor.withOpacity(0.2),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              customIndicator ??
                  SizedBox(
                    width: 40,
                    height: 40,
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                        indicatorColor ?? theme.colorScheme.primary,
                      ),
                    ),
                  ),
              if (message != null) ...[
                const SizedBox(height: 16),
                Text(
                  message!,
                  style: theme.textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
              ],
              if (canCancel && onCancel != null) ...[
                const SizedBox(height: 16),
                TextButton(onPressed: onCancel, child: const Text('Cancelar')),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
