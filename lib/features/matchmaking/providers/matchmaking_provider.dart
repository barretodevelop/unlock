import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:unlock/core/constants/app_constants.dart';
import 'package:unlock/core/utils/logger.dart';
import 'package:unlock/models/user_model.dart';
import 'package:unlock/providers/auth_provider.dart';
import 'package:unlock/services/game_service.dart';

/// Provedor para o serviço de jogo.
final gameServiceProvider = Provider((ref) => GameService());

/// Provedor que busca e classifica os 3 melhores "matches" para o usuário atual.
final matchmakingProvider = FutureProvider<List<UserModel>>((ref) async {
  final authState = ref.watch(authProvider);
  final currentUser = authState.user;

  if (currentUser == null) {
    AppLogger.warning('Matchmaking: Usuário não autenticado.');
    return [];
  }

  AppLogger.info(' matchmaking para ${currentUser.uid}');

  try {
    // 1. Buscar todos os outros usuários que completaram o onboarding.
    // Em um app real, essa query seria mais complexa, filtrando por
    // localização, idade, gênero, etc., e usaria paginação.
    final querySnapshot = await FirebaseFirestore.instance
        .collection(FirestoreCollections.users)
        .where('onboardingCompleted', isEqualTo: true)
        .where(FieldPath.documentId, isNotEqualTo: currentUser.uid)
        .limit(50) // Limitar para fins de performance no MVP
        .get();

    final allUsers = querySnapshot.docs
        .map((doc) => UserModel.fromJson(doc.data()))
        .toList();

    AppLogger.debug('Encontrados ${allUsers.length} usuários potenciais.');

    // 2. Calcular a pontuação de compatibilidade para cada usuário.
    final scoredUsers = allUsers.map((otherUser) {
      final score = _calculateCompatibility(currentUser, otherUser);
      return MapEntry(otherUser, score);
    }).toList();

    // 3. Ordenar usuários pela pontuação (do maior para o menor).
    scoredUsers.sort((a, b) => b.value.compareTo(a.value));

    // 4. Retornar os 3 melhores.
    final topUsers = scoredUsers.take(3).map((entry) => entry.key).toList();

    AppLogger.info(
      '✅ Matchmaking concluído. Top 3 usuários encontrados.',
      data: {'top_users_ids': topUsers.map((u) => u.uid).toList()},
    );

    return topUsers;
  } catch (e, stackTrace) {
    AppLogger.error(
      '❌ Erro no matchmakingProvider',
      error: e,
      stackTrace: stackTrace,
    );
    // Retorna uma lista vazia em caso de erro para a UI tratar.
    return [];
  }
});

/// Lógica de cálculo de compatibilidade.
///
/// Este é um algoritmo simples para o MVP.
/// - 50% do peso para interesses em comum.
/// - 30% do peso para proximidade do "nível de conexão" desejado.
/// - 20% do peso para um fator aleatório para adicionar variedade.
double _calculateCompatibility(UserModel currentUser, UserModel otherUser) {
  // Interesses em comum
  final currentUserInterests = currentUser.interesses.toSet();
  final otherUserInterests = otherUser.interesses.toSet();
  final commonInterests = currentUserInterests.intersection(otherUserInterests);
  final interestScore =
      commonInterests.length /
      (currentUserInterests.length + otherUserInterests.length).toDouble();

  // Proximidade do nível de conexão
  final levelDifference =
      (currentUser.connectionLevel - otherUser.connectionLevel).abs();
  final levelScore = 1.0 - (levelDifference / 9.0); // Normaliza de 0 a 1

  // Fator aleatório
  final randomFactor = Random().nextDouble() * 0.5; // 0.0 a 0.5

  // Pontuação final ponderada
  final finalScore =
      (interestScore * 0.5) + (levelScore * 0.3) + (randomFactor * 0.2);

  return finalScore;
}
