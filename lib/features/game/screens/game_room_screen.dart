import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:unlock/core/utils/extensions.dart';
import 'package:unlock/core/utils/logger.dart';
import 'package:unlock/features/game/models/question_model.dart';
import 'package:unlock/features/game/providers/game_room_provider.dart';
import 'package:unlock/models/game_room_model.dart';
import 'package:unlock/models/user_model.dart';
import 'package:unlock/providers/auth_provider.dart';
import 'package:unlock/shared/widgets/user_avatar.dart';

class GameRoomScreen extends ConsumerStatefulWidget {
  final String gameRoomId;

  // Total de itens que podem ser revelados (deve ser consistente com o provider)
  static const int totalRevealableItems = 3;

  const GameRoomScreen({super.key, required this.gameRoomId});

  @override
  ConsumerState<GameRoomScreen> createState() => _GameRoomScreenState();
}

class _GameRoomScreenState extends ConsumerState<GameRoomScreen> {
  final TextEditingController _answerController = TextEditingController();
  final ScrollController _chatScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // A lógica de aceitar/iniciar é agora manual
    });
  }

  @override
  void dispose() {
    _answerController.dispose();
    _chatScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currentUser = ref.watch(authProvider).user;

    if (currentUser == null) {
      return const Scaffold(
        body: Center(child: Text('Erro: Usuário não autenticado.')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sala de Jogo'),
        centerTitle: true,
        actions: [
          ref
              .watch(gameRoomStreamProvider(widget.gameRoomId))
              .when(
                data: (gameRoom) {
                  if (gameRoom.status == GameStatus.active) {
                    return IconButton(
                      icon: const Icon(Icons.flag_outlined),
                      tooltip: 'Abandonar Jogo',
                      onPressed: () {
                        ref
                            .read(gameLogicProvider(widget.gameRoomId).notifier)
                            .abandonGame();
                      },
                    );
                  }
                  return const SizedBox.shrink();
                },
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
              ),
        ],
      ),
      body: ref
          .watch(gameRoomStreamProvider(widget.gameRoomId))
          .when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, stack) => Center(child: Text('Erro: $err')),
            data: (gameRoom) {
              AppLogger.info(
                'GameRoomScreen: gameRoomStreamProvider data received. Status: ${gameRoom.status}',
              );
              return ref
                  .watch(gamePlayersProvider(widget.gameRoomId))
                  .when(
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (err, stack) =>
                        Center(child: Text('Erro ao carregar jogadores: $err')),
                    data: (players) {
                      final opponent = players.values.firstWhere(
                        (p) => p.uid != currentUser.uid,
                      );
                      final currentQuestion = gameRoom.questions.isNotEmpty
                          ? QuestionModel.fromJson(gameRoom.questions.last)
                          : null;

                      return Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Avatares e Barras de Progresso
                            _buildPlayerInfo(
                              context,
                              currentUser,
                              gameRoom,
                              theme,
                              false,
                            ),
                            const SizedBox(height: 16),
                            _buildPlayerInfo(
                              context,
                              opponent,
                              gameRoom,
                              theme,
                              true,
                            ),
                            const Divider(height: 32),

                            // Área do Quiz / Chat
                            Expanded(
                              child: _buildGameContent(
                                gameRoom,
                                currentQuestion,
                                currentUser.uid,
                                opponent,
                                theme,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  );
            },
          ),
    );
  }

  Widget _buildPlayerInfo(
    BuildContext context,
    UserModel player,
    GameRoomModel gameRoom,
    ThemeData theme,
    bool isOpponent,
  ) {
    final revealedItems = gameRoom.revealedInfo[player.uid]?.length ?? 0;
    final progress = (revealedItems / GameRoomScreen.totalRevealableItems)
        .clamp(0.0, 1.0);

    final revealedInfoForAvatar = isOpponent
        ? gameRoom.revealedInfo[player.uid]
        : null; // O usuário atual sempre vê sua própria foto

    return Row(
      children: [
        UserAvatar(
          user: player,
          size: 50,
          // ✅ CORREÇÃO: Sintaxe do operador ternário e cast corrigidos.
          photoUrlOverride: isOpponent
              ? (revealedInfoForAvatar?['photo_url'] as String?)
              : player.actualPhotoUrl, // Usuário atual sempre vê a própria foto
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                player.codinome ?? 'Misterioso',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: progress,
                backgroundColor: theme.colorScheme.surfaceVariant,
                color: theme.colorScheme.primary,
                minHeight: 10,
                borderRadius: BorderRadius.circular(5),
              ),
              const SizedBox(height: 4),
              Text(
                '${(progress * 100).toInt()}% Revelado',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
              // Informações reveladas
              if (revealedInfoForAvatar != null &&
                  revealedInfoForAvatar.isNotEmpty) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    // Safely check for photo_url
                    if (revealedInfoForAvatar['photo_url'] is String &&
                        (revealedInfoForAvatar['photo_url'] as String)
                            .isNotEmpty)
                      _RevealedInfoChip(
                        icon: Icons.photo_camera,
                        label: 'Foto',
                        theme: theme,
                      ),
                    // Safely check for favorite_bands
                    if (revealedInfoForAvatar['favorite_bands'] is List &&
                        (revealedInfoForAvatar['favorite_bands'] as List)
                            .isNotEmpty)
                      _RevealedInfoChip(
                        icon: Icons.music_note,
                        label: 'Música',
                        theme: theme,
                      ),
                    // Safely check for social_media
                    if (revealedInfoForAvatar['social_media'] is String &&
                        (revealedInfoForAvatar['social_media'] as String)
                            .isNotEmpty)
                      _RevealedInfoChip(
                        icon: Icons.link,
                        label: 'Social',
                        theme: theme,
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildGameContent(
    GameRoomModel gameRoom,
    QuestionModel? currentQuestion,
    String currentUserId,
    UserModel opponent,
    ThemeData theme,
  ) {
    // ✅ LOGGING APRIMORADO: Verifique estes logs no console!
    AppLogger.info(
      'GameRoomScreen: Building content for gameRoomId: ${gameRoom.id}',
    );
    AppLogger.info('GameRoomScreen: Current User ID: $currentUserId');
    AppLogger.info('GameRoomScreen: Game Status: ${gameRoom.status}');
    AppLogger.info('GameRoomScreen: Player IDs: ${gameRoom.playerIds}');
    AppLogger.info('GameRoomScreen: Opponent ID: ${opponent.uid}');
    AppLogger.info(
      'GameRoomScreen: Is current user the invitee? ${gameRoom.playerIds.last == currentUserId}',
    );
    // Lógica de status do jogo
    if (gameRoom.status == GameStatus.pending) {
      // Se o usuário atual é o convidado
      if (gameRoom.playerIds.last == currentUserId) {
        return _buildPendingInviteActions(theme);
      } else {
        // Se o usuário atual é o convidante
        AppLogger.info(
          'GameRoomScreen: Showing pending invite message for inviter.',
        );
        return _buildStatusMessage(
          icon: Icons.hourglass_empty,
          title: 'Convite Enviado',
          message:
              'Aguardando ${opponent.codinome?.capitalize() ?? 'o outro jogador'} aceitar o convite...',
          theme: theme,
        );
      }
    }

    // Se o jogo terminou, mostrar tela de finalização e chat
    if (gameRoom.status == GameStatus.finished) {
      return _buildGameFinished(gameRoom, currentUserId, theme);
    }

    // Outros status de término
    if (gameRoom.status == GameStatus.declined) {
      return _buildStatusMessage(
        icon: Icons.person_remove_alt_1_outlined,
        title: 'Convite Recusado',
        message:
            '${opponent.codinome?.capitalize() ?? 'O outro jogador'} não aceitou o convite.',
        theme: theme,
      );
    }

    if (gameRoom.status == GameStatus.abandoned) {
      return _buildStatusMessage(
        icon: Icons.flag_outlined,
        title: 'Jogo Abandonado',
        message:
            '${opponent.codinome?.capitalize() ?? 'O outro jogador'} deixou o jogo.',
        theme: theme,
      );
    }

    if (gameRoom.status == GameStatus.expired) {
      return _buildStatusMessage(
        icon: Icons.timer_off_outlined,
        title: 'Convite Expirado',
        message: 'Este convite não é mais válido.',
        theme: theme,
      );
    }

    // Jogo ativo
    if (currentQuestion == null) {
      // This block is reached if gameRoom.status is active, but no question is set.
      // This implies _selectNextQuestion() either failed or found no questions.
      AppLogger.warning(
        'GameRoomScreen: Game is active but currentQuestion is null. '
        'This might indicate an issue with question selection or empty question data.',
      );
      return Center(
        child: Text(
          'Preparando a primeira pergunta...', // Mensagem mais específica
          style: theme.textTheme.headlineSmall,
        ),
      );
    }

    return _buildActiveGame(gameRoom, currentQuestion, currentUserId, theme);
  }

  Widget _buildActiveGame(
    GameRoomModel gameRoom,
    QuestionModel currentQuestion,
    String currentUserId,
    ThemeData theme,
  ) {
    return Column(
      children: [
        // Pergunta atual
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Pergunta:',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  currentQuestion.text,
                  style: theme.textTheme.headlineSmall,
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),

        // Input de Resposta ou Mensagem de Espera
        if (gameRoom.currentTurnPlayerId == currentUserId)
          _buildAnswerInput(currentQuestion, theme)
        else
          Center(
            child:
                Text(
                      'Aguardando a resposta do outro jogador...',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontStyle: FontStyle.italic,
                      ),
                    )
                    .animate(onPlay: (c) => c.repeat(reverse: true))
                    .fade(duration: 1500.ms, curve: Curves.easeInOut),
          ),
      ],
    );
  }

  Widget _buildAnswerInput(QuestionModel question, ThemeData theme) {
    if (question.type == 'multiple_choice' && question.options.isNotEmpty) {
      return Column(
        children: question.options.map((option) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4.0),
            child: SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => _submitAnswer(option),
                child: Text(option),
              ),
            ),
          );
        }).toList(),
      );
    }

    // Default to text input
    return Padding(
      padding: const EdgeInsets.only(top: 16.0, bottom: 8.0),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _answerController,
              decoration: const InputDecoration(labelText: 'Sua resposta'),
              onSubmitted: (_) => _submitAnswer(_answerController.text),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.send),
            onPressed: () => _submitAnswer(_answerController.text),
            color: theme.colorScheme.primary,
          ),
        ],
      ),
    );
  }

  void _submitAnswer(String answer) {
    if (answer.trim().isEmpty) return;
    ref
        .read(gameLogicProvider(widget.gameRoomId).notifier)
        .submitAnswer(answer);
    _answerController.clear();
  }

  Widget _buildChatArea(
    GameRoomModel gameRoom,
    String currentUserId,
    ThemeData theme,
  ) {
    return _buildChat(currentUserId, theme);
  }

  Widget _buildGameFinished(
    GameRoomModel gameRoom,
    String currentUserId,
    ThemeData theme,
  ) {
    return Column(
      children: [
        _buildStatusMessage(
          icon: Icons.celebration_rounded,
          title: 'Conexão Formada!',
          message:
              'Vocês se revelaram completamente. Quebre o gelo e mande a primeira mensagem!',
          theme: theme,
        ).animate().scale(
          delay: 200.ms,
          duration: 500.ms,
          curve: Curves.elasticOut,
        ),
        const Divider(height: 32),
        Expanded(child: _buildChat(currentUserId, theme)),
      ],
    );
  }

  Widget _buildChat(String currentUserId, ThemeData theme) {
    // Reutiliza o controller de resposta para o chat
    final chatController = _answerController;

    void sendChatMessage() {
      if (chatController.text.trim().isEmpty) return;
      ref
          .read(gameLogicProvider(widget.gameRoomId).notifier)
          .sendMessage(chatController.text);
      chatController.clear();
    }

    final messagesAsync = ref.watch(
      gameMessagesStreamProvider(widget.gameRoomId),
    );

    // Scroll to bottom when new messages arrive
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_chatScrollController.hasClients) {
        _chatScrollController.animateTo(
          _chatScrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });

    return Column(
      children: [
        Expanded(
          child: messagesAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, stack) =>
                Center(child: Text('Erro ao carregar chat: $err')),
            data: (messages) {
              if (messages.isEmpty) {
                // A mensagem de "Conexão Formada" já é mostrada acima.
                return const Center(
                  child: Text('Seja o primeiro a dizer olá!'),
                );
              }
              return ListView.builder(
                controller: _chatScrollController,
                itemCount: messages.length,
                itemBuilder: (context, index) {
                  final message = messages[index];
                  final isMe = message.senderId == currentUserId;
                  return Align(
                    alignment: isMe
                        ? Alignment.centerRight
                        : Alignment.centerLeft,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      margin: const EdgeInsets.symmetric(
                        vertical: 4,
                        horizontal: 8,
                      ),
                      decoration: BoxDecoration(
                        color: isMe
                            ? theme.colorScheme.primary
                            : theme.colorScheme.surfaceVariant,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        message.content,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: isMe
                              ? theme.colorScheme.onPrimary
                              : theme.colorScheme.onSurface,
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: TextField(
            controller: chatController,
            decoration: InputDecoration(
              hintText: 'Digite sua mensagem...',
              suffixIcon: IconButton(
                icon: const Icon(Icons.send),
                onPressed: sendChatMessage,
              ),
            ),
            onSubmitted: (_) => sendChatMessage(),
          ),
        ),
      ],
    );
  }

  Widget _buildPendingInviteActions(ThemeData theme) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.mail_outline, size: 80),
        const SizedBox(height: 16),
        Text(
          'Você recebeu um convite para jogar!',
          style: theme.textTheme.headlineSmall,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            OutlinedButton(
              onPressed: () => ref
                  .read(gameLogicProvider(widget.gameRoomId).notifier)
                  .declineInvite(),
              child: const Text('Recusar'),
              style: OutlinedButton.styleFrom(
                foregroundColor: theme.colorScheme.error,
              ),
            ),
            const SizedBox(width: 16),
            ElevatedButton(
              onPressed: () => ref
                  .read(gameLogicProvider(widget.gameRoomId).notifier)
                  .acceptInvite(),
              child: const Text('Aceitar'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatusMessage({
    required IconData icon,
    required String title,
    required String message,
    required ThemeData theme,
  }) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 80,
            color: theme.colorScheme.onSurface.withOpacity(0.5),
          ),
          const SizedBox(height: 24),
          Text(
            title,
            style: theme.textTheme.headlineSmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: theme.textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _RevealedInfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final ThemeData theme;

  const _RevealedInfoChip({
    required this.icon,
    required this.label,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: Icon(icon, size: 16, color: theme.colorScheme.secondary),
      label: Text(label),
      backgroundColor: theme.colorScheme.secondary.withOpacity(0.1),
      labelStyle: TextStyle(
        color: theme.colorScheme.secondary,
        fontWeight: FontWeight.w600,
      ),
      side: BorderSide.none,
      padding: const EdgeInsets.symmetric(horizontal: 8),
    );
  }
}
