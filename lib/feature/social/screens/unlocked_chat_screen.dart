// lib/feature/games/social/screens/unlocked_chat_screen.dart
import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:unlock/models/user_model.dart';
import 'package:unlock/providers/auth_provider.dart';
import 'package:unlock/widgtes/animated_button.dart';
import 'package:unlock/widgtes/custom_card.dart';

// ============== MODELS ==============
class ChatMessage {
  final String id;
  final String senderId;
  final String receiverId;
  final String text;
  final DateTime timestamp;
  final bool isRead;
  final MessageType type;

  const ChatMessage({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.text,
    required this.timestamp,
    this.isRead = false,
    this.type = MessageType.text,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'senderId': senderId,
    'receiverId': receiverId,
    'text': text,
    'timestamp': timestamp.toIso8601String(),
    'isRead': isRead,
    'type': type.name,
  };

  factory ChatMessage.fromJson(Map<String, dynamic> json) => ChatMessage(
    id: json['id'] ?? '',
    senderId: json['senderId'] ?? '',
    receiverId: json['receiverId'] ?? '',
    text: json['text'] ?? '',
    timestamp: DateTime.tryParse(json['timestamp'] ?? '') ?? DateTime.now(),
    isRead: json['isRead'] ?? false,
    type: MessageType.values.firstWhere(
      (t) => t.name == json['type'],
      orElse: () => MessageType.text,
    ),
  );
}

enum MessageType { text, emoji, system }

// ============== CHAT PROVIDER ==============
final chatProvider =
    StateNotifierProvider.family<ChatNotifier, ChatState, String>(
      (ref, connectionId) => ChatNotifier(ref, connectionId),
    );

class ChatState {
  final List<ChatMessage> messages;
  final bool isLoading;
  final bool isSending;
  final String? error;
  final bool isTyping;
  final DateTime? lastSeen;

  const ChatState({
    this.messages = const [],
    this.isLoading = false,
    this.isSending = false,
    this.error,
    this.isTyping = false,
    this.lastSeen,
  });

  ChatState copyWith({
    List<ChatMessage>? messages,
    bool? isLoading,
    bool? isSending,
    String? error,
    bool? isTyping,
    DateTime? lastSeen,
  }) => ChatState(
    messages: messages ?? this.messages,
    isLoading: isLoading ?? this.isLoading,
    isSending: isSending ?? this.isSending,
    error: error,
    isTyping: isTyping ?? this.isTyping,
    lastSeen: lastSeen ?? this.lastSeen,
  );
}

class ChatNotifier extends StateNotifier<ChatState> {
  final Ref _ref;
  final String _connectionId;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  StreamSubscription<QuerySnapshot>? _messagesSubscription;
  StreamSubscription<DocumentSnapshot>? _presenceSubscription;
  Timer? _typingTimer;

  ChatNotifier(this._ref, this._connectionId) : super(const ChatState()) {
    _loadMessages();
    _listenToPresence();
  }

  @override
  void dispose() {
    _messagesSubscription?.cancel();
    _presenceSubscription?.cancel();
    _typingTimer?.cancel();
    super.dispose();
  }

  void _loadMessages() {
    state = state.copyWith(isLoading: true);

    _messagesSubscription = _db
        .collection('chats')
        .doc(_connectionId)
        .collection('messages')
        .orderBy('timestamp', descending: false)
        .limit(100)
        .snapshots()
        .listen(
          (snapshot) {
            final messages = snapshot.docs
                .map(
                  (doc) => ChatMessage.fromJson({'id': doc.id, ...doc.data()}),
                )
                .toList();

            state = state.copyWith(
              messages: messages,
              isLoading: false,
              error: null,
            );

            _markMessagesAsRead();
          },
          onError: (error) {
            state = state.copyWith(
              error: 'Erro ao carregar mensagens: $error',
              isLoading: false,
            );
          },
        );
  }

  void _listenToPresence() {
    _presenceSubscription = _db
        .collection('user_presence')
        .doc(_getOtherUserId())
        .snapshots()
        .listen((snapshot) {
          if (snapshot.exists) {
            final data = snapshot.data()!;
            state = state.copyWith(
              isTyping: data['isTyping'] ?? false,
              lastSeen: DateTime.tryParse(data['lastSeen'] ?? ''),
            );
          }
        });
  }

  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    final currentUser = _ref.read(authProvider).user;
    if (currentUser == null) return;

    state = state.copyWith(isSending: true);

    try {
      final messageRef = _db
          .collection('chats')
          .doc(_connectionId)
          .collection('messages')
          .doc();

      final message = ChatMessage(
        id: messageRef.id,
        senderId: currentUser.uid,
        receiverId: _getOtherUserId(),
        text: text.trim(),
        timestamp: DateTime.now(),
      );

      await messageRef.set(message.toJson());

      // Atualizar última atividade do chat
      await _db.collection('chats').doc(_connectionId).update({
        'lastMessage': message.toJson(),
        'lastActivity': FieldValue.serverTimestamp(),
      });

      state = state.copyWith(isSending: false);
    } catch (e) {
      state = state.copyWith(
        error: 'Erro ao enviar mensagem: $e',
        isSending: false,
      );
    }
  }

  void _markMessagesAsRead() async {
    final currentUser = _ref.read(authProvider).user;
    if (currentUser == null) return;

    final unreadMessages = state.messages
        .where((msg) => msg.receiverId == currentUser.uid && !msg.isRead)
        .toList();

    if (unreadMessages.isEmpty) return;

    final batch = _db.batch();
    for (final message in unreadMessages) {
      final messageRef = _db
          .collection('chats')
          .doc(_connectionId)
          .collection('messages')
          .doc(message.id);
      batch.update(messageRef, {'isRead': true});
    }

    try {
      await batch.commit();
    } catch (e) {
      // Log error silently
    }
  }

  String _getOtherUserId() {
    // Implementar lógica para obter o ID do outro usuário na conexão
    // Por agora, retornar placeholder
    return 'other_user_id';
  }

  void setTyping(bool isTyping) async {
    final currentUser = _ref.read(authProvider).user;
    if (currentUser == null) return;

    try {
      await _db.collection('user_presence').doc(currentUser.uid).set({
        'isTyping': isTyping,
        'lastSeen': DateTime.now().toIso8601String(),
      }, SetOptions(merge: true));

      if (isTyping) {
        _typingTimer?.cancel();
        _typingTimer = Timer(const Duration(seconds: 3), () {
          setTyping(false);
        });
      }
    } catch (e) {
      // Handle error silently
    }
  }
}

// ============== CHAT SCREEN ==============
class UnlockedChatScreen extends ConsumerStatefulWidget {
  final String connectionId;
  final UserModel otherUser;
  final double compatibilityScore;

  const UnlockedChatScreen({
    super.key,
    required this.connectionId,
    required this.otherUser,
    required this.compatibilityScore,
  });

  @override
  ConsumerState<UnlockedChatScreen> createState() => _UnlockedChatScreenState();
}

class _UnlockedChatScreenState extends ConsumerState<UnlockedChatScreen>
    with TickerProviderStateMixin {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _messageFocus = FocusNode();

  late AnimationController _slideController;
  late AnimationController _floatController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _floatAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _messageController.addListener(_onTyping);
  }

  void _initializeAnimations() {
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _floatController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOut));

    _floatAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOut),
    );

    _slideController.forward();
    _floatController.repeat(reverse: true);
  }

  void _onTyping() {
    final chatNotifier = ref.read(chatProvider(widget.connectionId).notifier);
    final isTyping = _messageController.text.isNotEmpty;
    chatNotifier.setTyping(isTyping);
  }

  @override
  void dispose() {
    _slideController.dispose();
    _floatController.dispose();
    _messageController.dispose();
    _scrollController.dispose();
    _messageFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final chatState = ref.watch(chatProvider(widget.connectionId));
    final currentUser = ref.watch(authProvider).user;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: _buildAppBar(chatState),
      body: Column(
        children: [
          _buildConnectionBanner(),
          Expanded(child: _buildMessagesList(chatState, currentUser)),
          _buildTypingIndicator(chatState),
          _buildMessageInput(chatState),
        ],
      ),
    );
  }

  // ============== APP BAR ==============
  PreferredSizeWidget _buildAppBar(ChatState chatState) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      shadowColor: Colors.black12,
      leading: Container(
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
        ),
        child: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => context.pop(),
        ),
      ),
      title: Row(
        children: [
          Stack(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: Colors.blue[100],
                child: Text(
                  widget.otherUser.displayName.isNotEmpty
                      ? widget.otherUser.displayName[0].toUpperCase()
                      : '?',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[700],
                  ),
                ),
              ),
              if (chatState.lastSeen != null &&
                  DateTime.now().difference(chatState.lastSeen!).inMinutes < 5)
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.otherUser.displayName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  _getStatusText(chatState),
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.blue[50],
            borderRadius: BorderRadius.circular(12),
          ),
          child: IconButton(
            icon: Icon(Icons.info_outline, color: Colors.blue[700]),
            onPressed: _showConnectionInfo,
          ),
        ),
      ],
    );
  }

  String _getStatusText(ChatState chatState) {
    if (chatState.isTyping) {
      return 'digitando...';
    }

    if (chatState.lastSeen != null) {
      final difference = DateTime.now().difference(chatState.lastSeen!);
      if (difference.inMinutes < 5) {
        return 'online';
      } else if (difference.inHours < 1) {
        return 'visto há ${difference.inMinutes}min';
      } else if (difference.inDays < 1) {
        return 'visto há ${difference.inHours}h';
      }
    }

    return 'visto recentemente';
  }

  // ============== CONNECTION BANNER ==============
  Widget _buildConnectionBanner() {
    return SlideTransition(
      position: _slideAnimation,
      child: Container(
        margin: const EdgeInsets.all(16),
        child: CustomCard(
          padding: const EdgeInsets.all(16),
          borderRadius: 0,
          child: Row(
            children: [
              AnimatedBuilder(
                animation: _floatAnimation,
                builder: (context, child) {
                  return Transform.translate(
                    offset: Offset(0, _floatAnimation.value * 2),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.green[100],
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.favorite,
                        color: Colors.green[600],
                        size: 20,
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '🎉 Conexão Desbloqueada!',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Compatibilidade: ${widget.compatibilityScore.toStringAsFixed(1)}%',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============== MESSAGES LIST ==============
  Widget _buildMessagesList(ChatState chatState, UserModel? currentUser) {
    if (chatState.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (chatState.messages.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: chatState.messages.length,
      itemBuilder: (context, index) {
        final message = chatState.messages[index];
        final isMe = message.senderId == currentUser?.uid;
        final showAvatar =
            index == 0 ||
            chatState.messages[index - 1].senderId != message.senderId;

        return _buildMessageBubble(message, isMe, showAvatar);
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.chat_bubble_outline, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          const Text(
            'Início da conversa',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Envie a primeira mensagem para\ncomeçar a conversa!',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message, bool isMe, bool showAvatar) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: isMe
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe && showAvatar) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: Colors.blue[100],
              child: Text(
                widget.otherUser.displayName.isNotEmpty
                    ? widget.otherUser.displayName[0].toUpperCase()
                    : '?',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue[700],
                ),
              ),
            ),
            const SizedBox(width: 8),
          ] else if (!isMe) ...[
            const SizedBox(width: 40),
          ],

          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.7,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isMe ? Colors.blue[600] : Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message.text,
                    style: TextStyle(
                      color: isMe ? Colors.white : Colors.grey[800],
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatMessageTime(message.timestamp),
                    style: TextStyle(
                      color: isMe
                          ? Colors.white.withOpacity(0.7)
                          : Colors.grey[500],
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
          ),

          if (isMe) ...[
            const SizedBox(width: 8),
            Icon(
              message.isRead ? Icons.done_all : Icons.done,
              size: 16,
              color: message.isRead ? Colors.blue[600] : Colors.grey[400],
            ),
          ],
        ],
      ),
    );
  }

  String _formatMessageTime(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays > 0) {
      return '${difference.inDays}d';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}min';
    } else {
      return 'agora';
    }
  }

  // ============== TYPING INDICATOR ==============
  Widget _buildTypingIndicator(ChatState chatState) {
    if (!chatState.isTyping) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          const SizedBox(width: 40),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildTypingDot(0),
                const SizedBox(width: 4),
                _buildTypingDot(1),
                const SizedBox(width: 4),
                _buildTypingDot(2),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypingDot(int index) {
    return AnimatedBuilder(
      animation: _floatController,
      builder: (context, child) {
        final delay = index * 0.3;
        final animationValue = (_floatController.value + delay) % 1.0;
        final opacity = (animationValue < 0.5)
            ? animationValue * 2
            : (1 - animationValue) * 2;

        return Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            color: Colors.grey.withOpacity(0.3 + opacity * 0.4),
            shape: BoxShape.circle,
          ),
        );
      },
    );
  }

  // ============== MESSAGE INPUT ==============
  Widget _buildMessageInput(ChatState chatState) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(24),
              ),
              child: TextField(
                controller: _messageController,
                focusNode: _messageFocus,
                maxLines: null,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  hintText: 'Escreva uma mensagem...',
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                ),
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
          ),
          const SizedBox(width: 12),
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 48,
            height: 48,
            child: AnimatedButton(
              onPressed: chatState.isSending ? null : _sendMessage,
              backgroundColor: _messageController.text.trim().isNotEmpty
                  ? Colors.blue[600]!
                  : Colors.grey[300]!,
              foregroundColor: Colors.white,
              padding: EdgeInsets.zero,
              // borderRadius: 24,
              child: chatState.isSending
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Icon(Icons.send, size: 20),
            ),
          ),
        ],
      ),
    );
  }

  // ============== ACTIONS ==============
  void _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    _messageController.clear();
    FocusScope.of(context).unfocus();

    HapticFeedback.lightImpact();

    await ref
        .read(chatProvider(widget.connectionId).notifier)
        .sendMessage(text);

    // Auto scroll to bottom
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _showConnectionInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Informações da Conexão'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: Colors.blue[100],
                  child: Text(
                    widget.otherUser.displayName.isNotEmpty
                        ? widget.otherUser.displayName[0].toUpperCase()
                        : '?',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.blue[700],
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.otherUser.displayName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Compatibilidade: ${widget.compatibilityScore.toStringAsFixed(1)}%',
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Text(
              'Interesses em comum:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: widget.otherUser.interesses.map((interest) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.blue[100],
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    interest,
                    style: TextStyle(fontSize: 12, color: Colors.blue[700]),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Fechar'),
          ),
        ],
      ),
    );
  }
}
