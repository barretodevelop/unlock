// lib/providers/connection_lifecycle_provider.dart
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:unlock/feature/games/social/providers/discovery_provider.dart';
import 'package:unlock/feature/games/social/providers/test_invite_provider.dart';
import 'package:unlock/feature/games/social/providers/test_session_provider.dart';
import 'package:unlock/providers/auth_provider.dart';
import 'package:unlock/services/notification_service.dart';

// ============== CONNECTION LIFECYCLE STATE ==============
@immutable
class ConnectionLifecycleState {
  final bool isInitialized;
  final bool hasActiveConnections;
  final int pendingInvites;
  final bool hasActiveTest;
  final String? currentActivity;
  final DateTime? lastHeartbeat;

  const ConnectionLifecycleState({
    this.isInitialized = false,
    this.hasActiveConnections = false,
    this.pendingInvites = 0,
    this.hasActiveTest = false,
    this.currentActivity,
    this.lastHeartbeat,
  });

  ConnectionLifecycleState copyWith({
    bool? isInitialized,
    bool? hasActiveConnections,
    int? pendingInvites,
    bool? hasActiveTest,
    String? currentActivity,
    DateTime? lastHeartbeat,
  }) {
    return ConnectionLifecycleState(
      isInitialized: isInitialized ?? this.isInitialized,
      hasActiveConnections: hasActiveConnections ?? this.hasActiveConnections,
      pendingInvites: pendingInvites ?? this.pendingInvites,
      hasActiveTest: hasActiveTest ?? this.hasActiveTest,
      currentActivity: currentActivity,
      lastHeartbeat: lastHeartbeat ?? this.lastHeartbeat,
    );
  }

  bool get needsAttention => pendingInvites > 0 || hasActiveTest;
  bool get isActive => hasActiveConnections || hasActiveTest;
}

// ============== CONNECTION LIFECYCLE PROVIDER ==============
final connectionLifecycleProvider =
    StateNotifierProvider<
      ConnectionLifecycleNotifier,
      ConnectionLifecycleState
    >((ref) {
      return ConnectionLifecycleNotifier(ref);
    });

class ConnectionLifecycleNotifier
    extends StateNotifier<ConnectionLifecycleState> {
  final Ref _ref;
  Timer? _heartbeatTimer;
  Timer? _cleanupTimer;
  ProviderSubscription<AuthState>? _authSubscription;

  static const Duration _heartbeatInterval = Duration(minutes: 1);
  static const Duration _cleanupInterval = Duration(minutes: 5);
  static const Duration _offlineThreshold = Duration(minutes: 3);

  ConnectionLifecycleNotifier(this._ref)
    : super(const ConnectionLifecycleState()) {
    _initialize();
  }

  // ============== INICIALIZAÇÃO ==============
  void _initialize() async {
    try {
      if (kDebugMode) {
        print('🔄 ConnectionLifecycle: Inicializando...');
      }

      // Escutar mudanças de autenticação
      _authSubscription = _ref.listen<AuthState>(authProvider, (
        previous,
        next,
      ) {
        _handleAuthChange(previous, next);
      }, fireImmediately: true);

      // Escutar mudanças nos providers relacionados
      _setupProviderListeners();

      state = state.copyWith(isInitialized: true);

      if (kDebugMode) {
        print('✅ ConnectionLifecycle: Inicializado');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ ConnectionLifecycle: Erro na inicialização: $e');
      }
    }
  }

  void _handleAuthChange(AuthState? previous, AuthState next) {
    if (next.isAuthenticated && (previous?.isAuthenticated != true)) {
      // Usuário fez login
      _startActiveServices();
    } else if (!next.isAuthenticated && (previous?.isAuthenticated == true)) {
      // Usuário fez logout
      _stopActiveServices();
    }
  }

  void _setupProviderListeners() {
    // Escutar mudanças no estado de convites
    _ref.listen(testInviteProvider, (previous, next) {
      state = state.copyWith(
        pendingInvites: next?.pendingReceivedInvites.length,
        hasActiveConnections:
            next!.sentInvites.isNotEmpty || next!.receivedInvites.isNotEmpty,
      );

      _updateCurrentActivity(next);
    });

    // Escutar mudanças no estado da sessão de teste
    _ref.listen(testSessionProvider, (previous, next) {
      state = state.copyWith(hasActiveTest: next.hasActiveSession);

      _updateTestActivity(next);
    });

    // Escutar mudanças no discovery
    _ref.listen(discoveryProvider, (previous, next) {
      if (next.isSearching) {
        state = state.copyWith(currentActivity: 'Buscando conexões...');
      }
    });
  }

  // ============== SERVIÇOS ATIVOS ==============
  void _startActiveServices() {
    if (kDebugMode) {
      print('🚀 ConnectionLifecycle: Iniciando serviços ativos');
    }

    // Iniciar heartbeat para manter usuário ativo
    _startHeartbeat();

    // Iniciar limpeza periódica
    _startPeriodicCleanup();

    // Atualizar atividade inicial
    _ref.read(discoveryProvider.notifier).updateUserActivity();
  }

  void _stopActiveServices() {
    if (kDebugMode) {
      print('🛑 ConnectionLifecycle: Parando serviços ativos');
    }

    // Parar timers
    _heartbeatTimer?.cancel();
    _cleanupTimer?.cancel();

    // Marcar usuário como offline
    _ref.read(discoveryProvider.notifier).setUserOffline();

    // Finalizar sessão ativa se houver
    final testSessionState = _ref.read(testSessionProvider);
    if (testSessionState.hasActiveSession) {
      _ref.read(testSessionProvider.notifier).endSession();
    }

    // Limpar estado
    state = const ConnectionLifecycleState();
  }

  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(_heartbeatInterval, (timer) {
      _sendHeartbeat();
    });
  }

  void _startPeriodicCleanup() {
    _cleanupTimer?.cancel();
    _cleanupTimer = Timer.periodic(_cleanupInterval, (timer) {
      _performCleanup();
    });
  }

  // ============== HEARTBEAT E ATIVIDADE ==============
  void _sendHeartbeat() {
    final authState = _ref.read(authProvider);
    if (!authState.isAuthenticated) return;

    try {
      // Atualizar atividade do usuário
      _ref.read(discoveryProvider.notifier).updateUserActivity();

      state = state.copyWith(lastHeartbeat: DateTime.now());

      if (kDebugMode) {
        print('💗 ConnectionLifecycle: Heartbeat enviado');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ ConnectionLifecycle: Erro no heartbeat: $e');
      }
    }
  }

  void _updateCurrentActivity(TestInviteState testInviteState) {
    String? activity;

    if (testInviteState.pendingReceivedInvites.isNotEmpty) {
      final count = testInviteState.pendingReceivedInvites.length;
      activity = count == 1
          ? 'Novo convite de teste!'
          : '$count convites pendentes';
    } else if (testInviteState.hasActiveTest) {
      activity = 'Teste em andamento';
    } else if (testInviteState.sentInvites.any(
      (invite) => invite.canStartTest,
    )) {
      activity = 'Convite aceito - pode iniciar teste';
    }

    if (activity != state.currentActivity) {
      state = state.copyWith(currentActivity: activity);

      // Enviar notificação se necessário
      if (activity != null &&
          testInviteState.pendingReceivedInvites.isNotEmpty) {
        _sendActivityNotification(activity);
      }
    }
  }

  void _updateTestActivity(TestSessionState testSessionState) {
    String? activity;

    switch (testSessionState.phase) {
      case TestPhase.waiting:
        activity = 'Aguardando sincronização...';
        break;
      case TestPhase.questions:
        activity = 'Respondendo perguntas';
        break;
      case TestPhase.miniGame:
        activity = 'Mini-jogo colaborativo';
        break;
      case TestPhase.result:
        activity = 'Vendo resultado do teste';
        break;
      case TestPhase.completed:
        activity = null;
        break;
    }

    if (activity != state.currentActivity) {
      state = state.copyWith(currentActivity: activity);
    }
  }

  void _sendActivityNotification(String activity) {
    NotificationService.showSimpleLocalNotification(
      title: '🎯 UNLOCK',
      body: activity,
      payload: 'activity_update',
    ).catchError((e) {
      if (kDebugMode) {
        print('❌ ConnectionLifecycle: Erro ao enviar notificação: $e');
      }
    });
  }

  // ============== LIMPEZA E MANUTENÇÃO ==============
  void _performCleanup() {
    if (kDebugMode) {
      print('🧹 ConnectionLifecycle: Executando limpeza periódica');
    }

    try {
      // Verificar se há sessões expiradas
      final testSessionState = _ref.read(testSessionProvider);
      if (testSessionState.hasActiveSession &&
          testSessionState.timeRemaining != null) {
        if (testSessionState.timeRemaining!.isNegative) {
          _ref.read(testSessionProvider.notifier).endSession();
        }
      }

      // Verificar heartbeat
      if (state.lastHeartbeat != null) {
        final timeSinceHeartbeat = DateTime.now().difference(
          state.lastHeartbeat!,
        );
        if (timeSinceHeartbeat > _offlineThreshold) {
          if (kDebugMode) {
            print('⚠️ ConnectionLifecycle: Usuário offline por muito tempo');
          }
          // Aqui você pode implementar lógica de reconexão ou alerta
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ ConnectionLifecycle: Erro na limpeza: $e');
      }
    }
  }

  // ============== MÉTODOS PÚBLICOS ==============

  /// Força atualização de atividade
  void updateActivity() {
    _sendHeartbeat();
  }

  /// Força limpeza imediata
  void forceCleanup() {
    _performCleanup();
  }

  /// Verifica se o usuário pode fazer novas conexões
  bool canMakeNewConnections() {
    final authState = _ref.read(authProvider);
    if (!authState.isAuthenticated) return false;

    final testSessionState = _ref.read(testSessionProvider);
    if (testSessionState.hasActiveSession) return false;

    // Verificar limites diários, etc.
    // TODO: Implementar lógica de limites baseada no nível do usuário

    return true;
  }

  /// Verifica se pode iniciar teste
  bool canStartTest() {
    final testInviteState = _ref.read(testInviteProvider);
    return testInviteState.hasActiveTest &&
        !_ref.read(testSessionProvider).hasActiveSession;
  }

  /// Obter status resumido para UI
  Map<String, dynamic> getStatusSummary() {
    return {
      'isActive': state.isActive,
      'needsAttention': state.needsAttention,
      'pendingInvites': state.pendingInvites,
      'hasActiveTest': state.hasActiveTest,
      'currentActivity': state.currentActivity,
      'canMakeConnections': canMakeNewConnections(),
      'canStartTest': canStartTest(),
    };
  }

  // ============== GERENCIAMENTO DE ESTADO ==============

  /// Pausar serviços (quando app vai para background)
  void pauseServices() {
    if (kDebugMode) {
      print('⏸️ ConnectionLifecycle: Pausando serviços');
    }

    _heartbeatTimer?.cancel();
    // Manter cleanup ativo para verificações críticas
  }

  /// Retomar serviços (quando app volta para foreground)
  void resumeServices() {
    if (kDebugMode) {
      print('▶️ ConnectionLifecycle: Retomando serviços');
    }

    final authState = _ref.read(authProvider);
    if (authState.isAuthenticated) {
      _startHeartbeat();
      _sendHeartbeat(); // Heartbeat imediato
    }
  }

  @override
  void dispose() {
    _heartbeatTimer?.cancel();
    _cleanupTimer?.cancel();
    _authSubscription?.close();

    // Marcar como offline ao sair
    try {
      _ref.read(discoveryProvider.notifier).setUserOffline();
    } catch (e) {
      // Ignorar erros no dispose
    }

    super.dispose();
  }
}

// ============== LIFECYCLE HOOKS ==============
class ConnectionLifecycleHooks {
  static void onAppPaused(WidgetRef ref) {
    ref.read(connectionLifecycleProvider.notifier).pauseServices();
  }

  static void onAppResumed(WidgetRef ref) {
    ref.read(connectionLifecycleProvider.notifier).resumeServices();
  }

  static void onAppDetached(WidgetRef ref) {
    ref.read(discoveryProvider.notifier).setUserOffline();
  }
}

// ============== EXTENSIONS ==============
extension ConnectionLifecycleX on WidgetRef {
  ConnectionLifecycleNotifier get connectionLifecycle =>
      read(connectionLifecycleProvider.notifier);
  ConnectionLifecycleState get connectionLifecycleState =>
      watch(connectionLifecycleProvider);

  Map<String, dynamic> get connectionStatus =>
      read(connectionLifecycleProvider.notifier).getStatusSummary();
}
