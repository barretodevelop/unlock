// lib/providers/auth_provider.dart - CORRIGIDO para Onboarding
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

    // 🔧 FIX: Verificação mais rigorosa para novos usuários
    final hasOnboardingCompleted = user!.onboardingCompleted;
    final hasCodinome = user!.codinome != null && user!.codinome!.isNotEmpty;
    final hasAvatarId = user!.avatarId != null && user!.avatarId!.isNotEmpty;
    final hasInterests = user!.interesses.isNotEmpty;
    final hasBirthDate = user!.birthDate != null;

    // Debug detalhado para identificar problemas
    if (kDebugMode) {
      AppLogger.debug('🔍 ONBOARDING CHECK for ${user!.uid}:');
      AppLogger.debug('  ✓ onboardingCompleted: $hasOnboardingCompleted');
      AppLogger.debug(
        '  ✓ codinome: "${user!.codinome}" (hasCodinome: $hasCodinome)',
      );
      AppLogger.debug(
        '  ✓ avatarId: "${user!.avatarId}" (hasAvatarId: $hasAvatarId)',
      );
      AppLogger.debug(
        '  ✓ interesses: ${user!.interesses} (count: ${user!.interesses.length})',
      );
      AppLogger.debug(
        '  ✓ birthDate: ${user!.birthDate} (hasBirthDate: $hasBirthDate)',
      );

      final needsOnboardingResult =
          !hasOnboardingCompleted ||
          !hasCodinome ||
          !hasAvatarId ||
          !hasInterests ||
          !hasBirthDate;

      AppLogger.debug('  🎯 RESULT: needsOnboarding = $needsOnboardingResult');
    }

    // 🔧 FIX: Verificação mais rigorosa
    // Um usuário precisa de onboarding se:
    // 1. Não marcou onboarding como completo OU
    // 2. Qualquer campo obrigatório está vazio
    return !hasOnboardingCompleted ||
        !hasCodinome ||
        !hasAvatarId ||
        !hasInterests ||
        !hasBirthDate;
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

  // 🔧 FIX: Inicialização mais robusta
  Future<void> _initialize() async {
    if (_disposed) return;

    try {
      _sessionStartTime = DateTime.now();
      AppLogger.auth('🔄 Inicializando AuthProvider...');

      // 📊 Analytics: Início da inicialização de auth
      await _trackAnalyticsEvent('auth_provider_init_start');

      // 🔧 FIX: Resetar estado completamente
      state = const AuthState(
        isLoading: true,
        status: AuthStatus.unknown,
        isInitialized: false,
      );

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
      _handleError('Erro na inicialização do AuthProvider', error);
    }
  }

  // 🔧 FIX: Handling melhorado para mudanças de auth
  Future<void> _handleAuthStateChange(dynamic firebaseUser) async {
    if (_disposed) return;

    try {
      AppLogger.auth(
        '🔄 Mudança no estado de autenticação',
        data: {
          'hasUser': firebaseUser != null,
          'uid': firebaseUser?.uid,
          'email': firebaseUser?.email,
        },
      );

      if (firebaseUser == null) {
        // 🔧 FIX: Limpar estado completamente no logout
        _clearUserState();
      } else {
        // 🔧 FIX: Carregar dados com verificação rigorosa
        await _loadUserDataWithValidation(firebaseUser);
      }
    } catch (error) {
      _handleError('Erro ao processar mudança de autenticação', error);
    }
  }

  // 🔧 FIX: Novo método para limpar estado no logout
  void _clearUserState() {
    AppLogger.auth('🧹 Limpando estado do usuário (logout)');

    // 📊 Analytics: Logout processado
    _trackAnalyticsEvent('user_logged_out');

    _updateState(
      user: null,
      isLoading: false,
      isInitialized: true,
      status: AuthStatus.unauthenticated,
      error: null,
    );
  }

  // 🔧 FIX: Carregamento de dados com validação rigorosa
  Future<void> _loadUserDataWithValidation(dynamic firebaseUser) async {
    if (_disposed) return;

    try {
      final loadStartTime = DateTime.now();

      AppLogger.auth('🔄 Carregando dados do usuário: ${firebaseUser.uid}');

      // Manter loading durante carregamento
      _updateState(isLoading: true, error: null);

      // 🔧 FIX: Sempre buscar dados frescos do Firestore
      final userModel = await AuthService.getOrCreateUserInFirestore(
        firebaseUser,
      );

      if (_disposed) return;

      if (userModel != null) {
        final loadDuration = DateTime.now().difference(loadStartTime);

        // 🔧 FIX: Log detalhado dos dados carregados
        AppLogger.auth(
          '✅ Dados do usuário carregados com sucesso',
          data: {
            'uid': userModel.uid,
            'username': userModel.username,
            'email': userModel.email,
            'level': userModel.level,
            'coins': userModel.coins,
            'onboardingCompleted': userModel.onboardingCompleted,
            'needsOnboarding': userModel.needsOnboarding,
            'codinome': userModel.codinome,
            'avatarId': userModel.avatarId,
            'interesses_count': userModel.interesses.length,
            'birthDate': userModel.birthDate?.toString(),
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
            'onboarding_completed': userModel.onboardingCompleted.toString(),
            'needs_onboarding': userModel.needsOnboarding.toString(),
            'is_minor': userModel.isMinor.toString(),
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
            'onboarding_completed': userModel.onboardingCompleted,
            'needs_onboarding': userModel.needsOnboarding,
            'is_new_user': userModel.createdAt.isAfter(
              DateTime.now().subtract(const Duration(minutes: 5)),
            ),
          },
        );

        _updateState(
          user: userModel,
          isLoading: false,
          isInitialized: true,
          status: AuthStatus.authenticated,
          error: null,
        );

        // 🔧 FIX: Log final do estado para debug
        AppLogger.auth(
          '🎯 Estado final do usuário',
          data: {
            'needsOnboarding': userModel.needsOnboarding,
            'shouldShowOnboarding': state.shouldShowOnboarding,
            'shouldShowHome': state.shouldShowHome,
          },
        );
      } else {
        // Falha ao carregar dados - forçar logout
        AppLogger.auth('❌ Falha ao carregar dados do usuário');
        await AuthService.signOut();
      }
    } catch (error) {
      _handleError('Erro ao carregar dados do usuário', error);
      // Em caso de erro, também forçar logout para manter consistência
      try {
        await AuthService.signOut();
      } catch (signOutError) {
        AppLogger.auth('❌ Erro adicional no logout: $signOutError');
      }
    }
  }

  // Métodos públicos originais mantidos...
  Future<bool> signInWithGoogle() async {
    if (state.isLoading) {
      AppLogger.auth('⚠️ Login já em andamento');
      return false;
    }

    try {
      AppLogger.auth('🔄 Iniciando login com Google...');

      _updateState(isLoading: true, error: null);

      final success = await AuthService.signInWithGoogle();

      if (success != null) {
        AppLogger.auth('✅ Login com Google iniciado');
        return true;
      } else {
        AppLogger.auth('❌ Login cancelado pelo usuário');
        _updateState(isLoading: false);
        return false;
      }
    } catch (error) {
      _handleError('Erro no login com Google', error);
      return false;
    }
  }

  Future<bool> signOut() async {
    if (state.isLoading && !state.isAuthenticated) {
      AppLogger.auth('⚠️ Logout já em andamento');
      return false;
    }

    try {
      AppLogger.auth('🔄 Iniciando logout...');

      _updateState(isLoading: true, error: null);

      await AuthService.signOut();

      AppLogger.auth('✅ Logout concluído');
      return true;
    } catch (error) {
      _handleError('Erro no logout', error);
      return false;
    }
  }

  void clearError() {
    if (!_disposed) {
      state = state.copyWith(error: null);
    }
  }

  Future<void> refreshUser() async {
    if (!state.isAuthenticated) return;

    try {
      AppLogger.auth('🔄 Recarregando dados do usuário...');

      final currentUser = AuthService.currentUser;
      if (currentUser != null) {
        await _loadUserDataWithValidation(currentUser);
      }
    } catch (error) {
      _handleError('Erro ao recarregar usuário', error);
    }
  }

  /// ✅ Atualiza o estado do usuário localmente com os dados completos do onboarding.
  /// Usado para evitar uma releitura do Firestore imediatamente após o onboarding.
  void updateUserWithOnboardingData(UserModel updatedUser) {
    if (_disposed) return;

    AppLogger.auth(
      '🔄 Atualizando AuthState localmente com dados do onboarding completo',
      data: {
        'userId': updatedUser.uid,
        'onboardingCompleted': updatedUser.onboardingCompleted,
        'codinome': updatedUser.codinome,
      },
    );
    _updateState(
      user: updatedUser,
      isLoading: false, // Onboarding concluído, não estamos carregando auth
      status: AuthStatus.authenticated, // Usuário continua autenticado
    );
  }

  // Completar onboarding
  Future<void> completeOnboarding() async {
    if (state.user == null) {
      throw Exception('User not authenticated');
    }

    try {
      AppLogger.auth(
        '🔄 Completando onboarding para usuário ${state.user!.uid}',
      );

      // Atualizar estado local imediatamente
      final updatedUser = state.user!.copyWith(onboardingCompleted: true);

      _updateState(user: updatedUser);

      AppLogger.auth('✅ Onboarding marcado como completado');

      // 📊 Analytics
      await _trackAnalyticsEvent('onboarding_completed_via_auth_provider');
    } catch (error) {
      _handleError('Erro ao completar onboarding', error);
      rethrow;
    }
  }

  // Helpers privados...
  void _handleAuthError(Object error) {
    _handleError('Erro no stream de autenticação', error);
  }

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

  void _updateState({
    UserModel? user,
    bool? isLoading,
    bool? isInitialized,
    AuthStatus? status,
    String? error,
  }) {
    if (!_disposed) {
      state = state.copyWith(
        user: user,
        isLoading: isLoading,
        isInitialized: isInitialized,
        status: status,
        error: error,
      );
    }
  }

  Future<void> _trackAnalyticsEvent(
    String eventName, {
    Map<String, dynamic>? data,
  }) async {
    try {
      if (AnalyticsIntegration.isEnabled) {
        await AnalyticsIntegration.manager.trackEvent(
          eventName,
          parameters: data,
          category: EventCategory.auth,
          priority: EventPriority.high,
        );
      }
    } catch (e) {
      AppLogger.debug('Falha ao rastrear evento de auth: $e');
    }
  }

  @override
  void dispose() {
    AppLogger.auth('🧹 Disposing AuthProvider');
    _disposed = true;
    _authSubscription?.cancel();
    super.dispose();
  }
}
