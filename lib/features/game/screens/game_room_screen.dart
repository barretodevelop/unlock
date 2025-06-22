import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:unlock/features/game/models/question_model.dart';
import 'package:unlock/features/game/providers/game_room_provider.dart';
import 'package:unlock/models/game_room_model.dart';
import 'package:unlock/models/user_model.dart';
import 'package:unlock/onboarding/constants/onboarding_data.dart';
import 'package:unlock/providers/auth_provider.dart';
import 'package:unlock/shared/widgets/user_avatar.dart';

class GameRoomScreen extends ConsumerStatefulWidget {
  final String gameRoomId;

  const GameRoomScreen({super.key, required this.gameRoomId});

  @override
  ConsumerState<GameRoomScreen> createState() => _GameRoomScreenState();
}

class _GameRoomScreenState extends ConsumerState<GameRoomScreen> {
  final TextEditingController _answerController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Iniciar o jogo assim que a tela for carregada, se ainda estiver pendente
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(gameLogicProvider(widget.gameRoomId).notifier).startGame();
    });
  }

  @override
  void dispose() {
    _answerController.dispose();
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
      appBar: AppBar(title: const Text('Sala de Jogo'), centerTitle: true),
      body: ref
          .watch(gameRoomStreamProvider(widget.gameRoomId))
          .when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, stack) => Center(child: Text('Erro: $err')),
            data: (gameRoom) {
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
                          children: [
                            // Avatares e Barras de Progresso
                            _buildPlayerInfo(
                              currentUser,
                              gameRoom.progress[currentUser.uid] ?? 0.0,
                              theme,
                            ),
                            const SizedBox(height: 16),
                            _buildPlayerInfo(
                              opponent,
                              gameRoom.progress[opponent.uid] ?? 0.0,
                              theme,
                            ),
                            const Divider(height: 32),

                            // Área do Quiz
                            Expanded(
                              child: _buildQuizArea(
                                gameRoom,
                                currentQuestion,
                                currentUser.uid,
                                theme,
                              ),
                            ),

                            // Input de Resposta
                            if (gameRoom.status == GameStatus.active &&
                                gameRoom.currentTurnPlayerId ==
                                    currentUser.uid &&
                                currentQuestion != null)
                              _buildAnswerInput(currentQuestion, theme),
                          ],
                        ),
                      );
                    },
                  );
            },
          ),
    );
  }

  Widget _buildPlayerInfo(UserModel player, double progress, ThemeData theme) {
    final avatar = OnboardingConstants.freeAvatars.firstWhere(
      (a) => a.id == player.avatarId,
      orElse: () => OnboardingConstants.freeAvatars.first,
    );

    return Row(
      children: [
        UserAvatar(user: player, size: 50),
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
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildQuizArea(
    GameRoomModel gameRoom,
    QuestionModel? currentQuestion,
    String currentUserId,
    ThemeData theme,
  ) {
    if (gameRoom.status == GameStatus.pending) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.hourglass_empty,
              size: 80,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(height: 24),
            Text(
              'Aguardando o outro jogador aceitar o convite...',
              style: theme.textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    if (gameRoom.status == GameStatus.finished) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.celebration,
              size: 80,
              color: theme.colorScheme.secondary,
            ),
            const SizedBox(height: 24),
            Text(
              'Conexão Formada!',
              style: theme.textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Vocês se revelaram completamente um ao outro!',
              style: theme.textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
            // TODO: Botão para ir para o chat
          ],
        ),
      );
    }

    if (currentQuestion == null) {
      return Center(
        child: Text(
          'Carregando perguntas...',
          style: theme.textTheme.headlineSmall,
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Pergunta:',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(currentQuestion.text, style: theme.textTheme.headlineSmall),
        const SizedBox(height: 16),
        // TODO: Exibir respostas anteriores se for o turno do outro jogador
        if (gameRoom.currentTurnPlayerId != currentUserId)
          Center(
            child: Text(
              'Aguardando a resposta do outro jogador...',
              style: theme.textTheme.bodyLarge?.copyWith(
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildAnswerInput(QuestionModel question, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(top: 16.0),
      child: TextField(
        controller: _answerController,
        decoration: InputDecoration(
          labelText: 'Sua resposta',
          suffixIcon: IconButton(
            icon: const Icon(Icons.send),
            onPressed: () {
              ref // Corrected: Access notifier for submitAnswer
                  .read(gameLogicProvider(widget.gameRoomId).notifier)
                  .submitAnswer(_answerController.text);
              _answerController.clear();
            },
          ),
        ),
        onSubmitted: (value) {
          ref
              .read(gameLogicProvider(widget.gameRoomId).notifier)
              .submitAnswer(
                value,
              ); // Corrected: Access notifier for submitAnswer
          _answerController.clear();
        },
      ),
    );
  }
}
