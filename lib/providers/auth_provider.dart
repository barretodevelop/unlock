// lib/providers/auth_provider.dart
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:unlock/models/user_model.dart';
import 'package:unlock/services/auth_service.dart';

// Provider principal
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});

// lib/providers/auth_provider.dart - NAVEGAÇÃO CORRIGIDA
// Substitua apenas a classe AuthState por esta versão:

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

    // Debug para verificar valores
    if (kDebugMode) {
      print('🔍 Checking onboarding for ${user!.uid}:');
      print('  onboardingCompleted: ${user!.onboardingCompleted}');
      print('  codinome: "${user!.codinome}"');
      print('  interesses.length: ${user!.interesses.length}');
      print('  relationshipInterest: "${user!.relationshipInterest}"');
      print('  needsOnboarding: ${user!.needsOnboarding}');
    }

    return user!.needsOnboarding;
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

  AuthNotifier() : super(const AuthState()) {
    _initialize();
  }

  // Inicialização do provider
  Future<void> _initialize() async {
    if (_disposed) return;

    try {
      _log('🔄 Inicializando AuthProvider...');

      // Definir estado de carregamento
      state = state.copyWith(isLoading: true, status: AuthStatus.unknown);

      // Escutar mudanças de autenticação
      _authSubscription = AuthService.authStateChanges.listen(
        _handleAuthStateChange,
        onError: _handleAuthError,
      );
    } catch (error) {
      _handleError('Erro na inicialização', error);
    }
  }

  // Handler para mudanças no estado de autenticação
  Future<void> _handleAuthStateChange(dynamic firebaseUser) async {
    if (_disposed) return;

    try {
      _log('🔄 Auth state changed: ${firebaseUser?.uid ?? 'null'}');

      if (firebaseUser == null) {
        // Usuário deslogado
        _updateState(
          user: null,
          isLoading: false,
          isInitialized: true,
          status: AuthStatus.unauthenticated,
          error: null,
        );
      } else {
        // Usuário logado - carregar dados
        await _loadUserData(firebaseUser);
      }
    } catch (error) {
      _handleError('Erro ao processar mudança de autenticação', error);
    }
  }

  // Carregar dados do usuário
  Future<void> _loadUserData(dynamic firebaseUser) async {
    if (_disposed) return;

    try {
      _log('🔄 Carregando dados do usuário: ${firebaseUser.uid}');

      // Manter loading durante carregamento
      state = state.copyWith(isLoading: true, error: null);

      // Buscar ou criar usuário no Firestore
      final userModel = await AuthService.getOrCreateUserInFirestore(
        firebaseUser,
      );

      if (_disposed) return;

      if (userModel != null) {
        _updateState(
          user: userModel,
          isLoading: false,
          isInitialized: true,
          status: AuthStatus.authenticated,
          error: null,
        );
        _log(
          '✅ Usuário carregado: ${userModel.username} (onboarding: ${userModel.needsOnboarding ? 'pendente' : 'completo'})',
        );
      } else {
        // Falha ao carregar dados - forçar logout
        _log('❌ Falha ao carregar dados do usuário');
        await AuthService.signOut();
      }
    } catch (error) {
      _handleError('Erro ao carregar dados do usuário', error);
      // Em caso de erro, também forçar logout para manter consistência
      try {
        await AuthService.signOut();
      } catch (signOutError) {
        _log('❌ Erro adicional no logout: $signOutError');
      }
    }
  }

  // Handler para erros de autenticação
  void _handleAuthError(Object error) {
    _handleError('Erro no stream de autenticação', error);
  }

  // Handler genérico de erros
  void _handleError(String context, Object error) {
    _log('❌ $context: $error');

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
      state = state.copyWith(
        user: user,
        isLoading: isLoading,
        isInitialized: isInitialized,
        status: status,
        error: error,
      );
    }
  }

  // ========== MÉTODOS PÚBLICOS ORIGINAIS ==========

  // Login com Google
  Future<bool> signInWithGoogle() async {
    if (state.isLoading) {
      _log('⚠️ Login já em andamento');
      return false;
    }

    try {
      _log('🔄 Iniciando login com Google...');

      // Definir estado de loading
      _updateState(isLoading: true, error: null);

      // Fazer login
      final success = await AuthService.signInWithGoogle();

      if (success) {
        _log('✅ Login com Google iniciado');
        // O resultado será processado pelo stream de auth
        return true;
      } else {
        _log('❌ Login cancelado pelo usuário');
        _updateState(isLoading: false);
        return false;
      }
    } catch (error) {
      _handleError('Erro no login com Google', error);
      return false;
    }
  }

  // Logout
  Future<bool> signOut() async {
    if (state.isLoading && !state.isAuthenticated) {
      _log('⚠️ Logout já em andamento');
      return false;
    }

    try {
      _log('🔄 Iniciando logout...');

      // Definir estado de loading
      _updateState(isLoading: true, error: null);

      // Fazer logout
      await AuthService.signOut();

      _log('✅ Logout concluído');
      // O resultado será processado pelo stream de auth
      return true;
    } catch (error) {
      _handleError('Erro no logout', error);
      return false;
    }
  }

  // Limpar erro
  void clearError() {
    if (!_disposed) {
      state = state.copyWith(error: null);
    }
  }

  // Recarregar dados do usuário
  Future<void> refreshUser() async {
    if (!state.isAuthenticated) return;

    try {
      _log('🔄 Recarregando dados do usuário...');

      final currentUser = AuthService.currentUser;
      if (currentUser != null) {
        await _loadUserData(currentUser);
      }
    } catch (error) {
      _handleError('Erro ao recarregar usuário', error);
    }
  }

  // ========== ✅ NOVOS MÉTODOS PARA ONBOARDING ==========

  // Completar onboarding
  Future<void> completeOnboarding() async {
    if (state.user == null) {
      throw Exception('User not authenticated');
    }

    try {
      _log('🔄 Completando onboarding para usuário ${state.user!.uid}...');

      // Força uma atualização do estado de autenticação
      // Isso garantirá que o usuário seja redirecionado corretamente
      await refreshUser();

      _log('✅ Onboarding completed for user ${state.user!.uid}');
    } catch (e) {
      _log('❌ Complete onboarding failed: $e');
      _handleError('Erro ao completar onboarding', e);
      rethrow;
    }
  }

  // Forçar recheck do status de onboarding (útil após updates de perfil)
  Future<void> recheckOnboardingStatus() async {
    if (!state.isAuthenticated) return;

    try {
      _log('🔄 Verificando status de onboarding...');
      await refreshUser();
    } catch (error) {
      _handleError('Erro ao verificar status de onboarding', error);
    }
  }

  // ========== MÉTODOS AUXILIARES ==========

  // Método interno para verificar status de auth (já existe como refreshUser, mantendo compatibilidade)
  Future<void> _checkAuthStatus() async {
    await refreshUser();
  }

  // ========== UTILITÁRIOS ==========

  void _log(String message) {
    if (kDebugMode) {
      print('AuthProvider: $message');
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _authSubscription?.cancel();
    super.dispose();
  }
}
