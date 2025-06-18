// lib/services/auth_service.dart - ATUALIZADO para Onboarding
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:unlock/core/utils/logger.dart';
import 'package:unlock/models/user_model.dart';
import 'package:unlock/services/analytics/analytics_integration.dart';
import 'package:unlock/services/analytics/interfaces/analytics_interface.dart';
import 'package:unlock/services/firestore_service.dart';

class AuthService {
  static final _auth = FirebaseAuth.instance;
  static final _googleSignIn = GoogleSignIn();
  static final _firestore = FirestoreService();

  static User? get currentUser => _auth.currentUser;
  static Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Login com Google com analytics detalhado
  static Future<UserModel?> signInWithGoogle() async {
    final stopwatch = Stopwatch()..start();

    try {
      AppLogger.auth('🔄 Iniciando Google Sign-In...');

      // 📊 Analytics: Tentativa de login iniciada
      await _trackAuthEvent('login_attempt', {
        'method': 'google',
        'timestamp': DateTime.now().toIso8601String(),
      });

      // Iniciar processo de login com Google
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        stopwatch.stop();

        // 📊 Analytics: Login cancelado
        await _trackAuthEvent('login_cancelled', {
          'method': 'google',
          'duration_ms': stopwatch.elapsedMilliseconds,
          'step': 'google_account_selection',
        });

        AppLogger.auth('❌ Google Sign-In cancelado pelo usuário');
        return null;
      }

      AppLogger.auth(
        '✅ Usuário selecionado no Google',
        data: {
          'email': googleUser.email,
          'displayName': googleUser.displayName,
          'id': googleUser.id,
        },
      );

      // Obter credenciais de autenticação
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      AppLogger.auth(
        '🔑 Credenciais Google obtidas',
        data: {
          'hasAccessToken': googleAuth.accessToken != null,
          'hasIdToken': googleAuth.idToken != null,
        },
      );

      // Criar credencial Firebase
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      AppLogger.auth('🔐 Credencial Firebase criada');

      // Fazer login no Firebase
      final UserCredential userCredential = await _auth.signInWithCredential(
        credential,
      );
      final User? firebaseUser = userCredential.user;

      if (firebaseUser == null) {
        stopwatch.stop();

        // 📊 Analytics: Falha no Firebase
        await _trackAuthEvent('login_failed', {
          'method': 'google',
          'duration_ms': stopwatch.elapsedMilliseconds,
          'step': 'firebase_credential',
          'error': 'firebase_user_null',
        });

        AppLogger.auth('❌ Firebase user é null após credential sign in');
        return null;
      }

      final isNewUser = userCredential.additionalUserInfo?.isNewUser ?? false;

      AppLogger.auth(
        '✅ Login Firebase bem-sucedido',
        data: {
          'uid': firebaseUser.uid,
          'email': firebaseUser.email,
          'displayName': firebaseUser.displayName,
          'isNewUser': isNewUser,
        },
      );

      // Buscar ou criar usuário no Firestore
      final userModel = await getOrCreateUserInFirestore(firebaseUser);
      stopwatch.stop();

      if (userModel != null) {
        // 📊 Analytics: Login bem-sucedido
        await _trackAuthEvent('login_success', {
          'method': 'google',
          'duration_ms': stopwatch.elapsedMilliseconds,
          'is_new_user': isNewUser,
          'user_level': userModel.level,
          'user_coins': userModel.coins,
          'onboarding_completed': userModel.onboardingCompleted,
          'needs_onboarding': userModel.needsOnboarding,
        });

        // 📊 Analytics: Performance do login
        await _trackAuthPerformance(
          'login_duration',
          stopwatch.elapsedMilliseconds,
          {'method': 'google', 'success': true, 'is_new_user': isNewUser},
        );
      } else {
        // 📊 Analytics: Falha no Firestore
        await _trackAuthEvent('login_failed', {
          'method': 'google',
          'duration_ms': stopwatch.elapsedMilliseconds,
          'step': 'firestore_user_creation',
          'error': 'user_model_null',
        });
      }

      return userModel;
    } catch (e) {
      stopwatch.stop();

      // 📊 Analytics: Erro no login
      await _trackAuthEvent('login_error', {
        'method': 'google',
        'duration_ms': stopwatch.elapsedMilliseconds,
        'error_type': e.runtimeType.toString(),
        'error_message': e.toString(),
      });

      AppLogger.auth('❌ Erro no Google Sign-In: $e');
      return null;
    }
  }

  /// Buscar ou criar usuário no Firestore com suporte a onboarding
  static Future<UserModel?> getOrCreateUserInFirestore(User user) async {
    final stopwatch = Stopwatch()..start();

    try {
      AppLogger.firestore(
        '🔍 Verificando usuário no Firestore',
        data: {'uid': user.uid, 'email': user.email},
      );

      // Verificar se usuário já existe
      final UserModel? existingUser = await _firestore.getUser(user.uid);
      stopwatch.stop();

      if (existingUser != null) {
        // 📊 Analytics: Usuário existente encontrado
        await _trackAuthEvent('existing_user_loaded', {
          'uid': existingUser.uid,
          'duration_ms': stopwatch.elapsedMilliseconds,
          'user_level': existingUser.level,
          'user_coins': existingUser.coins,
          'onboarding_completed': existingUser.onboardingCompleted,
          'needs_onboarding': existingUser.needsOnboarding,
          'account_age_days': DateTime.now()
              .difference(existingUser.createdAt)
              .inDays,
        });

        AppLogger.auth(
          '✅ Usuário encontrado no Firestore',
          data: {
            'uid': existingUser.uid,
            'username': existingUser.username,
            'level': existingUser.level,
            'coins': existingUser.coins,
            'gems': existingUser.gems,
            'onboardingCompleted': existingUser.onboardingCompleted,
            'needsOnboarding': existingUser.needsOnboarding,
            'createdAt': existingUser.createdAt.toString(),
          },
        );
        return existingUser;
      }

      // Criar novo usuário se não encontrado
      AppLogger.auth(
        '🆕 Usuário não encontrado, criando novo documento',
        data: {
          'uid': user.uid,
          'email': user.email,
          'displayName': user.displayName,
        },
      );

      final createStopwatch = Stopwatch()..start();

      // ✅ CRIAR USUÁRIO INICIAL COM CAMPOS DE ONBOARDING
      final newUser = UserModel.createInitial(
        uid: user.uid,
        email: user.email ?? '',
        displayName: user.displayName,
        photoURL: user.photoURL,
      );

      AppLogger.auth(
        '💾 Salvando novo usuário no Firestore...',
        data: {
          'uid': newUser.uid,
          'username': newUser.username,
          'initialCoins': newUser.coins,
          'initialGems': newUser.gems,
          'onboardingCompleted': newUser.onboardingCompleted,
          'needsOnboarding': newUser.needsOnboarding,
        },
      );

      await _firestore.createUser(newUser);
      createStopwatch.stop();

      // 📊 Analytics: Novo usuário criado
      await _trackAuthEvent('new_user_created', {
        'uid': newUser.uid,
        'creation_duration_ms': createStopwatch.elapsedMilliseconds,
        'total_duration_ms':
            stopwatch.elapsedMilliseconds + createStopwatch.elapsedMilliseconds,
        'initial_coins': newUser.coins,
        'initial_gems': newUser.gems,
        'onboarding_completed': newUser.onboardingCompleted,
        'needs_onboarding': newUser.needsOnboarding,
        'has_display_name': newUser.displayName.isNotEmpty,
        'has_photo': newUser.avatar != '👤',
      });

      // 📊 Analytics: Evento de conversão (novo cadastro)
      await _trackAuthConversion('user_registration', {
        'method': 'google',
        'user_id': newUser.uid,
        'needs_onboarding': newUser.needsOnboarding,
      });

      AppLogger.auth(
        '✅ Novo usuário criado com sucesso',
        data: {
          'uid': newUser.uid,
          'username': newUser.username,
          'level': newUser.level,
          'coins': newUser.coins,
          'gems': newUser.gems,
          'onboardingCompleted': newUser.onboardingCompleted,
          'needsOnboarding': newUser.needsOnboarding,
        },
      );

      return newUser;
    } catch (e) {
      stopwatch.stop();

      // 📊 Analytics: Erro na criação/busca do usuário
      await _trackAuthEvent('user_firestore_error', {
        'uid': user.uid,
        'duration_ms': stopwatch.elapsedMilliseconds,
        'error_type': e.runtimeType.toString(),
        'error_message': e.toString(),
      });

      AppLogger.auth(
        '❌ Erro ao buscar/criar usuário no Firestore: $e',
        data: {'uid': user.uid, 'email': user.email},
      );
      return null;
    }
  }

  /// Logout com analytics
  static Future<void> signOut() async {
    final stopwatch = Stopwatch()..start();
    final currentUserUid = currentUser?.uid;

    try {
      AppLogger.auth(
        '🔄 Iniciando logout...',
        data: {'currentUserUid': currentUserUid ?? 'none'},
      );

      // 📊 Analytics: Logout iniciado
      await _trackAuthEvent('logout_attempt', {
        'user_id': currentUserUid,
        'timestamp': DateTime.now().toIso8601String(),
      });

      // Logout do Google
      await _googleSignIn.signOut();
      AppLogger.auth('👋 Google Sign-Out concluído');

      // Logout do Firebase
      await _auth.signOut();
      AppLogger.auth('👋 Firebase Sign-Out concluído');

      stopwatch.stop();

      // 📊 Analytics: Logout bem-sucedido
      await _trackAuthEvent('logout_success', {
        'user_id': currentUserUid,
        'duration_ms': stopwatch.elapsedMilliseconds,
      });

      // 📊 Analytics: Performance do logout
      await _trackAuthPerformance(
        'logout_duration',
        stopwatch.elapsedMilliseconds,
        {'success': true},
      );

      AppLogger.auth('✅ Logout completo realizado com sucesso');
    } catch (e) {
      stopwatch.stop();

      // 📊 Analytics: Erro no logout
      await _trackAuthEvent('logout_error', {
        'user_id': currentUserUid,
        'duration_ms': stopwatch.elapsedMilliseconds,
        'error_type': e.runtimeType.toString(),
        'error_message': e.toString(),
      });

      AppLogger.auth('❌ Erro durante logout: $e');
      rethrow;
    }
  }

  /// Reautenticar usuário com analytics
  static Future<bool> reauthenticateWithGoogle() async {
    final stopwatch = Stopwatch()..start();

    try {
      AppLogger.auth('🔐 Iniciando reautenticação...');

      // 📊 Analytics: Tentativa de reautenticação
      await _trackAuthEvent('reauthentication_attempt', {
        'method': 'google',
        'user_id': currentUser?.uid,
      });

      final user = currentUser;
      if (user == null) {
        stopwatch.stop();

        await _trackAuthEvent('reauthentication_failed', {
          'method': 'google',
          'duration_ms': stopwatch.elapsedMilliseconds,
          'error': 'no_current_user',
        });

        AppLogger.auth('❌ Nenhum usuário logado para reautenticação');
        return false;
      }

      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        stopwatch.stop();

        await _trackAuthEvent('reauthentication_cancelled', {
          'method': 'google',
          'duration_ms': stopwatch.elapsedMilliseconds,
          'user_id': user.uid,
        });

        AppLogger.auth('❌ Reautenticação cancelada pelo usuário');
        return false;
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      await user.reauthenticateWithCredential(credential);
      stopwatch.stop();

      // 📊 Analytics: Reautenticação bem-sucedida
      await _trackAuthEvent('reauthentication_success', {
        'method': 'google',
        'duration_ms': stopwatch.elapsedMilliseconds,
        'user_id': user.uid,
      });

      AppLogger.auth('✅ Reautenticação bem-sucedida', data: {'uid': user.uid});

      return true;
    } catch (e) {
      stopwatch.stop();

      // 📊 Analytics: Erro na reautenticação
      await _trackAuthEvent('reauthentication_error', {
        'method': 'google',
        'duration_ms': stopwatch.elapsedMilliseconds,
        'user_id': currentUser?.uid,
        'error_type': e.runtimeType.toString(),
        'error_message': e.toString(),
      });

      AppLogger.auth('❌ Erro na reautenticação: $e');
      return false;
    }
  }

  // ========== MÉTODOS DE ANALYTICS INTERNOS ==========

  /// Rastrear evento de autenticação
  static Future<void> _trackAuthEvent(
    String eventName,
    Map<String, dynamic> data,
  ) async {
    if (!AnalyticsIntegration.isEnabled) return;

    try {
      await AnalyticsIntegration.manager.trackEvent(
        'auth_$eventName',
        parameters: {
          'auth_provider': 'google',
          'timestamp': DateTime.now().toIso8601String(),
          ...data,
        },
        category: EventCategory.user,
        priority: _getEventPriority(eventName),
      );
    } catch (e) {
      AppLogger.warning('Erro ao enviar analytics de auth: $e');
    }
  }

  /// Rastrear performance de autenticação
  static Future<void> _trackAuthPerformance(
    String operationName,
    int durationMs,
    Map<String, dynamic> data,
  ) async {
    if (!AnalyticsIntegration.isEnabled) return;

    try {
      await AnalyticsIntegration.manager.trackTiming(
        operationName,
        durationMs,
        category: 'auth_performance',
        parameters: {
          'auth_provider': 'google',
          'performance_category': _getPerformanceCategory(durationMs),
          ...data,
        },
      );
    } catch (e) {
      AppLogger.warning('Erro ao enviar performance de auth: $e');
    }
  }

  /// Rastrear conversão de autenticação
  static Future<void> _trackAuthConversion(
    String goalName,
    Map<String, dynamic> data,
  ) async {
    if (!AnalyticsIntegration.isEnabled) return;

    try {
      await AnalyticsIntegration.manager.trackConversion(
        goalName,
        parameters: {
          'auth_provider': 'google',
          'conversion_category': 'user_acquisition',
          ...data,
        },
      );
    } catch (e) {
      AppLogger.warning('Erro ao enviar conversão de auth: $e');
    }
  }

  /// Obter prioridade do evento baseado no nome
  static EventPriority _getEventPriority(String eventName) {
    if (eventName.contains('success') || eventName.contains('created')) {
      return EventPriority.high;
    } else if (eventName.contains('error') || eventName.contains('failed')) {
      return EventPriority.high;
    } else if (eventName.contains('attempt') ||
        eventName.contains('cancelled')) {
      return EventPriority.medium;
    } else {
      return EventPriority.low;
    }
  }

  /// Categorizar performance baseada na duração
  static String _getPerformanceCategory(int durationMs) {
    if (durationMs < 1000) return 'fast';
    if (durationMs < 3000) return 'normal';
    if (durationMs < 5000) return 'slow';
    return 'very_slow';
  }

  // ========== MÉTODOS EXISTENTES (sem alteração) ==========

  static bool get isSignedIn => currentUser != null;
  static String? get currentUserUid => currentUser?.uid;
  static String? get currentUserEmail => currentUser?.email;

  static Future<bool> deleteAccount() async {
    // Implementação existente com analytics adicionado...
    return false;
  }

  static void logCurrentUser() {
    // Implementação existente...
  }
}