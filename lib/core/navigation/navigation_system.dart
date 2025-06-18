// lib/core/navigation/navigation_system.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:unlock/core/navigation/navigation_providers.dart';
import 'package:unlock/core/navigation/navigation_routes.dart';
import 'package:unlock/core/utils/logger.dart';

/// ✅ CORREÇÃO: Sistema de navegação sem loops de estado
class NavigationSystem {
  static GoRouter createRouter(WidgetRef ref) {
    return GoRouter(
      initialLocation: '/',
      debugLogDiagnostics: false, // ✅ Desabilitar para reduzir logs
      // ✅ CORREÇÃO: Usar refreshListenable mais simples
      refreshListenable: _NavigationRefreshNotifier(ref),

      // ✅ CORREÇÃO: Redirect mais limpo sem mutações
      redirect: (context, state) {
        return _handleRedirect(ref, context, state);
      },

      routes: NavigationRoutes.routes,
      errorBuilder: NavigationRoutes.errorBuilder,
      observers: [_NavigationObserver()],
    );
  }

  /// ✅ CORREÇÃO: Redirect simplificado
  static String? _handleRedirect(
    WidgetRef ref,
    BuildContext context,
    GoRouterState state,
  ) {
    try {
      final currentLocation = state.uri.toString();
      final targetRoute = ref.read(currentRouteProvider);

      // Se já estamos na rota correta, não redirecionar
      if (targetRoute.path == currentLocation) {
        return null;
      }

      // ✅ CORREÇÃO: Log sem causar side effects
      AppLogger.navigation(
        '🔄 Redirecting: ${currentLocation} → ${targetRoute.path}',
        data: {'reason': targetRoute.reason},
      );

      return targetRoute.path;
    } catch (e, stackTrace) {
      AppLogger.error(
        '❌ Navigation redirect error',
        error: e,
        stackTrace: stackTrace,
      );
      return '/';
    }
  }

  // ✅ Métodos de navegação programática
  static void navigateTo(BuildContext context, String path) {
    try {
      AppLogger.navigation('🧭 Navigating to: $path');
      context.go(path);
    } catch (e) {
      AppLogger.error('❌ Navigation error', error: e);
    }
  }

  static void pushTo(BuildContext context, String path) {
    try {
      AppLogger.navigation('🧭 Pushing to: $path');
      context.push(path);
    } catch (e) {
      AppLogger.error('❌ Push navigation error', error: e);
    }
  }

  static bool canPop(BuildContext context) {
    return GoRouter.of(context).canPop();
  }

  static void popIfPossible(BuildContext context) {
    if (canPop(context)) {
      context.pop();
    } else {
      context.go('/home');
    }
  }

  static void clearStackAndNavigateTo(BuildContext context, String path) {
    AppLogger.navigation('🧭 Clearing stack and navigating to: $path');
    context.go(path);
  }
}

/// ✅ CORREÇÃO: Notificador mais simples
class _NavigationRefreshNotifier extends ChangeNotifier {
  final WidgetRef _ref;
  NavigationRoute? _lastRoute;

  _NavigationRefreshNotifier(this._ref) {
    _ref.listen(currentRouteProvider, (previous, current) {
      if (_lastRoute?.path != current.path) {
        _lastRoute = current;

        // ✅ CORREÇÃO: Notificar de forma segura
        WidgetsBinding.instance.addPostFrameCallback((_) {
          notifyListeners();
        });
      }
    });
  }

  @override
  void dispose() {
    AppLogger.navigation('🧹 NavigationRefreshNotifier disposed');
    super.dispose();
  }
}

/// ✅ Observer simplificado
class _NavigationObserver extends NavigatorObserver {
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    _logRouteChange('PUSH', route);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPop(route, previousRoute);
    _logRouteChange('POP', route);
  }

  void _logRouteChange(String action, Route<dynamic>? route) {
    AppLogger.navigation(
      '🧭 Route $action: ${route?.settings.name ?? 'unknown'}',
    );
  }
}

/// ✅ Extensions para facilitar uso
extension NavigationSystemExtensions on BuildContext {
  void navigateToRoute(String path) {
    NavigationSystem.navigateTo(this, path);
  }

  void pushToRoute(String path) {
    NavigationSystem.pushTo(this, path);
  }

  void popOrNavigateToHome() {
    NavigationSystem.popIfPossible(this);
  }

  void clearAndNavigateTo(String path) {
    NavigationSystem.clearStackAndNavigateTo(this, path);
  }
}

/// ✅ Widget de debug simplificado
class NavigationDebugWidget extends ConsumerWidget {
  const NavigationDebugWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentRoute = ref.watch(currentRouteProvider);
    final navState = ref.watch(navigationChangeNotifierProvider);

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.black87,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Navigation Debug',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            'Current: ${currentRoute.path}',
            style: const TextStyle(color: Colors.green),
          ),
          Text(
            'Reason: ${currentRoute.reason}',
            style: const TextStyle(color: Colors.yellow),
          ),
          Text(
            'History: ${navState.history.length} items',
            style: const TextStyle(color: Colors.blue),
          ),
        ],
      ),
    );
  }
}
