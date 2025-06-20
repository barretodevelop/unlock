// lib/features/missions/repositories/mission_repository.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:unlock/features/missions/models/mission.dart'; // Importa os modelos de missão
import 'package:unlock/features/missions/models/user_mission_progress.dart';
import 'package:unlock/features/missions/repositories/mission_repository_interface.dart';

/// Provedor Riverpod para o MissionRepository.
///
/// Este provedor permite que outras partes da aplicação acessem uma instância
/// do MissionRepository, que pode ser facilmente substituída para testes (mocking)
/// ou para usar diferentes implementações de persistência.
final missionRepositoryProvider = Provider<MissionRepository>((ref) {
  // Em um cenário real, aqui você injetaria dependências para o backend,
  // como uma instância do FirebaseFirestore, um cliente HTTP, etc.
  // Por exemplo:
  // final firestore = ref.read(firestoreProvider);
  // return MissionRepository(firestore: firestore);
  return MissionRepository(); // Por enquanto, usa uma implementação simples com dados mockados.
}); // ✅ Implementa a interface

/// Repositório para gerenciar a obtenção e atualização de dados de missões e
/// progresso do usuário.

// Simulação de dados de backend para missões.
class MissionRepository implements IMissionRepository {
  // Em uma aplicação real, estas missões seriam carregadas de um serviço de backend
  // que as definiria, ativaria e desativaria.
  final List<Mission> _allMissions = [
    Mission(
      id: 'missao_login_diario_001',
      title: 'Login Diário',
      description: 'Faça login no jogo hoje para ganhar uma recompensa.',
      category: 'gamification', // Adicionar categoria
      type: MissionType.DAILY,
      criterion: MissionCriterion(eventType: 'LOGIN_DAILY', targetCount: 1),
      reward: MissionReward(coins: 50, xp: 20),
    ),
    Mission(
      id: 'missao_curtir_perfil_001',
      title: 'Curta 3 Perfis',
      description: 'Curta 3 perfis de outros usuários para ganhar recompensas.',
      category: 'social', // Adicionar categoria
      type: MissionType.ONE_TIME,
      criterion: MissionCriterion(eventType: 'LIKE_PROFILE', targetCount: 3),
      reward: MissionReward(coins: 100, xp: 50),
    ),
    Mission(
      id: 'missao_fazer_post_001',
      title: 'Crie um Post',
      description: 'Crie um novo post no feed da comunidade.',
      category: 'social', // Adicionar categoria
      type: MissionType.ONE_TIME,
      criterion: MissionCriterion(eventType: 'CREATE_POST', targetCount: 1),
      reward: MissionReward(gems: 5, xp: 30),
    ),
    Mission(
      id: 'missao_tutorial_concluido_001',
      title: 'Conclua o Tutorial',
      description:
          'Complete o tutorial do jogo para entender as mecânicas básicas.',
      category: 'gamification', // Adicionar categoria
      type: MissionType.ONE_TIME,
      criterion: MissionCriterion(
        eventType: 'TUTORIAL_COMPLETED',
        targetCount: 1,
      ),
      reward: MissionReward(coins: 150, xp: 80, gems: 10),
    ),
  ];

  // Simulação de banco de dados para o progresso do usuário.
  // Em uma aplicação real, isso seria persistido (ex: em Firestore, SharedPreferences ou um banco de dados local).
  // A chave é uma combinação de 'userId-missionId' para identificar o progresso único de cada missão por usuário.
  final Map<String, UserMissionProgress> _userProgress = {};

  /// Retorna uma lista de missões que estão ativas no momento.
  ///
  /// Em um cenário real de backend, este método faria uma chamada API
  /// para buscar missões ativas, filtrando por data, status, etc.
  Future<List<Mission>> getActiveMissions() async {
    // Simulando um pequeno atraso de rede
    await Future.delayed(const Duration(milliseconds: 300));
    // Por enquanto, retorna todas as missões mockadas.
    return Future.value(_allMissions);
  }

  /// Obtém o progresso de um usuário para uma missão específica.
  ///
  /// Se o progresso para a dada missão e usuário não existir, uma nova instância
  /// de UserMissionProgress é criada e inicializada.
  Future<UserMissionProgress> getMissionProgress(
    String userId,
    String missionId,
  ) async {
    final key = '$userId-$missionId';
    if (!_userProgress.containsKey(key)) {
      _userProgress[key] = UserMissionProgress(
        userId: userId,
        missionId: missionId,
      );
    }
    // Simulando um pequeno atraso de rede
    await Future.delayed(const Duration(milliseconds: 50));
    return Future.value(_userProgress[key]!);
  }

  bool missionExists(String missionId) {
    return _allMissions.any((mission) => mission.id == missionId);
  }

  /// Atualiza o progresso de uma missão para um usuário no "banco de dados".
  ///
  /// Em uma aplicação real, este método faria uma requisição ao backend
  /// para persistir as mudanças no progresso do usuário.
  @override // ✅ Adicionar @override
  Future<void> updateMissionProgress(UserMissionProgress progress) async {
    final key = '${progress.userId}-${progress.missionId}';
    _userProgress[key] = progress;
    // Simulando um pequeno atraso de rede
    await Future.delayed(const Duration(milliseconds: 100));
    print(
      'DEBUG: Progresso da missão ${progress.missionId} atualizado para ${progress.currentProgress}, Concluída: ${progress.isCompleted}, Resgatada: ${progress.isClaimed}',
    );
    return Future.value();
  }

  /// Resetar o progresso de missões diárias/semanais para um usuário.
  ///
  /// NOTA: Em um sistema de produção, o reset de missões diárias/semanais
  /// deve ser orquestrado e executado no backend (via cron jobs, por exemplo).
  /// Este método é uma simulação para fins de desenvolvimento no cliente.
  @override // ✅ Adicionar @override
  Future<void> resetDailyMissionProgress(
    String userId,
    String missionId,
  ) async {
    final key = '$userId-$missionId';
    if (_userProgress.containsKey(key)) {
      final progress = _userProgress[key]!;
      // A verificação se é uma missão diária que precisa ser resetada é feita pelo chamador (MissionsNotifier).
      // Este método apenas executa a lógica de reset se o progresso existir e a condição de data for atendida.
      final now = DateTime.now();
      if (progress.lastUpdateDate == null ||
          progress.lastUpdateDate!.day != now.day ||
          progress.lastUpdateDate!.month != now.month ||
          progress.lastUpdateDate!.year != now.year) {
        _userProgress[key] = UserMissionProgress(
          userId: userId,
          missionId: missionId,
          currentProgress: 0,
          isCompleted: false,
          isClaimed: false, // Mantém isClaimed como false no reset
          lastUpdateDate:
              null, // Define lastUpdateDate como null para forçar o reprocessamento do evento
        );
        print(
          'DEBUG: Missão diária $missionId resetada para o usuário $userId',
        );
        await updateMissionProgress(_userProgress[key]!); // Persiste o reset
      }
    }
  }
}
