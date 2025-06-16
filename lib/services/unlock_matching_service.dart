// lib/services/unlock_matching_service.dart
import 'dart:math';

import 'package:unlock/enums/enums.dart';
import 'package:unlock/models/affinity_test_model.dart';
import 'package:unlock/models/unlock_match_model.dart';
import 'package:unlock/models/user_model.dart';

class UnlockMatchingService {
  static const int _minCompatibilityScore = 60;
  static const int _maxDailyMatches = 5;
  static const Duration _testTimeLimit = Duration(minutes: 2);

  // ================================================================
  // ALGORITMO DE COMPATIBILIDADE
  // ================================================================

  /// Calcula score de compatibilidade entre dois usuários
  static double calculateCompatibilityScore(UserModel user1, UserModel user2) {
    double score = 0.0;

    // 1. Interesses comuns (40% do score)
    final interestScore = _calculateInterestCompatibility(
      user1.interesses,
      user2.interesses,
    );
    score += interestScore * 0.4;

    // 2. Tipo de relacionamento (30% do score)
    final relationshipScore = _calculateRelationshipCompatibility(
      user1.relationshipInterest,
      user2.relationshipInterest,
    );
    score += relationshipScore * 0.3;

    // 3. Faixa etária e localização (20% do score) - mock por enquanto
    final demographicScore = _calculateDemographicCompatibility(user1, user2);
    score += demographicScore * 0.2;

    // 4. Nível de atividade no app (10% do score)
    final activityScore = _calculateActivityCompatibility(user1, user2);
    score += activityScore * 0.1;

    return (score * 100).clamp(0.0, 100.0);
  }

  static double _calculateInterestCompatibility(
    List<String> interests1,
    List<String> interests2,
  ) {
    if (interests1.isEmpty || interests2.isEmpty) return 0.0;

    final common = interests1
        .where((interest) => interests2.contains(interest))
        .length;
    final total = {...interests1, ...interests2}.length;

    // Bonus para muitos interesses comuns
    double baseScore = common / max(interests1.length, interests2.length);
    double bonusScore = common >= 3 ? 0.2 : 0.0;

    return (baseScore + bonusScore).clamp(0.0, 1.0);
  }

  static double _calculateRelationshipCompatibility(
    String? type1,
    String? type2,
  ) {
    if (type1 == null || type2 == null) return 0.5;

    // Matriz de compatibilidade entre tipos de relacionamento
    const compatibilityMatrix = {
      'amizade': {
        'amizade': 1.0,
        'casual': 0.8,
        'namoro': 0.6,
        'networking': 0.9,
        'mentoria': 0.7,
      },
      'namoro': {
        'namoro': 1.0,
        'casual': 0.7,
        'amizade': 0.6,
        'networking': 0.3,
        'mentoria': 0.2,
      },
      'casual': {
        'casual': 1.0,
        'amizade': 0.8,
        'namoro': 0.7,
        'networking': 0.5,
        'mentoria': 0.4,
      },
      'networking': {
        'networking': 1.0,
        'amizade': 0.9,
        'mentoria': 0.8,
        'casual': 0.5,
        'namoro': 0.3,
      },
      'mentoria': {
        'mentoria': 1.0,
        'networking': 0.8,
        'amizade': 0.7,
        'casual': 0.4,
        'namoro': 0.2,
      },
    };

    return compatibilityMatrix[type1]?[type2] ?? 0.5;
  }

  static double _calculateDemographicCompatibility(
    UserModel user1,
    UserModel user2,
  ) {
    // Por enquanto retorna score mock baseado no level
    // No futuro: idade, localização, etc.
    final levelDiff = (user1.level - user2.level).abs();
    return levelDiff <= 2 ? 1.0 : 0.7;
  }

  static double _calculateActivityCompatibility(
    UserModel user1,
    UserModel user2,
  ) {
    // Score baseado na atividade no app (XP, último login, etc.)
    final user1Activity = user1.xp + (user1.level * 100);
    final user2Activity = user2.xp + (user2.level * 100);

    final activityDiff = (user1Activity - user2Activity).abs();
    final maxActivity = max(user1Activity, user2Activity);

    if (maxActivity == 0) return 1.0;
    return (1.0 - (activityDiff / maxActivity)).clamp(0.0, 1.0);
  }

  // ================================================================
  // GERAÇÃO DE MATCHES POTENCIAIS
  // ================================================================

  /// Encontra matches potenciais para um usuário
  static List<UnlockMatchModel> findPotentialMatches(
    UserModel currentUser,
    List<UserModel> allUsers, {
    int limit = 10,
  }) {
    final potentialMatches = <UnlockMatchModel>[];

    for (final otherUser in allUsers) {
      // Não pode fazer match consigo mesmo
      if (otherUser.uid == currentUser.uid) continue;

      // Calcular compatibilidade
      final compatibility = calculateCompatibilityScore(currentUser, otherUser);

      // Só sugerir se tiver compatibilidade mínima
      if (compatibility < _minCompatibilityScore) continue;

      // Encontrar interesses comuns
      final commonInterests = currentUser.interesses
          .where((interest) => otherUser.interesses.contains(interest))
          .toList();

      final match = UnlockMatchModel(
        id: _generateMatchId(currentUser.uid, otherUser.uid),
        userId: currentUser.uid,
        targetUserId: otherUser.uid,
        targetCodinome: otherUser.codinome ?? otherUser.displayName,
        targetAvatarUrl: otherUser.avatar,
        commonInterests: commonInterests,
        compatibilityScore: compatibility,
        createdAt: DateTime.now(),
        expiresAt: DateTime.now().add(const Duration(days: 7)),
        currentUserId: '',
        targetUserCodinome: '',
        isUnlocked: null,
        unlockRequirement: null, // Match expira em 7 dias
      );

      potentialMatches.add(match);
    }

    // Ordenar por compatibilidade e limitar
    potentialMatches.sort(
      (a, b) => b.compatibilityScore.compareTo(a.compatibilityScore),
    );
    return potentialMatches.take(limit).toList();
  }

  static String _generateMatchId(String userId1, String userId2) {
    final sortedIds = [userId1, userId2]..sort();
    return '${sortedIds[0]}_${sortedIds[1]}_${DateTime.now().millisecondsSinceEpoch}';
  }

  // ================================================================
  // SISTEMA DE TESTES DE AFINIDADE
  // ================================================================

  /// Gera teste de afinidade baseado no perfil do usuário
  static AffinityTestModel generateAffinityTest(
    UnlockMatchModel match,
    UserModel targetUser,
  ) {
    final testType = _selectTestType(match.completedTests);

    switch (testType) {
      case TestType.interests:
        return _generateInterestTest(match, targetUser);
      case TestType.personality:
        return _generatePersonalityTest(match, targetUser);
      case TestType.lifestyle:
        return _generateLifestyleTest(match, targetUser);
      case TestType.values1:
        return _generateValuesTest(match, targetUser);
      case TestType.quickFire:
        return _generateQuickFireTest(match, targetUser);
    }
  }

  static TestType _selectTestType(List<AffinityTestModel> completedTests) {
    // Evitar repetir tipos já testados
    final completedTypes = completedTests.map((test) => test.type).toSet();
    final availableTypes = TestType.values
        .where((type) => !completedTypes.contains(type))
        .toList();

    if (availableTypes.isEmpty) {
      // Se já fez todos os tipos, escolher aleatório
      return TestType.values[Random().nextInt(TestType.values.length)];
    }

    return availableTypes[Random().nextInt(availableTypes.length)];
  }

  static AffinityTestModel _generateInterestTest(
    UnlockMatchModel match,
    UserModel targetUser,
  ) {
    // Teste baseado nos interesses do usuário alvo
    final targetInterests = targetUser.interesses;
    if (targetInterests.isEmpty) {
      return _generatePersonalityTest(match, targetUser); // Fallback
    }

    final randomInterest =
        targetInterests[Random().nextInt(targetInterests.length)];

    final questions = {
      'Música': {
        'question': 'Qual seu estilo musical favorito para relaxar?',
        'options': [
          'Jazz/Blues',
          'Pop/Rock',
          'Clássica/Instrumental',
          'Eletrônica/Ambiente',
        ],
        'expected': 'Jazz/Blues', // Mock - seria baseado no perfil do target
      },
      'Viagens': {
        'question': 'Qual tipo de viagem mais te atrai?',
        'options': [
          'Aventura na natureza',
          'Cultura e história',
          'Relaxamento na praia',
          'Cidades cosmopolitas',
        ],
        'expected': 'Cultura e história',
      },
      'Tecnologia': {
        'question': 'Como você se relaciona com tecnologia?',
        'options': [
          'Early adopter',
          'Uso quando necessário',
          'Prefiro o analógico',
          'Equilibrio saudável',
        ],
        'expected': 'Equilibrio saudável',
      },
      'Esportes': {
        'question': 'Qual sua abordagem ideal para exercícios?',
        'options': [
          'Academia regular',
          'Esportes em grupo',
          'Atividades ao ar livre',
          'Yoga/meditação',
        ],
        'expected': 'Esportes em grupo',
      },
    };

    final testData = questions[randomInterest] ?? questions['Música']!;

    return AffinityTestModel(
      id: 'test_${DateTime.now().millisecondsSinceEpoch}',
      matchId: match.id,
      type: TestType.interests,
      question: testData['question'] as String,
      options: testData['options'] as List<String>,
      targetExpectedAnswer: testData['expected'] as String,
      maxScore: 100,
      questions: [],
      createdAt: null,
      timeLimit: null,
    );
  }

  static AffinityTestModel _generatePersonalityTest(
    UnlockMatchModel match,
    UserModel targetUser,
  ) {
    final personalityQuestions = [
      {
        'question': 'Em um fim de semana ideal, você prefere:',
        'options': [
          'Sair com amigos',
          'Ficar em casa lendo',
          'Explorar lugares novos',
          'Praticar hobbies',
        ],
        'expected': 'Explorar lugares novos',
      },
      {
        'question': 'Como você lida com conflitos?',
        'options': [
          'Converso diretamente',
          'Evito confrontos',
          'Busco mediação',
          'Analiso primeiro',
        ],
        'expected': 'Converso diretamente',
      },
      {
        'question': 'Sua energia vem principalmente de:',
        'options': [
          'Interação social',
          'Tempo sozinho',
          'Novas experiências',
          'Rotina estabelecida',
        ],
        'expected': 'Interação social',
      },
    ];

    final randomQuestion =
        personalityQuestions[Random().nextInt(personalityQuestions.length)];

    return AffinityTestModel(
      id: 'test_${DateTime.now().millisecondsSinceEpoch}',
      matchId: match.id,
      type: TestType.personality,
      question: randomQuestion['question'] as String,
      options: randomQuestion['options'] as List<String>,
      targetExpectedAnswer: randomQuestion['expected'] as String,
      maxScore: 100,
    );
  }

  static AffinityTestModel _generateLifestyleTest(
    UnlockMatchModel match,
    UserModel targetUser,
  ) {
    final lifestyleQuestions = [
      {
        'question': 'Qual seu horário ideal para um encontro?',
        'options': ['Manhã (café da manhã)', 'Almoço', 'Happy hour', 'Jantar'],
        'expected': 'Happy hour',
      },
      {
        'question': 'Como você gosta de passar as férias?',
        'options': [
          'Planejadas com antecedência',
          'Espontâneas',
          'Staycation',
          'Mochilão',
        ],
        'expected': 'Planejadas com antecedência',
      },
      {
        'question': 'Sua relação com comida é:',
        'options': [
          'Adoro cozinhar',
          'Gosto de experimentar',
          'Praticidade é key',
          'Vida social gira em torno',
        ],
        'expected': 'Gosto de experimentar',
      },
    ];

    final randomQuestion =
        lifestyleQuestions[Random().nextInt(lifestyleQuestions.length)];

    return AffinityTestModel(
      id: 'test_${DateTime.now().millisecondsSinceEpoch}',
      matchId: match.id,
      type: TestType.lifestyle,
      question: randomQuestion['question'] as String,
      options: randomQuestion['options'] as List<String>,
      targetExpectedAnswer: randomQuestion['expected'] as String,
      maxScore: 100,
    );
  }

  static AffinityTestModel _generateValuesTest(
    UnlockMatchModel match,
    UserModel targetUser,
  ) {
    final valuesQuestions = [
      {
        'question': 'O que mais valoriza em um relacionamento?',
        'options': [
          'Honestidade',
          'Diversão',
          'Crescimento mútuo',
          'Estabilidade',
        ],
        'expected': 'Honestidade',
      },
      {
        'question': 'Como você vê o futuro?',
        'options': [
          'Otimista e planejado',
          'Vivo o presente',
          'Realista e cauteloso',
          'Adaptável às mudanças',
        ],
        'expected': 'Otimista e planejado',
      },
      {
        'question': 'Sua definição de sucesso inclui:',
        'options': [
          'Realização profissional',
          'Relacionamentos sólidos',
          'Liberdade pessoal',
          'Impacto positivo',
        ],
        'expected': 'Relacionamentos sólidos',
      },
    ];

    final randomQuestion =
        valuesQuestions[Random().nextInt(valuesQuestions.length)];

    return AffinityTestModel(
      id: 'test_${DateTime.now().millisecondsSinceEpoch}',
      matchId: match.id,
      type: TestType.values1,
      question: randomQuestion['question'] as String,
      options: randomQuestion['options'] as List<String>,
      targetExpectedAnswer: randomQuestion['expected'] as String,
      maxScore: 100,
    );
  }

  static AffinityTestModel _generateQuickFireTest(
    UnlockMatchModel match,
    UserModel targetUser,
  ) {
    final quickQuestions = [
      {
        'question': 'Café ou chá?',
        'options': ['Café', 'Chá', 'Ambos', 'Nenhum'],
        'expected': 'Café',
      },
      {
        'question': 'Gato ou cachorro?',
        'options': ['Gato', 'Cachorro', 'Ambos', 'Outros pets'],
        'expected': 'Cachorro',
      },
      {
        'question': 'Praia ou montanha?',
        'options': ['Praia', 'Montanha', 'Cidade', 'Campo'],
        'expected': 'Montanha',
      },
    ];

    final randomQuestion =
        quickQuestions[Random().nextInt(quickQuestions.length)];

    return AffinityTestModel(
      id: 'test_${DateTime.now().millisecondsSinceEpoch}',
      matchId: match.id,
      type: TestType.quickFire,
      question: randomQuestion['question'] as String,
      options: randomQuestion['options'] as List<String>,
      targetExpectedAnswer: randomQuestion['expected'] as String,
      maxScore: 50, // Quick Fire vale menos pontos
    );
  }

  // ================================================================
  // SISTEMA DE PONTUAÇÃO E UNLOCK
  // ================================================================

  /// Avalia resposta do teste e calcula score
  static AffinityTestModel evaluateTestAnswer(
    AffinityTestModel test,
    String userAnswer,
    Duration timeSpent,
  ) {
    int scoreEarned = 0;
    bool hasPassed = false;

    // Score baseado na correspondência da resposta
    if (userAnswer == test.targetExpectedAnswer) {
      scoreEarned = test.maxScore; // Resposta perfeita
      hasPassed = true;
    } else {
      // Score parcial baseado na "proximidade" da resposta (simulado)
      scoreEarned = (test.maxScore * 0.3).round(); // 30% por participar

      // Quick Fire é mais tolerante
      if (test.type == TestType.quickFire) {
        scoreEarned = (test.maxScore * 0.6).round();
        hasPassed = true; // Quick Fire sempre passa
      }
    }

    // Bonus por responder rapidamente (apenas para quick fire)
    if (test.type == TestType.quickFire && timeSpent.inSeconds < 10) {
      scoreEarned = (scoreEarned * 1.2).round();
    }

    return test.copyWith(
      userAnswer: userAnswer,
      scoreEarned: scoreEarned,
      hasPassed: hasPassed,
      completedAt: DateTime.now(),
      timeSpent: timeSpent,
    );
  }

  /// Verifica se o match pode ser desbloqueado
  static bool canUnlockMatch(UnlockMatchModel match) {
    return match.hasPassedAllTests && match.status != MatchStatus.unlocked;
  }

  /// Desbloqueia um match
  static UnlockMatchModel unlockMatch(UnlockMatchModel match) {
    if (!canUnlockMatch(match)) return match;

    return match.copyWith(
      status: MatchStatus.unlocked,
      unlockedAt: DateTime.now(),
      canStartChat: true,
    );
  }

  /// Calcula score total do match baseado nos testes
  static int calculateTotalMatchScore(UnlockMatchModel match) {
    if (match.completedTests.isEmpty) return 0;

    final totalEarned = match.completedTests.fold<int>(
      0,
      (sum, test) => sum + test.scoreEarned,
    );

    final totalPossible = match.completedTests.fold<int>(
      0,
      (sum, test) => sum + test.maxScore,
    );

    if (totalPossible == 0) return 0;
    return ((totalEarned / totalPossible) * 100).round();
  }
}
