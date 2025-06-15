import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:unlock/screens/social/other_user_profile_screen.dart';
import 'package:unlock/utils/helpers.dart';

class ChatScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic> connectionData;
  final bool isRealConnection;

  const ChatScreen({
    super.key,
    required this.connectionData,
    this.isRealConnection = false,
  });

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen>
    with TickerProviderStateMixin {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  late AnimationController _messageController2;

  List<Map<String, dynamic>> _messages = [];
  bool _isTyping = false;
  bool _isOnline = true;

  @override
  void initState() {
    super.initState();

    _messageController2 = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _initializeChat();
  }

  void _initializeChat() {
    // Mensagens iniciais baseadas no tipo de conexão
    if (widget.isRealConnection) {
      _messages = [
        {
          'sender': 'other',
          'message': 'Olá! Que legal que conseguimos nos conectar! 😊',
          'timestamp': DateTime.now().subtract(const Duration(minutes: 5)),
          'type': 'text',
        },
        {
          'sender': 'other',
          'message': 'Vi que temos vários interesses em comum!',
          'timestamp': DateTime.now().subtract(const Duration(minutes: 4)),
          'type': 'text',
        },
      ];
    } else {
      _messages = [
        {
          'sender': 'other',
          'message': 'Oi! Como você está?',
          'timestamp': DateTime.now().subtract(const Duration(hours: 1)),
          'type': 'text',
        },
      ];
    }

    // Simula status online
    _isOnline = widget.connectionData['status'] == 'Online';
  }

  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isNotEmpty) {
      setState(() {
        _messages.add({
          'sender': 'me',
          'message': text,
          'timestamp': DateTime.now(),
          'type': 'text',
        });
      });

      _messageController.clear();
      _scrollToBottom();
      _simulateTyping();

      // Atualiza estatísticas
      // currentUser.updateStats(messages: 1);
      // currentUser.updateMissionProgress('m1', 1);
    }
  }

  void _simulateTyping() async {
    await Future.delayed(const Duration(milliseconds: 500));

    if (mounted) {
      setState(() {
        _isTyping = true;
      });

      await Future.delayed(const Duration(seconds: 2));

      if (mounted) {
        setState(() {
          _isTyping = false;
          _messages.add({
            'sender': 'other',
            'message': _generateReply(),
            'timestamp': DateTime.now(),
            'type': 'text',
          });
        });
        _scrollToBottom();
      }
    }
  }

  String _generateReply() {
    final replies = [
      'Que interessante! Conte-me mais sobre isso.',
      'Concordo totalmente! 😄',
      'Nossa, que legal! Nunca tinha pensado nisso.',
      'Hahaha adorei! Você é muito engraçado(a).',
      'Verdade! Também penso assim.',
      'Que experiência incrível!',
      'Adoraria saber mais sobre seus hobbies.',
    ];

    return replies[DateTime.now().millisecond % replies.length];
  }

  void _scrollToBottom() {
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

  void _showReactionPicker(int messageIndex) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Reagir à mensagem',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildReactionButton(
                    '👍',
                    () => _addReaction(messageIndex, '👍'),
                  ),
                  _buildReactionButton(
                    '❤️',
                    () => _addReaction(messageIndex, '❤️'),
                  ),
                  _buildReactionButton(
                    '😂',
                    () => _addReaction(messageIndex, '😂'),
                  ),
                  _buildReactionButton(
                    '😮',
                    () => _addReaction(messageIndex, '😮'),
                  ),
                  _buildReactionButton(
                    '😢',
                    () => _addReaction(messageIndex, '😢'),
                  ),
                  _buildReactionButton(
                    '😡',
                    () => _addReaction(messageIndex, '😡'),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildReactionButton(String emoji, VoidCallback onTap) {
    return GestureDetector(
      onTap: () {
        onTap();
        Navigator.pop(context);
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          shape: BoxShape.circle,
        ),
        child: Text(emoji, style: const TextStyle(fontSize: 24)),
      ),
    );
  }

  void _addReaction(int messageIndex, String reaction) {
    setState(() {
      _messages[messageIndex]['reaction'] = reaction;
    });

    // currentUser.updateMissionProgress('m5', 1);

    AppHelpers.showCustomSnackBar(
      context,
      'Reação adicionada!',
      icon: Icons.emoji_emotions,
    );
  }

  void _startMiniGame() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _buildMiniGameDialog(),
    );
  }

  Widget _buildMiniGameDialog() {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.videogame_asset, size: 64, color: Colors.purple),
          const SizedBox(height: 16),
          const Text(
            'Mini-Jogo: Adivinhação!',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Escolha um número de 1 a 3:',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [1, 2, 3].map((number) {
              return ElevatedButton(
                onPressed: () => _playMiniGame(number),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple,
                  foregroundColor: Colors.white,
                  shape: const CircleBorder(),
                  padding: const EdgeInsets.all(16),
                ),
                child: Text(
                  number.toString(),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  void _playMiniGame(int chosenNumber) {
    Navigator.pop(context);

    final winningNumber = math.Random().nextInt(3) + 1;
    final won = chosenNumber == winningNumber;
    final reward = won ? 15 : 5;

    // currentUser.updateResources(moedas: reward);
    // currentUser.updateMissionProgress('m2', 1);

    setState(() {
      _messages.add({
        'sender': 'system',
        'message': won
            ? '🎉 Você ganhou! O número era $winningNumber. +$reward moedas!'
            : '😅 Que pena! O número era $winningNumber. +$reward moedas pela tentativa.',
        'timestamp': DateTime.now(),
        'type': 'system',
      });
    });

    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Stack(
              children: [
                AppHelpers.buildUserAvatar(
                  avatarId: widget.connectionData['avatarId'],
                  borderId: widget.connectionData['borderId'],
                  radius: 20,
                ),
                if (_isOnline)
                  Positioned(
                    right: 0,
                    bottom: 0,
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
                    widget.connectionData['nome'] as String,
                    style: const TextStyle(fontSize: 16),
                  ),
                  Text(
                    _isTyping
                        ? 'digitando...'
                        : (widget.connectionData['status'] as String),
                    style: TextStyle(
                      fontSize: 12,
                      color: _isTyping ? Colors.green : Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => OtherUserProfileScreen(
                    connectionData: widget.connectionData,
                  ),
                ),
              );
            },
            icon: const Icon(Icons.info_outline),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length + (_isTyping ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == _messages.length && _isTyping) {
                  return _buildTypingIndicator();
                }

                final message = _messages[index];
                return _buildMessageBubble(message, index);
              },
            ),
          ),
          _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(Map<String, dynamic> message, int index) {
    final isMe = message['sender'] == 'me';
    final isSystem = message['sender'] == 'system';
    final reaction = message['reaction'] as String?;

    if (isSystem) {
      return Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Text(
              message['message'] as String,
              style: TextStyle(
                fontSize: 14,
                color: Colors.blue.shade700,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: isMe
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onLongPress: () => _showReactionPicker(index),
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.7,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isMe
                    ? Theme.of(context).primaryColor
                    : Colors.grey.shade200,
                borderRadius: BorderRadius.circular(20).copyWith(
                  bottomLeft: isMe
                      ? const Radius.circular(20)
                      : const Radius.circular(4),
                  bottomRight: isMe
                      ? const Radius.circular(4)
                      : const Radius.circular(20),
                ),
              ),
              child: Text(
                message['message'] as String,
                style: TextStyle(
                  fontSize: 16,
                  color: isMe ? Colors.white : Colors.black87,
                ),
              ),
            ),
          ),
          if (reaction != null)
            Padding(
              padding: EdgeInsets.only(
                top: 4,
                left: isMe ? 0 : 8,
                right: isMe ? 8 : 0,
              ),
              child: Text(reaction, style: const TextStyle(fontSize: 16)),
            ),
          Padding(
            padding: EdgeInsets.only(
              top: 4,
              left: isMe ? 0 : 8,
              right: isMe ? 8 : 0,
            ),
            child: Text(
              AppHelpers.formatRelativeTime(
                (message['timestamp'] as DateTime).toString(),
              ),
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          AppHelpers.buildUserAvatar(
            avatarId: widget.connectionData['avatarId'],
            radius: 12,
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildDot(0),
                const SizedBox(width: 4),
                _buildDot(1),
                const SizedBox(width: 4),
                _buildDot(2),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDot(int index) {
    return AnimatedBuilder(
      animation: _messageController2,
      builder: (context, child) {
        final delay = index * 0.2;
        final value = ((_messageController2.value - delay) % 1.0).clamp(
          0.0,
          1.0,
        );
        final opacity = (math.sin(value * math.pi)).clamp(0.3, 1.0);

        return Opacity(
          opacity: opacity,
          child: Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: Colors.grey,
              shape: BoxShape.circle,
            ),
          ),
        );
      },
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        boxShadow: [
          BoxShadow(
            offset: const Offset(0, -2),
            blurRadius: 4,
            color: Colors.black.withOpacity(0.1),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            // Botão de mini-jogo
            Container(
              decoration: BoxDecoration(
                color: Colors.purple.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                onPressed: _startMiniGame,
                icon: const Icon(Icons.videogame_asset, color: Colors.purple),
                tooltip: 'Jogar mini-jogo',
              ),
            ),
            const SizedBox(width: 8),

            // Campo de texto
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(25),
                ),
                child: TextField(
                  controller: _messageController,
                  decoration: const InputDecoration(
                    hintText: 'Digite sua mensagem...',
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                  ),
                  maxLines: null,
                  textCapitalization: TextCapitalization.sentences,
                  onSubmitted: (_) => _sendMessage(),
                ),
              ),
            ),
            const SizedBox(width: 8),

            // Botão de enviar
            Container(
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
                shape: BoxShape.circle,
              ),
              child: IconButton(
                onPressed: _sendMessage,
                icon: const Icon(Icons.send, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _messageController2.dispose();
    super.dispose();
  }
}
