// enhanced_test_invite_provider.dart
// PROVIDER OTIMIZADO PARA FLUXO BIDIRECIONAL DE CONVITES

import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:unlock/models/user_model.dart';
import 'package:unlock/providers/auth_provider.dart';
import 'package:unlock/services/firestore_service.dart';
import 'package:unlock/services/notification_service.dart';

// ============== ENHANCED MODELS ==============

enum TestInviteStatus {
  pending, // Convite enviado, aguardando resposta
  accepted, // Convite aceito, teste pode iniciar
  rejected, // Convite rejeitado
  expired, // Convite expirou
  inProgress, // Teste em andamento
  completed, // Teste finalizado
}

enum InviteRole {
  sender, // Quem enviou o convite
  receiver, // Quem recebeu o convite
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
  final DateTime? testStartedAt;
  final Map<String, dynamic>? testData;

  // NOVOS CAMPOS PARA SINCRONIZAÇÃO
  final bool canStartTest; // Pode iniciar o teste
  final String? sessionId; // ID da sessão de teste
  final bool isWaitingForPartner; // Aguardando o parceiro

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
    this.testStartedAt,
    this.testData,
    this.canStartTest = false,
    this.sessionId,
    this.isWaitingForPartner = false,
  });

  // Getters utilitários
  bool get isPending => status == TestInviteStatus.pending;
  bool get isAccepted => status == TestInviteStatus.accepted;
  bool get isRejected => status == TestInviteStatus.rejected;
  bool get isExpired => status == TestInviteStatus.expired;
  bool get isInProgress => status == TestInviteStatus.inProgress;
  bool get isCompleted => status == TestInviteStatus.completed;

  bool get readyToStart => isAccepted && canStartTest && !isInProgress;

  InviteRole getRoleForUser(String userId) {
    return userId == senderId ? InviteRole.sender : InviteRole.receiver;
  }

  UserModel getPartnerForUser(String userId) {
    return userId == senderId ? receiverUser : senderUser;
  }

  TestInvite copyWith({
    TestInviteStatus? status,
    DateTime? respondedAt,
    DateTime? testStartedAt,
    Map<String, dynamic>? testData,
    bool? canStartTest,
    String? sessionId,
    bool? isWaitingForPartner,
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
      testStartedAt: testStartedAt ?? this.testStartedAt,
      testData: testData ?? this.testData,
      canStartTest: canStartTest ?? this.canStartTest,
      sessionId: sessionId ?? this.sessionId,
      isWaitingForPartner: isWaitingForPartner ?? this.isWaitingForPartner,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'senderId': senderId,
      'receiverId': receiverId,
      'participants': [senderId, receiverId],
      'status': status.name,
      'createdAt': createdAt.toIso8601String(),
      'respondedAt': respondedAt?.toIso8601String(),
      'expiresAt': expiresAt?.toIso8601String(),
      'testStartedAt': testStartedAt?.toIso8601String(),
      'testData': testData,
      'canStartTest': canStartTest,
      'sessionId': sessionId,
      'isWaitingForPartner': isWaitingForPartner,
      'lastModified': DateTime.now().toIso8601String(),
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
      testStartedAt: data['testStartedAt'] != null
          ? DateTime.tryParse(data['testStartedAt'])
          : null,
      testData: data['testData'] as Map<String, dynamic>?,
      canStartTest: data['canStartTest'] ?? false,
      sessionId: data['sessionId'],
      isWaitingForPartner: data['isWaitingForPartner'] ?? false,
    );
  }
}

// ============== ENHANCED STATE ==============

@immutable
class EnhancedTestInviteState {
  final List<TestInvite> sentInvites;
  final List<TestInvite> receivedInvites;
  final TestInvite? activeInvite;
  final bool isLoading;
  final String? error;
  final String? successMessage;

  const EnhancedTestInviteState({
    this.sentInvites = const [],
    this.receivedInvites = const [],
    this.activeInvite,
    this.isLoading = false,
    this.error,
    this.successMessage,
  });

  // Getters otimizados
  List<TestInvite> get pendingReceivedInvites =>
      receivedInvites.where((i) => i.isPending).toList();

  List<TestInvite> get acceptedSentInvites =>
      sentInvites.where((i) => i.isAccepted).toList();

  List<TestInvite> get readyToStartInvites => [
    ...sentInvites.where((i) => i.readyToStart),
    ...receivedInvites.where((i) => i.readyToStart),
  ];

  bool get hasPendingInvites => pendingReceivedInvites.isNotEmpty;
  bool get hasReadyToStartInvites => readyToStartInvites.isNotEmpty;
  bool get hasActiveTest => activeInvite?.isInProgress ?? false;

  EnhancedTestInviteState copyWith({
    List<TestInvite>? sentInvites,
    List<TestInvite>? receivedInvites,
    TestInvite? activeInvite,
    bool? isLoading,
    String? error,
    String? successMessage,
  }) {
    return EnhancedTestInviteState(
      sentInvites: sentInvites ?? this.sentInvites,
      receivedInvites: receivedInvites ?? this.receivedInvites,
      activeInvite: activeInvite ?? this.activeInvite,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      successMessage: successMessage,
    );
  }
}

// ============== ENHANCED PROVIDER ==============

final enhancedTestInviteProvider =
    StateNotifierProvider<EnhancedTestInviteNotifier, EnhancedTestInviteState>(
      (ref) => EnhancedTestInviteNotifier(ref),
    );

class EnhancedTestInviteNotifier
    extends StateNotifier<EnhancedTestInviteState> {
  final Ref _ref;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  StreamSubscription<QuerySnapshot>? _invitesSubscription;
  Timer? _cleanupTimer;

  EnhancedTestInviteNotifier(this._ref)
    : super(const EnhancedTestInviteState()) {
    _initializeListeners();
    _startCleanupTimer();
  }

  @override
  void dispose() {
    _invitesSubscription?.cancel();
    _cleanupTimer?.cancel();
    super.dispose();
  }

  // ============== REAL-TIME LISTENERS ==============

  void _initializeListeners() {
    final user = _ref.read(authProvider).user;
    if (user?.uid == null) return;

    _invitesSubscription = _firestore
        .collection('test_invites')
        .where('participants', arrayContains: user!.uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .listen(_handleInvitesUpdate, onError: _handleError);

    if (kDebugMode) {
      print(
        '🔄 EnhancedTestInviteProvider: Listeners inicializados para ${user.uid}',
      );
    }
  }

  Future<void> _handleInvitesUpdate(QuerySnapshot snapshot) async {
    try {
      final user = _ref.read(authProvider).user;
      if (user?.uid == null) return;

      final sentInvites = <TestInvite>[];
      final receivedInvites = <TestInvite>[];

      for (final doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final senderId = data['senderId'] as String;
        final receiverId = data['receiverId'] as String;

        // Buscar dados dos usuários
        final senderUser = await _getUserById(senderId);
        final receiverUser = await _getUserById(receiverId);

        if (senderUser == null || receiverUser == null) continue;

        final invite = TestInvite.fromFirestore(data, senderUser, receiverUser);

        if (invite.senderId == user!.uid) {
          sentInvites.add(invite);
        } else {
          receivedInvites.add(invite);
        }
      }

      if (mounted) {
        state = state.copyWith(
          sentInvites: sentInvites,
          receivedInvites: receivedInvites,
        );

        // Detectar novos convites aceitos
        _detectNewAcceptedInvites(sentInvites);
      }
    } catch (e) {
      _handleError('Erro ao atualizar convites: $e');
    }
  }

  void _detectNewAcceptedInvites(List<TestInvite> newSentInvites) {
    final previousAccepted = state.acceptedSentInvites.map((i) => i.id).toSet();
    final currentAccepted = newSentInvites.where((i) => i.isAccepted).toList();

    for (final invite in currentAccepted) {
      if (!previousAccepted.contains(invite.id)) {
        _notifyInviteAccepted(invite);
      }
    }
  }

  // ============== CORE ACTIONS ==============

  Future<bool> respondToInvite(String inviteId, bool accept) async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      final newStatus = accept
          ? TestInviteStatus.accepted
          : TestInviteStatus.rejected;

      await _firestore.collection('test_invites').doc(inviteId).update({
        'status': newStatus.name,
        'respondedAt': DateTime.now().toIso8601String(),
        'canStartTest': accept, // Se aceito, pode iniciar teste
        'lastModified': DateTime.now().toIso8601String(),
      });

      if (mounted) {
        state = state.copyWith(
          isLoading: false,
          successMessage: accept ? 'Convite aceito!' : 'Convite recusado',
        );
      }

      return true;
    } catch (e) {
      _handleError('Erro ao responder convite: $e');
      return false;
    }
  }

  Future<bool> startTestSession(String inviteId) async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      // Marcar como teste iniciado
      await _firestore.collection('test_invites').doc(inviteId).update({
        'status': TestInviteStatus.inProgress.name,
        'testStartedAt': DateTime.now().toIso8601String(),
        'canStartTest': false,
        'isWaitingForPartner': false,
        'lastModified': DateTime.now().toIso8601String(),
      });

      if (mounted) {
        state = state.copyWith(isLoading: false);
      }

      return true;
    } catch (e) {
      _handleError('Erro ao iniciar teste: $e');
      return false;
    }
  }

  // ============== NOTIFICATIONS ==============

  void _notifyInviteAccepted(TestInvite invite) {
    _sendLocalNotification(
      title: '🎉 Convite Aceito!',
      body:
          '${invite.receiverUser.preferredDisplayName} aceitou seu convite! '
          'Vocês podem iniciar o teste agora.',
      payload: 'invite_accepted_${invite.id}',
    );
  }

  Future<void> _sendLocalNotification({
    required String title,
    required String body,
    required String payload,
  }) async {
    try {
      await NotificationService.showSimpleLocalNotification(
        title: title,
        body: body,
        payload: payload,
      );
    } catch (e) {
      if (kDebugMode) {
        print('❌ Erro ao enviar notificação: $e');
      }
    }
  }

  // ============== HELPERS ==============

  Future<UserModel?> _getUserById(String userId) async {
    final FirestoreService _firestoreService;
    try {
      // return _firestoreService.getUser(userId);
    } catch (e) {
      if (kDebugMode) {
        print('❌ Erro ao buscar usuário $userId: $e');
      }
      return null;
    }
  }

  void _handleError(String error) {
    if (mounted) {
      state = state.copyWith(isLoading: false, error: error);
    }

    if (kDebugMode) {
      print('❌ EnhancedTestInviteProvider: $error');
    }
  }

  void _startCleanupTimer() {
    _cleanupTimer = Timer.periodic(const Duration(minutes: 5), (_) {
      _cleanupExpiredInvites();
    });
  }

  Future<void> _cleanupExpiredInvites() async {
    try {
      final now = DateTime.now();
      final batch = _firestore.batch();

      final expiredQuery = await _firestore
          .collection('test_invites')
          .where('status', isEqualTo: 'pending')
          .where('expiresAt', isLessThan: now.toIso8601String())
          .get();

      for (final doc in expiredQuery.docs) {
        batch.update(doc.reference, {
          'status': TestInviteStatus.expired.name,
          'lastModified': now.toIso8601String(),
        });
      }

      if (expiredQuery.docs.isNotEmpty) {
        await batch.commit();
        if (kDebugMode) {
          print('🧹 ${expiredQuery.docs.length} convites expirados limpos');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Erro na limpeza de convites expirados: $e');
      }
    }
  }

  // ============== PUBLIC HELPERS ==============

  void clearMessages() {
    state = state.copyWith(error: null, successMessage: null);
  }
}
