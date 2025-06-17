// lib/providers/auth_provider.dart - Com Analytics Integrado
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:unlock/core/utils/logger.dart';
import 'package:unlock/models/user_model.dart';
import 'package:unlock/services/analytics/analytics_integration.dart';
import 'package:unlock/services/analytics/interfaces/analytics_interface.dart';
import 'package:unlock/services/auth_service.dart';

// Provider principal
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});

@immutable
class AuthState {
  final UserModel? user;
  final bool isLoading;
  final bool isInitialized;
  final String? error;
  final AuthStatus status;

  const AuthState({
    this.user,
    this.isLoading = false,
    this.isInitialized = false,
    this.error,
    this.status = AuthStatus.unknown,
  });

  // ✅ NAVEGAÇÃO CORRIGIDA - Getters convenientes
  bool get isAuthenticated =>
      user != null && status == AuthStatus.authenticated;

  bool get canNavigate => isInitialized && !isLoading && error == null;

  // ✅ ONBOARDING - Verifica se usuário precisa completar perfil
  bool get needsOnboarding {
    if (!isAuthenticated || user == null) return false;

    // TODO: Implementar lógica de onboarding na Fase 2
    // Por enquanto, sempre retorna false
    return false;
  }

  // ✅ PROPRIEDADES DE NAVEGAÇÃO CORRETAS
  bool get shouldShowSplash {
    return !isInitialized || isLoading;
  }

  bool get shouldShowLogin {
    return canNavigate && !isAuthenticated;
  }

  bool get shouldShowOnboarding {
    return canNavigate && isAuthenticated && needsOnboarding;
  }

  bool get shouldShowHome {
    return canNavigate && isAuthenticated && !needsOnboarding;
  }

  // ✅ PROPRIEDADES LEGADAS (manter compatibilidade)
  bool get shouldShowSplashScreen => shouldShowSplash;
  bool get shouldShowHomeScreen => shouldShowHome;

  AuthState copyWith({
    UserModel? user,
    bool? isLoading,
    bool? isInitialized,
    String? error,
    AuthStatus? status,
  }) {
    return AuthState(
      user: user,
      isLoading: isLoading ?? this.isLoading,
      isInitialized: isInitialized ?? this.isInitialized,
      error: error,
      status: status ?? this.status,
    );
  }

  @override
  String toString() {
    return 'AuthState('
        'user: ${user?.uid}, '
        'isLoading: $isLoading, '
        'isInitialized: $isInitialized, '
        'status: $status, '
        'error: $error, '
        'needsOnboarding: $needsOnboarding, '
        'shouldShowLogin: $shouldShowLogin, '
        'shouldShowOnboarding: $shouldShowOnboarding, '
        'shouldShowHome: $shouldShowHome'
        ')';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AuthState &&
        other.user?.uid == user?.uid &&
        other.isLoading == isLoading &&
        other.isInitialized == isInitialized &&
        other.error == error &&
        other.status == status;
  }

  @override
  int get hashCode {
    return Object.hash(user?.uid, isLoading, isInitialized, error, status);
  }
}

// Estados possíveis da autenticação
enum AuthStatus {
  unknown, // Estado inicial
  authenticated, // Usuário logado
  unauthenticated, // Usuário não logado
  error, // Erro na autenticação
}

// Notifier da autenticação
class AuthNotifier extends StateNotifier<AuthState> {
  StreamSubscription? _authSubscription;
  bool _disposed = false;
  DateTime? _sessionStartTime;

  AuthNotifier() : super(const AuthState()) {
    _initialize();
  }

  // Inicialização do provider
  Future<void> _initialize() async {
    if (_disposed) return;

    try {
      _sessionStartTime = DateTime.now();
      AppLogger.auth('🔄 Inicializando AuthProvider...');

      // 📊 Analytics: Início da inicialização de auth
      await _trackAnalyticsEvent('auth_provider_init_start');

      // Definir estado de carregamento
      state = state.copyWith(isLoading: true, status: AuthStatus.unknown);

      // Escutar mudanças de autenticação
      _authSubscription = AuthService.authStateChanges.listen(
        _handleAuthStateChange,
        onError: _handleAuthError,
      );

      AppLogger.auth('✅ AuthProvider inicializado com sucesso');

      // 📊 Analytics: Inicialização concluída
      await _trackAnalyticsEvent(
        'auth_provider_init_success',
        data: {
          'init_duration_ms': DateTime.now()
              .difference(_sessionStartTime!)
              .inMilliseconds,
        },
      );
    } catch (error) {
      // 📊 Analytics: Erro na inicialização
      await _trackAnalyticsEvent(
        'auth_provider_init_error',
        data: {'error_type': error.runtimeType.toString()},
      );

      _handleError('Erro na inicialização', error);
    }
  }

  // Handler para mudanças no estado de autenticação
  Future<void> _handleAuthStateChange(dynamic firebaseUser) async {
    if (_disposed) return;

    try {
      AppLogger.auth(
        '🔄 Auth state changed',
        data: {
          'userUid': firebaseUser?.uid ?? 'null',
          'hasUser': firebaseUser != null,
        },
      );

      // 📊 Analytics: Mudança de estado
      await _trackAnalyticsEvent(
        'auth_state_changed',
        data: {
          'has_user': firebaseUser != null,
          'user_exists': firebaseUser?.uid != null,
        },
      );

      if (firebaseUser == null) {
        // Usuário deslogado
        AppLogger.auth('👤 Usuário deslogado');

        // 📊 Analytics: Logout detectado
        await _trackAnalyticsEvent(
          'user_logged_out',
          data: {'logout_method': 'auth_state_change'},
        );

        // Limpar dados do analytics
        await AnalyticsIntegration.clearUser();

        _updateState(
          user: null,
          isLoading: false,
          isInitialized: true,
          status: AuthStatus.unauthenticated,
          error: null,
        );
      } else {
        // Usuário logado - carregar dados
        AppLogger.auth(
          '👤 Usuário logado, carregando dados...',
          data: {'uid': firebaseUser.uid, 'email': firebaseUser.email},
        );

        // 📊 Analytics: Login detectado
        await _trackAnalyticsEvent(
          'user_login_detected',
          data: {
            'uid': firebaseUser.uid,
            'email_domain': firebaseUser.email?.split('@').last,
            'login_method': 'auth_state_change',
          },
        );

        await _loadUserData(firebaseUser);
      }
    } catch (error) {
      // 📊 Analytics: Erro no processamento
      await _trackAnalyticsEvent(
        'auth_state_change_error',
        data: {'error_type': error.runtimeType.toString()},
      );

      _handleError('Erro ao processar mudança de autenticação', error);
    }
  }

  // Carregar dados do usuário
  Future<void> _loadUserData(dynamic firebaseUser) async {
    if (_disposed) return;

    final loadStartTime = DateTime.now();

    try {
      AppLogger.auth(
        '🔄 Carregando dados do usuário',
        data: {'uid': firebaseUser.uid},
      );

      // Manter loading durante carregamento
      state = state.copyWith(isLoading: true, error: null);

      // Buscar ou criar usuário no Firestore
      final userModel = await AuthService.getOrCreateUserInFirestore(
        firebaseUser,
      );

      if (_disposed) return;

      if (userModel != null) {
        final loadDuration = DateTime.now().difference(loadStartTime);

        AppLogger.auth(
          '✅ Dados do usuário carregados com sucesso',
          data: {
            'uid': userModel.uid,
            'username': userModel.username,
            'email': userModel.email,
            'level': userModel.level,
            'coins': userModel.coins,
            'load_duration_ms': loadDuration.inMilliseconds,
          },
        );

        // 📊 Analytics: Configurar usuário no analytics
        await AnalyticsIntegration.setUser(
          userId: userModel.uid,
          username: userModel.username,
          email: userModel.email,
          properties: {
            'level': userModel.level.toString(),
            'coins': userModel.coins.toString(),
            'gems': userModel.gems.toString(),
            'user_type': 'authenticated',
          },
        );

        // 📊 Analytics: Dados carregados com sucesso
        await _trackAnalyticsEvent(
          'user_data_loaded',
          data: {
            'load_duration_ms': loadDuration.inMilliseconds,
            'user_level': userModel.level,
            'user_coins': userModel.coins,
            'user_gems': userModel.gems,
            'is_new_user':
                userModel.createdAt.difference(DateTime.now()).inDays < 1,
          },
        );

        _updateState(
          user: userModel,
          isLoading: false,
          isInitialized: true,
          status: AuthStatus.authenticated,
          error: null,
        );
      } else {
        // Falha ao carregar dados - forçar logout
        AppLogger.auth(
          '❌ Falha ao carregar dados do usuário - forçando logout',
        );

        // 📊 Analytics: Falha no carregamento
        await _trackAnalyticsEvent(
          'user_data_load_failed',
          data: {
            'uid': firebaseUser.uid,
            'load_duration_ms': DateTime.now()
                .difference(loadStartTime)
                .inMilliseconds,
          },
        );

        await AuthService.signOut();
      }
    } catch (error) {
      final loadDuration = DateTime.now().difference(loadStartTime);

      // 📊 Analytics: Erro no carregamento
      await _trackAnalyticsEvent(
        'user_data_load_error',
        data: {
          'error_type': error.runtimeType.toString(),
          'load_duration_ms': loadDuration.inMilliseconds,
        },
      );

      _handleError('Erro ao carregar dados do usuário', error);

      // Em caso de erro, também forçar logout para manter consistência
      try {
        await AuthService.signOut();
      } catch (signOutError) {
        AppLogger.auth('❌ Erro adicional no logout: $signOutError');
      }
    }
  }

  // Handler para erros de autenticação
  void _handleAuthError(Object error) {
    _handleError('Erro no stream de autenticação', error);
  }

  // Handler genérico de erros
  void _handleError(String context, Object error) {
    AppLogger.auth('❌ $context: $error');

    if (!_disposed) {
      _updateState(
        isLoading: false,
        isInitialized: true,
        status: AuthStatus.error,
        error: error.toString(),
      );
    }
  }

  // Atualizar estado de forma segura
  void _updateState({
    UserModel? user,
    bool? isLoading,
    bool? isInitialized,
    AuthStatus? status,
    String? error,
  }) {
    if (!_disposed) {
      final newState = state.copyWith(
        user: user,
        isLoading: isLoading,
        isInitialized: isInitialized,
        status: status,
        error: error,
      );

      AppLogger.debug(
        '🔄 AuthState updated',
        data: {
          'previousStatus': state.status.toString(),
          'newStatus': newState.status.toString(),
          'isLoading': newState.isLoading,
          'isInitialized': newState.isInitialized,
          'hasUser': newState.user != null,
          'hasError': newState.error != null,
        },
      );

      state = newState;
    }
  }

  // ========== MÉTODOS PÚBLICOS ==========

  // Login com Google
  Future<bool> signInWithGoogle() async {
    if (state.isLoading) {
      AppLogger.auth('⚠️ Login já em andamento');
      return false;
    }

    final loginStartTime = DateTime.now();

    try {
      AppLogger.auth('🔄 Iniciando login com Google...');

      // 📊 Analytics: Tentativa de login
      await _trackAnalyticsEvent('login_attempt', data: {'method': 'google'});

      // Definir estado de loading
      _updateState(isLoading: true, error: null);

      // Fazer login
      final success = await AuthService.signInWithGoogle();

      final loginDuration = DateTime.now().difference(loginStartTime);

      if (success != null) {
        AppLogger.auth(
          '✅ Login com Google bem-sucedido',
          data: {
            'uid': success.uid,
            'username': success.username,
            'duration_ms': loginDuration.inMilliseconds,
          },
        );

        // 📊 Analytics: Login bem-sucedido
        await _trackAnalyticsEvent(
          'login_success',
          data: {
            'method': 'google',
            'duration_ms': loginDuration.inMilliseconds,
            'user_level': success.level,
          },
        );

        // O resultado será processado pelo stream de auth
        return true;
      } else {
        AppLogger.auth('❌ Login cancelado pelo usuário ou falhou');

        // 📊 Analytics: Login falhou
        await _trackAnalyticsEvent(
          'login_failed',
          data: {
            'method': 'google',
            'duration_ms': loginDuration.inMilliseconds,
            'reason': 'user_cancelled_or_error',
          },
        );

        _updateState(isLoading: false);
        return false;
      }
    } catch (error) {
      final loginDuration = DateTime.now().difference(loginStartTime);

      // 📊 Analytics: Erro no login
      await _trackAnalyticsEvent(
        'login_error',
        data: {
          'method': 'google',
          'duration_ms': loginDuration.inMilliseconds,
          'error_type': error.runtimeType.toString(),
        },
      );

      _handleError('Erro no login com Google', error);
      return false;
    }
  }

  // Logout
  Future<bool> signOut() async {
    if (state.isLoading && !state.isAuthenticated) {
      AppLogger.auth('⚠️ Logout já em andamento');
      return false;
    }

    final logoutStartTime = DateTime.now();
    final currentUserId = state.user?.uid;

    try {
      AppLogger.auth(
        '🔄 Iniciando logout...',
        data: {'currentUser': currentUserId ?? 'none'},
      );

      // 📊 Analytics: Tentativa de logout
      await _trackAnalyticsEvent(
        'logout_attempt',
        data: {
          'user_id': currentUserId,
          'session_duration_ms': _sessionStartTime != null
              ? DateTime.now().difference(_sessionStartTime!).inMilliseconds
              : null,
        },
      );

      // Definir estado de loading
      _updateState(isLoading: true, error: null);

      // Fazer logout
      await AuthService.signOut();

      final logoutDuration = DateTime.now().difference(logoutStartTime);

      AppLogger.auth('✅ Logout concluído com sucesso');

      // 📊 Analytics: Logout bem-sucedido
      await _trackAnalyticsEvent(
        'logout_success',
        data: {
          'duration_ms': logoutDuration.inMilliseconds,
          'user_id': currentUserId,
        },
      );

      // O resultado será processado pelo stream de auth
      return true;
    } catch (error) {
      final logoutDuration = DateTime.now().difference(logoutStartTime);

      // 📊 Analytics: Erro no logout
      await _trackAnalyticsEvent(
        'logout_error',
        data: {
          'duration_ms': logoutDuration.inMilliseconds,
          'error_type': error.runtimeType.toString(),
        },
      );

      _handleError('Erro no logout', error);
      return false;
    }
  }

  // Limpar erro
  void clearError() {
    if (!_disposed && state.error != null) {
      AppLogger.auth('🧹 Limpando erro de autenticação');

      // 📊 Analytics: Erro limpo
      _trackAnalyticsEvent('auth_error_cleared');

      state = state.copyWith(error: null);
    }
  }

  // Recarregar dados do usuário
  Future<void> refreshUser() async {
    if (!state.isAuthenticated) {
      AppLogger.auth('⚠️ Tentativa de refresh sem usuário autenticado');
      return;
    }

    try {
      AppLogger.auth('🔄 Recarregando dados do usuário...');

      // 📊 Analytics: Refresh iniciado
      await _trackAnalyticsEvent('user_refresh_started');

      final currentUser = AuthService.currentUser;
      if (currentUser != null) {
        await _loadUserData(currentUser);
      }
    } catch (error) {
      // 📊 Analytics: Erro no refresh
      await _trackAnalyticsEvent(
        'user_refresh_error',
        data: {'error_type': error.runtimeType.toString()},
      );

      _handleError('Erro ao recarregar usuário', error);
    }
  }

  // ========== NOVOS MÉTODOS PARA ONBOARDING (Fase 2) ==========

  // Completar onboarding
  Future<void> completeOnboarding() async {
    if (state.user == null) {
      throw Exception('User not authenticated');
    }

    try {
      AppLogger.auth(
        '🔄 Completando onboarding',
        data: {'uid': state.user!.uid},
      );

      // 📊 Analytics: Onboarding iniciado
      await _trackAnalyticsEvent(
        'onboarding_completed',
        data: {'user_id': state.user!.uid},
      );

      // Força uma atualização do estado de autenticação
      await refreshUser();

      AppLogger.auth('✅ Onboarding completed', data: {'uid': state.user!.uid});
    } catch (e) {
      AppLogger.auth('❌ Complete onboarding failed: $e');

      // 📊 Analytics: Erro no onboarding
      await _trackAnalyticsEvent(
        'onboarding_error',
        data: {'error_type': e.runtimeType.toString()},
      );

      _handleError('Erro ao completar onboarding', e);
      rethrow;
    }
  }

  // Forçar recheck do status de onboarding
  Future<void> recheckOnboardingStatus() async {
    if (!state.isAuthenticated) return;

    try {
      AppLogger.auth('🔄 Verificando status de onboarding...');
      await refreshUser();
    } catch (error) {
      _handleError('Erro ao verificar status de onboarding', error);
    }
  }

  // ========== MÉTODOS DE ANALYTICS ==========

  /// Método helper para rastrear eventos de analytics
  Future<void> _trackAnalyticsEvent(
    String eventName, {
    Map<String, dynamic>? data,
  }) async {
    try {
      if (AnalyticsIntegration.isEnabled) {
        await AnalyticsIntegration.manager.trackEvent(
          eventName,
          parameters: data,
          category: EventCategory.user,
          priority: EventPriority.medium,
        );
      }
    } catch (e) {
      // Não interromper fluxo principal por falha em analytics
      AppLogger.debug('Falha ao rastrear evento de analytics: $e');
    }
  }

  @override
  void dispose() {
    AppLogger.auth('🧹 Disposing AuthProvider');

    // 📊 Analytics: Provider sendo disposed
    _trackAnalyticsEvent(
      'auth_provider_disposed',
      data: {
        'session_duration_ms': _sessionStartTime != null
            ? DateTime.now().difference(_sessionStartTime!).inMilliseconds
            : null,
      },
    );

    _disposed = true;
    _authSubscription?.cancel();
    super.dispose();
  }
}
