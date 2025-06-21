import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:unlock/core/utils/logger.dart';
import 'package:unlock/features/connections/services/connections_service.dart'; // Importar ConnectionsService
import 'package:unlock/features/missions/providers/missions_provider.dart'; // Importar o MissionsNotifier
import 'package:unlock/features/rewards/models/reward_model.dart';
import 'package:unlock/features/rewards/providers/rewards_provider.dart';
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
    if (!isAuthenticated || user == null) return false;

    // Verificar campos obrigatórios do onboarding
    final hasOnboardingCompleted = user!.onboardingCompleted;
    final hasCodinome = user!.codinome?.isNotEmpty == true;
    final hasAvatarId = user!.avatarId?.isNotEmpty == true;
    final hasInterests = user!.interesses.length >= 3;
    final hasBirthDate = user!.birthDate != null;

    // Debug para verificar valores
    if (kDebugMode) {
      AppLogger.debug(
        '🔍 Checking onboarding for ${user!.uid}',
        data: {
          'onboardingCompleted': hasOnboardingCompleted,
          'hasCodinome': hasCodinome,
          'hasAvatarId': hasAvatarId,
          'hasInterests': hasInterests,
          'hasBirthDate': hasBirthDate,
        },
      );
    }

    // Usuário precisa de onboarding se:
    // 1. Não marcou onboarding como completo OU
    // 2. Qualquer campo obrigatório está vazio
    return !hasOnboardingCompleted ||
        !hasCodinome ||
        !hasAvatarId ||
        !hasInterests ||
        !hasBirthDate;
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
    // ✅ NOVO: Construtor com ref
    _initialize();
  }

  /// Inicialização do provider com triggers de gamificação
  Future<void> _initialize() async {
    if (_disposed) return;
    try {
      _sessionStartTime = DateTime.now();
      AppLogger.auth('🔄 Inicializando AuthProvider com triggers...');
      // Analytics: Início da inicialização
      await _trackAnalyticsEvent('auth_provider_init_start');
      // Resetar estado completamente
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
      // Bloco removido: A verificação síncrona de `AuthService.currentUser == null` foi removida.
      // A lógica para definir o estado inicial (incluindo isInitialized = true)
      // agora depende exclusivamente do primeiro evento processado pelo _handleAuthStateChange,
      // garantindo que `isInitialized` só se torne `true` após o stream de autenticação
      // ter emitido e sido processado.
      AppLogger.auth('✅ AuthProvider inicializado com triggers');
      // Analytics: Inicialização concluída
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

  /// Handler melhorado para mudanças de autenticação
  Future<void> _handleAuthStateChange(dynamic firebaseUser) async {
    if (_disposed) return;

    AppLogger.auth(
      '🔥 _handleAuthStateChange TRIGGERED',
      data: {'hasFirebaseUser': firebaseUser != null, 'uid': firebaseUser?.uid},
    );

    // ✅ NOVO: Adicionar timeout para a inicialização/carregamento
    const initializationTimeout = Duration(
      seconds: 15,
    ); // Tempo limite de 15 segundos
    try {
      AppLogger.auth(
        // Mantém o log original
        '🔄 Mudança no estado de autenticação',
        data: {
          'hasUser': firebaseUser != null,
          'uid': firebaseUser?.uid,
          'email': firebaseUser?.email,
        },
      );
      // Garante que o estado de loading seja definido no início do processamento.
      // Não definimos isInitialized aqui, pois isso acontece ao final do login/logout.
      _updateState(isLoading: true, error: null);
      // Envolve a lógica principal em um timeout
      await (() async {
        if (firebaseUser == null) {
          // Limpar estado e triggers no logout
          await _handleUserLogout();
        } else {
          // Carregar dados e disparar triggers no login
          await _handleUserLogin(firebaseUser);
        }
      }()).timeout(
        initializationTimeout,
        onTimeout: () {
          AppLogger.error(
            // Corrige a mensagem de log
            '❌ Inicialização/Carregamento de Auth excedeu o tempo limite (${initializationTimeout.inSeconds}s).',
          );
          // Define um estado de erro no timeout, garantindo isLoading: false e isInitialized: true
          _updateState(
            isLoading: false,
            isInitialized: true,
            error: 'Tempo limite excedido ao carregar dados.',
            status: AuthStatus.error,
          );
        },
      );
    } on TimeoutException catch (_) {
      // O erro de timeout já foi tratado no onTimeout.
      // Apenas garantimos que o estado final seja consistente se não foi definido lá.
      if (state.isLoading || !state.isInitialized) {
        _updateState(
          isLoading: false,
          isInitialized: true,
          status: AuthStatus.error,
          error: state.error ?? 'Timeout não tratado.',
        );
      }
    } catch (error) {
      // Captura outros erros que não sejam TimeoutException
      _handleError('Erro ao processar mudança de autenticação', error);
    } finally {
      // Bloco finally para garantir que isLoading seja false e isInitialized seja true,
      // caso algum fluxo de erro não tenha feito isso.
      if (state.isLoading || !state.isInitialized) {
        // Se o status ainda é unknown e não há erro, provavelmente é unauthenticated.
        // Caso contrário, mantém o status atual (que pode ser error ou authenticated).
        final finalStatus =
            (state.status == AuthStatus.unknown && state.error == null)
            ? AuthStatus.unauthenticated
            : state.status;
        _updateState(
          isLoading: false,
          isInitialized: true,
          status: finalStatus,
          user: finalStatus == AuthStatus.unauthenticated ? null : state.user,
        );
        AppLogger.auth(
          '🚪 _handleAuthStateChange FINALLY fallback state update',
          data: {'state': state.toString()},
        );
      }
    }
  }

  // ================================================================================================
  // ✅ NOVOS MÉTODOS: TRIGGERS DE GAMIFICAÇÃO
  // ================================================================================================

  /// Lidar com login do usuário (com triggers)
  Future<void> _handleUserLogin(dynamic firebaseUser) async {
    if (_disposed) return;
    try {
      final loadStartTime = DateTime.now();
      AppLogger.auth('🔄 Carregando dados do usuário: ${firebaseUser.uid}');
      // Manter loading durante carregamento
      // isLoading já deve ter sido definido por _handleAuthStateChange
      // _updateState(isLoading: true, error: null);
      // Buscar dados atualizados do Firestore
      final userModel = await AuthService.getOrCreateUserInFirestore(
        firebaseUser,
      );
      if (userModel != null) {
        final loadDuration = DateTime.now().difference(loadStartTime);
        // Dados carregados com sucesso
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
        // ✅ NOVO: TRIGGER GAMIFICAÇÃO APÓS LOGIN COMPLETO
        await _triggerGamificationSystems(userModel);
        // Log final do estado para debug
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
        // O signOut será tratado pelo stream, que chamará _handleUserLogout.
        // Apenas garantimos que o estado atual reflita o erro.
        _updateState(
          isLoading: false,
          isInitialized: true,
          status: AuthStatus.error,
          error: 'Falha ao carregar dados do usuário.',
          user: null,
        );
        // Chamada explícita ao signOut para garantir que o Firebase também seja deslogado.
        // O _handleUserLogout subsequente (via stream) apenas confirmará o estado.
        await AuthService.signOut().catchError(
          (e) =>
              AppLogger.error("Erro no signOut após falha de carregamento: $e"),
        );
      }
    } catch (error) {
      _handleError('Erro ao carregar dados do usuário', error);
      // Em caso de erro, também forçar logout para manter consistência
      try {
        // Garante que o estado reflita o erro antes de tentar o signOut.
        if (!_disposed) {
          _updateState(
            isLoading: false,
            isInitialized: true,
            status: AuthStatus.error,
            error: state.error ?? 'Erro ao carregar usuário.',
            user: null,
          );
        }
        await AuthService.signOut();
      } catch (signOutError) {
        AppLogger.auth('❌ Erro adicional no logout: $signOutError');
      }
    }
  }

  /// Trigger para sistemas de gamificação após login
  Future<void> _triggerGamificationSystems(UserModel user) async {
    if (_disposed) return;
    try {
      AppLogger.auth('🎮 Disparando triggers de gamificação para ${user.uid}');
      // ✅ TRIGGER: Sistema de Missões
      // Garante que as missões sejam carregadas antes de tentar reportar eventos
      final missionsNotifier = _ref.read(missionsProvider.notifier);
      if (missionsNotifier.state.isLoading) {
        AppLogger.debug('MissionsNotifier ainda carregando, aguardando...');
        // Aguarda até que o MissionsNotifier termine de carregar
        await for (var _ in missionsNotifier.stream) {
          if (!missionsNotifier.state.isLoading) break;
        }
        AppLogger.debug('MissionsNotifier finalizou o carregamento.');
      }
      await _triggerMissionsSystem(user); // Isso apenas loga agora
      // ✅ TRIGGER: Sistema de Recompensas
      await _triggerRewardsSystem(user);
      // ✅ TRIGGER: Login Diário
      await _triggerDailyLogin(user);
      AppLogger.auth('✅ Todos os triggers de gamificação executados');
    } catch (e) {
      AppLogger.error('❌ Erro ao disparar triggers de gamificação', error: e);
      // Não falhar o login por causa dos triggers
    }
  }

  /// Trigger específico para sistema de missões
  Future<void> _triggerMissionsSystem(UserModel user) async {
    try {
      AppLogger.debug('🎯 Trigger: Sistema de Missões');
      // Este trigger agora serve para garantir que o MissionsNotifier está ativo
      // e pode começar a observar eventos.
      // A inicialização real das missões (carregamento do repositório) acontece
      // no construtor do MissionsNotifier quando ele é lido.
      await _trackAnalyticsEvent(
        'missions_system_triggered',
        data: {
          'user_id': user.uid,
          'user_level': user.level,
          'onboarding_completed': user.onboardingCompleted,
        },
      );
      AppLogger.debug('✅ Trigger de missões executado');
    } catch (e) {
      AppLogger.error('⚠️ Trigger de missões falhou (não crítico)', error: e);
    }
  }

  /// Trigger específico para sistema de recompensas
  Future<void> _triggerRewardsSystem(UserModel user) async {
    try {
      AppLogger.debug('🎁 Trigger: Sistema de Recompensas');
      // Lógica para verificar recompensas pendentes, login bonuses, etc.
      // O `RewardsNotifier` em si já tem a lógica de carregar recompensas no initialize.
      await _trackAnalyticsEvent(
        'rewards_system_triggered',
        data: {'user_id': user.uid},
      );
      AppLogger.debug('✅ Trigger de recompensas executado');
    } catch (e) {
      AppLogger.error(
        '⚠️ Trigger de recompensas falhou (não crítico)',
        error: e,
      );
    }
  }

  /// Trigger para login diário
  Future<void> _triggerDailyLogin(UserModel user) async {
    try {
      AppLogger.debug('📅 Trigger: Login Diário');
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      // Assumindo que UserModel agora tem lastLoginDate e loginStreak
      // vindos do Firestore através do AuthService.getOrCreateUserInFirestore
      final DateTime? lastLoginDate = user.lastLoginDate;
      int currentStreak = user.loginStreak ?? 0;
      bool isFirstLoginToday = true;
      if (lastLoginDate != null) {
        final DateTime lastLoginDay = DateTime(
          lastLoginDate.year,
          lastLoginDate.month,
          lastLoginDate.day,
        );
        if (lastLoginDay.isAtSameMomentAs(today)) {
          isFirstLoginToday = false;
          AppLogger.debug('Login diário já processado hoje para ${user.uid}.');
        } else {
          final DateTime yesterday = today.subtract(const Duration(days: 1));
          if (lastLoginDay.isAtSameMomentAs(yesterday)) {
            currentStreak++;
            AppLogger.debug(
              'Sequência de login incrementada para: $currentStreak dias para ${user.uid}.',
            );
          } else {
            currentStreak = 1; // Quebrou a sequência
            AppLogger.debug(
              'Sequência de login quebrada. Reiniciada para 1 dia para ${user.uid}.',
            );
          }
        }
      } else {
        currentStreak = 1; // Primeiro login
        AppLogger.debug(
          'Primeiro login registrado para ${user.uid}. Sequência: 1 dia.',
        );
      }
      if (isFirstLoginToday) {
        AppLogger.debug(
          'Processando primeiro login do dia para ${user.uid}. Streak: $currentStreak',
        );
        // Conceder bônus de login diário (moedas)
        final bonusCoins = _ref
            .read(rewardsProvider.notifier)
            .calculateDailyLoginBonus(currentStreak);
        if (bonusCoins > 0) {
          AppLogger.debug(
            'Concedendo bônus de login diário: $bonusCoins moedas para $currentStreak dias de streak para ${user.uid}.',
          );
          // Aplica as moedas diretamente ao UserModel local e dispara atualização no Firestore
          _ref
              .read(authProvider.notifier)
              .addRewardsToCurrentUser(0, bonusCoins, 0);
          // Registrar a recompensa como já resgatada no histórico de recompensas
          // Isso também pode atualizar 'totalEarned' no RewardsNotifier/Service.
          await _ref
              .read(rewardsProvider.notifier)
              .recordDirectlyClaimedCoinReward(
                userId: user.uid,
                amount: bonusCoins,
                source: RewardSource.dailyLogin,
                description: 'Bônus de login diário ($currentStreak dias)',
                metadata: {'streakDays': currentStreak},
              );
        }
        // Atualizar lastLoginDate e loginStreak no Firestore
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .update({
              'lastLoginDate': Timestamp.fromDate(now),
              'loginStreak': currentStreak,
              'lastLogin': FieldValue.serverTimestamp(),
            });
        AppLogger.debug(
          'Dados de login (lastLoginDate, loginStreak) atualizados no Firestore para ${user.uid}.',
        );
        // Reportar evento para o sistema de missões
        _ref.read(missionsProvider.notifier).reportMissionEvent('LOGIN_DAILY');
        AppLogger.debug(
          'Evento LOGIN_DAILY reportado para o sistema de missões para ${user.uid}.',
        );
        await _trackAnalyticsEvent(
          'daily_login_bonus_granted',
          data: {
            'user_id': user.uid,
            'streak': currentStreak,
            'bonus_coins': bonusCoins,
          },
        );
      }
      AppLogger.debug('✅ Trigger de login diário concluído para ${user.uid}.');
    } catch (e) {
      AppLogger.error(
        '⚠️ Trigger de login diário falhou (não crítico)',
        error: e,
      );
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

    // Limpar o cache de conexões no logout
    _ref.read(connectionsServiceProvider).clearAllCache();

    AppLogger.auth('✅ Logout finalizado, estado atual: $state');
  }

  // ================================================================================================
  // MÉTODOS PÚBLICOS EXISTENTES (mantidos inalterados)
  // ================================================================================================

  /// Método para adicionar recompensas ao usuário logado.
  /// Será chamado pelo RewardsService.
  void addRewardsToCurrentUser(int xp, int coins, int gems) {
    if (state.user != null) {
      // Cria uma nova instância de UserModel com as recompensas adicionadas
      // O método `addRewards` no UserModel já lida com a atualização e recalculo de nível.
      final updatedUser = state.user!.addRewards(xp, coins, gems);
      // Atualiza o estado do AuthProvider com o novo UserModel imutável
      state = state.copyWith(user: updatedUser);
      print(
        'DEBUG: UserModel atualizado com recompensas: XP=${updatedUser.xp}, Coins=${updatedUser.coins}, Gems=${updatedUser.gems}',
      );
      // Opcional: Persistir o usuário atualizado no backend aqui, se necessário.
      // _userRepository.updateUser(updatedUser);
    }
  }

  /// Login com Google
  Future<bool> signInWithGoogle() async {
    if (_disposed) return false;
    try {
      _log('🔑 Iniciando login com Google...');
      _updateState(
        isLoading: true,
        error: null,
        status: AuthStatus.unknown,
      ); // Mantém isInitialized como está ou false
      final result = await AuthService.signInWithGoogle();
      if (result != null) {
        _log('✅ Login com Google bem-sucedido');
        await _trackAnalyticsEvent('google_sign_in_success');
        return true;
      } else {
        _log('❌ Login com Google falhou');
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
      _log('❌ Erro no login com Google: $error');
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
      _log('🚪 Fazendo logout...');
      _updateState(
        isLoading: true,
        status: state.status,
      ); // Mantém o status atual enquanto faz logout
      await AuthService.signOut();
      _log('✅ Logout realizado com sucesso');
      // Chamar _handleUserLogout explicitamente para garantir que o estado seja limpo
      // e o GoRouter seja notificado imediatamente.
      await _handleUserLogout(); // Isso já define isLoading: false e status corretos.
      await _trackAnalyticsEvent(
        'user_sign_out',
      ); // Mover analytics para depois da atualização do estado
    } catch (error) {
      _log('❌ Erro no logout: $error');
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
      _log('🔄 Verificando status de onboarding...');
      await refreshUser();
    } catch (error) {
      _handleError('Erro ao verificar status de onboarding', error);
    }
  }

  /// Handler de erro de autenticação
  void _handleAuthError(error) {
    _log('❌ Erro no stream de autenticação: $error');
    _handleError('Erro no stream de autenticação', error);
  }

  /// Handler genérico de erros
  void _handleError(String message, dynamic error) {
    if (_disposed) return;
    _log('❌ $message: $error');
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

  /// Logging interno
  void _log(String message) {
    if (kDebugMode) {
      AppLogger.auth(message);
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
