// lib/feature/games/social/providers/unlocked_connections_provider.dart
import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:unlock/models/user_model.dart';
import 'package:unlock/providers/auth_provider.dart';
import 'package:unlock/services/notification_service.dart';

// ============== MODELS ==============
@immutable
class UnlockedConnection {
  final String id;
  final String connectionId;
  final UserModel otherUser;
  final double compatibilityScore;
  final DateTime unlockedAt;
  final bool chatEnabled;
  final int unreadMessages;
  final DateTime? lastActivity;
  final ConnectionStatus status;

  const UnlockedConnection({
    required this.id,
    required this.connectionId,
    required this.otherUser,
    required this.compatibilityScore,
    required this.unlockedAt,
    this.chatEnabled = true,
    this.unreadMessages = 0,
    this.lastActivity,
    this.status = ConnectionStatus.active,
  });

  UnlockedConnection copyWith({
    String? id,
    String? connectionId,
    UserModel? otherUser,
    double? compatibilityScore,
    DateTime? unlockedAt,
    bool? chatEnabled,
    int? unreadMessages,
    DateTime? lastActivity,
    ConnectionStatus? status,
  }) {
    return UnlockedConnection(
      id: id ?? this.id,
      connectionId: connectionId ?? this.connectionId,
      otherUser: otherUser ?? this.otherUser,
      compatibilityScore: compatibilityScore ?? this.compatibilityScore,
      unlockedAt: unlockedAt ?? this.unlockedAt,
      chatEnabled: chatEnabled ?? this.chatEnabled,
      unreadMessages: unreadMessages ?? this.unreadMessages,
      lastActivity: lastActivity ?? this.lastActivity,
      status: status ?? this.status,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'connectionId': connectionId,
      'otherUser': otherUser.toJson(),
      'compatibilityScore': compatibilityScore,
      'unlockedAt': unlockedAt.toIso8601String(),
      'chatEnabled': chatEnabled,
      'unreadMessages': unreadMessages,
      'lastActivity': lastActivity?.toIso8601String(),
      'status': status.name,
    };
  }

  factory UnlockedConnection.fromJson(Map<String, dynamic> json) {
    return UnlockedConnection(
      id: json['id'] ?? '',
      connectionId: json['connectionId'] ?? '',
      otherUser: UserModel.fromJson(json['otherUser'] ?? {}),
      compatibilityScore:
          (json['compatibilityScore'] as num?)?.toDouble() ?? 0.0,
      unlockedAt: DateTime.tryParse(json['unlockedAt'] ?? '') ?? DateTime.now(),
      chatEnabled: json['chatEnabled'] ?? true,
      unreadMessages: json['unreadMessages'] ?? 0,
      lastActivity: json['lastActivity'] != null
          ? DateTime.tryParse(json['lastActivity'])
          : null,
      status: ConnectionStatus.values.firstWhere(
        (s) => s.name == json['status'],
        orElse: () => ConnectionStatus.active,
      ),
    );
  }

  bool get hasUnreadMessages => unreadMessages > 0;
  bool get isRecentlyActive =>
      lastActivity != null &&
      DateTime.now().difference(lastActivity!).inHours < 24;
}

enum ConnectionStatus { active, paused, archived, blocked }

// ============== STATE ==============
@immutable
class UnlockedConnectionsState {
  final List<UnlockedConnection> connections;
  final bool isLoading;
  final String? error;
  final int totalUnreadMessages;
  final DateTime? lastUpdated;

  const UnlockedConnectionsState({
    this.connections = const [],
    this.isLoading = false,
    this.error,
    this.totalUnreadMessages = 0,
    this.lastUpdated,
  });

  UnlockedConnectionsState copyWith({
    List<UnlockedConnection>? connections,
    bool? isLoading,
    String? error,
    int? totalUnreadMessages,
    DateTime? lastUpdated,
  }) {
    return UnlockedConnectionsState(
      connections: connections ?? this.connections,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      totalUnreadMessages: totalUnreadMessages ?? this.totalUnreadMessages,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }

  // Getters convenientes
  List<UnlockedConnection> get activeConnections =>
      connections.where((c) => c.status == ConnectionStatus.active).toList();

  List<UnlockedConnection> get recentConnections =>
      connections.where((c) => c.isRecentlyActive).toList()..sort(
        (a, b) => (b.lastActivity ?? b.unlockedAt).compareTo(
          a.lastActivity ?? a.unlockedAt,
        ),
      );

  List<UnlockedConnection> get unreadConnections =>
      connections.where((c) => c.hasUnreadMessages).toList();

  bool get hasUnreadMessages => totalUnreadMessages > 0;
}

// ============== PROVIDER ==============
final unlockedConnectionsProvider =
    StateNotifierProvider<
      UnlockedConnectionsNotifier,
      UnlockedConnectionsState
    >((ref) {
      return UnlockedConnectionsNotifier(ref);
    });

class UnlockedConnectionsNotifier
    extends StateNotifier<UnlockedConnectionsState> {
  final Ref _ref;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  StreamSubscription<QuerySnapshot>? _connectionsSubscription;
  Timer? _periodicUpdateTimer;

  UnlockedConnectionsNotifier(this._ref)
    : super(const UnlockedConnectionsState()) {
    _initialize();
  }

  @override
  void dispose() {
    _connectionsSubscription?.cancel();
    _periodicUpdateTimer?.cancel();
    super.dispose();
  }

  // ============== INITIALIZATION ==============
  void _initialize() {
    // Escutar mudanças no estado de autenticação
    _ref.listen<AuthState>(authProvider, (previous, next) {
      if (next.isAuthenticated && previous?.isAuthenticated != true) {
        _startListening();
      } else if (!next.isAuthenticated && previous?.isAuthenticated == true) {
        _stopListening();
      }
    });

    // Se já está autenticado, começar a escutar
    final authState = _ref.read(authProvider);
    if (authState.isAuthenticated) {
      _startListening();
    }
  }

  void _startListening() {
    final currentUser = _ref.read(authProvider).user;
    if (currentUser == null) return;

    state = state.copyWith(isLoading: true);

    _connectionsSubscription = _db
        .collection('unlocked_connections')
        .where('participants', arrayContains: currentUser.uid)
        .orderBy('lastActivity', descending: true)
        .limit(50)
        .snapshots()
        .listen(_handleConnectionsUpdate, onError: _handleError);

    // Timer para atualizações periódicas
    _periodicUpdateTimer = Timer.periodic(
      const Duration(minutes: 5),
      (_) => _updateConnectionsData(),
    );
  }

  void _stopListening() {
    _connectionsSubscription?.cancel();
    _periodicUpdateTimer?.cancel();
    state = const UnlockedConnectionsState();
  }

  // ============== REAL-TIME UPDATES ==============
  void _handleConnectionsUpdate(QuerySnapshot snapshot) async {
    try {
      final connections = <UnlockedConnection>[];
      int totalUnread = 0;

      for (final doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final connection = await _parseConnectionFromDoc(doc.id, data);

        if (connection != null) {
          connections.add(connection);
          totalUnread += connection.unreadMessages;
        }
      }

      state = state.copyWith(
        connections: connections,
        isLoading: false,
        error: null,
        totalUnreadMessages: totalUnread,
        lastUpdated: DateTime.now(),
      );

      if (kDebugMode) {
        print(
          '✅ UnlockedConnections: Carregadas ${connections.length} conexões',
        );
      }
    } catch (e) {
      _handleError(e);
    }
  }

  Future<UnlockedConnection?> _parseConnectionFromDoc(
    String docId,
    Map<String, dynamic> data,
  ) async {
    try {
      final currentUser = _ref.read(authProvider).user;
      if (currentUser == null) return null;

      final participants = List<String>.from(data['participants'] ?? []);
      final otherUserId = participants.firstWhere(
        (id) => id != currentUser.uid,
        orElse: () => '',
      );

      if (otherUserId.isEmpty) return null;

      // Buscar dados do outro usuário
      final otherUserDoc = await _db.collection('users').doc(otherUserId).get();
      if (!otherUserDoc.exists) return null;

      final otherUser = UserModel.fromJson(otherUserDoc.data()!);

      // Contar mensagens não lidas
      final unreadCount = await _getUnreadMessagesCount(docId, currentUser.uid);

      return UnlockedConnection(
        id: docId,
        connectionId: docId,
        otherUser: otherUser,
        compatibilityScore: (data['compatibility'] as num?)?.toDouble() ?? 0.0,
        unlockedAt:
            DateTime.tryParse(data['unlockedAt'] ?? '') ?? DateTime.now(),
        chatEnabled: data['chatEnabled'] ?? true,
        unreadMessages: unreadCount,
        lastActivity: data['lastActivity'] != null
            ? (data['lastActivity'] as Timestamp).toDate()
            : null,
        status: ConnectionStatus.values.firstWhere(
          (s) => s.name == data['status'],
          orElse: () => ConnectionStatus.active,
        ),
      );
    } catch (e) {
      if (kDebugMode) {
        print('❌ Erro ao parsear conexão: $e');
      }
      return null;
    }
  }

  Future<int> _getUnreadMessagesCount(
    String connectionId,
    String userId,
  ) async {
    try {
      final query = await _db
          .collection('chats')
          .doc(connectionId)
          .collection('messages')
          .where('receiverId', isEqualTo: userId)
          .where('isRead', isEqualTo: false)
          .count()
          .get();

      return query.count ?? 0;
    } catch (e) {
      return 0;
    }
  }

  // ============== ACTIONS ==============
  Future<void> refreshConnections() async {
    final currentUser = _ref.read(authProvider).user;
    if (currentUser == null) return;

    try {
      state = state.copyWith(isLoading: true);

      // Forçar atualização dos dados
      await _updateConnectionsData();

      NotificationService.showSuccess('Conexões atualizadas!');
    } catch (e) {
      _handleError('Erro ao atualizar conexões: $e');
    }
  }

  Future<void> _updateConnectionsData() async {
    // Atualizar contadores de mensagens não lidas
    final updatedConnections = <UnlockedConnection>[];
    int totalUnread = 0;

    for (final connection in state.connections) {
      final currentUser = _ref.read(authProvider).user;
      if (currentUser == null) continue;

      final unreadCount = await _getUnreadMessagesCount(
        connection.connectionId,
        currentUser.uid,
      );

      final updatedConnection = connection.copyWith(
        unreadMessages: unreadCount,
      );

      updatedConnections.add(updatedConnection);
      totalUnread += unreadCount;
    }

    state = state.copyWith(
      connections: updatedConnections,
      totalUnreadMessages: totalUnread,
      lastUpdated: DateTime.now(),
    );
  }

  // ============== CONNECTION MANAGEMENT ==============
  Future<void> markMessagesAsRead(String connectionId) async {
    try {
      final currentUser = _ref.read(authProvider).user;
      if (currentUser == null) return;

      // Atualizar no Firebase
      final messages = await _db
          .collection('chats')
          .doc(connectionId)
          .collection('messages')
          .where('receiverId', isEqualTo: currentUser.uid)
          .where('isRead', isEqualTo: false)
          .get();

      final batch = _db.batch();
      for (final doc in messages.docs) {
        batch.update(doc.reference, {'isRead': true});
      }
      await batch.commit();

      // Atualizar estado local
      final updatedConnections = state.connections.map((connection) {
        if (connection.connectionId == connectionId) {
          return connection.copyWith(unreadMessages: 0);
        }
        return connection;
      }).toList();

      final newTotalUnread = updatedConnections.fold<int>(
        0,
        (sum, conn) => sum + conn.unreadMessages,
      );

      state = state.copyWith(
        connections: updatedConnections,
        totalUnreadMessages: newTotalUnread,
      );
    } catch (e) {
      if (kDebugMode) {
        print('❌ Erro ao marcar mensagens como lidas: $e');
      }
    }
  }

  Future<void> updateConnectionStatus(
    String connectionId,
    ConnectionStatus status,
  ) async {
    try {
      await _db.collection('unlocked_connections').doc(connectionId).update({
        'status': status.name,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Estado será atualizado automaticamente via listener

      String message;
      switch (status) {
        case ConnectionStatus.paused:
          message = 'Conversa pausada';
          break;
        case ConnectionStatus.archived:
          message = 'Conversa arquivada';
          break;
        case ConnectionStatus.blocked:
          message = 'Usuário bloqueado';
          break;
        case ConnectionStatus.active:
          message = 'Conversa reativada';
          break;
      }

      NotificationService.showInfo(message);
    } catch (e) {
      _handleError('Erro ao atualizar status: $e');
    }
  }

  // ============== SEARCH & FILTER ==============
  List<UnlockedConnection> searchConnections(String query) {
    if (query.trim().isEmpty) return state.connections;

    final lowerQuery = query.toLowerCase();
    return state.connections.where((connection) {
      return connection.otherUser.displayName.toLowerCase().contains(
            lowerQuery,
          ) ||
          connection.otherUser.interesses.any(
            (interest) => interest.toLowerCase().contains(lowerQuery),
          );
    }).toList();
  }

  List<UnlockedConnection> filterByCompatibility(double minScore) {
    return state.connections
        .where((connection) => connection.compatibilityScore >= minScore)
        .toList();
  }

  List<UnlockedConnection> filterByStatus(ConnectionStatus status) {
    return state.connections
        .where((connection) => connection.status == status)
        .toList();
  }

  // ============== STATISTICS ==============
  Map<String, dynamic> getConnectionStats() {
    final connections = state.connections;

    return {
      'total': connections.length,
      'active': connections
          .where((c) => c.status == ConnectionStatus.active)
          .length,
      'unread': connections.where((c) => c.hasUnreadMessages).length,
      'recentlyActive': connections.where((c) => c.isRecentlyActive).length,
      'averageCompatibility': connections.isNotEmpty
          ? connections
                    .map((c) => c.compatibilityScore)
                    .reduce((a, b) => a + b) /
                connections.length
          : 0.0,
      'totalUnreadMessages': state.totalUnreadMessages,
    };
  }

  // ============== ERROR HANDLING ==============
  void _handleError(dynamic error) {
    final message = error.toString();
    state = state.copyWith(error: message, isLoading: false);

    NotificationService.showError('Erro nas conexões: $message');

    if (kDebugMode) {
      print('❌ UnlockedConnections Error: $error');
    }
  }

  // ============== DEBUGGING ==============
  void debugPrintState() {
    if (kDebugMode) {
      print('🐛 UnlockedConnections Debug:');
      print('  Total: ${state.connections.length}');
      print('  Unread: ${state.totalUnreadMessages}');
      print('  Loading: ${state.isLoading}');
      print('  Error: ${state.error}');
      print('  Last Updated: ${state.lastUpdated}');
    }
  }
}
