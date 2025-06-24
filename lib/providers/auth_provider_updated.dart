// lib/providers/auth_provider_updated.dart
// Atualização do AuthProvider para integrar sistema de streaks

import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:unlock/core/utils/logger.dart';
import 'package:unlock/models/user_model.dart';
import 'package:unlock/providers/currency_provider.dart';
import 'package:unlock/providers/streak_provider.dart'; // ✅ NOVO IMPORT
import 'package:unlock/services/auth_service.dart';
import 'package:unlock/services/firestore_service.dart';

// ========================================
// ESTADO DA AUTENTICAÇÃO
// ========================================

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

  // Getters computados
  bool get isAuthenticated =>
      user != null && status == AuthStatus.authenticated;
  bool get needsOnboarding => user?.needsOnboarding ?? false;
  bool get shouldShowLogin => !isAuthenticated && isInitialized;
  bool get shouldShowOnboarding => isAuthenticated && needsOnboarding;
  bool get shouldShowHome => isAuthenticated && !needsOnboarding;

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
enum AuthStatus { unknown, authenticated, unauthenticated, error }

// ========================================
// NOTIFIER DA AUTENTICAÇÃO
// ========================================

class AuthNotifier extends StateNotifier<AuthState> {
  final Ref _ref;
  StreamSubscription? _authSubscription;
  bool _disposed = false;
  DateTime? _sessionStartTime;

  AuthNotifier(this._ref) : super(const AuthState()) {
    _initialize();
  }

  @override
  void dispose() {
    _disposed = true;
    _authSubscription?.cancel();
    super.dispose();
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
  Future<void> _handleUserLogin(firebase_auth.User firebaseUser) async {
    try {
      _updateState(isLoading: true);

      final firestoreService = _ref.read(firestoreServiceProvider);
      UserModel? user = await firestoreService.getUser(firebaseUser.uid);

      if (user == null) {
        AppLogger.auth('👤 User not found in Firestore, creating new user...');
        user = UserModel.createInitial(
          uid: firebaseUser.uid,
          email: firebaseUser.email ?? '',
          displayName: firebaseUser.displayName,
          photoURL: firebaseUser.photoURL,
        );

        await firestoreService.createUser(user);
        AppLogger.auth('✅ New user created successfully');
      } else {
        AppLogger.auth('✅ Existing user found and loaded');
      }

      _updateState(
        user: user,
        isLoading: false,
        isInitialized: true,
        status: AuthStatus.authenticated,
      );

      // ✅ NOVO: Processa login streak e recompensas
      await _processLoginRewards(user);

      _sessionStartTime = DateTime.now();
      AppLogger.auth(
        '🎉 Login completed successfully',
        data: {
          'uid': user.uid,
          'needsOnboarding': user.needsOnboarding,
          'sessionStart': _sessionStartTime?.toIso8601String(),
        },
      );
    } catch (e, stackTrace) {
      AppLogger.error(
        '❌ Error handling user login',
        error: e,
        stackTrace: stackTrace,
      );
      _updateState(
        isLoading: false,
        isInitialized: true,
        status: AuthStatus.error,
        error: _parseError(e),
      );
    }
  }

  /// ✅ NOVO: Processa recompensas de login e streak
  Future<void> _processLoginRewards(UserModel user) async {
    try {
      AppLogger.auth('💰 Processing login rewards...');

      // Processa streak de login
      final streakNotifier = _ref.read(streakProvider.notifier);
      await streakNotifier.processLogin();

      // Inicializa sistema de moedas se necessário
      final currencyNotifier = _ref.read(currencyProvider.notifier);
      await currencyNotifier.refresh();

      AppLogger.auth('✅ Login rewards processed successfully');
    } catch (e, stackTrace) {
      AppLogger.error(
        '❌ Failed to process login rewards',
        error: e,
        stackTrace: stackTrace,
      );
      // Não impede o login por falha nas recompensas
    }
  }

  /// Lida com o logout do usuário.
  Future<void> _handleUserLogout() async {
    AppLogger.auth('👋 User logged out');

    // Log session duration se houver
    if (_sessionStartTime != null) {
      final sessionDuration = DateTime.now().difference(_sessionStartTime!);
      AppLogger.auth(
        '📊 Session duration',
        data: {
          'duration': sessionDuration.toString(),
          'minutes': sessionDuration.inMinutes,
        },
      );
      _sessionStartTime = null;
    }

    _updateState(
      user: null,
      isLoading: false,
      isInitialized: true,
      status: AuthStatus.unauthenticated,
    );
  }

  /// Lida com erros de autenticação.
  void _handleAuthError(Object error, StackTrace stackTrace) {
    AppLogger.error(
      '🔥 Auth stream error',
      error: error,
      stackTrace: stackTrace,
    );
    _updateState(
      isLoading: false,
      isInitialized: true,
      status: AuthStatus.error,
      error: _parseError(error),
    );
  }

  /// Atualiza o estado de forma consistente.
  void _updateState({
    UserModel? user,
    bool? isLoading,
    bool? isInitialized,
    AuthStatus? status,
    String? error,
  }) {
    if (_disposed) return;

    state = state.copyWith(
      user: user,
      isLoading: isLoading,
      isInitialized: isInitialized,
      status: status,
      error: error,
    );

    AppLogger.auth(
      '🔄 Auth state updated',
      data: {
        'status': state.status.name,
        'isAuthenticated': state.isAuthenticated,
        'needsOnboarding': state.needsOnboarding,
      },
    );
  }

  // ========================================
  // MÉTODOS PÚBLICOS
  // ========================================

  /// Login com Google
  Future<void> signInWithGoogle() async {
    try {
      AppLogger.auth('🚀 Starting Google Sign In...');
      _updateState(isLoading: true, error: null);

      final googleSignIn = _ref.read(googleSignInProvider);
      final firebaseAuth = _ref.read(firebaseAuthProvider);

      final googleUser = await googleSignIn.signIn();
      if (googleUser == null) {
        AppLogger.auth('❌ Google Sign In cancelled by user');
        _updateState(isLoading: false);
        return;
      }

      final googleAuth = await googleUser.authentication;
      final credential = firebase_auth.GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      await firebaseAuth.signInWithCredential(credential);
      AppLogger.auth('✅ Google Sign In successful');
    } catch (e, stackTrace) {
      AppLogger.error(
        '❌ Google Sign In failed',
        error: e,
        stackTrace: stackTrace,
      );
      _updateState(
        isLoading: false,
        error: _parseError(e),
        status: AuthStatus.error,
      );
    }
  }

  /// Logout
  Future<void> signOut() async {
    try {
      AppLogger.auth('👋 Starting sign out...');
      _updateState(isLoading: true);

      final googleSignIn = _ref.read(googleSignInProvider);
      final firebaseAuth = _ref.read(firebaseAuthProvider);

      await googleSignIn.signOut();
      await firebaseAuth.signOut();

      AppLogger.auth('✅ Sign out successful');
    } catch (e, stackTrace) {
      AppLogger.error('❌ Sign out failed', error: e, stackTrace: stackTrace);
      _updateState(isLoading: false, error: _parseError(e));
    }
  }

  /// Atualiza dados do usuário
  Future<void> updateUser(UserModel updatedUser) async {
    try {
      AppLogger.auth('📝 Updating user data...');

      final firestoreService = _ref.read(firestoreServiceProvider);
      await firestoreService.updateUser(updatedUser.uid, updatedUser.toJson());

      _updateState(user: updatedUser);
      AppLogger.auth('✅ User data updated successfully');
    } catch (e, stackTrace) {
      AppLogger.error(
        '❌ Failed to update user data',
        error: e,
        stackTrace: stackTrace,
      );
      _updateState(error: 'Erro ao atualizar dados do usuário');
    }
  }

  /// Recarrega dados do usuário
  Future<void> refreshUser() async {
    if (state.user?.uid == null) return;

    try {
      AppLogger.auth('🔄 Refreshing user data...');
      final firestoreService = _ref.read(firestoreServiceProvider);
      final user = await firestoreService.getUser(state.user!.uid);

      if (user != null) {
        _updateState(user: user);
        AppLogger.auth('✅ User data refreshed');
      }
    } catch (e, stackTrace) {
      AppLogger.error(
        '❌ Failed to refresh user data',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Força refresh completo do sistema
  Future<void> forceRefresh() async {
    try {
      AppLogger.auth('🔄 Force refreshing auth system...');

      // Refresh user data
      await refreshUser();

      // Refresh related systems
      if (state.isAuthenticated) {
        await _ref.read(streakProvider.notifier).refresh();
        await _ref.read(currencyProvider.notifier).refresh();
      }

      AppLogger.auth('✅ Force refresh completed');
    } catch (e, stackTrace) {
      AppLogger.error(
        '❌ Force refresh failed',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Obtém estatísticas da sessão atual
  Map<String, dynamic> getSessionStats() {
    final duration = _sessionStartTime != null
        ? DateTime.now().difference(_sessionStartTime!)
        : Duration.zero;

    return {
      'isAuthenticated': state.isAuthenticated,
      'sessionStartTime': _sessionStartTime?.toIso8601String(),
      'sessionDuration': duration.toString(),
      'sessionMinutes': duration.inMinutes,
      'userUid': state.user?.uid,
      'needsOnboarding': state.needsOnboarding,
    };
  }

  /// Converte erros em mensagens amigáveis.
  String _parseError(Object error) {
    if (error is firebase_auth.FirebaseAuthException) {
      switch (error.code) {
        case 'user-disabled':
          return 'Sua conta foi desabilitada';
        case 'user-not-found':
          return 'Usuário não encontrado';
        case 'wrong-password':
          return 'Senha incorreta';
        case 'email-already-in-use':
          return 'E-mail já está em uso';
        case 'weak-password':
          return 'Senha muito fraca';
        case 'operation-not-allowed':
          return 'Operação não permitida';
        case 'invalid-email':
          return 'E-mail inválido';
        case 'account-exists-with-different-credential':
          return 'Conta já existe com credencial diferente';
        case 'invalid-credential':
          return 'Credencial inválida';
        case 'user-mismatch':
          return 'Usuário não corresponde';
        case 'requires-recent-login':
          return 'Faça login novamente para continuar';
        case 'credential-already-in-use':
          return 'Credencial já está em uso';
        case 'timeout':
          return 'Operação expirou. Tente novamente mais tarde';
        case 'network-request-failed':
          return 'Erro de conexão. Verifique sua internet';
        default:
          return 'Erro de autenticação: ${error.message}';
      }
    }
    return 'Erro inesperado: $error';
  }

  /// Limpa erro
  void clearError() {
    if (state.error != null) {
      state = state.copyWith(error: null);
    }
  }
}

// ========================================
// PROVIDERS
// ========================================

final googleSignInProvider = Provider<GoogleSignIn>((ref) {
  return GoogleSignIn(scopes: ['email', 'profile']);
});

final firebaseAuthProvider = Provider<firebase_auth.FirebaseAuth>((ref) {
  return firebase_auth.FirebaseAuth.instance;
});

final firestoreServiceProvider = Provider<FirestoreService>((ref) {
  return FirestoreService.instance;
});

/// ✅ PROVIDER PRINCIPAL COM INTEGRAÇÃO DE STREAKS
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref);
});

// Providers computados para facilitar o uso
final currentUserProvider = Provider<UserModel?>((ref) {
  return ref.watch(authProvider).user;
});

final isAuthenticatedProvider = Provider<bool>((ref) {
  return ref.watch(authProvider).isAuthenticated;
});

final isLoadingProvider = Provider<bool>((ref) {
  return ref.watch(authProvider).isLoading;
});

final authErrorProvider = Provider<String?>((ref) {
  return ref.watch(authProvider).error;
});

/// Provider para dados do usuário formatados
final userDataProvider = Provider<Map<String, String?>>((ref) {
  final user = ref.watch(currentUserProvider);

  if (user == null) {
    return {'name': null, 'email': null, 'photoUrl': null};
  }

  return {
    'name': user.displayName ?? user.email.split('@').first,
    'email': user.email,
    'photoUrl': user.actualPhotoUrl,
  };
});

/// Provider para verificar se deve mostrar indicadores de gamificação
final shouldShowGamificationProvider = Provider<bool>((ref) {
  final authState = ref.watch(authProvider);
  return authState.isAuthenticated && !authState.needsOnboarding;
});

/// Provider para estatísticas da sessão
final sessionStatsProvider = Provider<Map<String, dynamic>>((ref) {
  final authNotifier = ref.read(authProvider.notifier);
  return authNotifier.getSessionStats();
});
