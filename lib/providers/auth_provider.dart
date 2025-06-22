import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' show User;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:unlock/core/utils/logger.dart';
import 'package:unlock/models/user_model.dart';
import 'package:unlock/services/auth_service.dart';

// Provider principal
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref); // ✅ NOVO: Passar ref para triggers
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

  // Getters convenientes para navegação
  bool get isAuthenticated =>
      user != null && status == AuthStatus.authenticated;

  bool get canNavigate => isInitialized && !isLoading && error == null;

  // ✅ ONBOARDING - Verifica se usuário precisa completar perfil
  bool get needsOnboarding {
    // A única fonte de verdade para o fluxo de navegação deve ser o booleano
    // `onboardingCompleted`. Se o usuário está autenticado, mas não completou
    // o onboarding, ele precisa ser direcionado para o fluxo de onboarding.
    // As validações de campos individuais pertencem à lógica interna do onboarding.
    return isAuthenticated && user != null && !user!.onboardingCompleted;
  }

  // ✅ GETTER PARA VERIFICAR SE É MENOR DE IDADE
  bool get isMinor {
    // Correção: Acessa birthDate através do objeto user
    if (user?.birthDate == null) return false;
    final age = DateTime.now().difference(user!.birthDate!).inDays ~/ 365;
    return age < 18;
  }

  // ✅ GETTER PARA IDADE
  int? get age {
    // Correção: Acessa birthDate através do objeto user
    if (user?.birthDate == null) return null;
    return DateTime.now().difference(user!.birthDate!).inDays ~/ 365;
  }

  // Propriedades de navegação
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

  // Propriedades legadas (compatibilidade)
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
      user:
          user, // Note: user is explicitly passed as nullable to allow nulling it out
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

  when({
    required Center Function() loading,
    required Center Function(dynamic error, dynamic stack) error,
    required Widget Function(dynamic user) data,
  }) {}
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
  final Ref _ref; // ✅ NOVO: Referência para triggers
  StreamSubscription? _authSubscription;
  bool _disposed = false;
  DateTime? _sessionStartTime;

  AuthNotifier(this._ref) : super(const AuthState()) {
    _initialize(); // Inicia o listener de autenticação
  }

  /// Inicializa o Notifier, escutando as mudanças de autenticação.
  void _initialize() {
    AppLogger.auth('🚀 AuthNotifier Initializing...');
    _updateState(isLoading: true, isInitialized: false);

    _authSubscription = AuthService.authStateChanges.listen((
      firebaseUser,
    ) async {
      if (_disposed) return;
      if (firebaseUser != null) {
        AppLogger.auth(
          '🔥 Auth stream event: User found (uid: ${firebaseUser.uid})',
        );
        await _handleUserLogin(firebaseUser);
      } else {
        AppLogger.auth('🔥 Auth stream event: No user found.');
        await _handleUserLogout();
      }
    }, onError: _handleAuthError);
  }

  /// Lida com o login bem-sucedido, buscando dados do usuário.
  Future<void> _handleUserLogin(User firebaseUser) async {
    if (_disposed) return;
    try {
      AppLogger.auth('🔄 Handling user login for ${firebaseUser.uid}');
      // Mantém o loading enquanto busca dados do Firestore
      _updateState(isLoading: true);

      final userModel = await AuthService.getOrCreateUserInFirestore(
        firebaseUser,
      );

      if (userModel != null && !_disposed) {
        AppLogger.auth('✅ User model loaded: ${userModel.username}');
        _sessionStartTime = DateTime.now();
        _updateState(
          user: userModel,
          isLoading: false,
          isInitialized: true,
          status: AuthStatus.authenticated,
          error: null,
        );
        await _trackAnalyticsEvent(
          'user_logged_in',
          data: {'uid': userModel.uid},
        );
      } else if (!_disposed) {
        AppLogger.auth('❌ Could not get or create user model in Firestore.');
        await AuthService.signOut(); // Força logout se dados do usuário falharem
        _handleError('Failed to load user data.', null);
      }
    } catch (e, stackTrace) {
      AppLogger.error(
        '❌ Error in _handleUserLogin',
        error: e,
        stackTrace: stackTrace,
      );
      _handleError('Error processing login.', e);
    }
  }

  /// Lidar com logout do usuário
  Future<void> _handleUserLogout() async {
    if (_disposed) return;
    try {
      AppLogger.auth('🧹 Limpando estado do usuário (logout)');
      // Analytics: Logout processado
      await _trackAnalyticsEvent('user_logged_out');
      _updateState(
        user: null,
        isLoading: false,
        isInitialized: true,
        status: AuthStatus.unauthenticated,
        error: null,
        // user: null já está implícito ao definir AuthStatus.unauthenticated
        // e error: null. copyWith com user: null fará isso.
      );
      AppLogger.auth('✅ Logout processado com sucesso');
    } catch (e) {
      AppLogger.error('❌ Erro durante logout', error: e);
      // Forçar limpeza mesmo com erro
      _updateState(
        user: null,
        isLoading: false,
        isInitialized: true,
        status: AuthStatus.unauthenticated,
        error: null,
        // user: null
      );
    }

    AppLogger.auth('✅ Logout finalizado, estado atual: $state');
  }

  /// Login com Google
  Future<bool> signInWithGoogle() async {
    if (_disposed) return false;
    try {
      AppLogger.auth('🔑 Iniciando login com Google...');
      _updateState(
        isLoading: true,
        error: null,
        status: AuthStatus.unknown,
      ); // Mantém isInitialized como está ou false
      final result = await AuthService.signInWithGoogle();
      if (result != null) {
        AppLogger.auth('✅ Login com Google bem-sucedido');
        await _trackAnalyticsEvent('google_sign_in_success');
        return true;
      } else {
        AppLogger.auth('❌ Login com Google falhou');
        await _trackAnalyticsEvent('google_sign_in_failed');
        _updateState(
          isLoading: false,
          isInitialized: true,
          error: 'Falha no login com Google',
          status: AuthStatus.error,
        );
        return false;
      }
    } catch (error) {
      AppLogger.error('❌ Erro no login com Google', error: error);
      await _trackAnalyticsEvent(
        'google_sign_in_error',
        data: {'error': error.toString()},
      );
      _handleError('Erro no login com Google', error);
      return false;
    }
  }

  /// Logout
  Future<void> signOut() async {
    if (_disposed) return;
    try {
      AppLogger.auth('🚪 Fazendo logout...');
      _updateState(
        isLoading: true,
        status: state.status,
      ); // Mantém o status atual enquanto faz logout
      await AuthService.signOut();
      AppLogger.auth('✅ Logout realizado com sucesso');
      // Chamar _handleUserLogout explicitamente para garantir que o estado seja limpo
      // e o GoRouter seja notificado imediatamente.
      await _handleUserLogout(); // Isso já define isLoading: false e status corretos.
      await _trackAnalyticsEvent(
        'user_sign_out',
      ); // Mover analytics para depois da atualização do estado
    } catch (error) {
      AppLogger.error('❌ Erro no logout', error: error);
      _handleError('Erro no logout', error);
      // Mesmo em erro, garantir que o estado de logout seja refletido se possível
      if (!_disposed && state.isAuthenticated) {
        await _handleUserLogout();
      }
    }
  }

  /// Desbloqueia uma feature para o usuário atual.
  Future<void> unlockFeature(String featureName) async {
    if (_disposed || state.user == null) return;

    final currentUser = state.user!;
    if (currentUser.unlockedFeatures[featureName] == true) {
      AppLogger.auth(
        '🔓 Feature "$featureName" já está desbloqueada para ${currentUser.uid}.',
      );
      return;
    }

    AppLogger.auth(
      '🔓 Tentando desbloquear feature "$featureName" para ${currentUser.uid}.',
    );

    // 1. Atualizar o UserModel localmente
    final newUnlockedFeatures = Map<String, bool>.from(
      currentUser.unlockedFeatures,
    );
    newUnlockedFeatures[featureName] = true;
    final updatedUser = currentUser.copyWith(
      unlockedFeatures: newUnlockedFeatures,
    );

    _updateState(
      user: updatedUser,
    ); // Atualiza o estado do AuthProvider imediatamente

    try {
      // 2. Persistir a mudança no Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .update({
            'unlockedFeatures.$featureName': true,
          }); // Atualiza apenas o campo específico no mapa

      AppLogger.auth(
        '✅ Feature "$featureName" desbloqueada e persistida para ${currentUser.uid}.',
      );
      await _trackAnalyticsEvent(
        'feature_unlocked',
        data: {'feature_name': featureName, 'user_id': currentUser.uid},
      );
    } catch (e) {
      AppLogger.error(
        '❌ Erro ao persistir desbloqueio da feature "$featureName"',
        error: e,
      );
      // Opcional: Reverter a mudança local se a persistência falhar?
      // _updateState(user: currentUser); // Reverte para o estado anterior
    }
  }

  /// ✅ Atualiza o humor do usuário no estado local e no Firestore.
  /// Se o mesmo humor for selecionado novamente, ele será desmarcado (null).
  Future<void> updateUserMood(String moodId) async {
    if (_disposed || state.user == null) {
      AppLogger.warning(
        'AuthProvider: Tentativa de atualizar humor sem usuário logado ou provider descartado.',
      );
      return;
    }

    final currentUser = state.user!;
    // Permite desmarcar o humor se o mesmo for tocado novamente
    final String? newMood = currentUser.currentMood == moodId ? null : moodId;

    AppLogger.auth(
      '🎭 Atualizando humor do usuário para: $newMood',
      data: {'uid': currentUser.uid, 'oldMood': currentUser.currentMood},
    );

    // 1. Atualiza o estado local imediatamente para uma UI responsiva
    final updatedUser = currentUser.copyWith(currentMood: () => newMood);
    _updateState(user: updatedUser);

    try {
      // 2. Persiste a mudança no Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .update({'currentMood': newMood});

      AppLogger.auth(
        '✅ Humor do usuário atualizado e persistido no Firestore.',
      );
    } catch (e) {
      AppLogger.error(
        '❌ Erro ao persistir humor do usuário no Firestore',
        error: e,
        stackTrace: StackTrace.current,
      );
      // Reverte a mudança local se a persistência falhar
      _updateState(user: currentUser);
    }
  }

  /// Atualizar dados do usuário
  Future<void> refreshUser() async {
    if (_disposed) return;
    try {
      AppLogger.auth('🔄 Refresh silencioso dos dados do usuário...');
      final firebaseUser = AuthService.currentUser;
      if (firebaseUser == null) {
        AppLogger.auth('⚠️ Nenhum usuário logado para atualizar');
        return;
      }
      // ✅ CORREÇÃO: NÃO CHAMAR _handleUserLogin QUE MEXE NO LOADING
      // await _handleUserLogin(firebaseUser);  // ❌ LINHA ORIGINAL PROBLEMÁTICA
      // ✅ VERSÃO CORRIGIDA: CARREGAR DADOS SEM ALTERAR LOADING STATE
      try {
        AppLogger.auth('🔄 Carregando dados do usuário silenciosamente...');
        // Buscar dados do Firestore diretamente - SEM mexer no loading
        final userModel = await AuthService.getOrCreateUserInFirestore(
          firebaseUser,
        );
        if (userModel != null && !_disposed) {
          // ✅ ATUALIZAR APENAS OS DADOS DO USUÁRIO
          // NÃO mexer em isLoading, isInitialized, status
          _updateState(user: userModel);
          AppLogger.auth('✅ Dados do usuário atualizados silenciosamente');
          // ✅ Analytics opcional (sem afetar o estado)
          await _trackAnalyticsEvent(
            'user_data_refreshed_silently',
            data: {
              'user_level': userModel.level,
              'onboarding_completed': userModel.onboardingCompleted,
            },
          );
        }
      } catch (loadError) {
        AppLogger.auth('❌ Erro ao carregar dados silenciosamente: $loadError');
        // ✅ NÃO ALTERAR O ESTADO EM CASO DE ERRO NO REFRESH
        // Manter usuário logado para evitar redirecionamento indesejado
      }
    } catch (error) {
      AppLogger.auth('❌ Erro no refresh silencioso: $error');
      // ✅ NÃO CHAMAR _handleError QUE MEXE NO STATUS
      // _handleError('Erro ao atualizar usuário', error);  // ❌ LINHA ORIGINAL
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

  /// Recheck do status de onboarding
  Future<void> recheckOnboardingStatus() async {
    if (!state.isAuthenticated || _disposed) return;
    try {
      AppLogger.auth('🔄 Verificando status de onboarding...');
      await refreshUser();
    } catch (error) {
      _handleError('Erro ao verificar status de onboarding', error);
    }
  }

  /// Handler de erro de autenticação
  void _handleAuthError(error) {
    AppLogger.error('❌ Erro no stream de autenticação', error: error);
    _handleError('Erro no stream de autenticação', error);
  }

  /// Handler genérico de erros
  void _handleError(String message, dynamic error) {
    if (_disposed) return;
    AppLogger.error('❌ $message: $error');
    AppLogger.error(message, error: error);
    _updateState(
      isLoading: false,
      isInitialized: true,
      error: message,
      status: AuthStatus.error,
      user: state.status == AuthStatus.authenticated
          ? state.user
          : null, // Mantém o usuário se o erro ocorreu após autenticação
    );
  }

  /// Atualizar estado do provider
  void _updateState({
    UserModel? user,
    bool? isLoading,
    bool? isInitialized,
    String? error,
    AuthStatus? status,
  }) {
    if (_disposed) return;
    state = state.copyWith(
      user: user,
      isLoading: isLoading,
      isInitialized: isInitialized,
      error: error,
      status: status,
    );
  }

  /// Fazer tracking de analytics
  Future<void> _trackAnalyticsEvent(
    String eventName, {
    Map<String, dynamic>? data,
  }) async {
    try {
      // Por enquanto apenas log - implementar analytics real depois
      AppLogger.debug('📊 Analytics: $eventName', data: data);
    } catch (e) {
      AppLogger.warning('⚠️ Falha no analytics: $e');
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _authSubscription?.cancel();
    super.dispose();
  }

  Future<void> updateUserData(UserModel updatedUser) async {}
}
