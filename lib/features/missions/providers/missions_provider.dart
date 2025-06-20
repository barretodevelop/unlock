// // lib/features/missions/providers/missions_notifier.dart

// import 'dart:async'; // Importar Completer
// import 'dart:math'; // Para randomizar targetCount

// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:unlock/core/constants/mission_constants.dart'; // Para templates de missão
// import 'package:unlock/core/constants/mission_event_types.dart';
// import 'package:unlock/core/utils/logger.dart';
// import 'package:unlock/features/connections/services/connections_service.dart'; // Importar o novo serviço
// import 'package:unlock/features/missions/models/mission.dart';
// import 'package:unlock/features/missions/models/user_mission_progress.dart';
// import 'package:unlock/features/missions/repositories/mission_repository.dart';
// import 'package:unlock/features/rewards/providers/rewards_provider.dart';
// import 'package:unlock/features/rewards/services/rewards_service.dart';
// import 'package:unlock/models/user_model.dart'; // Importar UserModel
// import 'package:unlock/providers/auth_provider.dart'; // Importa o AuthProvider

// /// Estado que o provedor MissionsNotifier irá gerenciar.
// /// Contém a lista de missões disponíveis, o progresso do usuário em cada missão,
// /// e o status de carregamento/erro.
// class MissionsState {
//   final List<Mission> availableMissions;
//   // Correção: Inicializa userProgress com um mapa vazio do tipo correto
//   final Map<String, UserMissionProgress> userProgress; // Chave: missionId
//   final bool isLoading;
//   final String? error;

//   MissionsState({
//     this.availableMissions = const [],
//     // Garante que o mapa padrão seja do tipo correto
//     Map<String, UserMissionProgress>? userProgress,
//     this.isLoading = false,
//     this.error,
//   }) : userProgress =
//            userProgress ??
//            const {}; // Usa const {} para um mapa vazio e imutável do tipo inferido

//   /// Permite criar uma nova instância de MissionsState com campos atualizados.
//   MissionsState copyWith({
//     List<Mission>? availableMissions,
//     Map<String, UserMissionProgress>? userProgress, // Parameter type
//     bool? isLoading,
//     String? error,
//   }) {
//     return MissionsState(
//       availableMissions: availableMissions ?? this.availableMissions,
//       // Correção: Torna a cópia do mapa explícita para o tipo correto.
//       // Se userProgress for nulo, cria um novo mapa a partir do existente.
//       userProgress:
//           userProgress ??
//           Map<String, UserMissionProgress>.from(this.userProgress),
//       isLoading: isLoading ?? this.isLoading,
//       error: error,
//     );
//   }
// }

// /// Provedor principal para o sistema de missões.
// ///
// /// Gerencia o estado das missões, o progresso do usuário e a lógica de conclusão/recompensa.
// final missionsProvider = StateNotifierProvider<MissionsNotifier, MissionsState>((
//   ref,
// ) {
//   final userId = ref
//       .watch(authProvider)
//       .user
//       ?.uid; // Obtém o ID do usuário logado

//   // Se não há usuário logado, retorna um MissionsNotifier que não carregará dados
//   // ou um estado de erro, dependendo da sua preferência para usuários não logados.
//   if (userId == null) {
//     print(
//       'DEBUG: MissionsNotifier inicializado sem userId. Não carregará missões.',
//     );
//     return MissionsNotifier(ref, null);
//   }
//   return MissionsNotifier(ref, userId);
// });

// /// StateNotifier responsável por gerenciar o estado das missões.
// class MissionsNotifier extends StateNotifier<MissionsState> {
//   final Ref _ref;
//   final String? _userId; // O ID do usuário logado (pode ser nulo se não logado)
//   late final MissionRepository
//   _missionRepository; // Repositório para acesso a dados
//   late final RewardsService _rewardsService; // Serviço para aplicar recompensas
//   final Completer<void> _initialLoadCompleter =
//       Completer<void>(); // Para sincronização

//   MissionsNotifier(this._ref, this._userId) : super(MissionsState()) {
//     _missionRepository = _ref.read(missionRepositoryProvider);
//     _rewardsService = _ref.read(rewardsServiceProvider);

//     // Carrega as missões e o progresso se houver um usuário logado
//     if (_userId != null) {
//       _loadData();
//     } else {
//       // Se não há usuário, o carregamento inicial é considerado completo (não há o que carregar).
//       if (!_initialLoadCompleter.isCompleted) {
//         _initialLoadCompleter.complete();
//       }
//     }
//   }

//   /// Carrega as missões ativas e o progresso do usuário a partir do repositório.
//   Future<void> _loadData() async {
//     // Usar o userId mais recente do AuthProvider, embora _userId deva estar correto aqui
//     // devido à recriação do notifier quando authProvider muda.
//     final currentUserId = _userId ?? _ref.read(authProvider).user?.uid;

//     if (currentUserId == null) {
//       state = state.copyWith(
//         error: 'Usuário não autenticado para carregar missões.',
//         isLoading: false, // Garante que isLoading seja false
//       );
//       if (!_initialLoadCompleter.isCompleted) _initialLoadCompleter.complete();
//       return;
//     }

//     state = state.copyWith(isLoading: true, error: null);
//     try {
//       // 1. Carregar missões ONE_TIME e EVENT (ou outras fixas) do repositório
//       final fixedMissions = await _missionRepository.getActiveMissions();
//       final List<Mission> allAvailableMissions = List.from(fixedMissions);

//       // Correção: Garante que progressMap é do tipo correto desde o início
//       final Map<String, UserMissionProgress> progressMap = {};

//       // Obter dados do usuário atual para verificar requisitos
//       final UserModel? currentUserModel = _ref.read(authProvider).user;

//       // 2. "Gerar" missões diárias a partir dos templates
//       final random = Random();
//       final List<Map<String, dynamic>> dailyTemplates = List.from(
//         MissionConstants.dailyMissionTemplates,
//       );
//       dailyTemplates.shuffle(
//         random,
//       ); // Embaralha para pegar diferentes a cada "dia" (simulado)

//       final List<Mission> generatedDailyMissions = [];
//       for (
//         int i = 0;
//         i < MissionConstants.dailyMissionsCount && i < dailyTemplates.length;
//         i++
//       ) {
//         final template = dailyTemplates[i];

//         // >>> INÍCIO DA LÓGICA DE VERIFICAÇÃO DE REQUISITOS <<<
//         bool meetsAllRequirements = true;
//         final List<Map<String, dynamic>> requirements =
//             (template['requirements'] as List<dynamic>?)
//                 ?.map((e) => e as Map<String, dynamic>)
//                 .toList() ??
//             [];

//         if (currentUserModel != null && requirements.isNotEmpty) {
//           for (var req in requirements) {
//             final String reqType = req['type'] as String;
//             final dynamic reqValue = req['value'];

//             if (reqType == 'level') {
//               if (currentUserModel.level < (reqValue as int)) {
//                 meetsAllRequirements = false;
//                 AppLogger.debug(
//                   'Usuário não cumpre requisito de NÍVEL para "${template['title']}". Nível: ${currentUserModel.level}, Requerido: $reqValue',
//                 );
//                 break;
//               }
//             } else if (reqType == 'connections') {
//               // Agora usa o ConnectionsService
//               final connectionsService = _ref.read(connectionsServiceProvider);
//               int userConnections = await connectionsService
//                   .getConnectionsCount(currentUserModel.uid);
//               if (userConnections < (reqValue as int)) {
//                 meetsAllRequirements = false;
//                 AppLogger.debug(
//                   'Usuário não cumpre requisito de CONEXÕES para "${template['title']}". Conexões: $userConnections, Requerido: $reqValue',
//                 );
//                 break;
//               }
//             } else if (reqType == 'mission_completed') {
//               final String requiredMissionId = reqValue as String;
//               // Precisamos buscar o progresso desta missão específica.
//               // Nota: Se a missão requerida ainda não foi carregada/gerada, esta verificação pode falhar.
//               // Idealmente, as missões 'ONE_TIME' que são pré-requisitos já estariam em `fixedMissions`.
//               final requiredMissionProgress = await _missionRepository
//                   .getMissionProgress(currentUserId, requiredMissionId);
//               if (!requiredMissionProgress.isCompleted ||
//                   !requiredMissionProgress.isClaimed) {
//                 // Ou apenas isCompleted
//                 meetsAllRequirements = false;
//                 AppLogger.debug(
//                   'Usuário não cumpre requisito de MISSÃO COMPLETADA ("$requiredMissionId") para "${template['title']}".',
//                 );
//                 break;
//               }
//             } else if (reqType == 'feature_unlocked') {
//               final String featureName = reqValue as String;
//               if (!_isFeatureUnlocked(currentUserModel, featureName)) {
//                 meetsAllRequirements = false;
//                 AppLogger.debug(
//                   'Usuário não cumpre requisito de FEATURE DESBLOQUEADA ("$featureName") para "${template['title']}".',
//                 );
//                 break;
//               }
//             }
//             // Adicionar mais tipos de requisitos aqui (ex: 'feature_unlocked')
//           }
//         }

//         if (!meetsAllRequirements) {
//           AppLogger.debug(
//             'Missão "${template['title']}" pulada devido a requisitos não cumpridos.',
//           );
//           continue; // Pula para o próximo template de missão
//         }
//         // >>> FIM DA LÓGICA DE VERIFICAÇÃO DE REQUISITOS <<<

//         // Evitar duplicar a missão de LOGIN_DAILY se ela já vem do _allMissions
//         if (template['eventType'] == MissionEventTypes.LOGIN_DAILY &&
//             fixedMissions.any(
//               (m) =>
//                   m.criterion.eventType == MissionEventTypes.LOGIN_DAILY &&
//                   m.type == MissionType.DAILY,
//             )) {
//           AppLogger.debug(
//             "Missão de Login Diário já existe nas missões fixas, pulando template.",
//           );
//           continue;
//         }

//         final targetCountRange = template['targetCountRange'] as List<int>;
//         final targetCount =
//             targetCountRange[0] +
//             (targetCountRange.length > 1
//                 ? random.nextInt(targetCountRange[1] - targetCountRange[0] + 1)
//                 : 0);

//         final description = (template['description_template'] as String)
//             .replaceAll('{targetCount}', targetCount.toString());

//         final rewardMap = template['reward'] as Map<String, int>;

//         // Gerar um ID único para a instância da missão diária
//         // Para mock, podemos usar o id_template + um sufixo simples. Em produção, seria mais robusto.
//         final missionId =
//             '${template['id_template']}_${currentUserId.substring(0, 5)}_${DateTime.now().millisecondsSinceEpoch}_$i';

//         final dailyMission = Mission(
//           id: missionId,
//           title: template['title'] as String,
//           description: description,
//           category:
//               template['category'] as String? ??
//               'Outras', // Incluir categoria do template
//           type: MissionType.DAILY, // Definido como diária
//           criterion: MissionCriterion(
//             eventType: template['eventType'] as String,
//             targetCount: targetCount,
//           ),
//           reward: MissionReward(
//             xp: rewardMap['xp'] ?? 0,
//             coins: rewardMap['coins'] ?? 0,
//             gems: rewardMap['gems'] ?? 0,
//           ),
//         );
//         generatedDailyMissions.add(dailyMission);
//       }
//       allAvailableMissions.addAll(generatedDailyMissions);

//       // Para cada missão (fixa ou gerada), busca/reseta o progresso.
//       for (var mission in allAvailableMissions) {
//         final progress = await _missionRepository.getMissionProgress(
//           currentUserId,
//           mission.id,
//         );
//         progressMap[mission.id] = progress;

//         // Lógica para resetar missões diárias automaticamente ao carregar, se necessário.
//         // O ideal é que isso seja orquestrado pelo backend, mas aqui é uma simulação.
//         if (mission.type == MissionType.DAILY) {
//           final now = DateTime.now();
//           if (progress.lastUpdateDate == null ||
//               progress.lastUpdateDate!.day != now.day ||
//               progress.lastUpdateDate!.month != now.month ||
//               progress.lastUpdateDate!.year != now.year) {
//             // Se a última atualização não foi hoje, reseta a missão.
//             await _missionRepository.resetDailyMissionProgress(
//               currentUserId,
//               mission.id,
//             );
//             // Rebusca o progresso para ter o estado resetado
//             progressMap[mission.id] = await _missionRepository
//                 .getMissionProgress(currentUserId, mission.id);
//             print(
//               'DEBUG: Missão diária ${mission.title} (${mission.id}) resetada no cliente.',
//             );
//           }
//         }
//       }
//       state = state.copyWith(
//         availableMissions: allAvailableMissions,
//         userProgress: progressMap,
//         isLoading: false,
//       );
//       print('DEBUG: Missões e progresso carregados com sucesso.');
//     } catch (e, stackTrace) {
//       // Adicionar stackTrace para melhor debugging
//       state = state.copyWith(error: e.toString(), isLoading: false);
//       AppLogger.error(
//         'ERRO: Erro ao carregar missões',
//         error: e,
//         stackTrace: stackTrace,
//       );
//     } finally {
//       // Garante que o completer seja finalizado mesmo em caso de erro.
//       if (!_initialLoadCompleter.isCompleted) {
//         _initialLoadCompleter.complete();
//       }
//     }
//   }

//   /// Reporta um evento de ação que pode afetar o progresso das missões.
//   ///
//   /// [eventType]: A string que identifica o tipo de evento (ex: 'LOGIN_DIARIO', 'LIKE_PROFILE').
//   /// [details]: Um mapa opcional com detalhes adicionais do evento.
//   Future<void> reportMissionEvent(
//     String eventType, {
//     Map<String, dynamic>? details,
//   }) async {
//     // Espera o carregamento inicial ter sido concluído
//     await _initialLoadCompleter.future;

//     // Obter o userId mais atualizado do AuthProvider no momento da chamada.
//     final currentUserId = _ref.read(authProvider).user?.uid;
//     AppLogger.debug(
//       'MissionsNotifier.reportMissionEvent para eventType: $eventType. _userId (do construtor): $_userId, currentUserId (lido agora): $currentUserId',
//     );

//     if (currentUserId == null) {
//       AppLogger.info(
//         'Evento $eventType ignorado. Usuário não autenticado (currentUserId é nulo).',
//       );
//       return;
//     }

//     // Garante que currentProgressMap seja uma nova instância baseada no estado atual.
//     final currentProgressMap = Map<String, UserMissionProgress>.from(
//       state.userProgress,
//     );
//     bool stateChanged = false;

//     // Itera sobre as missões disponíveis para ver quais são afetadas pelo evento
//     for (var mission in state.availableMissions) {
//       if (mission.criterion.eventType == eventType) {
//         // Usa currentUserId para buscar ou criar o progresso.
//         UserMissionProgress progress =
//             currentProgressMap[mission.id] ??
//             UserMissionProgress(userId: currentUserId, missionId: mission.id);

//         // Garante que o progresso tenha o userId mais atualizado.
//         if (progress.userId != currentUserId) {
//           progress = progress.copyWith(userId: currentUserId);
//         }

//         // Somente atualiza se a missão não estiver COMPLETA E não tiver sido RESGATADA
//         if (!progress.isCompleted && !progress.isClaimed) {
//           // Lógica específica para LOGIN_DAILY para garantir que só conta uma vez por dia no progresso da missão
//           if (eventType == MissionEventTypes.LOGIN_DAILY) {
//             final now = DateTime.now();
//             if (progress.lastUpdateDate == null ||
//                 progress.lastUpdateDate!.day != now.day ||
//                 progress.lastUpdateDate!.month != now.month ||
//                 progress.lastUpdateDate!.year != now.year) {
//               // Cria uma nova instância de progress com os campos atualizados
//               progress = progress.copyWith(
//                 currentProgress: 1,
//                 lastUpdateDate: now,
//               );
//               stateChanged = true;
//             } else {
//               // Já logou hoje, não incrementa.
//               AppLogger.debug(
//                 'Evento LOGIN_DAILY já processado hoje para missão ${mission.id}. Nenhuma alteração no progresso.',
//               );
//               continue;
//             }
//           } else if (eventType == MissionEventTypes.VIEW_PROFILE_UNIQUE_TODAY) {
//             // Exemplo de lógica para evento que precisa de `details`
//             // Supondo que `details` conteria {'profileId': 'someProfileId'}
//             // Aqui você precisaria de uma lógica para rastrear os IDs únicos visitados no dia
//             // e só incrementar se o profileId for novo para hoje.
//             // Por simplicidade do mock, vamos apenas incrementar.
//             // Em um sistema real, o UserMissionProgress poderia ter um campo `Set<String> dailyUniqueEvents`
//             progress = progress.copyWith(
//               currentProgress: progress.currentProgress + 1,
//               lastUpdateDate:
//                   DateTime.now(), // Atualiza lastUpdateDate para qualquer progresso
//             );
//             stateChanged = true;
//           } else {
//             // Cria uma nova instância de progress com currentProgress incrementado
//             progress = progress.copyWith(
//               currentProgress: progress.currentProgress + 1,
//             );
//             stateChanged = true;
//           }

//           // Verifica se a missão foi concluída
//           final bool wasCompletedBefore = progress.isCompleted;
//           if (progress.currentProgress >= mission.criterion.targetCount) {
//             // Cria uma nova instância de progress com isCompleted = true, se ainda não estiver
//             if (!progress.isCompleted) {
//               progress = progress.copyWith(isCompleted: true);
//             }
//           }

//           // Se o estado de 'isCompleted' mudou para true, marca stateChanged.
//           if (progress.isCompleted && !wasCompletedBefore) {
//             stateChanged = true;
//             AppLogger.debug(
//               'Missão "${mission.title}" (${mission.id}) AGORA está completa! Progresso: ${progress.currentProgress}/${mission.criterion.targetCount}',
//             );
//           } else if (progress.isCompleted) {
//             AppLogger.debug(
//               'Missão "${mission.title}" (${mission.id}) já estava completa ou continua completa. Progresso: ${progress.currentProgress}/${mission.criterion.targetCount}',
//             );
//           }

//           if (stateChanged) {
//             currentProgressMap[mission.id] =
//                 progress; // Atualiza o progresso no mapa local
//             // A atualização do estado global (state.copyWith) será feita uma vez após o loop se houver mudanças.

//             await _missionRepository.updateMissionProgress(
//               progress,
//             ); // Persiste a mudança
//             AppLogger.debug(
//               'Progresso da missão ${mission.id} atualizado no repositório: ${progress.toString()}',
//             );

//             // Se a missão foi concluída, emite a recompensa (antes de ser resgatada)
//             if (progress.isCompleted && !progress.isClaimed) {
//               final user = _ref.read(authProvider).user;
//               if (user != null && user.uid == currentUserId) {
//                 await _ref
//                     .read(rewardsProvider.notifier)
//                     .grantMissionRewards(mission, user);
//                 AppLogger.debug(
//                   'Recompensa da missão "${mission.title}" registrada como pendente.',
//                 );
//               } else {
//                 AppLogger.error(
//                   'Usuário nulo ou ID divergente ao tentar conceder recompensa da missão ${mission.title}. User from Auth: ${user?.uid}, currentUserId for mission: $currentUserId',
//                 );
//               }
//             }
//           }
//         }
//       }
//     }
//     // Após o loop, se houve alguma mudança, atualiza o estado uma vez.
//     if (stateChanged) {
//       state = state.copyWith(
//         userProgress: Map<String, UserMissionProgress>.from(currentProgressMap),
//       );
//       AppLogger.debug(
//         'Estado do MissionsNotifier atualizado com novo progresso global.',
//       );
//     }
//   }

//   /// Permite ao usuário resgatar as recompensas de uma missão concluída.
//   ///
//   /// [missionId]: O ID da missão cujas recompensas serão resgatadas.
//   Future<void> claimMissionReward(String missionId) async {
//     // Usar o userId atual do AuthProvider
//     final currentUserId = _ref.read(authProvider).user?.uid;
//     AppLogger.debug(
//       'MissionsNotifier.claimMissionReward para missionId: $missionId. _userId (do construtor): $_userId, currentUserId (lido agora): $currentUserId',
//     );

//     if (currentUserId == null) {
//       AppLogger.info(
//         'Resgate de recompensa ignorado para $missionId. Usuário não autenticado (lido dinamicamente).',
//       );
//       return;
//     }

//     final progress = state.userProgress[missionId];
//     if (progress != null && progress.isCompleted && !progress.isClaimed) {
//       // Marca a recompensa como resgatada
//       // Cria uma nova instância de progress com isClaimed = true
//       final updatedProgress = progress.copyWith(isClaimed: true);
//       // Garante que newProgressMap seja uma nova instância do mapa
//       final newProgressMap = Map<String, UserMissionProgress>.from(
//         state.userProgress,
//       );
//       newProgressMap[missionId] = updatedProgress; // Usa a instância atualizada
//       state = state.copyWith(userProgress: newProgressMap);
//       await _missionRepository.updateMissionProgress(
//         updatedProgress, // Persiste a instância atualizada
//       ); // Persiste a mudança

//       // Aplica a recompensa real ao UserModel do usuário usando o RewardsService
//       final mission = state.availableMissions.firstWhere(
//         (m) => m.id == missionId,
//         orElse: () =>
//             throw Exception('Missão com ID $missionId não encontrada.'),
//       );

//       // CORREÇÃO: Chamar o RewardsNotifier para resgatar as recompensas pendentes
//       // associadas a esta missão, em vez de aplicar diretamente via RewardsService.
//       await _ref
//           .read(rewardsProvider.notifier)
//           .claimRewardsForCompletedMission(missionId, currentUserId);

//       print(
//         'DEBUG: Recompensa de "${mission.title}" resgatada e aplicada ao usuário.',
//       );
//     } else if (progress != null && !progress.isCompleted) {
//       print('INFO: Missão "${missionId}" ainda não concluída para resgate.');
//     } else if (progress != null && progress.isClaimed) {
//       print('INFO: Recompensa de "${missionId}" já foi resgatada.');
//     } else {
//       print(
//         'ERRO: Progresso da missão "${missionId}" não encontrado para resgate.',
//       );
//     }
//   }

//   /// Reinicia o progresso de missões diárias para o dia atual.
//   ///
//   /// NOTA: Em um sistema de produção, o reset de missões diárias/semanais
//   /// deve ser orquestrado e executado no backend (via cron jobs, por exemplo).
//   /// Este método é uma simulação para fins de desenvolvimento no cliente,
//   /// garantindo que as missões diárias fiquem disponíveis novamente.
//   Future<void> resetDailyMissions() async {
//     final currentUserId = _userId ?? _ref.read(authProvider).user?.uid;
//     if (currentUserId == null) return;
//     AppLogger.debug(
//       'Tentando resetar missões diárias para o usuário $currentUserId',
//     );
//     bool changed = false;
//     for (var mission in state.availableMissions) {
//       if (mission.type == MissionType.DAILY) {
//         await _missionRepository.resetDailyMissionProgress(
//           // Este método já verifica se é realmente um novo dia
//           currentUserId,
//           mission.id,
//         );
//         changed = true;
//       }
//     }
//     if (changed) {
//       // Re-busca todas as missões e progresso para sincronizar o estado
//       await _loadData();
//       AppLogger.debug(
//         'Reset de missões diárias concluído e estado re-carregado.',
//       );
//     }
//   }

//   Future<void> refresh() async {
//     AppLogger.debug('MissionsNotifier.refresh() chamado.');
//     final currentUserId = _userId ?? _ref.read(authProvider).user?.uid;
//     if (currentUserId != null) {
//       await _loadData(); // Chama _loadData em vez de _fetchMissionsAndProgress diretamente
//     } else {
//       AppLogger.debug(
//         'MissionsNotifier.refresh() ignorado, currentUserId é nulo.',
//       );
//     }
//   }

//   // Função mockada/exemplo para verificar se uma feature está desbloqueada.
//   // Adapte esta lógica para como seu jogo realmente controla o desbloqueio de features.
//   bool _isFeatureUnlocked(UserModel? user, String featureName) {
//     if (user == null) return false;

//     // Agora usa diretamente o campo unlockedFeatures do UserModel (após UserModel ser atualizado)
//     final isUnlocked = user.unlockedFeatures[featureName] ?? false;
//     if (!isUnlocked) {
//       AppLogger.debug(
//         'Feature "$featureName" NÃO está desbloqueada para o usuário ${user.uid}.',
//       );
//     }
//     return isUnlocked;
//   }
// }

// lib/features/missions/providers/missions_notifier.dart

import 'dart:async'; // Importar Completer
import 'dart:math'; // Para randomizar targetCount

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:unlock/core/constants/mission_constants.dart'; // Para templates de missão
import 'package:unlock/core/constants/mission_event_types.dart';
import 'package:unlock/core/utils/logger.dart';
import 'package:unlock/features/connections/services/connections_service.dart'; // Importar o novo serviço
import 'package:unlock/features/missions/models/mission.dart';
import 'package:unlock/features/missions/models/user_mission_progress.dart';
import 'package:unlock/features/missions/repositories/mission_repository.dart';
import 'package:unlock/features/missions/repositories/mission_repository_interface.dart'; // Importar a interface
import 'package:unlock/features/rewards/providers/rewards_provider.dart';
import 'package:unlock/features/rewards/services/rewards_service.dart';
import 'package:unlock/models/user_model.dart'; // Importar UserModel
import 'package:unlock/providers/auth_provider.dart'; // Importa o AuthProvider

/// Estado que o provedor MissionsNotifier irá gerenciar.
/// Contém a lista de missões disponíveis, o progresso do usuário em cada missão,
/// e o status de carregamento/erro.
class MissionsState {
  final List<Mission> availableMissions;
  // Correção: Inicializa userProgress com um mapa vazio do tipo correto
  final Map<String, UserMissionProgress> userProgress; // Chave: missionId
  final bool isLoading;
  final String? error;

  MissionsState({
    this.availableMissions = const [],
    // Garante que o mapa padrão seja do tipo correto
    Map<String, UserMissionProgress>? userProgress,
    this.isLoading = false,
    this.error,
  }) : userProgress =
           userProgress ??
           const {}; // Usa const {} para um mapa vazio e imutável do tipo inferido

  /// Permite criar uma nova instância de MissionsState com campos atualizados.
  MissionsState copyWith({
    List<Mission>? availableMissions,
    Map<String, UserMissionProgress>? userProgress, // Parameter type
    bool? isLoading,
    String? error,
  }) {
    return MissionsState(
      availableMissions: availableMissions ?? this.availableMissions,
      // Correção: Torna a cópia do mapa explícita para o tipo correto.
      // Se userProgress for nulo, cria um novo mapa a partir do existente.
      userProgress:
          userProgress ??
          Map<String, UserMissionProgress>.from(this.userProgress),
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// Provedor principal para o sistema de missões.
///
/// Gerencia o estado das missões, o progresso do usuário e a lógica de conclusão/recompensa.
final missionsProvider = StateNotifierProvider<MissionsNotifier, MissionsState>((
  ref,
) {
  final userId = ref
      .watch(authProvider)
      .user
      ?.uid; // Obtém o ID do usuário logado

  // Se não há usuário logado, retorna um MissionsNotifier que não carregará dados
  // ou um estado de erro, dependendo da sua preferência para usuários não logados.
  if (userId == null) {
    print(
      'DEBUG: MissionsNotifier inicializado sem userId. Não carregará missões.',
    );
    return MissionsNotifier(ref, null);
  }
  return MissionsNotifier(ref, userId);
});

/// StateNotifier responsável por gerenciar o estado das missões.
class MissionsNotifier extends StateNotifier<MissionsState> {
  final Ref _ref;
  final String? _userId; // O ID do usuário logado (pode ser nulo se não logado)
  late final IMissionRepository // Usar a interface
  _missionRepository; // Repositório para acesso a dados
  late final RewardsService _rewardsService; // Serviço para aplicar recompensas
  final Completer<void> _initialLoadCompleter =
      Completer<void>(); // Para sincronização

  MissionsNotifier(this._ref, this._userId) : super(MissionsState()) {
    _missionRepository = _ref.read(missionRepositoryProvider);
    _rewardsService = _ref.read(rewardsServiceProvider);

    // Carrega as missões e o progresso se houver um usuário logado
    if (_userId != null) {
      _loadData();
    } else {
      // Se não há usuário, o carregamento inicial é considerado completo (não há o que carregar).
      if (!_initialLoadCompleter.isCompleted) {
        _initialLoadCompleter.complete();
      }
    }
  }

  /// Carrega as missões ativas e o progresso do usuário a partir do repositório.
  Future<void> _loadData() async {
    // Usar o userId mais recente do AuthProvider, embora _userId deva estar correto aqui
    // devido à recriação do notifier quando authProvider muda.
    final currentUserId = _userId ?? _ref.read(authProvider).user?.uid;

    if (currentUserId == null) {
      state = state.copyWith(
        error: 'Usuário não autenticado para carregar missões.',
        isLoading: false, // Garante que isLoading seja false
      );
      if (!_initialLoadCompleter.isCompleted) _initialLoadCompleter.complete();
      return;
    }

    state = state.copyWith(isLoading: true, error: null);
    try {
      // 1. Carregar missões ONE_TIME e EVENT (ou outras fixas) do repositório
      final fixedMissions = await _missionRepository.getActiveMissions();
      final List<Mission> allAvailableMissions = List.from(fixedMissions);

      // Correção: Garante que progressMap é do tipo correto desde o início
      final Map<String, UserMissionProgress> progressMap = {};

      // Obter dados do usuário atual para verificar requisitos
      final UserModel? currentUserModel = _ref.read(authProvider).user;

      // 2. "Gerar" missões diárias a partir dos templates
      final random = Random();
      final List<Map<String, dynamic>> dailyTemplates = List.from(
        MissionConstants.dailyMissionTemplates,
      );
      dailyTemplates.shuffle(
        random,
      ); // Embaralha para pegar diferentes a cada "dia" (simulado)

      final List<Mission> generatedDailyMissions = [];
      for (
        int i = 0;
        i < MissionConstants.dailyMissionsCount && i < dailyTemplates.length;
        i++
      ) {
        final template = dailyTemplates[i];

        // >>> INÍCIO DA LÓGICA DE VERIFICAÇÃO DE REQUISITOS <<<
        bool meetsAllRequirements = true;
        final List<Map<String, dynamic>> requirements =
            (template['requirements'] as List<dynamic>?)
                ?.map((e) => e as Map<String, dynamic>)
                .toList() ??
            [];

        if (currentUserModel != null && requirements.isNotEmpty) {
          for (var req in requirements) {
            final String reqType = req['type'] as String;
            final dynamic reqValue = req['value'];

            if (reqType == 'level') {
              if (currentUserModel.level < (reqValue as int)) {
                meetsAllRequirements = false;
                AppLogger.debug(
                  'Usuário não cumpre requisito de NÍVEL para "${template['title']}". Nível: ${currentUserModel.level}, Requerido: $reqValue',
                );
                break;
              }
            } else if (reqType == 'connections') {
              // Agora usa o ConnectionsService
              final connectionsService = _ref.read(connectionsServiceProvider);
              int userConnections = await connectionsService
                  .getConnectionsCount(currentUserModel.uid);
              if (userConnections < (reqValue as int)) {
                meetsAllRequirements = false;
                AppLogger.debug(
                  'Usuário não cumpre requisito de CONEXÕES para "${template['title']}". Conexões: $userConnections, Requerido: $reqValue',
                );
                break;
              }
            } else if (reqType == 'mission_completed') {
              final String requiredMissionId = reqValue as String;
              // Precisamos buscar o progresso desta missão específica.
              // Nota: Se a missão requerida ainda não foi carregada/gerada, esta verificação pode falhar.
              // Idealmente, as missões 'ONE_TIME' que são pré-requisitos já estariam em `fixedMissions`.
              final requiredMissionProgress = await _missionRepository
                  .getMissionProgress(currentUserId, requiredMissionId);
              if (!requiredMissionProgress.isCompleted ||
                  !requiredMissionProgress.isClaimed) {
                // Ou apenas isCompleted
                meetsAllRequirements = false;
                AppLogger.debug(
                  'Usuário não cumpre requisito de MISSÃO COMPLETADA ("$requiredMissionId") para "${template['title']}".',
                );
                break;
              }
            } else if (reqType == 'feature_unlocked') {
              final String featureName = reqValue as String;
              if (!_isFeatureUnlocked(currentUserModel, featureName)) {
                meetsAllRequirements = false;
                AppLogger.debug(
                  'Usuário não cumpre requisito de FEATURE DESBLOQUEADA ("$featureName") para "${template['title']}".',
                );
                break;
              }
            }
            // Adicionar mais tipos de requisitos aqui (ex: 'feature_unlocked')
          }
        }

        if (!meetsAllRequirements) {
          AppLogger.debug(
            'Missão "${template['title']}" pulada devido a requisitos não cumpridos.',
          );
          continue; // Pula para o próximo template de missão
        }
        // >>> FIM DA LÓGICA DE VERIFICAÇÃO DE REQUISITOS <<<

        // Evitar duplicar a missão de LOGIN_DAILY se ela já vem do _allMissions
        if (template['eventType'] == MissionEventTypes.LOGIN_DAILY &&
            fixedMissions.any(
              (m) =>
                  m.criterion.eventType == MissionEventTypes.LOGIN_DAILY &&
                  m.type == MissionType.DAILY,
            )) {
          AppLogger.debug(
            "Missão de Login Diário já existe nas missões fixas, pulando template.",
          );
          continue;
        }

        final targetCountRange = template['targetCountRange'] as List<int>;
        final targetCount =
            targetCountRange[0] +
            (targetCountRange.length > 1
                ? random.nextInt(targetCountRange[1] - targetCountRange[0] + 1)
                : 0);

        final description = (template['description_template'] as String)
            .replaceAll('{targetCount}', targetCount.toString());

        final rewardMap = template['reward'] as Map<String, int>;

        // Gerar um ID único para a instância da missão diária
        // Para mock, podemos usar o id_template + um sufixo simples. Em produção, seria mais robusto.
        final missionId =
            '${template['id_template']}_${currentUserId.substring(0, 5)}_${DateTime.now().millisecondsSinceEpoch}_$i';

        final dailyMission = Mission(
          id: missionId,
          title: template['title'] as String,
          description: description,
          category:
              template['category'] as String? ??
              'Outras', // Incluir categoria do template
          type: MissionType.DAILY, // Definido como diária
          criterion: MissionCriterion(
            eventType: template['eventType'] as String,
            targetCount: targetCount,
          ),
          reward: MissionReward(
            xp: rewardMap['xp'] ?? 0,
            coins: rewardMap['coins'] ?? 0,
            gems: rewardMap['gems'] ?? 0,
          ),
        );
        generatedDailyMissions.add(dailyMission);
      }
      allAvailableMissions.addAll(generatedDailyMissions);

      // Para cada missão (fixa ou gerada), busca/reseta o progresso.
      for (var mission in allAvailableMissions) {
        final progress = await _missionRepository.getMissionProgress(
          currentUserId,
          mission.id,
        );
        progressMap[mission.id] = progress;

        // Lógica para resetar missões diárias automaticamente ao carregar, se necessário.
        // O ideal é que isso seja orquestrado pelo backend, mas aqui é uma simulação.
        if (mission.type == MissionType.DAILY) {
          UserMissionProgress currentMissionProgress =
              progress; // Usar uma variável local
          final now = DateTime.now();
          if (currentMissionProgress.lastUpdateDate == null ||
              currentMissionProgress.lastUpdateDate!.day != now.day ||
              currentMissionProgress.lastUpdateDate!.month != now.month ||
              currentMissionProgress.lastUpdateDate!.year != now.year) {
            // Se a última atualização não foi hoje, reseta a missão.
            await _missionRepository.resetDailyMissionProgress(
              currentUserId,
              mission.id,
            );
            // Atualiza a variável local com o progresso resetado
            currentMissionProgress = await _missionRepository
                .getMissionProgress(currentUserId, mission.id);
            progressMap[mission.id] =
                currentMissionProgress; // Atualiza o mapa principal
            print(
              'DEBUG: Missão diária ${mission.title} (${mission.id}) resetada no cliente.',
            );
          }
        }
      }
      state = state.copyWith(
        availableMissions: allAvailableMissions,
        userProgress: progressMap,
        isLoading: false,
      );
      print('DEBUG: Missões e progresso carregados com sucesso.');
    } catch (e, stackTrace) {
      // Adicionar stackTrace para melhor debugging
      state = state.copyWith(error: e.toString(), isLoading: false);
      AppLogger.error(
        'ERRO: Erro ao carregar missões',
        error: e,
        stackTrace: stackTrace,
      );
    } finally {
      // Garante que o completer seja finalizado mesmo em caso de erro.
      if (!_initialLoadCompleter.isCompleted) {
        _initialLoadCompleter.complete();
      }
    }
  }

  /// Reporta um evento de ação que pode afetar o progresso das missões.
  ///
  /// [eventType]: A string que identifica o tipo de evento (ex: 'LOGIN_DIARIO', 'LIKE_PROFILE').
  /// [details]: Um mapa opcional com detalhes adicionais do evento.
  Future<void> reportMissionEvent(
    String eventType, {
    Map<String, dynamic>? details,
  }) async {
    // Espera o carregamento inicial ter sido concluído
    await _initialLoadCompleter.future;

    // Obter o userId mais atualizado do AuthProvider no momento da chamada.
    final currentUserId = _ref.read(authProvider).user?.uid;
    AppLogger.debug(
      'MissionsNotifier.reportMissionEvent para eventType: $eventType. _userId (do construtor): $_userId, currentUserId (lido agora): $currentUserId',
    );

    if (currentUserId == null) {
      AppLogger.info(
        'Evento $eventType ignorado. Usuário não autenticado (currentUserId é nulo).',
      );
      return;
    }

    // Garante que currentProgressMap seja uma nova instância baseada no estado atual.
    final currentProgressMap = Map<String, UserMissionProgress>.from(
      state.userProgress,
    );
    bool stateChanged = false;

    // Itera sobre as missões disponíveis para ver quais são afetadas pelo evento
    for (var mission in state.availableMissions) {
      if (mission.criterion.eventType == eventType) {
        // Usa currentUserId para buscar ou criar o progresso.
        UserMissionProgress progress =
            currentProgressMap[mission.id] ??
            UserMissionProgress(userId: currentUserId, missionId: mission.id);

        // Garante que o progresso tenha o userId mais atualizado.
        if (progress.userId != currentUserId) {
          progress = progress.copyWith(userId: currentUserId);
        }

        // Somente atualiza se a missão não estiver COMPLETA E não tiver sido RESGATADA
        if (!progress.isCompleted && !progress.isClaimed) {
          // Lógica específica para LOGIN_DAILY para garantir que só conta uma vez por dia no progresso da missão
          if (eventType == MissionEventTypes.LOGIN_DAILY) {
            final now = DateTime.now();
            if (progress.lastUpdateDate == null ||
                progress.lastUpdateDate!.day != now.day ||
                progress.lastUpdateDate!.month != now.month ||
                progress.lastUpdateDate!.year != now.year) {
              // Cria uma nova instância de progress com os campos atualizados
              progress = progress.copyWith(
                currentProgress: 1,
                lastUpdateDate: now,
              );
              stateChanged = true;
            } else {
              // Já logou hoje, não incrementa.
              AppLogger.debug(
                'Evento LOGIN_DAILY já processado hoje para missão ${mission.id}. Nenhuma alteração no progresso.',
              );
              continue;
            }
          } else if (eventType == MissionEventTypes.VIEW_PROFILE_UNIQUE_TODAY) {
            // Exemplo de lógica para evento que precisa de `details`
            // Supondo que `details` conteria {'profileId': 'someProfileId'}
            // Aqui você precisaria de uma lógica para rastrear os IDs únicos visitados no dia
            // e só incrementar se o profileId for novo para hoje.
            // Por simplicidade do mock, vamos apenas incrementar.
            // Em um sistema real, o UserMissionProgress poderia ter um campo `Set<String> dailyUniqueEvents`
            progress = progress.copyWith(
              currentProgress: progress.currentProgress + 1,
              lastUpdateDate:
                  DateTime.now(), // Atualiza lastUpdateDate para qualquer progresso
            );
            stateChanged = true;
          } else {
            // Cria uma nova instância de progress com currentProgress incrementado
            progress = progress.copyWith(
              currentProgress: progress.currentProgress + 1,
            );
            stateChanged = true;
          }

          // Verifica se a missão foi concluída
          final bool wasCompletedBefore = progress.isCompleted;
          if (progress.currentProgress >= mission.criterion.targetCount) {
            // Cria uma nova instância de progress com isCompleted = true, se ainda não estiver
            if (!progress.isCompleted) {
              progress = progress.copyWith(isCompleted: true);
            }
          }

          // Se o estado de 'isCompleted' mudou para true, marca stateChanged.
          if (progress.isCompleted && !wasCompletedBefore) {
            stateChanged = true;
            AppLogger.debug(
              'Missão "${mission.title}" (${mission.id}) AGORA está completa! Progresso: ${progress.currentProgress}/${mission.criterion.targetCount}',
            );
          } else if (progress.isCompleted) {
            AppLogger.debug(
              'Missão "${mission.title}" (${mission.id}) já estava completa ou continua completa. Progresso: ${progress.currentProgress}/${mission.criterion.targetCount}',
            );
          }

          if (stateChanged) {
            currentProgressMap[mission.id] =
                progress; // Atualiza o progresso no mapa local
            // A atualização do estado global (state.copyWith) será feita uma vez após o loop se houver mudanças.

            await _missionRepository.updateMissionProgress(
              progress,
            ); // Persiste a mudança
            AppLogger.debug(
              'Progresso da missão ${mission.id} atualizado no repositório: ${progress.toString()}',
            );

            // Se a missão foi concluída, emite a recompensa (antes de ser resgatada)
            if (progress.isCompleted && !progress.isClaimed) {
              final user = _ref.read(authProvider).user;
              if (user != null && user.uid == currentUserId) {
                await _ref
                    .read(rewardsProvider.notifier)
                    .grantMissionRewards(mission, user);
                AppLogger.debug(
                  'Recompensa da missão "${mission.title}" registrada como pendente.',
                );
              } else {
                AppLogger.error(
                  'Usuário nulo ou ID divergente ao tentar conceder recompensa da missão ${mission.title}. User from Auth: ${user?.uid}, currentUserId for mission: $currentUserId',
                );
              }
            }
          }
        }
      }
    }
    // Após o loop, se houve alguma mudança, atualiza o estado uma vez.
    if (stateChanged) {
      state = state.copyWith(
        userProgress: Map<String, UserMissionProgress>.from(currentProgressMap),
      );
      AppLogger.debug(
        'Estado do MissionsNotifier atualizado com novo progresso global.',
      );
    }
  }

  /// Permite ao usuário resgatar as recompensas de uma missão concluída.
  ///
  /// [missionId]: O ID da missão cujas recompensas serão resgatadas.
  Future<void> claimMissionReward(String missionId) async {
    // Usar o userId atual do AuthProvider
    final currentUserId = _ref.read(authProvider).user?.uid;
    AppLogger.debug(
      'MissionsNotifier.claimMissionReward para missionId: $missionId. _userId (do construtor): $_userId, currentUserId (lido agora): $currentUserId',
    );

    if (currentUserId == null) {
      AppLogger.info(
        'Resgate de recompensa ignorado para $missionId. Usuário não autenticado (lido dinamicamente).',
      );
      return;
    }

    final progress = state.userProgress[missionId];
    if (progress != null && progress.isCompleted && !progress.isClaimed) {
      // Marca a recompensa como resgatada
      // Cria uma nova instância de progress com isClaimed = true
      final updatedProgress = progress.copyWith(isClaimed: true);
      // Garante que newProgressMap seja uma nova instância do mapa
      final newProgressMap = Map<String, UserMissionProgress>.from(
        state.userProgress,
      );
      newProgressMap[missionId] = updatedProgress; // Usa a instância atualizada
      state = state.copyWith(userProgress: newProgressMap);
      await _missionRepository.updateMissionProgress(
        updatedProgress, // Persiste a instância atualizada
      ); // Persiste a mudança

      // Aplica a recompensa real ao UserModel do usuário usando o RewardsService
      final mission = state.availableMissions.firstWhere(
        (m) => m.id == missionId,
        orElse: () =>
            throw Exception('Missão com ID $missionId não encontrada.'),
      );

      // CORREÇÃO: Chamar o RewardsNotifier para resgatar as recompensas pendentes
      // associadas a esta missão, em vez de aplicar diretamente via RewardsService.
      await _ref
          .read(rewardsProvider.notifier)
          .claimRewardsForCompletedMission(missionId, currentUserId);

      print(
        'DEBUG: Recompensa de "${mission.title}" resgatada e aplicada ao usuário.',
      );
    } else if (progress != null && !progress.isCompleted) {
      print('INFO: Missão "${missionId}" ainda não concluída para resgate.');
    } else if (progress != null && progress.isClaimed) {
      print('INFO: Recompensa de "${missionId}" já foi resgatada.');
    } else {
      print(
        'ERRO: Progresso da missão "${missionId}" não encontrado para resgate.',
      );
    }
  }

  /// Reinicia o progresso de missões diárias para o dia atual.
  ///
  /// NOTA: Em um sistema de produção, o reset de missões diárias/semanais
  /// deve ser orquestrado e executado no backend (via cron jobs, por exemplo).
  /// Este método é uma simulação para fins de desenvolvimento no cliente,
  /// garantindo que as missões diárias fiquem disponíveis novamente.
  Future<void> resetDailyMissions() async {
    final currentUserId = _userId ?? _ref.read(authProvider).user?.uid;
    if (currentUserId == null) return;
    AppLogger.debug(
      'Tentando resetar missões diárias para o usuário $currentUserId',
    );
    bool changed = false;
    for (var mission in state.availableMissions) {
      if (mission.type == MissionType.DAILY) {
        await _missionRepository.resetDailyMissionProgress(
          // Este método já verifica se é realmente um novo dia
          currentUserId,
          mission.id,
        );
        changed = true;
      }
    }
    if (changed) {
      // Re-busca todas as missões e progresso para sincronizar o estado
      await _loadData();
      AppLogger.debug(
        'Reset de missões diárias concluído e estado re-carregado.',
      );
    }
  }

  Future<void> refresh() async {
    AppLogger.debug('MissionsNotifier.refresh() chamado.');
    final currentUserId = _userId ?? _ref.read(authProvider).user?.uid;
    if (currentUserId != null) {
      await _loadData(); // Chama _loadData em vez de _fetchMissionsAndProgress diretamente
    } else {
      AppLogger.debug(
        'MissionsNotifier.refresh() ignorado, currentUserId é nulo.',
      );
    }
  }

  // Função mockada/exemplo para verificar se uma feature está desbloqueada.
  // Adapte esta lógica para como seu jogo realmente controla o desbloqueio de features.
  bool _isFeatureUnlocked(UserModel? user, String featureName) {
    if (user == null) return false;

    // Agora usa diretamente o campo unlockedFeatures do UserModel (após UserModel ser atualizado)
    final isUnlocked = user.unlockedFeatures[featureName] ?? false;
    if (!isUnlocked) {
      AppLogger.debug(
        'Feature "$featureName" NÃO está desbloqueada para o usuário ${user.uid}.',
      );
    }
    return isUnlocked;
  }
}
