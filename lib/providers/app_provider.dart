// =============================================
// 1. app_provider.dart - FLUXO TOTALMENTE NOVO
// =============================================
import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:unlock/models/user_model.dart';
import 'package:unlock/providers/user_provider.dart';
import 'package:unlock/services/auth_service.dart';
import 'package:unlock/services/background_service.dart';
import 'package:unlock/services/notification_service.dart';

final appProvider = StateNotifierProvider<AppNotifier, AppState>(
  (ref) => AppNotifier(ref),
);

class AppState {
  final bool isLoading;
  final String? error;
  final UserModel? user;
  final bool backgroundServiceActive;
  final bool isInitialized;

  AppState({
    this.isLoading = false,
    this.error,
    this.user,
    this.backgroundServiceActive = false,
    this.isInitialized = false,
  });

  AppState copyWith({
    bool? isLoading,
    String? error,
    UserModel? user,
    bool? backgroundServiceActive,
    bool? isInitialized,
  }) => AppState(
    isLoading: isLoading ?? this.isLoading,
    error: error,
    user: user ?? this.user, // Permite definir user como null explicitamente
    backgroundServiceActive:
        backgroundServiceActive ?? this.backgroundServiceActive,
    isInitialized: isInitialized ?? this.isInitialized,
  );

  bool get isAuthenticated => user != null;
  // As condições shouldShowHome e shouldShowLogin são usadas pelo GoRouter redirect
  bool get shouldShowHome =>
      isAuthenticated &&
      isInitialized &&
      !isLoading; // Usuário está logado, app inicializado e não carregando
  bool get shouldShowLogin =>
      !isAuthenticated &&
      isInitialized &&
      !isLoading; // Usuário não está logado, app inicializado e não carregando
}

class AppNotifier extends StateNotifier<AppState> {
  final Ref _ref;
  StreamSubscription<User?>? _authSubscription;
  Timer? _periodicCheckTimer;
  bool _isDisposed = false;

  AppNotifier(this._ref) : super(AppState()) {
    _init();
  }

  void _init() async {
    if (_isDisposed) return;

    try {
      if (kDebugMode) {
        print('🔄 AppProvider: Iniciando inicialização...');
      }

      // Inicia como não inicializado e carregando
      state = state.copyWith(isLoading: true, isInitialized: false);

      // Inicializar serviços de background primeiro (opcional, pode ser movido para após o login se depender do usuário)
      await _initializeBackgroundServices();

      // Setup do listener de autenticação
      // O listener será disparado imediatamente com o estado atual do usuário (null ou User)
      _authSubscription = AuthService.authStateChanges.listen(
        _onAuthStateChanged,
        onError: (error) {
          if (kDebugMode) {
            print('❌ AppProvider: Erro no auth state listener: $error');
          }
          if (!_isDisposed) {
            state = state.copyWith(
              error: 'Erro no listener de autenticação: $error',
              isLoading: false,
              isInitialized:
                  true, // Marcar como inicializado mesmo com erro no listener
            );
          }
        },
      );
      // Não é necessário chamar _onAuthStateChanged manualmente aqui,
      // o listener de authStateChanges fará isso.
    } catch (e) {
      if (kDebugMode) {
        print('❌ AppProvider: Erro na inicialização: $e');
      }
      if (!_isDisposed) {
        state = state.copyWith(
          error: 'Erro crítico na inicialização: $e',
          isLoading: false,
          isInitialized: true,
        );
      }
    }
  }

  Future<void> _onAuthStateChanged(User? firebaseUser) async {
    if (_isDisposed) return;

    if (kDebugMode) {
      print(
        '🔄 AppProvider: _onAuthStateChanged - User: ${firebaseUser?.uid ?? 'null'}',
      );
    }

    if (firebaseUser != null) {
      // Usuário está logado ou acabou de fazer login
      // Verifica se é um novo login ou se os dados do usuário ainda não foram carregados
      if (state.user?.uid != firebaseUser.uid ||
          !state.isInitialized ||
          state.user == null) {
        state = state.copyWith(isLoading: true, error: null);
        await _loadUserData(firebaseUser);
      } else if (!state.isInitialized) {
        // Caso raro: usuário já existe no estado, mas app não foi marcado como inicializado
        // Apenas garante que isLoading seja false e isInitialized seja true
        state = state.copyWith(isLoading: false, isInitialized: true);
      }
    } else {
      // Usuário está deslogado ou nunca fez login
      // Verifica se o estado precisa ser atualizado (estava logado antes ou app não inicializado)
      if (state.user != null || !state.isInitialized) {
        await _processUserLogout();
      } else if (!state.isInitialized) {
        // Caso raro: sem usuário e app não inicializado
        state = state.copyWith(
          user: null,
          isLoading: false,
          isInitialized: true,
          error: null,
        );
      }
    }
  }

  Future<void> _loadUserData(User firebaseUser) async {
    if (_isDisposed) return;

    try {
      if (kDebugMode) {
        print(
          '🔄 AppProvider: Carregando dados do usuário: ${firebaseUser.uid}',
        );
      }

      final UserModel? userModel = await AuthService.getOrCreateUserInFirestore(
        firebaseUser,
      );

      if (!_isDisposed) {
        if (userModel != null) {
          // Sucesso no carregamento
          // Marcar como inicializado aqui garante que só ocorra após o primeiro carregamento bem-sucedido de dados
          state = state.copyWith(
            user: userModel,
            isLoading: false,
            error: null,
            isInitialized: true, // App está pronto para navegação
          );
          _ref.read(userProvider.notifier).setUser(userModel);
          // Iniciar background services
          await _startBackgroundServices();

          if (kDebugMode) {
            print(
              '✅ AppProvider: Usuário carregado com sucesso: ${userModel.username}',
            );
          }
        } else {
          // userModel é null
          // Falha ao carregar/criar dados do usuário no Firestore.
          // Forçar logout do Firebase para manter consistência.
          if (kDebugMode) {
            print(
              '❌ AppProvider: userModel é null após getOrCreateUserInFirestore. Forçando logout.',
            );
          }
          state = state.copyWith(
            user: null,
            isLoading: false,
            error: 'Falha ao carregar/criar dados do usuário no Firestore.',
            isInitialized:
                true, // Marcar como inicializado mesmo com erro de dados
          );
          _ref.read(userProvider.notifier).setUser(null);
          await AuthService.signOut(); // Forçar logout do Firebase
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ AppProvider: Erro ao carregar dados do usuário: $e');
      }
      if (!_isDisposed) {
        state = state.copyWith(
          user: null,
          isLoading: false,
          error: 'Erro ao carregar dados do usuário: $e',
          isInitialized: true, // Marcar como inicializado mesmo com erro
        );
        _ref.read(userProvider.notifier).setUser(null);
      }
    }
  }

  Future<void> _processUserLogout() async {
    if (_isDisposed) return;

    try {
      if (kDebugMode) {
        print('🔄 AppProvider: Processando logout...');
      }

      // Parar background services primeiro
      await _stopBackgroundServices();

      if (!_isDisposed) {
        state = state.copyWith(
          user: null,
          isLoading: false,
          error: null,
          backgroundServiceActive: false,
          isInitialized: true, // App está inicializado, mas sem usuário
        );
        _ref.read(userProvider.notifier).setUser(null);
      }
      if (kDebugMode) {
        print(
          '✅ AppProvider: Logout processado. shouldShowLogin: ${state.shouldShowLogin}',
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ AppProvider: Erro no logout: $e');
      }
      if (!_isDisposed) {
        state = state.copyWith(
          user: null,
          isLoading: false,
          error: 'Erro no logout: $e',
          backgroundServiceActive: false,
          isInitialized:
              true, // Mesmo com erro, o app está "inicializado" no sentido de ter tentado
        );
      }
    }
  }

  Future<void> loginWithGoogle() async {
    if (state.isLoading) return; // Evitar múltiplas tentativas

    // A tela de Login pode mostrar um indicador local para o botão.
    // O AppProvider.isLoading será definido por _onAuthStateChanged quando o Firebase iniciar a autenticação.
    try {
      if (kDebugMode) print('🔄 AppProvider: Iniciando loginWithGoogle...');
      await AuthService.signInWithGoogle();
      // _onAuthStateChanged cuidará da atualização do estado após o sucesso/falha do Firebase.
    } catch (e) {
      // Este catch é para erros que ocorrem ANTES do Firebase Auth ser acionado
      // ou se o usuário cancelar o fluxo do Google Sign-In.
      if (kDebugMode)
        print('❌ AppProvider: Erro em loginWithGoogle (antes do Firebase): $e');
      if (!_isDisposed) {
        state = state.copyWith(
          isLoading: false, // Garante que não fique preso em loading
          error: e.toString(),
          // isInitialized deve ser true se o app já passou pelo _init.
          // Se o login falhar durante a inicialização, _onAuthStateChanged (com user null) definirá isInitialized.
          isInitialized: state.isInitialized || true,
        );
      }
    }
  }

  Future<void> logout() async {
    // A tela Home pode mostrar um indicador local.
    // AppProvider.isLoading será definido por _onAuthStateChanged.
    if (state.isLoading && state.user == null)
      return; // Já está deslogando ou deslogado

    try {
      if (kDebugMode) print('🔄 AppProvider: Iniciando logout...');
      state = state.copyWith(
        isLoading: true,
        error: null,
      ); // Indica que o processo de logout começou
      await AuthService.signOut();
      // _onAuthStateChanged cuidará da atualização do estado quando o Firebase confirmar o logout.
    } catch (e) {
      if (kDebugMode) print('❌ AppProvider: Erro no logout: $e');
      if (!_isDisposed) {
        state = state.copyWith(
          isLoading: false, // Garante que não fique preso em loading
          error: e.toString(),
          isInitialized:
              state.isInitialized ||
              true, // Mantém isInitialized se já era true
        );
      }
    }
  }

  Future<void> _initializeBackgroundServices() async {
    try {
      if (kDebugMode) {
        print('🔄 AppProvider: Inicializando serviços de background...');
      }

      await NotificationService.initialize();
      await BackgroundService.initialize();

      if (kDebugMode) {
        print('✅ AppProvider: Serviços de background inicializados');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ AppProvider: Erro ao inicializar serviços de background: $e');
      }
    }
  }

  Future<void> _startBackgroundServices() async {
    if (_isDisposed || !state.isAuthenticated)
      return; // Só inicia se autenticado

    try {
      if (kDebugMode) {
        print('🔄 AppProvider: Iniciando monitoramento em background...');
      }

      await BackgroundService.performManualCheck();

      _periodicCheckTimer?.cancel();
      _periodicCheckTimer = Timer.periodic(const Duration(hours: 2), (
        timer,
      ) async {
        if (_isDisposed || !state.isAuthenticated) {
          // Verifica autenticação também no timer
          timer.cancel();
          return;
        }
        if (kDebugMode) {
          print('⏰ AppProvider: Verificação periódica de backup');
        }
        await BackgroundService.performManualCheck();
      });

      if (!_isDisposed) {
        state = state.copyWith(backgroundServiceActive: true);
      }

      if (kDebugMode) {
        print('✅ AppProvider: Monitoramento em background ativo');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ AppProvider: Erro ao iniciar background services: $e');
      }
    }
  }

  Future<void> _stopBackgroundServices() async {
    try {
      if (kDebugMode) {
        print('🛑 AppProvider: Parando monitoramento em background...');
      }

      _periodicCheckTimer?.cancel();
      _periodicCheckTimer = null;

      await BackgroundService.stop();

      if (!_isDisposed) {
        state = state.copyWith(backgroundServiceActive: false);
      }

      if (kDebugMode) {
        print('✅ AppProvider: Monitoramento em background parado');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ AppProvider: Erro ao parar background services: $e');
      }
    }
  }

  // Métodos públicos
  void setError(String? error) {
    if (!_isDisposed) {
      state = state.copyWith(error: error, isLoading: false);
    }
  }

  void clearError() {
    if (!_isDisposed) {
      state = state.copyWith(error: null);
    }
  }

  Future<void> forceCheckPets() async {
    if (!state.isAuthenticated) return; // Só permite se autenticado
    try {
      if (kDebugMode) {
        print('🔄 AppProvider: Verificação manual forçada pelo usuário');
      }
      await BackgroundService.performManualCheck();
    } catch (e) {
      if (kDebugMode) {
        print('❌ AppProvider: Erro na verificação manual: $e');
      }
      setError('Erro na verificação: $e');
    }
  }

  bool get isBackgroundServiceActive => state.backgroundServiceActive;

  @override
  void dispose() {
    _isDisposed = true;
    _authSubscription?.cancel();
    _periodicCheckTimer?.cancel();

    BackgroundService.stop().catchError((e) {
      if (kDebugMode) {
        print('❌ AppProvider: Erro ao parar background service no dispose: $e');
      }
    });

    super.dispose();
  }
}
