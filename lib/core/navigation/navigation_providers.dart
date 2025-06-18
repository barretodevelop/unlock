// lib/core/navigation/navigation_providers.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:unlock/core/utils/logger.dart';
import 'package:unlock/providers/auth_provider.dart';

/// Provider que determina a rota atual baseada no estado da aplicação
final currentRouteProvider = Provider<NavigationRoute>((ref) {
  final auth = ref.watch(authProvider);
  final route = NavigationCalculator.calculateRoute(auth);

  // Log para debug
  AppLogger.navigation(
    '🧭 Route calculated',
    data: {
      'route': route.path,
      'reason': route.reason,
      'userId': auth.user?.uid,
      'isAuthenticated': auth.isAuthenticated,
      'needsOnboarding': auth.needsOnboarding,
      'isInitialized': auth.isInitialized,
    },
  );

  return route;
});

/// ✅ CORREÇÃO: Provider separado para mudanças de navegação
final navigationChangeNotifierProvider =
    StateNotifierProvider<NavigationChangeNotifier, NavigationState>((ref) {
      return NavigationChangeNotifier(ref);
    });

/// ✅ CORREÇÃO: Notificador que escuta mudanças sem causar loops
class NavigationChangeNotifier extends StateNotifier<NavigationState> {
  final Ref _ref;

  NavigationChangeNotifier(this._ref) : super(NavigationState.initial()) {
    // Escuta mudanças no auth e calcula nova rota
    _ref.listen(authProvider, (previous, next) {
      final newRoute = NavigationCalculator.calculateRoute(next);
      _updateRoute(newRoute);
    });
  }

  void _updateRoute(NavigationRoute route) {
    if (state.currentRoute?.path != route.path) {
      state = state.copyWith(currentRoute: route, lastUpdate: DateTime.now());

      AppLogger.navigation(
        '🔄 Route updated',
        data: {'newRoute': route.path, 'reason': route.reason},
      );
    }
  }

  void addToHistory(NavigationRoute route) {
    final newHistory = [...state.history, route];
    if (newHistory.length > 10) {
      newHistory.removeRange(0, newHistory.length - 10);
    }

    state = state.copyWith(history: newHistory);
  }

  void clearHistory() {
    state = state.copyWith(history: []);
  }
}

/// ✅ Estado da navegação
class NavigationState {
  final NavigationRoute? currentRoute;
  final List<NavigationRoute> history;
  final DateTime lastUpdate;

  const NavigationState({
    this.currentRoute,
    required this.history,
    required this.lastUpdate,
  });

  factory NavigationState.initial() {
    return NavigationState(history: [], lastUpdate: DateTime.now());
  }

  NavigationState copyWith({
    NavigationRoute? currentRoute,
    List<NavigationRoute>? history,
    DateTime? lastUpdate,
  }) {
    return NavigationState(
      currentRoute: currentRoute ?? this.currentRoute,
      history: history ?? this.history,
      lastUpdate: lastUpdate ?? this.lastUpdate,
    );
  }
}

/// Modelo para representar uma rota com contexto
class NavigationRoute {
  final String path;
  final String reason;
  final Map<String, dynamic>? params;
  final DateTime timestamp;

  NavigationRoute({required this.path, required this.reason, this.params})
    : timestamp = DateTime.now();

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is NavigationRoute && other.path == path);

  @override
  int get hashCode => path.hashCode;

  @override
  String toString() =>
      'NavigationRoute(path: $path, reason: $reason, time: $timestamp)';
}

/// Calculadora de rotas - lógica centralizada e testável
class NavigationCalculator {
  static NavigationRoute calculateRoute(AuthState authState) {
    if (!authState.isInitialized) {
      return NavigationRoute(
        path: '/',
        reason: 'Auth not initialized - showing splash',
        params: {
          'isLoading': authState.isLoading,
          'hasError': authState.error != null,
        },
      );
    }

    if (authState.error != null) {
      return NavigationRoute(
        path: '/login',
        reason: 'Auth error occurred - redirecting to login',
        params: {'error': authState.error},
      );
    }

    if (!authState.isAuthenticated) {
      return NavigationRoute(
        path: '/login',
        reason: 'User not authenticated',
        params: {'hasError': authState.error != null},
      );
    }

    if (authState.needsOnboarding) {
      return NavigationRoute(
        path: '/onboarding',
        reason: 'User needs onboarding completion',
        params: {
          'userId': authState.user?.uid,
          'userEmail': authState.user?.email,
          'onboardingCompleted': authState.user?.onboardingCompleted,
          'hasCodinome': authState.user?.codinome?.isNotEmpty,
          'hasAvatarId': authState.user?.avatarId?.isNotEmpty,
          'hasInterests': authState.user?.interesses.isNotEmpty,
          'hasBirthDate': authState.user?.birthDate != null,
        },
      );
    }

    return NavigationRoute(
      path: '/home',
      reason: 'User authenticated and onboarding complete',
      params: {
        'userId': authState.user?.uid,
        'username': authState.user?.username,
        'level': authState.user?.level,
      },
    );
  }

  static bool shouldShowSplash(AuthState authState) {
    return !authState.isInitialized ||
        (authState.isLoading && !authState.isAuthenticated);
  }

  static bool isPublicRoute(String path) {
    return ['/', '/login', '/error'].contains(path);
  }

  static Map<String, dynamic> getNavigationDebugInfo(AuthState authState) {
    final route = calculateRoute(authState);

    return {
      'calculatedRoute': route.path,
      'reason': route.reason,
      'timestamp': route.timestamp.toIso8601String(),
      'authState': {
        'isInitialized': authState.isInitialized,
        'isAuthenticated': authState.isAuthenticated,
        'needsOnboarding': authState.needsOnboarding,
        'isLoading': authState.isLoading,
        'hasError': authState.error != null,
        'error': authState.error,
        'userId': authState.user?.uid,
      },
      'userDetails': authState.user != null
          ? {
              'onboardingCompleted': authState.user!.onboardingCompleted,
              'codinome': authState.user!.codinome,
              'avatarId': authState.user!.avatarId,
              'interessesCount': authState.user!.interesses.length,
              'hasBirthDate': authState.user!.birthDate != null,
              'needsOnboarding': authState.user!.needsOnboarding,
            }
          : null,
    };
  }
}
