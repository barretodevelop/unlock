// lib/features/navigation/widgets/floating_action_center.dart
// Floating Action Button central personalizado - Fase 3

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:unlock/core/theme/app_theme.dart';
import 'package:unlock/features/navigation/providers/navigation_provider.dart';

/// Floating Action Button central com design personalizado
class FloatingActionCenter extends ConsumerStatefulWidget {
  const FloatingActionCenter({super.key});

  @override
  ConsumerState<FloatingActionCenter> createState() =>
      _FloatingActionCenterState();
}

class _FloatingActionCenterState extends ConsumerState<FloatingActionCenter>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _rotationController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();

    // Animação de pulso
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Animação de rotação
    _rotationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _rotationAnimation =
        Tween<double>(
          begin: 0.0,
          end: 0.125, // 45 graus
        ).animate(
          CurvedAnimation(parent: _rotationController, curve: Curves.easeInOut),
        );

    // Iniciar pulso contínuo
    _startPulse();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _rotationController.dispose();
    super.dispose();
  }

  void _startPulse() {
    _pulseController.repeat(reverse: true);
  }

  void _stopPulse() {
    _pulseController.stop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final navigationState = ref.watch(navigationProvider);
    final isVisible = navigationState.isFloatingButtonVisible;
    final route = navigationState.floatingButtonRoute;

    if (!isVisible) {
      return const SizedBox.shrink();
    }

    return AnimatedBuilder(
      animation: Listenable.merge([_pulseAnimation, _rotationAnimation]),
      builder: (context, child) {
        return Transform.scale(
          scale: _pulseAnimation.value,
          child: Transform.rotate(
            angle: _rotationAnimation.value * 2 * 3.14159,
            child: Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [AppTheme.primaryColor, AppTheme.secondaryColor],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryColor.withOpacity(0.4),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                  BoxShadow(
                    color: AppTheme.primaryColor.withOpacity(0.2),
                    blurRadius: 40,
                    offset: const Offset(0, 16),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => _onPressed(context, route),
                  onTapDown: (_) => _onTapDown(),
                  onTapUp: (_) => _onTapUp(),
                  onTapCancel: () => _onTapUp(),
                  borderRadius: BorderRadius.circular(32),
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withOpacity(0.3),
                        width: 2,
                      ),
                    ),
                    child: Center(
                      child: Icon(
                        Icons.connect_without_contact,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  /// Ação quando pressionado
  void _onPressed(BuildContext context, String? route) {
    // Feedback haptic
    // HapticFeedback.mediumImpact();

    // Animação de feedback
    _pulseController.forward().then((_) {
      _pulseController.reverse();
    });

    // Executar ação
    if (route != null) {
      _navigateToRoute(context, route);
    } else {
      _showConnectAction(context);
    }
  }

  /// Ação ao começar a pressionar
  void _onTapDown() {
    _stopPulse();
    _rotationController.forward();
  }

  /// Ação ao soltar
  void _onTapUp() {
    _rotationController.reverse();
    _startPulse();
  }

  /// Navegar para rota
  void _navigateToRoute(BuildContext context, String route) {
    // Navigator.pushNamed(context, route);

    // Por ora, mostrar placeholder
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.connect_without_contact, color: Colors.white),
            const SizedBox(width: 12),
            Text('Navegando para: $route'),
          ],
        ),
        backgroundColor: AppTheme.primaryColor,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  /// Mostrar ação de conectar
  void _showConnectAction(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _ConnectActionSheet(),
    );
  }
}

/// Bottom sheet com opções de conexão
class _ConnectActionSheet extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.onSurface.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            const SizedBox(height: 20),

            // Título
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppTheme.primaryColor, AppTheme.secondaryColor],
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    Icons.connect_without_contact,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Conectar-se',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        'Encontre pessoas incríveis!',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Opções de conexão
            _buildConnectionOption(
              context,
              theme,
              '🎯',
              'Busca Inteligente',
              'Encontre pessoas com interesses similares',
              () => _onConnectionOption(context, 'smart_search'),
            ),

            const SizedBox(height: 12),

            _buildConnectionOption(
              context,
              theme,
              '📍',
              'Próximos de Você',
              'Conecte-se com pessoas da sua região',
              () => _onConnectionOption(context, 'nearby'),
            ),

            const SizedBox(height: 12),

            _buildConnectionOption(
              context,
              theme,
              '🎲',
              'Surpresa',
              'Deixe o acaso decidir sua próxima conexão',
              () => _onConnectionOption(context, 'random'),
            ),

            const SizedBox(height: 20),

            // Botão fechar
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Fechar'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Construir opção de conexão
  Widget _buildConnectionOption(
    BuildContext context,
    ThemeData theme,
    String emoji,
    String title,
    String description,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceVariant.withOpacity(0.5),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: theme.colorScheme.outline.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(emoji, style: const TextStyle(fontSize: 24)),
            ),

            const SizedBox(width: 16),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    description,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ),

            Icon(
              Icons.arrow_forward_ios,
              color: theme.colorScheme.onSurface.withOpacity(0.4),
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  /// Ação ao selecionar opção de conexão
  void _onConnectionOption(BuildContext context, String option) {
    Navigator.pop(context);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Opção "$option" selecionada'),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}

/// Variação simples do FAB
class SimpleFloatingActionCenter extends ConsumerWidget {
  final VoidCallback? onPressed;
  final String? tooltip;

  const SimpleFloatingActionCenter({super.key, this.onPressed, this.tooltip});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final navigationState = ref.watch(navigationProvider);
    final isVisible = navigationState.isFloatingButtonVisible;

    if (!isVisible) {
      return const SizedBox.shrink();
    }

    return FloatingActionButton(
      onPressed: onPressed ?? () => _defaultAction(context),
      tooltip: tooltip ?? 'Conectar',
      backgroundColor: AppTheme.primaryColor,
      foregroundColor: Colors.white,
      elevation: 8,
      child: const Icon(Icons.connect_without_contact),
    );
  }

  void _defaultAction(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Funcionalidade de conexão será implementada'),
        duration: Duration(seconds: 2),
      ),
    );
  }
}

/// FAB com design de material extendido
class ExtendedFloatingActionCenter extends ConsumerWidget {
  final String label;
  final IconData icon;
  final VoidCallback? onPressed;

  const ExtendedFloatingActionCenter({
    super.key,
    this.label = 'Conectar',
    this.icon = Icons.connect_without_contact,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final navigationState = ref.watch(navigationProvider);
    final isVisible = navigationState.isFloatingButtonVisible;

    if (!isVisible) {
      return const SizedBox.shrink();
    }

    return FloatingActionButton.extended(
      onPressed: onPressed ?? () => _defaultAction(context),
      icon: Icon(icon),
      label: Text(label),
      backgroundColor: AppTheme.primaryColor,
      foregroundColor: Colors.white,
      elevation: 8,
    );
  }

  void _defaultAction(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Funcionalidade de conexão será implementada'),
        duration: Duration(seconds: 2),
      ),
    );
  }
}
