import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:unlock/core/utils/logger.dart';
import 'package:unlock/features/game/data/questions_data.dart';
import 'package:unlock/features/game/models/question_model.dart';
import 'package:unlock/features/matchmaking/providers/matchmaking_provider.dart';
import 'package:unlock/models/game_room_model.dart';
import 'package:unlock/models/message_model.dart';
import 'package:unlock/models/user_model.dart';
import 'package:unlock/providers/auth_provider.dart';
import 'package:unlock/services/firestore_service.dart';
import 'package:unlock/services/game_service.dart';

// Provedor para o FirestoreService
final firestoreServiceProvider = Provider((ref) => FirestoreService());

// StreamProvider para a sala de jogo atual
final gameRoomStreamProvider = StreamProvider.family<GameRoomModel, String>((
  ref,
  gameRoomId,
) {
  return ref.watch(gameServiceProvider).getGameRoomStream(gameRoomId);
});

// Provedor para os dados dos jogadores na sala de jogo
final gamePlayersProvider =
    FutureProvider.family<Map<String, UserModel>, String>((
      ref,
      gameRoomId,
    ) async {
      final gameRoom = await ref.watch(
        gameRoomStreamProvider(gameRoomId).future,
      );
      final firestoreService = ref.watch(firestoreServiceProvider);

      final player1Id = gameRoom.playerIds[0];
      final player2Id = gameRoom.playerIds[1];

      final player1 = await firestoreService.getUser(player1Id);
      final player2 = await firestoreService.getUser(player2Id);

      if (player1 == null || player2 == null) {
        throw Exception('Um ou ambos os jogadores não foram encontrados.');
      }

      return {player1Id: player1, player2Id: player2};
    });

// StateNotifierProvider para a lógica do jogo
final gameLogicProvider =
    StateNotifierProvider.family<GameLogicNotifier, GameRoomModel, String>((
      ref,
      gameRoomId,
    ) {
      final gameRoom = ref.watch(gameRoomStreamProvider(gameRoomId)).value;
      if (gameRoom == null) {
        throw Exception('Sala de jogo não carregada para GameLogicNotifier.');
      }
      return GameLogicNotifier(ref, gameRoom);
    });

// StreamProvider para as mensagens da sala de jogo
final gameMessagesStreamProvider =
    StreamProvider.family<List<MessageModel>, String>((ref, gameRoomId) {
      return ref
          .watch(gameServiceProvider)
          .getGameRoomMessagesStream(gameRoomId);
    });

class GameLogicNotifier extends StateNotifier<GameRoomModel> {
  final Ref _ref;
  final GameService _gameService;
  final FirestoreService _firestoreService;

  GameLogicNotifier(this._ref, GameRoomModel initialGameRoom)
    : _gameService = _ref.read(gameServiceProvider),
      _firestoreService = _ref.read(firestoreServiceProvider),
      super(initialGameRoom);

  // Lista de chaves de perfil que podem ser reveladas
  static const List<String> _revealableKeys = [
    'photo_url',
    'favorite_bands',
    'social_media',
  ];

  /// Aceita um convite para o jogo.
  Future<void> acceptInvite() async {
    final currentUser = _ref.read(authProvider).user;
    if (currentUser == null) return;

    // Apenas o convidado (segundo jogador na lista) pode aceitar.
    if (state.status == GameStatus.pending &&
        state.playerIds.last == currentUser.uid) {
      AppLogger.info(
        'Usuário ${currentUser.uid} aceitou o convite para ${state.id}',
      );
      await _gameService.updateGameRoom(state.id, {
        'status': GameStatus.active.name,
      });
      // Selecionar a primeira pergunta
      await _selectNextQuestion();
    }
  }

  /// Recusa um convite para o jogo.
  Future<void> declineInvite() async {
    final currentUser = _ref.read(authProvider).user;
    if (currentUser == null) return;

    if (state.status == GameStatus.pending &&
        state.playerIds.contains(currentUser.uid)) {
      AppLogger.info(
        'Usuário ${currentUser.uid} recusou o convite para ${state.id}',
      );
      await _gameService.updateGameRoom(state.id, {
        'status': GameStatus.declined.name,
      });
    }
  }

  /// Abandona um jogo em andamento.
  Future<void> abandonGame() async {
    if (state.status == GameStatus.active) {
      AppLogger.info('Usuário abandonou o jogo ${state.id}');
      await _gameService.updateGameRoom(state.id, {
        'status': GameStatus.abandoned.name,
      });
    }
  }

  // Seleciona a próxima pergunta com base nos interesses em comum
  Future<void> _selectNextQuestion() async {
    final currentUser = _ref.read(authProvider).user;
    if (currentUser == null) return;

    final players = await _ref.read(gamePlayersProvider(state.id).future);
    final opponent = players.values.firstWhere((p) => p.uid != currentUser.uid);

    final commonInterests = currentUser.interesses
        .toSet()
        .intersection(opponent.interesses.toSet())
        .toList();

    AppLogger.info(
      'Selecting next question. Common interests: $commonInterests',
    );

    // Filtrar perguntas que ainda não foram feitas
    final askedQuestionIds = state.questions.map((q) => q['id']).toSet();
    final availableQuestions = QuestionsData.allQuestions.where(
      (q) =>
          !askedQuestionIds.contains(q.id) &&
          q.relatedInterests.any(
            (interest) => commonInterests.contains(interest),
          ),
    );

    QuestionModel? nextQuestion;
    if (availableQuestions.isNotEmpty) {
      // Para MVP, apenas pegue a primeira disponível. Em um app real, seria mais sofisticado.
      nextQuestion = availableQuestions.first;
    } else {
      // Se não houver mais perguntas baseadas em interesses, pegue qualquer uma não feita
      nextQuestion = QuestionsData.allQuestions
          .where((q) => !askedQuestionIds.contains(q.id))
          .firstOrNull;
    }

    if (nextQuestion != null) {
      final updatedQuestions = List<Map<String, dynamic>>.from(state.questions)
        ..add(nextQuestion.toJson());
      // await _gameService.updateGameRoom(state.id, {
      //   'questions': updatedQuestions,
      //   'currentTurnPlayerId':
      //       currentUser.uid, // O jogador atual faz a pergunta
      // });
      // A vez do jogador já foi definida na criação da sala (o convidante começa).
      // A vez só deve mudar DEPOIS que uma resposta for enviada.
      await _gameService.updateGameRoom(state.id, {
        'questions': updatedQuestions,
      });

      AppLogger.info('Nova pergunta selecionada: ${nextQuestion.text}');
    } else {
      AppLogger.info(
        'Todas as perguntas foram feitas ou não há mais perguntas relevantes.',
      );
      // O jogo terminará quando o progresso de ambos chegar a 100%
    }
  }

  // Submete uma resposta para a pergunta atual
  Future<void> submitAnswer(String answer) async {
    final currentUser = _ref.read(authProvider).user;
    if (currentUser == null || state.currentTurnPlayerId != currentUser.uid) {
      AppLogger.warning('Não é o turno do usuário para responder.');
      return;
    }

    final currentQuestion = state.questions.lastOrNull;
    if (currentQuestion == null) {
      AppLogger.warning('Nenhuma pergunta ativa para responder.');
      return;
    }

    final updatedAnswers = Map<String, Map<String, dynamic>>.from(
      state.answers,
    );
    updatedAnswers[currentQuestion['id']] = {
      ...(updatedAnswers[currentQuestion['id']] ?? {}),
      currentUser.uid: answer,
    };

    // Determinar qual informação revelar ao oponente
    final opponent = (await _ref.read(
      gamePlayersProvider(state.id).future,
    )).values.firstWhere((p) => p.uid != currentUser.uid);

    // // Calcular o índice da próxima revelação com base no progresso
    // final revelationIndex = ((newProgressValue * _revealableKeys.length) - 1);
    // final revealedToOpponentCount =
    //     state.revealedInfo[opponent.uid]?.keys.length ?? 0;
    // final revelationIndex = revealedToOpponentCount.clamp(
    //   0,
    //   _revealableKeys.length - 1,
    // );
    // Contar quantas informações o usuário atual já revelou sobre o oponente.
    // O índice da próxima revelação é simplesmente a contagem atual.
    final revealedCount = state.revealedInfo[currentUser.uid]?.length ?? 0;
    final revelationIndex = revealedCount;

    // Só revela se ainda houver itens a serem revelados
    String? keyToReveal;
    if (revelationIndex < _revealableKeys.length) {
      keyToReveal = _revealableKeys[revelationIndex];
    }
    // Obter o valor real a ser revelado do perfil do oponente
    dynamic valueToReveal;
    switch (keyToReveal) {
      case 'photo_url':
        valueToReveal = opponent.actualPhotoUrl;
        break;
      case 'favorite_bands':
        valueToReveal = opponent.actualFavoriteBands;
        break;
      case 'social_media':
        valueToReveal = opponent.actualSocialMediaHandle;
        break;
    }

    // Atualizar as informações reveladas na sala de jogo
    final updatedRevealedInfo = Map<String, Map<String, dynamic>>.from(
      state.revealedInfo,
    );
    if (keyToReveal != null && valueToReveal != null) {
      final userRevealed = Map<String, dynamic>.from(
        updatedRevealedInfo[currentUser.uid] ?? {},
      );
      userRevealed[keyToReveal] = valueToReveal;
      updatedRevealedInfo[currentUser.uid] = userRevealed;

      AppLogger.info('Informação revelada para ${opponent.uid}: $keyToReveal');
    }

    await _gameService.updateGameRoom(state.id, {
      'answers': updatedAnswers,
      'revealedInfo': updatedRevealedInfo,
      'currentTurnPlayerId': state.playerIds.firstWhere(
        (id) => id != currentUser.uid,
      ), // Passa o turno
    });

    AppLogger.info('Resposta submetida e progresso atualizado.');
    // Verificar se o jogo terminou (ambos 100%)
    final inviterRevealedCount =
        updatedRevealedInfo[state.playerIds[0]]?.length ?? 0;
    final inviteeRevealedCount =
        updatedRevealedInfo[state.playerIds[1]]?.length ?? 0;

    if (inviterRevealedCount >= _revealableKeys.length &&
        inviteeRevealedCount >= _revealableKeys.length) {
      AppLogger.info('Ambos os jogadores atingiram 100%. Jogo finalizado.');
      await _gameService.updateGameRoom(state.id, {
        'status': GameStatus.finished.name,
      });
      // Registrar conexão mútua nos perfis dos usuários
      await _firestoreService.updateUser(currentUser.uid, {
        'connectedUsers': FieldValue.arrayUnion([opponent.uid]),
      });
      await _firestoreService.updateUser(opponent.uid, {
        'connectedUsers': FieldValue.arrayUnion([currentUser.uid]),
      });
    }
  }

  // Envia uma mensagem no chat
  Future<void> sendMessage(String content) async {
    final currentUser = _ref.read(authProvider).user;
    if (currentUser == null) {
      AppLogger.warning(
        'Não é possível enviar mensagem: usuário não autenticado.',
      );
      return;
    }

    final message = MessageModel(
      id: _firestoreService
          .generateDocId(), // Gerar um ID único para a mensagem
      senderId: currentUser.uid,
      content: content,
    );
    await _gameService.sendMessage(gameRoomId: state.id, message: message);
  }
}
