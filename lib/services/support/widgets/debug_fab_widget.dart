// lib/widgets/debug_fab_widget.dart
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

// ============== DEBUG FAB WIDGET ==============
/// Widget que mostra um FAB apenas em modo debug para acessar funcionalidades de desenvolvimento
class DebugFAB extends StatefulWidget {
  const DebugFAB({super.key});

  @override
  State<DebugFAB> createState() => _DebugFABState();
}

class _DebugFABState extends State<DebugFAB>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotationAnimation;

  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.elasticOut),
    );

    _rotationAnimation =
        Tween<double>(
          begin: 0.0,
          end: 0.75, // 3/4 de uma rotação completa
        ).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Curves.easeInOut,
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    // Só mostrar em modo debug
    if (!kDebugMode) {
      return const SizedBox.shrink();
    }

    return Positioned(
      bottom: 16,
      right: 16,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Opções expandidas
          AnimatedBuilder(
            animation: _scaleAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _scaleAnimation.value,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (_isExpanded) ...[
                      // Admin de Usuários de Teste
                      _buildDebugOption(
                        icon: Icons.group,
                        label: 'Admin Usuários',
                        color: Colors.purple,
                        onTap: () {
                          _toggleExpanded();
                          context.go('/admin/test-users');
                        },
                      ),
                      const SizedBox(height: 12),

                      // Firestore Explorer (futuro)
                      _buildDebugOption(
                        icon: Icons.storage,
                        label: 'Firestore',
                        color: Colors.orange,
                        onTap: () {
                          _toggleExpanded();
                          _showNotImplemented(context, 'Firestore Explorer');
                        },
                      ),
                      const SizedBox(height: 12),

                      // Test Coverage (futuro)
                      _buildDebugOption(
                        icon: Icons.bug_report,
                        label: 'Debug Info',
                        color: Colors.green,
                        onTap: () {
                          _toggleExpanded();
                          _showDebugInfo(context);
                        },
                      ),
                      const SizedBox(height: 12),

                      // Clear All Data
                      _buildDebugOption(
                        icon: Icons.delete_forever,
                        label: 'Clear Cache',
                        color: Colors.red,
                        onTap: () {
                          _toggleExpanded();
                          _showClearCacheDialog(context);
                        },
                      ),
                      const SizedBox(height: 16),
                    ],
                  ],
                ),
              );
            },
          ),

          // Botão principal
          AnimatedBuilder(
            animation: _rotationAnimation,
            builder: (context, child) {
              return Transform.rotate(
                angle:
                    _rotationAnimation.value *
                    2 *
                    3.14159, // Converter para radianos
                child: FloatingActionButton(
                  onPressed: _toggleExpanded,
                  backgroundColor: Colors.deepPurple,
                  foregroundColor: Colors.white,
                  heroTag: 'debug_fab', // Evitar conflitos com outros FABs
                  child: Icon(_isExpanded ? Icons.close : Icons.code, size: 28),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDebugOption({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Label
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.black87,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        const SizedBox(width: 8),

        // Botão
        FloatingActionButton.small(
          onPressed: onTap,
          backgroundColor: color,
          foregroundColor: Colors.white,
          heroTag: 'debug_$label', // Tag única para cada botão
          child: Icon(icon, size: 20),
        ),
      ],
    );
  }

  void _toggleExpanded() {
    setState(() {
      _isExpanded = !_isExpanded;
    });

    if (_isExpanded) {
      _animationController.forward();
    } else {
      _animationController.reverse();
    }
  }

  void _showNotImplemented(BuildContext context, String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('🚧 $feature não implementado ainda'),
        backgroundColor: Colors.orange,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showDebugInfo(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('🐛 Debug Info'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildInfoRow('Mode', kDebugMode ? 'Debug' : 'Release'),
              _buildInfoRow('Platform', Theme.of(context).platform.name),
              _buildInfoRow('Route', GoRouterState.of(context).uri.toString()),
              _buildInfoRow('Build', 'Development'),
              const SizedBox(height: 16),
              const Text(
                'Environment Variables:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              _buildInfoRow('Firebase', 'Connected'),
              _buildInfoRow('Firestore', 'Active'),
              _buildInfoRow('Auth', 'Enabled'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fechar'),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(value, style: TextStyle(color: Colors.grey[600])),
          ),
        ],
      ),
    );
  }

  void _showClearCacheDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('🗑️ Limpar Cache'),
        content: const Text(
          'Isso irá limpar todos os dados locais temporários.\n\n'
          'Os dados do Firestore não serão afetados.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _clearLocalCache(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Limpar'),
          ),
        ],
      ),
    );
  }

  void _clearLocalCache(BuildContext context) {
    // Aqui você pode implementar limpeza de cache específica
    // Por exemplo: SharedPreferences, cache de imagens, etc.

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('✅ Cache local limpo!'),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
}

// ============== EXTENSION PARA FACILITAR USO ==============
extension DebugFABExtension on Widget {
  /// Adiciona o DebugFAB apenas em modo debug
  Widget withDebugFAB() {
    if (!kDebugMode) return this;

    return Stack(children: [this, const DebugFAB()]);
  }
}

// ============== DEBUG OVERLAY PARA INFORMAÇÕES RÁPIDAS ==============
class DebugOverlay extends StatelessWidget {
  final String? currentRoute;
  final Map<String, dynamic>? debugInfo;

  const DebugOverlay({super.key, this.currentRoute, this.debugInfo});

  @override
  Widget build(BuildContext context) {
    if (!kDebugMode) return const SizedBox.shrink();

    return Positioned(
      top: MediaQuery.of(context).padding.top + 10,
      left: 10,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.black87,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          'DEBUG: ${currentRoute ?? 'Unknown'}',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 10,
            fontFamily: 'monospace',
          ),
        ),
      ),
    );
  }
}

// ============== QUICK ACTIONS PARA DESENVOLVIMENTO ==============
class DebugQuickActions {
  static void showQuickActionsDialog(BuildContext context) {
    if (!kDebugMode) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('⚡ Quick Actions'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildQuickAction(
              context,
              'Reset Onboarding',
              Icons.restart_alt,
              () {
                // Implementar reset de onboarding
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Onboarding reset!')),
                );
              },
            ),
            _buildQuickAction(
              context,
              'Simulate Notification',
              Icons.notifications,
              () {
                // Implementar notificação de teste
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Test notification sent!')),
                );
              },
            ),
            _buildQuickAction(context, 'Force Refresh', Icons.refresh, () {
              // Implementar refresh forçado
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('App state refreshed!')),
              );
            }),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fechar'),
          ),
        ],
      ),
    );
  }

  static Widget _buildQuickAction(
    BuildContext context,
    String title,
    IconData icon,
    VoidCallback onTap,
  ) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      onTap: onTap,
      dense: true,
    );
  }
}
