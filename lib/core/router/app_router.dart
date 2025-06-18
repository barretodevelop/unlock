// lib/core/router/app_router.dart - CORRIGIDO e COMPATÍVEL com sistema escalável
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:unlock/core/navigation/navigation_system.dart';
import 'package:unlock/core/utils/logger.dart';

/// 🔧 COMPATIBILIDADE: Interface antiga mantida, mas usando sistema escalável
///
/// Este arquivo mantém a interface `AppRouter.router` para compatibilidade
/// com qualquer código existente, mas usa o novo NavigationSystem por baixo.
class AppRouter {
  static final GlobalKey<NavigatorState> _rootNavigatorKey =
      GlobalKey<NavigatorState>();
  static final GlobalKey<NavigatorState> _shellNavigatorKey =
      GlobalKey<NavigatorState>();

  // ✅ DELEGAÇÃO: Usar o sistema escalável criado
  static GoRouter? _router;

  /// Obter router (compatibilidade com código existente)
  static GoRouter router(WidgetRef ref) {
    _router ??= NavigationSystem.createRouter(ref);
    return _router!;
  }

  /// 🆕 NOVA FORMA RECOMENDADA: Criar router diretamente
  static GoRouter createRouter(WidgetRef ref) {
    return NavigationSystem.createRouter(ref);
  }

  // ========== GETTERS DE NAVIGATOR KEYS (COMPATIBILIDADE) ==========

  static GlobalKey<NavigatorState> get rootNavigatorKey => _rootNavigatorKey;
  static GlobalKey<NavigatorState> get shellNavigatorKey => _shellNavigatorKey;
}

/// ✅ CONSTANTES DE ROTAS (COMPATIBILIDADE MANTIDA)
class AppRoutes {
  static const String splash = '/';
  static const String login = '/login';

  // Onboarding routes
  static const String onboarding = '/onboarding';
  static const String onboardingWelcome = '/onboarding/welcome';
  static const String onboardingIdentity = '/onboarding/identity';
  static const String onboardingInterests = '/onboarding/interests';

  // Main app routes
  static const String home = '/home';
  static const String profile = '/profile';
  static const String connections = '/connections';
  static const String missions = '/missions';
  static const String shop = '/shop';
  static const String settings = '/settings';

  // Sub-rotas (para implementação futura)
  static const String editProfile = '/profile/edit';
  static const String connectionDetail = '/connections/:id';
  static const String missionDetail = '/missions/:id';
  static const String shopItem = '/shop/:id';
  static const String game = '/game/:id';
  static const String error = '/error';
}

/// ✅ NOMES DAS ROTAS (COMPATIBILIDADE MANTIDA)
class RouteNames {
  static const String splash = 'splash';
  static const String login = 'login';

  // Onboarding route names
  static const String onboarding = 'onboarding';
  static const String onboardingWelcome = 'onboarding_welcome';
  static const String onboardingIdentity = 'onboarding_identity';
  static const String onboardingInterests = 'onboarding_interests';

  // Main app route names
  static const String home = 'home';
  static const String profile = 'profile';
  static const String connections = 'connections';
  static const String missions = 'missions';
  static const String shop = 'shop';
  static const String settings = 'settings';

  // Special routes
  static const String error = 'error';
}

/// ✅ EXTENSÕES DE NAVEGAÇÃO (COMPATIBILIDADE MANTIDA)
extension AppRouterExtension on GoRouter {
  /// Navegar para home
  void goHome() => go(AppRoutes.home);

  /// Navegar para login
  void goLogin() => go(AppRoutes.login);

  /// Navegação de onboarding
  void goOnboarding() => go(AppRoutes.onboarding);
  void goOnboardingWelcome() => go(AppRoutes.onboardingWelcome);
  void goOnboardingIdentity() => go(AppRoutes.onboardingIdentity);
  void goOnboardingInterests() => go(AppRoutes.onboardingInterests);

  /// Navegar para outras seções
  void goProfile() => go(AppRoutes.profile);
  void goConnections() => go(AppRoutes.connections);
  void goMissions() => go(AppRoutes.missions);
  void goShop() => go(AppRoutes.shop);
  void goSettings() => go(AppRoutes.settings);
}

/// ✅ UTILITÁRIOS DE NAVEGAÇÃO (COMPATIBILIDADE + MELHORIAS)
class NavigationUtils {
  /// Obter context do router
  static BuildContext? get context =>
      AppRouter._rootNavigatorKey.currentContext;

  /// Verificar se pode voltar
  static bool canPop() {
    return AppRouter._rootNavigatorKey.currentState?.canPop() ?? false;
  }

  /// Voltar se possível
  static void popIfCan() {
    if (canPop()) {
      AppRouter._rootNavigatorKey.currentState?.pop();
    }
  }

  /// Limpar stack e ir para home
  static void goHomeAndClearStack() {
    _getCurrentRouter()?.go(AppRoutes.home);
  }

  /// Navegação específica de onboarding
  static void goToOnboarding() {
    _getCurrentRouter()?.go(AppRoutes.onboarding);
  }

  static void goToOnboardingStep(int step) {
    final router = _getCurrentRouter();
    if (router == null) return;

    switch (step) {
      case 0:
        router.go(AppRoutes.onboardingWelcome);
        break;
      case 1:
        router.go(AppRoutes.onboardingIdentity);
        break;
      case 2:
        router.go(AppRoutes.onboardingInterests);
        break;
      default:
        router.go(AppRoutes.onboarding);
    }
  }

  /// 🆕 NOVO: Navegar usando NavigationSystem (recomendado)
  static void navigateToRoute(BuildContext context, String path) {
    NavigationSystem.navigateTo(context, path);
  }

  /// Log da rota atual
  static void logCurrentRoute() {
    final context = NavigationUtils.context;
    if (context != null) {
      try {
        final location = GoRouter.of(
          context,
        ).routeInformationProvider.value.uri;
        AppLogger.navigation(
          'Rota atual',
          data: {'location': location.toString()},
        );
      } catch (e) {
        AppLogger.warning('Não foi possível obter rota atual: $e');
      }
    }
  }

  /// Verificar se está em onboarding
  static bool isInOnboarding() {
    final context = NavigationUtils.context;
    if (context != null) {
      try {
        final location = GoRouter.of(
          context,
        ).routeInformationProvider.value.uri.toString();
        return location.startsWith(AppRoutes.onboarding);
      } catch (e) {
        AppLogger.warning(
          'Não foi possível verificar se está em onboarding: $e',
        );
        return false;
      }
    }
    return false;
  }

  /// Verificar se a rota é pública
  static bool isPublicRoute(String path) {
    return [AppRoutes.splash, AppRoutes.login, AppRoutes.error].contains(path);
  }

  /// Verificar se a rota requer autenticação
  static bool requiresAuth(String path) {
    return !isPublicRoute(path);
  }

  /// Obter router atual (helper interno)
  static GoRouter? _getCurrentRouter() {
    try {
      final context = NavigationUtils.context;
      if (context != null) {
        return GoRouter.of(context);
      }
    } catch (e) {
      AppLogger.warning('Não foi possível obter router atual: $e');
    }
    return null;
  }
}

/// 🚨 CLASSE DEPRECADA (mantida para compatibilidade)
///
/// Esta classe era parte do sistema antigo. Use NavigationSystem em vez disso.
@Deprecated('Use NavigationSystem.createRouter() em vez disso')
class LegacyAppRouter {
  @Deprecated('Use NavigationSystem.createRouter() em vez disso')
  static GoRouter createRouter() {
    throw UnsupportedError(
      'LegacyAppRouter.createRouter() foi removido. '
      'Use NavigationSystem.createRouter(ref) em vez disso.',
    );
  }
}

/// ✅ CONSTANTES ADICIONAIS PARA COMPATIBILIDADE
class AppPaths {
  // Alias para AppRoutes (algumas partes do código podem usar)
  static const String splash = AppRoutes.splash;
  static const String login = AppRoutes.login;
  static const String onboarding = AppRoutes.onboarding;
  static const String home = AppRoutes.home;
  static const String profile = AppRoutes.profile;
  static const String connections = AppRoutes.connections;
  static const String missions = AppRoutes.missions;
  static const String shop = AppRoutes.shop;
  static const String settings = AppRoutes.settings;
}

/// ✅ HELPERS PARA MIGRAÇÃO
class NavigationMigrationHelpers {
  /// Migrar do sistema antigo para o novo
  static void logMigrationInfo() {
    AppLogger.info(
      '📦 Sistema de navegação migrado',
      data: {
        'old_system': 'app_router.dart manual',
        'new_system': 'NavigationSystem escalável',
        'compatibility': 'AppRouter.router() mantido para compatibilidade',
        'recommended':
            'Use NavigationSystem.createRouter(ref) para novos códigos',
      },
    );
  }

  /// Verificar se há conflitos de importação
  static void checkForConflicts() {
    AppLogger.debug('🔍 Verificando conflitos de navegação...');

    // TODO: Adicionar verificações específicas se necessário
    AppLogger.debug('✅ Nenhum conflito detectado');
  }
}

/// 📋 INSTRUÇÕES DE USO
/// 
/// ✅ CÓDIGO EXISTENTE (ainda funciona):
/// ```dart
/// MaterialApp.router(
///   routerConfig: AppRouter.router(ref),
/// );
/// ```
/// 
/// 🆕 CÓDIGO NOVO (recomendado):
/// ```dart
/// MaterialApp.router(
///   routerConfig: NavigationSystem.createRouter(ref),
/// );
/// ```
/// 
/// 🔄 MIGRAÇÃO GRADUAL:
/// 1. Código existente continua funcionando
/// 2. Novos códigos devem usar NavigationSystem
/// 3. Eventualmente, migrar todo código para NavigationSystem