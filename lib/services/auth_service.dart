// lib/services/auth_service.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:unlock/models/user_model.dart';
import 'package:unlock/services/connection_service.dart';
import 'package:unlock/services/firestore_service.dart';

class AuthService {
  // Instâncias singleton
  static final _auth = FirebaseAuth.instance;
  static final _googleSignIn = GoogleSignIn();
  static final _firestore = FirestoreService();

  // Getters públicos
  static User? get currentUser => _auth.currentUser;
  static Stream<User?> get authStateChanges => _auth.authStateChanges();
  static bool get isAuthenticated => currentUser != null;

  // ========== AUTENTICAÇÃO ==========

  /// Login com Google
  static Future<bool> signInWithGoogle() async {
    try {
      _log('🔄 Iniciando Google Sign-In...');

      // Verificar conectividade
      await _ensureConnection();

      // Iniciar fluxo de login do Google
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        _log('⚠️ Login cancelado pelo usuário');
        return false;
      }

      _log('🔄 Obtendo credenciais do Google...');

      // Obter credenciais
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      if (googleAuth.accessToken == null || googleAuth.idToken == null) {
        throw AuthException('Credenciais do Google inválidas');
      }

      // Criar credencial do Firebase
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      _log('🔄 Autenticando com Firebase...');

      // Autenticar com Firebase
      final UserCredential result = await _auth.signInWithCredential(
        credential,
      );

      if (result.user == null) {
        throw AuthException('Falha na autenticação com Firebase');
      }

      _log('✅ Autenticação com Google bem-sucedida: ${result.user!.uid}');

      // ✅ IMPORTANTE: Retornar true para indicar sucesso
      // O AuthProvider escutará a mudança via authStateChanges
      return true;
    } on FirebaseAuthException catch (e) {
      final message = _getFirebaseAuthErrorMessage(e);
      _log('❌ Erro Firebase Auth: ${e.code} - $message');
      throw AuthException(message);
    } catch (e) {
      _log('❌ Erro no Google Sign-In: $e');
      throw AuthException(_getGenericErrorMessage(e.toString()));
    }
  }

  /// Logout
  static Future<void> signOut() async {
    try {
      _log('🔄 Fazendo logout...');

      // Fazer logout em paralelo para maior velocidade
      final futures = <Future>[_googleSignIn.signOut(), _auth.signOut()];

      await Future.wait(futures, eagerError: false);

      _log('✅ Logout concluído');
    } catch (e) {
      _log('❌ Erro no logout: $e');

      // Garantir que pelo menos o Firebase Auth seja limpo
      try {
        await _auth.signOut();
      } catch (authError) {
        _log('❌ Erro crítico no logout do Firebase: $authError');
      }

      throw AuthException('Erro no logout: $e');
    }
  }

  // ========== GERENCIAMENTO DE USUÁRIO ==========

  /// Buscar ou criar usuário no Firestore
  static Future<UserModel?> getOrCreateUserInFirestore(
    User firebaseUser,
  ) async {
    const maxRetries = 3;
    int retryCount = 0;

    while (retryCount < maxRetries) {
      try {
        _log(
          '🔄 Tentativa ${retryCount + 1}/$maxRetries - Carregando usuário: ${firebaseUser.uid}',
        );

        // Verificar conectividade
        await _ensureConnection();

        // Tentar buscar usuário existente
        final existingUser = await _firestore.getUser(firebaseUser.uid);

        if (existingUser != null) {
          _log('✅ Usuário encontrado: ${existingUser.username}');
          return existingUser;
        }

        // Criar novo usuário
        _log('🔄 Criando novo usuário...');
        final newUser = _createUserModel(firebaseUser);

        await _firestore.createUser(newUser);

        _log('✅ Novo usuário criado: ${newUser.username}');
        return newUser;
      } catch (e) {
        retryCount++;
        _log('❌ Tentativa $retryCount falhou: $e');

        if (retryCount >= maxRetries) {
          _log('❌ Falha após $maxRetries tentativas');
          throw AuthException('Falha ao carregar dados do usuário: $e');
        }

        // Delay exponencial entre tentativas
        await Future.delayed(Duration(seconds: retryCount * 2));
      }
    }

    return null;
  }

  /// Atualizar dados do usuário
  static Future<UserModel?> updateUser(UserModel user) async {
    try {
      _log('🔄 Atualizando usuário: ${user.uid}');

      await _ensureConnection();
      await _firestore.updateUserModel(user);

      _log('✅ Usuário atualizado');
      return user;
    } catch (e) {
      _log('❌ Erro ao atualizar usuário: $e');
      throw AuthException('Erro ao atualizar usuário: $e');
    }
  }

  /// Deletar usuário
  static Future<void> deleteUser() async {
    try {
      final user = currentUser;
      if (user == null) {
        throw AuthException('Nenhum usuário logado');
      }

      _log('🔄 Deletando usuário: ${user.uid}');

      // Deletar do Firestore primeiro
      await _firestore.deleteUser(user.uid);

      // Deletar da autenticação
      await user.delete();

      _log('✅ Usuário deletado');
    } catch (e) {
      _log('❌ Erro ao deletar usuário: $e');
      throw AuthException('Erro ao deletar usuário: $e');
    }
  }

  // ========== UTILITÁRIOS ==========

  /// Verificar conectividade e aguardar se necessário
  static Future<void> _ensureConnection() async {
    if (!await ConnectionService.checkConnection()) {
      _log('⚠️ Sem conexão - aguardando...');

      final hasConnection = await ConnectionService.waitForConnection(
        timeout: const Duration(seconds: 15),
      );

      if (!hasConnection) {
        throw AuthException('Sem conexão com a internet');
      }
    }
  }

  /// Criar modelo de usuário a partir do Firebase User
  static UserModel _createUserModel(User firebaseUser) {
    final now = DateTime.now();

    return UserModel(
      uid: firebaseUser.uid,
      username: _generateUsername(firebaseUser),
      displayName: firebaseUser.displayName ?? 'Usuário',
      email: firebaseUser.email ?? '',
      avatar: firebaseUser.photoURL ?? '👤',
      level: 1,
      xp: 0,
      coins: 200,
      gems: 20,
      createdAt: now,
      lastLoginAt: now,
      aiConfig: const {'apiUrl': '', 'apiKey': '', 'enabled': false},
      // ✅ CAMPOS DE ONBOARDING - SEMPRE VAZIOS PARA USUÁRIO NOVO
      codinome: null,
      interesses: [],
      relationshipInterest: null,
      onboardingCompleted:
          false, // ← IMPORTANTE: sempre false para novo usuário
    );
  }

  /// Gerar nome de usuário único
  static String _generateUsername(User firebaseUser) {
    if (firebaseUser.displayName != null &&
        firebaseUser.displayName!.isNotEmpty) {
      return firebaseUser.displayName!.replaceAll(' ', '').toLowerCase();
    }

    if (firebaseUser.email != null && firebaseUser.email!.isNotEmpty) {
      return firebaseUser.email!.split('@').first.toLowerCase();
    }

    return 'usuario${firebaseUser.uid.substring(0, 6)}';
  }

  /// Mapear erros do Firebase Auth para mensagens amigáveis
  static String _getFirebaseAuthErrorMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'account-exists-with-different-credential':
        return 'Esta conta já existe com outro método de login';
      case 'invalid-credential':
        return 'Credenciais inválidas';
      case 'operation-not-allowed':
        return 'Login com Google não habilitado';
      case 'user-disabled':
        return 'Esta conta foi desabilitada';
      case 'user-not-found':
        return 'Usuário não encontrado';
      case 'wrong-password':
        return 'Senha incorreta';
      case 'email-already-in-use':
        return 'Este email já está em uso';
      case 'weak-password':
        return 'Senha muito fraca';
      case 'network-request-failed':
        return 'Erro de conexão. Verifique sua internet';
      case 'too-many-requests':
        return 'Muitas tentativas. Tente novamente mais tarde';
      default:
        return 'Erro na autenticação: ${e.message ?? e.code}';
    }
  }

  /// Mapear erros genéricos para mensagens amigáveis
  static String _getGenericErrorMessage(String error) {
    if (error.contains('network') || error.contains('connection')) {
      return 'Erro de conexão. Verifique sua internet';
    }

    if (error.contains('timeout')) {
      return 'Operação expirou. Tente novamente';
    }

    if (error.contains('cancelled') || error.contains('canceled')) {
      return 'Operação cancelada';
    }

    return 'Erro inesperado. Tente novamente';
  }

  /// Log de debug
  static void _log(String message) {
    if (kDebugMode) {
      print('AuthService: $message');
    }
  }

  // ========== STATUS E VALIDAÇÕES ==========

  /// Obter status detalhado da autenticação
  static Future<Map<String, dynamic>> getAuthStatus() async {
    try {
      final user = currentUser;
      final connection = await ConnectionService.getConnectionDetails();

      return {
        'isAuthenticated': user != null,
        'uid': user?.uid,
        'email': user?.email,
        'displayName': user?.displayName,
        'emailVerified': user?.emailVerified ?? false,
        'lastSignInTime': user?.metadata.lastSignInTime?.toIso8601String(),
        'creationTime': user?.metadata.creationTime?.toIso8601String(),
        'connection': connection,
        'timestamp': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      return {
        'error': e.toString(),
        'timestamp': DateTime.now().toIso8601String(),
      };
    }
  }

  /// Verificar se o usuário está verificado
  static bool get isEmailVerified => currentUser?.emailVerified ?? false;

  /// Enviar email de verificação
  static Future<void> sendEmailVerification() async {
    final user = currentUser;
    if (user == null) {
      throw AuthException('Nenhum usuário logado');
    }

    try {
      await user.sendEmailVerification();
      _log('✅ Email de verificação enviado');
    } catch (e) {
      _log('❌ Erro ao enviar email de verificação: $e');
      throw AuthException('Erro ao enviar email de verificação: $e');
    }
  }
}

/// Exception personalizada para erros de autenticação
class AuthException implements Exception {
  final String message;

  const AuthException(this.message);

  @override
  String toString() => 'AuthException: $message';
}
