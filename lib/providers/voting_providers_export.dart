// lib/providers/voting_providers_export.dart
// Arquivo de exportação central para todos os providers de votação

// Providers específicos que podem estar faltando
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:unlock/core/utils/logger.dart';
import 'package:unlock/providers/auth_provider.dart';
import 'package:unlock/services/voting_service.dart';

export 'package:unlock/models/challenge_model.dart';
export 'package:unlock/models/submission_model.dart';
// Re-exportar modelos necessários
export 'package:unlock/models/vote_model.dart';
export 'package:unlock/services/challenge_service.dart';
// Re-exportar serviços
export 'package:unlock/services/voting_service.dart';

// Re-exportar providers do arquivo principal
export 'voting_provider.dart';

// Provider adicional para garantir que challengeStatisticsProvider existe
final challengeStatisticsProvider =
    FutureProvider.family<Map<String, dynamic>, String>((ref, challengeId) {
      AppLogger.debug('📊 Carregando estatísticas do desafio: $challengeId');
      return VotingService.getAggregatedVotingStats(challengeId);
    });

// Provider para verificar conexão (útil para funcionalidades offline)
final connectionStatusProvider = StateProvider<bool>((ref) => true);

// Provider para configurações de votação globais
final votingConfigProvider = StateProvider<Map<String, dynamic>>(
  (ref) => {
    'enableOfflineVoting': false,
    'maxCachedVotes': 50,
    'syncInterval': 30, // segundos
    'enablePushNotifications': true,
  },
);

// Provider para cache de votos offline
final offlineVotesProvider = StateProvider<List<Map<String, dynamic>>>(
  (ref) => [],
);

// Provider helper para debug
final votingDebugProvider = Provider<Map<String, dynamic>>((ref) {
  final user = ref.watch(authProvider.select((state) => state.user));
  final config = ref.watch(votingConfigProvider);
  final isOnline = ref.watch(connectionStatusProvider);

  return {
    'user_authenticated': user != null,
    'user_id': user?.uid,
    'is_online': isOnline,
    'config': config,
    'timestamp': DateTime.now().toIso8601String(),
  };
});

// Provider para limpar cache quando necessário
final votingCacheProvider =
    StateNotifierProvider<VotingCacheNotifier, Map<String, dynamic>>((ref) {
      return VotingCacheNotifier();
    });

class VotingCacheNotifier extends StateNotifier<Map<String, dynamic>> {
  VotingCacheNotifier() : super({});

  void clearCache() {
    state = {};
    AppLogger.debug('🧹 Cache de votação limpo');
  }

  void addToCache(String key, dynamic value) {
    state = {...state, key: value};
  }

  T? getFromCache<T>(String key) {
    return state[key] as T?;
  }
}
