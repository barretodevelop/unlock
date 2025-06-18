// lib/features/navigation/providers/navigation_provider.dart
// Provider para gerenciamento de navegação - Fase 3

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:unlock/core/utils/logger.dart';
import 'package:unlock/features/missions/providers/missions_provider.dart';
import 'package:unlock/features/rewards/providers/rewards_provider.dart';

// Mock providers até serem implementados
// final rewardsProvider = StateNotifierProvider<dynamic, dynamic>((ref) => null);
// final missionsProvider = StateNotifierProvider<dynamic, dynamic>((ref) => null);
// final activeMissionsProvider = Provider<List<dynamic>>((ref) => []);
// final hasPendingRewardsProvider = Provider<bool>((ref) => false);
// final pendingRewardsProvider = Provider<List<dynamic>>((ref) => []);

/// Índices das páginas na navegação
enum NavigationPage {
  home(0, 'Home', Icons.home, '/home'),
  missions(1, 'Missões', Icons.assignment, '/missions'),
  connections(2, 'Conexões', Icons.people, '/connections'),
  profile(3, 'Perfil', Icons.person, '/profile');

  const NavigationPage(this.indexx, this.label, this.icon, this.route);
  final int indexx;
  final String label;
  final IconData icon;
  final String route;

  static NavigationPage fromIndex(int index) {
    return NavigationPage.values.firstWhere(
      (page) => page.index == index,
      orElse: () => NavigationPage.home,
    );
  }
}

/// Estado da navegação
class NavigationState {
  final NavigationPage currentPage;
  final int currentIndex;
  final bool canNavigate;
  final Map<int, bool> pageEnabled;
  final Map<int, int> pageBadges;
  final bool isFloatingButtonVisible;
  final String? floatingButtonRoute;

  const NavigationState({
    this.currentPage = NavigationPage.home,
    this.currentIndex = 0,
    this.canNavigate = true,
    this.pageEnabled = const {0: true, 1: true, 2: true, 3: true},
    this.pageBadges = const {},
    this.isFloatingButtonVisible = true,
    this.floatingButtonRoute = '/matching',
  });

  NavigationState copyWith({
    NavigationPage? currentPage,
    int? currentIndex,
    bool? canNavigate,
    Map<int, bool>? pageEnabled,
    Map<int, int>? pageBadges,
    bool? isFloatingButtonVisible,
    String? floatingButtonRoute,
  }) {
    return NavigationState(
      currentPage: currentPage ?? this.currentPage,
      currentIndex: currentIndex ?? this.currentIndex,
      canNavigate: canNavigate ?? this.canNavigate,
      pageEnabled: pageEnabled ?? this.pageEnabled,
      pageBadges: pageBadges ?? this.pageBadges,
      isFloatingButtonVisible:
          isFloatingButtonVisible ?? this.isFloatingButtonVisible,
      floatingButtonRoute: floatingButtonRoute ?? this.floatingButtonRoute,
    );
  }

  /// Verificar se uma página está habilitada
  bool isPageEnabled(int index) => pageEnabled[index] ?? false;

  /// Obter badge de uma página
  int? getPageBadge(int index) => pageBadges[index];

  /// Verificar se há badges em qualquer página
  bool get hasBadges => pageBadges.values.any((count) => count > 0);

  /// Contar total de badges
  int get totalBadges => pageBadges.values.fold(0, (sum, count) => sum + count);
}

/// Provider principal de navegação
final navigationProvider =
    StateNotifierProvider<NavigationNotifier, NavigationState>((ref) {
      return NavigationNotifier(ref);
    });

/// Notifier para gerenciar estado da navegação
class NavigationNotifier extends StateNotifier<NavigationState> {
  final Ref _ref;

  NavigationNotifier(this._ref) : super(const NavigationState()) {
    _initialize();
  }

  /// Inicializar provider
  void _initialize() {
    try {
      AppLogger.debug('🧭 Inicializando NavigationProvider');

      // Escutar mudanças nos providers relevantes para atualizar badges
      _ref.listen(rewardsProvider, (previous, next) {
        _updateBadges();
      });

      _ref.listen(missionsProvider, (previous, next) {
        _updateBadges();
      });

      // Configurar estado inicial
      _updateBadges();
      _updatePageStates();

      AppLogger.info('✅ NavigationProvider inicializado');
    } catch (e, stackTrace) {
      AppLogger.error('❌ Erro ao inicializar NavigationProvider', error: e);
    }
  }

  /// Navegar para uma página específica
  void navigateToPage(int index) {
    try {
      if (!state.canNavigate) {
        AppLogger.warning('⚠️ Navegação bloqueada');
        return;
      }

      if (!state.isPageEnabled(index)) {
        AppLogger.warning('⚠️ Página $index não está habilitada');
        return;
      }

      final page = NavigationPage.fromIndex(index);

      AppLogger.debug(
        '🧭 Navegando para página: ${page.label} (índice $index)',
      );

      state = state.copyWith(currentPage: page, currentIndex: index);

      // Limpar badge da página visitada
      _clearPageBadge(index);
    } catch (e, stackTrace) {
      AppLogger.error('❌ Erro ao navegar para página $index', error: e);
    }
  }

  /// Navegar para página por enum
  void navigateToPageEnum(NavigationPage page) {
    navigateToPage(page.index);
  }

  /// Atualizar badges das páginas
  void _updateBadges() {
    try {
      final newBadges = <int, int>{};

      // Badge para Missões (missões ativas não vistas)
      final activeMissions = _ref.read(activeMissionsProvider);
      if (activeMissions.isNotEmpty) {
        newBadges[NavigationPage.missions.index] = activeMissions.length;
      }

      // Badge para Home (recompensas pendentes)
      final hasPendingRewards = _ref.read(hasPendingRewardsProvider);
      if (hasPendingRewards) {
        final pendingCount = _ref.read(pendingRewardsProvider).length;
        newBadges[NavigationPage.home.index] = pendingCount;
      }

      // Badge para Conexões (convites pendentes - implementação futura)
      // final pendingConnections = _ref.read(pendingConnectionsProvider);
      // if (pendingConnections.isNotEmpty) {
      //   newBadges[NavigationPage.connections.index] = pendingConnections.length;
      // }

      // Atualizar estado apenas se houver mudanças
      if (_mapsDiffer(state.pageBadges, newBadges)) {
        state = state.copyWith(pageBadges: newBadges);
        AppLogger.debug('🔔 Badges atualizados: $newBadges');
      }
    } catch (e, stackTrace) {
      AppLogger.error('❌ Erro ao atualizar badges', error: e);
    }
  }

  /// Atualizar estados das páginas (habilitado/desabilitado)
  void _updatePageStates() {
    try {
      final newPageEnabled = <int, bool>{};

      // Todas as páginas sempre habilitadas por ora
      for (final page in NavigationPage.values) {
        newPageEnabled[page.index] = true;
      }

      // Lógica futura: desabilitar páginas baseado em condições
      // Por exemplo: desabilitar Conexões se perfil incompleto
      // final authState = _ref.read(authProvider);
      // if (authState.user?.needsOnboarding == true) {
      //   newPageEnabled[NavigationPage.connections.index] = false;
      // }

      state = state.copyWith(pageEnabled: newPageEnabled);
    } catch (e, stackTrace) {
      AppLogger.error('❌ Erro ao atualizar estados das páginas', error: e);
    }
  }

  /// Limpar badge de uma página específica
  void _clearPageBadge(int index) {
    if (state.pageBadges.containsKey(index)) {
      final newBadges = Map<int, int>.from(state.pageBadges);
      newBadges.remove(index);
      state = state.copyWith(pageBadges: newBadges);
    }
  }

  /// Configurar visibilidade do floating button
  void setFloatingButtonVisible(bool visible) {
    if (state.isFloatingButtonVisible != visible) {
      state = state.copyWith(isFloatingButtonVisible: visible);
      AppLogger.debug('🎈 Floating button visibilidade: $visible');
    }
  }

  /// Configurar rota do floating button
  void setFloatingButtonRoute(String route) {
    if (state.floatingButtonRoute != route) {
      state = state.copyWith(floatingButtonRoute: route);
      AppLogger.debug('🎈 Floating button rota: $route');
    }
  }

  /// Bloquear/desbloquear navegação
  void setCanNavigate(bool canNavigate) {
    if (state.canNavigate != canNavigate) {
      state = state.copyWith(canNavigate: canNavigate);
      AppLogger.debug(
        '🧭 Navegação ${canNavigate ? 'habilitada' : 'bloqueada'}',
      );
    }
  }

  /// Adicionar badge customizado
  void addBadge(NavigationPage page, int count) {
    final newBadges = Map<int, int>.from(state.pageBadges);
    newBadges[page.index] = count;
    state = state.copyWith(pageBadges: newBadges);
  }

  /// Remover badge
  void removeBadge(NavigationPage page) {
    final newBadges = Map<int, int>.from(state.pageBadges);
    newBadges.remove(page.index);
    state = state.copyWith(pageBadges: newBadges);
  }

  /// Incrementar badge
  void incrementBadge(NavigationPage page, [int amount = 1]) {
    final currentCount = state.pageBadges[page.index] ?? 0;
    addBadge(page, currentCount + amount);
  }

  /// Decrementar badge
  void decrementBadge(NavigationPage page, [int amount = 1]) {
    final currentCount = state.pageBadges[page.index] ?? 0;
    final newCount = (currentCount - amount).clamp(0, 999);

    if (newCount <= 0) {
      removeBadge(page);
    } else {
      addBadge(page, newCount);
    }
  }

  /// Limpar todos os badges
  void clearAllBadges() {
    if (state.pageBadges.isNotEmpty) {
      state = state.copyWith(pageBadges: {});
      AppLogger.debug('🔔 Todos os badges limpos');
    }
  }

  /// Verificar se dois maps são diferentes
  bool _mapsDiffer(Map<int, int> map1, Map<int, int> map2) {
    if (map1.length != map2.length) return true;

    for (final entry in map1.entries) {
      if (map2[entry.key] != entry.value) return true;
    }

    return false;
  }

  /// Obter informações da página atual
  Map<String, dynamic> getCurrentPageInfo() {
    return {
      'page': state.currentPage,
      'index': state.currentIndex,
      'label': state.currentPage.label,
      'route': state.currentPage.route,
      'icon': state.currentPage.icon,
      'badge': state.getPageBadge(state.currentIndex),
      'enabled': state.isPageEnabled(state.currentIndex),
    };
  }

  /// Reset para página inicial
  void resetToHome() {
    navigateToPage(NavigationPage.home.index);
  }

  /// Limpar estado (logout)
  void clear() {
    state = const NavigationState();
  }
}

// ================================================================================================
// PROVIDERS DERIVADOS
// ================================================================================================

/// Provider para página atual
final currentPageProvider = Provider<NavigationPage>((ref) {
  return ref.watch(navigationProvider).currentPage;
});

/// Provider para índice atual
final currentIndexProvider = Provider<int>((ref) {
  return ref.watch(navigationProvider).currentIndex;
});

/// Provider para verificar se há badges
final hasBadgesProvider = Provider<bool>((ref) {
  return ref.watch(navigationProvider).hasBadges;
});

/// Provider para contagem total de badges
final totalBadgesProvider = Provider<int>((ref) {
  return ref.watch(navigationProvider).totalBadges;
});

/// Provider para badge de uma página específica
final pageBadgeProvider = Provider.family<int?, NavigationPage>((ref, page) {
  return ref.watch(navigationProvider).getPageBadge(page.index);
});

/// Provider para verificar se uma página está habilitada
final pageEnabledProvider = Provider.family<bool, NavigationPage>((ref, page) {
  return ref.watch(navigationProvider).isPageEnabled(page.index);
});

/// Provider para visibilidade do floating button
final floatingButtonVisibleProvider = Provider<bool>((ref) {
  return ref.watch(navigationProvider).isFloatingButtonVisible;
});

/// Provider para rota do floating button
final floatingButtonRouteProvider = Provider<String?>((ref) {
  return ref.watch(navigationProvider).floatingButtonRoute;
});
