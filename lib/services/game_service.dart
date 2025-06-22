import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:unlock/core/constants/app_constants.dart';
import 'package:unlock/core/utils/logger.dart';
import 'package:unlock/models/game_room_model.dart';
import 'package:unlock/models/message_model.dart';

class GameService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Cria um convite para um jogo, resultando em um novo `game_room`.
  ///
  /// Retorna o ID da sala de jogo criada ou `null` em caso de falha.
  Future<String?> sendGameInvite({
    required String inviterId,
    required String inviteeId,
  }) async {
    try {
      AppLogger.info(
        '💌 Enviando convite de jogo',
        data: {'from': inviterId, 'to': inviteeId},
      );

      final gameRoomData = {
        'playerIds': [inviterId, inviteeId],
        'status': GameStatus.pending.name,
        'progress': {inviterId: 0.0, inviteeId: 0.0},
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'currentTurnPlayerId': inviterId, // O convidante começa
      };

      final docRef = await _db
          .collection(FirestoreCollections.game_rooms)
          .add(gameRoomData);

      AppLogger.info('✅ Sala de jogo criada com sucesso: ${docRef.id}');

      // TODO: Implementar envio de notificação via Cloud Function
      // A Cloud Function deve ser acionada na criação de um documento em 'game_rooms'
      // e enviar uma notificação para o 'inviteeId'.
      // NotificationService.sendGameInviteNotification(inviteeId: inviteeId, inviterId: inviterId);

      return docRef.id;
    } catch (e, stackTrace) {
      AppLogger.error(
        '❌ Erro ao enviar convite de jogo',
        error: e,
        stackTrace: stackTrace,
      );
      return null;
    }
  }

  /// Obtém um stream de uma sala de jogo específica.
  Stream<GameRoomModel> getGameRoomStream(String gameRoomId) {
    return _db
        .collection(FirestoreCollections.game_rooms)
        .doc(gameRoomId)
        .snapshots()
        .map((snapshot) {
          if (!snapshot.exists) {
            throw Exception('Sala de jogo não encontrada: $gameRoomId');
          }
          return GameRoomModel.fromJson(snapshot.id, snapshot.data()!);
        });
  }

  /// Atualiza campos específicos de uma sala de jogo.
  Future<void> updateGameRoom(
    String gameRoomId,
    Map<String, dynamic> data,
  ) async {
    try {
      await _db
          .collection(FirestoreCollections.game_rooms)
          .doc(gameRoomId)
          .update(data);
      AppLogger.info('✅ Sala de jogo atualizada: $gameRoomId', data: data);
    } catch (e, stackTrace) {
      AppLogger.error(
        '❌ Erro ao atualizar sala de jogo: $gameRoomId',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  Future<void> sendMessage({
    required String gameRoomId,
    required MessageModel message,
  }) async {
    try {
      await _db
          .collection(FirestoreCollections.game_rooms)
          .doc(gameRoomId)
          .collection('messages')
          .doc(message.id)
          .set(message.toJson());
    } catch (e, stackTrace) {
      AppLogger.error(
        '❌ Erro ao enviar mensagem na sala de jogo: $gameRoomId',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Obtém um stream das mensagens de uma sala de jogo, ordenadas por tempo.
  Stream<List<MessageModel>> getGameRoomMessagesStream(String gameRoomId) {
    return _db
        .collection(FirestoreCollections.game_rooms)
        .doc(gameRoomId)
        .collection('messages')
        .orderBy('timestamp')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => MessageModel.fromJson(doc.data()))
              .toList(),
        );
  }
}
