// lib/providers/unlock_matching_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:unlock/enums/enums.dart';
import 'package:unlock/models/affinity_test_model.dart';
import 'package:unlock/models/unlock_match_model.dart';
import 'package:unlock/models/user_model.dart';
import 'package:unlock/services/unlock_matching_service.dart';
import 'package:uuid/uuid.dart';

// ================================================================
// ESTADOS
// ================================================================

class MatchingState {
  final List<UnlockMatchModel> potentialMatches;
  final List<UnlockMatchModel> activeMatches;
  final List<UnlockMatchModel> unlockedMatches;
  final UnlockMatchModel? currentMatch;
  final AffinityTestModel? currentTest;
  final bool isLoading;
  final bool isTakingTest;
  final String? error;
  final DateTime? testStartTime;
  final int dailyMatchesUsed;
  final int maxDailyMatches;

  const MatchingState({
    this.potentialMatches = const [],
    this.activeMatches = const [],
    this.unlockedMatches = const [],
    this.currentMatch,
    this.currentTest,
    this.isLoading = false,
    this.isTakingTest = false,
    this.error,
    this.testStartTime,
    this.dailyMatchesUsed = 0,
    this.maxDailyMatches = 5,
  });

  MatchingState copyWith({
    List<UnlockMatchModel>? potentialMatches,
    List<UnlockMatchModel>? activeMatches,
    List<UnlockMatchModel>? unlockedMatches,
    UnlockMatchModel? currentMatch,
    AffinityTestModel? currentTest,
    bool? isLoading,
    bool? isTakingTest,
    String? error,
    DateTime? testStartTime,
    int? dailyMatchesUsed,
    int? maxDailyMatches,
  }) {
    return MatchingState(
      potentialMatches: potentialMatches ?? this.potentialMatches,
      activeMatches: activeMatches ?? this.activeMatches,
      unlockedMatches: unlockedMatches ?? this.unlockedMatches,
      currentMatch: currentMatch ?? this.currentMatch,
      currentTest: currentTest ?? this.currentTest,
      isLoading: isLoading ?? this.isLoading,
      isTakingTest: isTakingTest ?? this.isTakingTest,
      error: error,
      testStartTime: testStartTime ?? this.testStartTime,
      dailyMatchesUsed: dailyMatchesUsed ?? this.dailyMatchesUsed,
      maxDailyMatches: maxDailyMatches ?? this.maxDailyMatches,
    );
  }

  // Getters de conveniência
  bool get canCreateNewMatches => dailyMatchesUsed < maxDailyMatches;
  bool get hasActiveTests => activeMatches.any((match) => match.canTakeTests);
  int get totalUnlocked => unlockedMatches.length;
  int get totalActive => activeMatches.length;
}

// ================================================================
// NOTIFIER
// ================================================================

class UnlockMatchingNotifier extends StateNotifier<MatchingState> {
  UnlockMatchingNotifier() : super(const MatchingState());

  // ================================================================
  // DISCOVERY E MATCHING
  // ================================================================

  /// Busca matches potenciais para o usuário
  Future<void> findPotentialMatches(UserModel currentUser) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      // Buscar usuários mock para demonstração
      // Em produção, viria do Firestore
      final allUsers = _getMockUsers();

      // Gerar matches usando o algoritmo
      final potentialMatches = UnlockMatchingService.findPotentialMatches(
        currentUser,
        allUsers,
        limit: 10,
      );

      state = state.copyWith(
        potentialMatches: potentialMatches,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Erro ao buscar matches: $e',
      );
    }
  }

  /// Inicia um novo match com teste de afinidade
  Future<void> startMatch(String targetUserId) async {
    if (!state.canCreateNewMatches) {
      state = state.copyWith(error: 'Limite diário de matches atingido');
      return;
    }

    state = state.copyWith(isLoading: true, error: null);

    try {
      // Encontrar o match potencial
      final potentialMatch = state.potentialMatches.firstWhere(
        (match) => match.targetUserId == targetUserId,
        orElse: () => throw Exception('Match não encontrado'),
      );

      // Criar match ativo
      final activeMatch = potentialMatch.copyWith(
        status: MatchStatus.testing,
        id: const Uuid().v4(),
      );

      // Buscar dados do usuário alvo (mock)
      final targetUser = _getMockUserById(targetUserId);
      if (targetUser == null) {
        throw Exception('Usuário alvo não encontrado');
      }

      // Gerar primeiro teste
      final firstTest = UnlockMatchingService.generateAffinityTest(
        activeMatch,
        targetUser,
      );

      // Atualizar estado
      final updatedActiveMatches = [...state.activeMatches, activeMatch];
      final updatedPotentialMatches = state.potentialMatches
          .where((match) => match.targetUserId != targetUserId)
          .toList();

      state = state.copyWith(
        activeMatches: updatedActiveMatches,
        potentialMatches: updatedPotentialMatches,
        currentMatch: activeMatch,
        currentTest: firstTest,
        isLoading: false,
        dailyMatchesUsed: state.dailyMatchesUsed + 1,
      );

      // Salvar no Firestore (implementar depois)
      // await _saveMatchToFirestore(activeMatch);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Erro ao iniciar match: $e',
      );
    }
  }

  // ================================================================
  // SISTEMA DE TESTES
  // ================================================================

  /// Inicia um teste de afinidade
  Future<void> startAffinityTest(String matchId) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      // Encontrar o match
      final match = state.activeMatches.firstWhere(
        (m) => m.id == matchId,
        orElse: () => throw Exception('Match não encontrado'),
      );

      // Buscar dados do usuário alvo
      final targetUser = _getMockUserById(match.targetUserId);
      if (targetUser == null) {
        throw Exception('Usuário alvo não encontrado');
      }

      // Gerar teste
      final test = UnlockMatchingService.generateAffinityTest(
        match,
        targetUser,
      );

      state = state.copyWith(
        currentMatch: match,
        currentTest: test,
        isTakingTest: true,
        testStartTime: DateTime.now(),
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Erro ao iniciar teste: $e',
      );
    }
  }

  /// Submete resposta do teste
  Future<void> submitTestAnswer(String answer) async {
    if (state.currentTest == null ||
        state.currentMatch == null ||
        state.testStartTime == null) {
      state = state.copyWith(error: 'Teste não iniciado corretamente');
      return;
    }

    state = state.copyWith(isLoading: true);

    try {
      final timeSpent = DateTime.now().difference(state.testStartTime!);

      // Avaliar resposta
      final evaluatedTest = UnlockMatchingService.evaluateTestAnswer(
        state.currentTest!,
        answer,
        timeSpent,
      );

      // Atualizar match com o teste completado
      final updatedTests = [
        ...state.currentMatch!.completedTests,
        evaluatedTest,
      ];
      final updatedMatch = state.currentMatch!.copyWith(
        completedTests: updatedTests,
      );

      // Verificar se pode desbloquear
      final canUnlock = UnlockMatchingService.canUnlockMatch(updatedMatch);
      final finalMatch = canUnlock
          ? UnlockMatchingService.unlockMatch(updatedMatch)
          : updatedMatch;

      // Atualizar listas
      final updatedActiveMatches = state.activeMatches
          .map((match) => match.id == finalMatch.id ? finalMatch : match)
          .toList();

      List<UnlockMatchModel> updatedUnlockedMatches = state.unlockedMatches;
      if (finalMatch.isUnlocked) {
        updatedUnlockedMatches = [...state.unlockedMatches, finalMatch];
      }

      state = state.copyWith(
        activeMatches: updatedActiveMatches,
        unlockedMatches: updatedUnlockedMatches,
        currentTest: null,
        isTakingTest: false,
        testStartTime: null,
        isLoading: false,
      );

      // Salvar progresso no Firestore
      // await _updateMatchInFirestore(finalMatch);

      // Mostrar resultado do unlock se conseguiu
      if (finalMatch.isUnlocked && !state.currentMatch!.isUnlocked) {
        _showUnlockSuccess(finalMatch);
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Erro ao submeter resposta: $e',
      );
    }
  }

  /// Pula o teste atual (com penalidade)
  Future<void> skipCurrentTest() async {
    if (state.currentTest == null || state.currentMatch == null) {
      return;
    }

    // Submeter com resposta vazia (recebe score mínimo)
    await submitTestAnswer('');
  }

  // ================================================================
  // GERENCIAMENTO DE MATCHES
  // ================================================================

  /// Remove um match (desistir)
  Future<void> removeMatch(String matchId) async {
    final updatedActiveMatches = state.activeMatches
        .where((match) => match.id != matchId)
        .toList();

    state = state.copyWith(activeMatches: updatedActiveMatches);

    // Remover do Firestore
    // await _removeMatchFromFirestore(matchId);
  }

  /// Obtém detalhes de um match específico
  UnlockMatchModel? getMatchById(String matchId) {
    // Buscar em todas as listas
    try {
      return state.activeMatches.firstWhere((match) => match.id == matchId);
    } catch (e) {
      try {
        return state.unlockedMatches.firstWhere((match) => match.id == matchId);
      } catch (e) {
        return null;
      }
    }
  }

  /// Obtém próximo teste disponível para um match
  Future<AffinityTestModel?> getNextTestForMatch(String matchId) async {
    final match = getMatchById(matchId);
    if (match == null || !match.canTakeTests) return null;

    final targetUser = _getMockUserById(match.targetUserId);
    if (targetUser == null) return null;

    return UnlockMatchingService.generateAffinityTest(match, targetUser);
  }

  // ================================================================
  // ESTATÍSTICAS E DADOS
  // ================================================================

  /// Obtém estatísticas do usuário
  Map<String, dynamic> getUserMatchingStats() {
    final totalScore = state.unlockedMatches.fold<int>(
      0,
      (sum, match) =>
          sum + UnlockMatchingService.calculateTotalMatchScore(match),
    );

    final avgScore = state.unlockedMatches.isNotEmpty
        ? totalScore / state.unlockedMatches.length
        : 0.0;

    return {
      'totalMatches': state.totalActive + state.totalUnlocked,
      'unlockedMatches': state.totalUnlocked,
      'activeMatches': state.totalActive,
      'averageScore': avgScore.round(),
      'dailyMatchesUsed': state.dailyMatchesUsed,
      'dailyMatchesRemaining': state.maxDailyMatches - state.dailyMatchesUsed,
      'successRate': state.totalActive > 0
          ? (state.totalUnlocked / (state.totalActive + state.totalUnlocked)) *
                100
          : 0.0,
    };
  }

  /// Reset diário dos matches
  void resetDailyMatches() {
    state = state.copyWith(dailyMatchesUsed: 0);
  }

  // ================================================================
  // MÉTODOS AUXILIARES E MOCK DATA
  // ================================================================

  void _showUnlockSuccess(UnlockMatchModel match) {
    // Implementar notificação de sucesso
    // Pode ser um callback ou event bus
    print('🎉 Perfil desbloqueado: ${match.targetCodinome}');
  }

  /// Dados mock para demonstração
  List<UserModel> _getMockUsers() {
    // Retornar lista de usuários mock
    // Em produção, vem do Firestore
    return [
      UserModel(
        uid: 'user_1',
        username: 'ana_star',
        displayName: 'Ana',
        email: 'ana@example.com',
        codinome: 'Estrela',
        interesses: ['Música', 'Viagens', 'Arte'],
        relationshipInterest: 'namoro',
        onboardingCompleted: true,
        level: 3,
        xp: 250,
        coins: 150,
        gems: 5,
        createdAt: DateTime.now().subtract(const Duration(days: 30)),
        lastLoginAt: DateTime.now().subtract(const Duration(hours: 2)),
        avatar: '',
        aiConfig: {},
      ),
      UserModel(
        uid: 'user_2',
        username: 'carlos_bolt',
        displayName: 'Carlos',
        email: 'carlos@example.com',
        codinome: 'Raio',
        interesses: ['Tecnologia', 'Jogos', 'Música'],
        relationshipInterest: 'amizade',
        onboardingCompleted: true,
        level: 5,
        xp: 450,
        coins: 300,
        gems: 12,
        createdAt: DateTime.now().subtract(const Duration(days: 45)),
        lastLoginAt: DateTime.now().subtract(const Duration(minutes: 15)),
        avatar: '',
        aiConfig: {},
      ),
      UserModel(
        uid: 'user_3',
        username: 'sofia_palette',
        displayName: 'Sofia',
        email: 'sofia@example.com',
        codinome: 'Artista',
        interesses: ['Arte', 'Leitura', 'Natureza'],
        relationshipInterest: 'casual',
        onboardingCompleted: true,
        level: 4,
        xp: 380,
        coins: 220,
        gems: 8,
        createdAt: DateTime.now().subtract(const Duration(days: 20)),
        lastLoginAt: DateTime.now().subtract(const Duration(hours: 1)),
        avatar: '',
        aiConfig: {},
      ),
    ];
  }

  UserModel? _getMockUserById(String userId) {
    try {
      return _getMockUsers().firstWhere((user) => user.uid == userId);
    } catch (e) {
      return null;
    }
  }

  /// Limpar estado (para testes)
  void clearState() {
    state = const MatchingState();
  }

  /// Limpar erro
  void clearError() {
    state = state.copyWith(error: null);
  }
}

// ================================================================
// PROVIDER
// ================================================================

final unlockMatchingProvider =
    StateNotifierProvider<UnlockMatchingNotifier, MatchingState>(
      (ref) => UnlockMatchingNotifier(),
    );

// ================================================================
// PROVIDERS DERIVADOS PARA PERFORMANCE
// ================================================================

/// Provider que só escuta matches potenciais
final potentialMatchesProvider = Provider<List<UnlockMatchModel>>((ref) {
  return ref.watch(
    unlockMatchingProvider.select((state) => state.potentialMatches),
  );
});

/// Provider que só escuta matches ativos
final activeMatchesProvider = Provider<List<UnlockMatchModel>>((ref) {
  return ref.watch(
    unlockMatchingProvider.select((state) => state.activeMatches),
  );
});

/// Provider que só escuta matches desbloqueados
final unlockedMatchesProvider = Provider<List<UnlockMatchModel>>((ref) {
  return ref.watch(
    unlockMatchingProvider.select((state) => state.unlockedMatches),
  );
});

/// Provider para o teste atual
final currentTestProvider = Provider<AffinityTestModel?>((ref) {
  return ref.watch(unlockMatchingProvider.select((state) => state.currentTest));
});

/// Provider para estatísticas
final matchingStatsProvider = Provider<Map<String, dynamic>>((ref) {
  final notifier = ref.watch(unlockMatchingProvider.notifier);
  return notifier.getUserMatchingStats();
});

/// Provider para verificar se pode criar novos matches
final canCreateMatchesProvider = Provider<bool>((ref) {
  return ref.watch(
    unlockMatchingProvider.select((state) => state.canCreateNewMatches),
  );
});

/// Provider para loading states específicos
final isMatchingLoadingProvider = Provider<bool>((ref) {
  return ref.watch(unlockMatchingProvider.select((state) => state.isLoading));
});

final isTakingTestProvider = Provider<bool>((ref) {
  return ref.watch(
    unlockMatchingProvider.select((state) => state.isTakingTest),
  );
});
