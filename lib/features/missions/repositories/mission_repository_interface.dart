// lib/features/missions/repositories/mission_repository_interface.dart

import 'package:unlock/features/missions/models/mission.dart';
import 'package:unlock/features/missions/models/user_mission_progress.dart';

/// Define o contrato para qualquer serviço ou repositório que gerencie missões e progresso.
/// Classes concretas (como MissionRepositoryMock ou MissionRepositoryFirestore)
/// devem implementar esta interface.
abstract class IMissionRepository {
  /// Retorna uma lista de missões que estão ativas no momento.
  Future<List<Mission>> getActiveMissions();

  /// Obtém o progresso de um usuário para uma missão específica.
  Future<UserMissionProgress> getMissionProgress(
    String userId,
    String missionId,
  );

  /// Atualiza o progresso de uma missão para um usuário.
  Future<void> updateMissionProgress(UserMissionProgress progress);

  Future<void> resetDailyMissionProgress(
    String currentUserId,
    String id,
  ) async {}
}
