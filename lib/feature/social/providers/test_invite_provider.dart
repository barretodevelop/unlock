// lib/providers/test_invite_provider.dart
import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:unlock/models/user_model.dart';
import 'package:unlock/providers/auth_provider.dart';
import 'package:unlock/services/notification_service.dart';

// ============== TEST INVITE MODELS ==============
enum TestInviteStatus {
  pending, // Convite enviado, aguardando resposta
  accepted, // Convite aceito, teste pode iniciar
  rejected, // Convite rejeitado
  expired, // Convite expirou
  inProgress, // Teste em andamento
  completed, // Teste finalizado
}

@immutable
class TestInvite {
  final String id;
  final String senderId;
  final String receiverId;
  final UserModel senderUser;
  final UserModel receiverUser;
  final TestInviteStatus status;
  final DateTime createdAt;
  final DateTime? respondedAt;
  final DateTime? expiresAt;
  final Map<String, dynamic>? testData;

  const TestInvite({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.senderUser,
    required this.receiverUser,
    required this.status,
    required this.createdAt,
    this.respondedAt,
    this.expiresAt,
    this.testData,
  });

  TestInvite copyWith({
    TestInviteStatus? status,
    DateTime? respondedAt,
    Map<String, dynamic>? testData,
  }) {
    return TestInvite(
      id: id,
      senderId: senderId,
      receiverId: receiverId,
      senderUser: senderUser,
      receiverUser: receiverUser,
      status: status ?? this.status,
      createdAt: createdAt,
      respondedAt: respondedAt ?? this.respondedAt,
      expiresAt: expiresAt,
      testData: testData ?? this.testData,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'senderId': senderId,
      'receiverId': receiverId,
      'status': status.name,
      'createdAt': createdAt.toIso8601String(),
      'respondedAt': respondedAt?.toIso8601String(),
      'expiresAt': expiresAt?.toIso8601String(),
      'testData': testData,
    };
  }

  factory TestInvite.fromFirestore(
    Map<String, dynamic> data,
    UserModel senderUser,
    UserModel receiverUser,
  ) {
    return TestInvite(
      id: data['id'] ?? '',
      senderId: data['senderId'] ?? '',
      receiverId: data['receiverId'] ?? '',
      senderUser: senderUser,
      receiverUser: receiverUser,
      status: TestInviteStatus.values.firstWhere(
        (s) => s.name == data['status'],
        orElse: () => TestInviteStatus.pending,
      ),
      createdAt: DateTime.tryParse(data['createdAt'] ?? '') ?? DateTime.now(),
      respondedAt: data['respondedAt'] != null
          ? DateTime.tryParse(data['respondedAt'])
          : null,
      expiresAt: data['expiresAt'] != null
          ? DateTime.tryParse(data['expiresAt'])
          : null,
      testData: data['testData'],
    );
  }

  bool get isExpired => expiresAt != null && DateTime.now().isAfter(expiresAt!);
  bool get canRespond => status == TestInviteStatus.pending && !isExpired;
  bool get canStartTest => status == TestInviteStatus.accepted;
}

// ============== TEST INVITE STATE ==============
@immutable
class TestInviteState {
  final List<TestInvite> sentInvites;
  final List<TestInvite> receivedInvites;
  final TestInvite? activeInvite;
  final bool isLoading;
  final String? error;

  const TestInviteState({
    this.sentInvites = const [],
    this.receivedInvites = const [],
    this.activeInvite,
    this.isLoading = false,
    this.error,
  });

  TestInviteState copyWith({
    List<TestInvite>? sentInvites,
    List<TestInvite>? receivedInvites,
    TestInvite? activeInvite,
    bool? isLoading,
    String? error,
  }) {
    return TestInviteState(
      sentInvites: sentInvites ?? this.sentInvites,
      receivedInvites: receivedInvites ?? this.receivedInvites,
      activeInvite: activeInvite,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }

  bool get hasPendingInvites =>
      receivedInvites.any((invite) => invite.canRespond);
  bool get hasActiveTest => activeInvite?.canStartTest == true;

  List<TestInvite> get pendingReceivedInvites =>
      receivedInvites.where((invite) => invite.canRespond).toList();
}

// ============== TEST INVITE PROVIDER ==============
final testInviteProvider =
    StateNotifierProvider<TestInviteNotifier, TestInviteState>((ref) {
      return TestInviteNotifier(ref);
    });

class TestInviteNotifier extends StateNotifier<TestInviteState> {
  final Ref _ref;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  StreamSubscription<QuerySnapshot>? _invitesSubscription;
  ProviderSubscription<AuthState>?
  _authSubscription; // Adicionar para escutar auth
  Timer? _expirationTimer;

  static const Duration _inviteExpirationDuration = Duration(minutes: 5);

  TestInviteNotifier(this._ref) : super(const TestInviteState()) {
    // Escutar mudanças de autenticação para inicializar/limpar o listener de convites
    _authSubscription = _ref.listen<AuthState>(authProvider, (previous, next) {
      final prevUser = previous?.user;
      final nextUser = next.user;

      if (nextUser != null && prevUser == null) {
        // Usuário fez login
        _initializeInvitesListener();
        _startExpirationTimer(); // Iniciar timer de expiração apenas quando logado
      } else if (nextUser == null &&
          (prevUser != null || previous?.isAuthenticated == true)) {
        // Usuário fez logout ou estado de autenticação mudou para não autenticado

        // Usuário fez logout
        _disposeInvitesListener();
        _expirationTimer?.cancel(); // Parar timer de expiração
        state = const TestInviteState(); // Resetar estado
      }
    }, fireImmediately: true); // fireImmediately para pegar o estado inicial
  }

  // ============== INICIALIZAÇÃO ==============
  void _initializeInvitesListener() {
    final currentUser = _ref.read(authProvider).user;
    if (currentUser == null) return;

    _invitesSubscription?.cancel(); // Cancelar subscrição anterior, se houver

    try {
      // Escutar convites onde o usuário é sender ou receiver
      _invitesSubscription = _firestore
          .collection('test_invites')
          .where('participants', arrayContains: currentUser.uid)
          .orderBy('createdAt', descending: true)
          .limit(50)
          .snapshots()
          .listen(
            _handleInvitesUpdate,
            onError: (Object error, StackTrace stackTrace) => _handleError(
              'Erro no listener de convites: $error\n$stackTrace',
            ),
          );

      if (kDebugMode) {
        print('✅ TestInviteProvider: Listener de convites inicializado');
      }
    } catch (e) {
      _handleError('Erro ao inicializar listener de convites: $e');
    }
  }

  void _disposeInvitesListener() {
    _invitesSubscription?.cancel();
    _invitesSubscription = null;
    if (kDebugMode) {
      print('🗑️ TestInviteProvider: Listener de convites finalizado.');
    }
  }

  void _handleInvitesUpdate(QuerySnapshot snapshot) async {
    try {
      final currentUser = _ref.read(authProvider).user;
      if (currentUser == null) {
        if (kDebugMode) {
          print(
            'TestInviteProvider: currentUser é null em _handleInvitesUpdate',
          );
        }
        return;
      }
      if (kDebugMode) {
        print(
          'TestInviteProvider: _handleInvitesUpdate para ${currentUser.uid}. Docs: ${snapshot.docs.length}',
        );
      }

      final sentInvites = <TestInvite>[];
      final receivedInvites = <TestInvite>[];

      for (final doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final senderId = data['senderId'] ?? '';
        final receiverId = data['receiverId'] ?? '';
        if (kDebugMode) {
          print(
            'TestInviteProvider: Processando convite docId: ${doc.id}, senderId: $senderId, receiverId: $receiverId',
          );
        }

        // Buscar dados dos usuários
        final senderUser = await _getUserData(senderId);
        final receiverUser = await _getUserData(receiverId);

        if (senderUser == null || receiverUser == null) {
          if (kDebugMode) {
            print(
              'TestInviteProvider: Pulando convite ${doc.id} pois senderUser ou receiverUser é null.',
            );
          }
          continue;
        }

        final invite = TestInvite.fromFirestore(data, senderUser, receiverUser);
        if (kDebugMode) {
          print(
            'TestInviteProvider: Convite ${invite.id}, Status: ${invite.status}, isExpired: ${invite.isExpired}, canRespond: ${invite.canRespond}',
          );
        }

        if (invite.senderId == currentUser.uid) {
          sentInvites.add(invite);
        } else if (invite.receiverId == currentUser.uid) {
          receivedInvites.add(invite);
        }
      }

      // Lógica para determinar o activeInvite (se necessário)
      final activeInvite = _determineActiveInvite(sentInvites, receivedInvites);

      if (mounted) {
        state = state.copyWith(
          sentInvites: sentInvites,
          receivedInvites: receivedInvites,
          activeInvite:
              activeInvite, // Pode ser null se nenhum convite ativo for encontrado
          isLoading: false, // Certifique-se de resetar isLoading
          error: null, // Limpar erro anterior em caso de sucesso
        );

        if (kDebugMode) {
          print(
            '📨 TestInviteProvider: ${sentInvites.length} enviados, ${receivedInvites.length} recebidos. ActiveInvite: ${activeInvite?.id}',
          );
        }
      }
    } catch (e) {
      _handleError('Erro ao processar convites: $e');
    }
  }

  TestInvite? _determineActiveInvite(
    List<TestInvite> sentInvites,
    List<TestInvite> receivedInvites,
  ) {
    // Priorizar convites em progresso, depois aceitos, mais recentes primeiro.
    final allInvites = [
      ...receivedInvites,
      ...sentInvites,
    ]; // Processar recebidos primeiro ou conforme sua prioridade
    allInvites.sort(
      (a, b) => b.createdAt.compareTo(a.createdAt),
    ); // Processar mais novos primeiro

    for (final invite in allInvites) {
      if ((invite.status == TestInviteStatus.inProgress ||
              invite.status == TestInviteStatus.accepted) &&
          !invite.isExpired) {
        return invite;
      }
    }
    return null;
  }

  Future<UserModel?> _getUserData(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        return UserModel.fromJson(doc.data()!);
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ TestInviteProvider: Erro ao buscar usuário $uid: $e');
      }
    }
    return null;
  }

  // ============== ENVIAR CONVITE ==============
  Future<bool> sendTestInvite(UserModel targetUser) async {
    final currentUser = _ref.read(authProvider).user;
    if (currentUser == null) return false;

    try {
      state = state.copyWith(isLoading: true, error: null);

      // Verificar se já existe convite pendente entre esses usuários
      final existingInvite = await _checkExistingInvite(
        currentUser.uid,
        targetUser.uid,
      );
      if (existingInvite != null) {
        _handleError('Já existe um convite pendente com este usuário');
        return false;
      }

      // Criar novo convite
      final inviteId = _firestore.collection('test_invites').doc().id;
      final now = DateTime.now();
      final expiresAt = now.add(_inviteExpirationDuration);

      final inviteData = {
        'id': inviteId,
        'senderId': currentUser.uid,
        'receiverId': targetUser.uid,
        'participants': [currentUser.uid, targetUser.uid],
        'status': TestInviteStatus.pending.name,
        'createdAt': now.toIso8601String(),
        'expiresAt': expiresAt.toIso8601String(),
        'senderName': currentUser.preferredDisplayName,
        'senderAvatar': currentUser.avatar,
      };

      await _firestore.collection('test_invites').doc(inviteId).set(inviteData);

      // Enviar notificação para o usuário alvo
      await _sendInviteNotification(targetUser, currentUser);

      if (mounted) {
        state = state.copyWith(isLoading: false);
        if (kDebugMode) {
          print(
            '✅ TestInviteProvider: Convite enviado para ${targetUser.preferredDisplayName}',
          );
        }
      }

      return true;
    } catch (e) {
      _handleError('Erro ao enviar convite: $e');
      return false;
    }
  }

  Future<Map<String, dynamic>?> _checkExistingInvite(
    String userId1,
    String userId2,
  ) async {
    try {
      final query = await _firestore
          .collection('test_invites')
          .where('participants', arrayContains: userId1)
          .where(
            'status',
            whereIn: [
              TestInviteStatus.pending.name,
              TestInviteStatus.accepted.name,
              TestInviteStatus.inProgress.name,
            ],
          )
          .get();

      for (final doc in query.docs) {
        final data = doc.data();
        final participants = List<String>.from(data['participants'] ?? []);
        if (participants.contains(userId2)) {
          return data;
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ TestInviteProvider: Erro ao verificar convite existente: $e');
      }
    }
    return null;
  }

  Future<void> _sendInviteNotification(
    UserModel targetUser,
    UserModel senderUser,
  ) async {
    try {
      // TODO: Implementar FCM notification
      await NotificationService.showSimpleLocalNotification(
        title: '🎯 Novo Convite de Teste!',
        body:
            '${senderUser.preferredDisplayName} quer testar a compatibilidade com você',
        payload: 'test_invite_${targetUser.uid}',
      );

      if (kDebugMode) {
        print(
          '📨 TestInviteProvider: Notificação enviada para ${targetUser.preferredDisplayName}',
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ TestInviteProvider: Erro ao enviar notificação: $e');
      }
    }
  }

  // ============== RESPONDER CONVITE ==============
  Future<bool> respondToInvite(String inviteId, bool accept) async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      final status = accept
          ? TestInviteStatus.accepted
          : TestInviteStatus.rejected;

      await _firestore.collection('test_invites').doc(inviteId).update({
        'status': status.name,
        'respondedAt': DateTime.now().toIso8601String(),
      });

      if (accept) {
        // Se aceito, notificar o sender que pode iniciar o teste
        final invite = _findInviteById(inviteId);
        if (invite != null) {
          await _sendAcceptNotification(invite.senderUser);
        }
      }

      if (mounted) {
        state = state.copyWith(isLoading: false);
        if (kDebugMode) {
          print(
            '✅ TestInviteProvider: Convite ${accept ? 'aceito' : 'rejeitado'}',
          );
        }
      }

      return true;
    } catch (e) {
      _handleError('Erro ao responder convite: $e');
      return false;
    }
  }

  TestInvite? _findInviteById(String inviteId) {
    final allInvites = [...state.sentInvites, ...state.receivedInvites];
    try {
      return allInvites.firstWhere((invite) => invite.id == inviteId);
    } catch (e) {
      return null;
    }
  }

  Future<void> _sendAcceptNotification(UserModel senderUser) async {
    try {
      await NotificationService.showSimpleLocalNotification(
        title: '🎉 Convite Aceito!',
        body: 'Seu convite foi aceito! O teste pode começar.',
        payload: 'invite_accepted_${senderUser.uid}',
      );
    } catch (e) {
      if (kDebugMode) {
        print('❌ TestInviteProvider: Erro ao enviar notificação de aceite: $e');
      }
    }
  }

  // ============== INICIAR TESTE ==============
  Future<bool> startTest(String inviteId) async {
    try {
      await _firestore.collection('test_invites').doc(inviteId).update({
        'status': TestInviteStatus.inProgress.name,
        'testStartedAt': DateTime.now().toIso8601String(),
      });

      if (kDebugMode) {
        print('✅ TestInviteProvider: Teste iniciado para convite $inviteId');
      }

      return true;
    } catch (e) {
      _handleError('Erro ao iniciar teste: $e');
      return false;
    }
  }

  // ============== FINALIZAR TESTE ==============
  Future<bool> completeTest(
    String inviteId,
    Map<String, dynamic> testResults,
  ) async {
    try {
      await _firestore.collection('test_invites').doc(inviteId).update({
        'status': TestInviteStatus.completed.name,
        'testCompletedAt': DateTime.now().toIso8601String(),
        'testResults': testResults,
      });

      // Limpar convite ativo
      if (mounted) {
        state = state.copyWith(
          activeInvite: null,
        ); // Limpa o activeInvite se o teste concluído era o ativo
        if (kDebugMode) {
          print(
            '✅ TestInviteProvider: Teste finalizado para convite $inviteId',
          );
        }
      }

      return true; // Retorna true mesmo se não estiver montado, pois a operação no Firestore foi feita.
    } catch (e) {
      _handleError('Erro ao finalizar teste: $e');
      return false;
    }
  }

  // ============== EXPIRAÇÃO AUTOMÁTICA ==============
  void _startExpirationTimer() {
    _expirationTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
      _checkAndExpireInvites();
    });
  }

  Future<void> _checkAndExpireInvites() async {
    try {
      final now = DateTime.now();
      final expiredInvites = <String>[];

      // Verificar convites enviados expirados
      for (final invite in state.sentInvites) {
        if (invite.status == TestInviteStatus.pending && invite.isExpired) {
          expiredInvites.add(invite.id);
        }
      }

      // Verificar convites recebidos expirados
      for (final invite in state.receivedInvites) {
        if (invite.status == TestInviteStatus.pending && invite.isExpired) {
          expiredInvites.add(invite.id);
        }
      }

      // Marcar como expirados no Firestore
      for (final inviteId in expiredInvites) {
        await _firestore.collection('test_invites').doc(inviteId).update({
          'status': TestInviteStatus.expired.name,
          'expiredAt': now.toIso8601String(),
        });
      }

      if (expiredInvites.isNotEmpty && kDebugMode) {
        print(
          '⏰ TestInviteProvider: ${expiredInvites.length} convites expirados',
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ TestInviteProvider: Erro ao verificar expiração: $e');
      }
    }
  }

  // ============== CONTROLE DE ESTADO ==============
  void clearError() {
    if (mounted) {
      state = state.copyWith(error: null);
    }
  }

  void _handleError(String error) {
    if (kDebugMode) {
      print('❌ TestInviteProvider: $error');
    }
    if (mounted) {
      state = state.copyWith(isLoading: false, error: error);
    }
  }

  @override
  void dispose() {
    _invitesSubscription?.cancel();
    _authSubscription?.close();
    _expirationTimer?.cancel();
    super.dispose();
  }
}

// ============== EXTENSION PARA FACILITAR USO ==============
extension TestInviteProviderX on WidgetRef {
  TestInviteNotifier get testInvite => read(testInviteProvider.notifier);
  TestInviteState get testInviteState => watch(testInviteProvider);
}
