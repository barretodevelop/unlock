// lib/services/unlock_algorithm.dart
import 'dart:math';

import 'package:unlock/enums/enums.dart';
import 'package:unlock/models/affinity_question.dart';
import 'package:unlock/models/unlock_requirement.dart';

import '../models/affinity_test_model.dart';
import '../models/unlock_match_model.dart';
import '../models/user_model.dart';

/// Algoritmo principal do sistema Unlock
/// Responsável por calcular compatibilidade e gerar matches inteligentes
class UnlockAlgorithm {
  static const double _interestWeight = 0.35;
  static const double _relationshipWeight = 0.25;
  static const double _activityWeight = 0.20;
  static const double _locationWeight = 0.10;
  static const double _demographicWeight = 0.10;

  static const double _unlockThreshold = 75.0; // Mínimo para desbloquear

  /// Calcula compatibilidade base entre dois usuários
  static double calculateBaseCompatibility(
    UserModel currentUser,
    UserModel potentialMatch,
  ) {
    double totalScore = 0.0;

    // 1. Compatibilidade de interesses (35%)
    double interestScore = _calculateInterestCompatibility(
      currentUser.interesses,
      potentialMatch.interesses,
    );
    totalScore += interestScore * _interestWeight;

    // 2. Compatibilidade de relacionamento (25%)
    double relationshipScore = _calculateRelationshipCompatibility(
      currentUser.relationshipInterest,
      potentialMatch.relationshipInterest,
    );
    totalScore += relationshipScore * _relationshipWeight;

    // 3. Compatibilidade de atividade (20%)
    double activityScore = _calculateActivityCompatibility(
      currentUser,
      potentialMatch,
    );
    totalScore += activityScore * _activityWeight;

    // 4. Proximidade (10%)
    double locationScore = _calculateLocationCompatibility(
      currentUser,
      potentialMatch,
    );
    totalScore += locationScore * _locationWeight;

    // 5. Demografia (10%)
    double demographicScore = _calculateDemographicCompatibility(
      currentUser,
      potentialMatch,
    );
    totalScore += demographicScore * _demographicWeight;

    return (totalScore * 100).clamp(0.0, 100.0);
  }

  /// Calcula compatibilidade de interesses
  static double _calculateInterestCompatibility(
    List<String> userInterests,
    List<String> matchInterests,
  ) {
    if (userInterests.isEmpty || matchInterests.isEmpty) return 0.0;

    // Interesses em comum
    final commonInterests = userInterests
        .where((interest) => matchInterests.contains(interest))
        .toList();

    // Fórmula: Jaccard similarity com bonus para muitos interesses comuns
    double jaccard =
        commonInterests.length /
        (userInterests.length + matchInterests.length - commonInterests.length);

    // Bonus para 3+ interesses comuns
    double bonus = commonInterests.length >= 3 ? 0.15 : 0.0;

    return (jaccard + bonus).clamp(0.0, 1.0);
  }

  /// Calcula compatibilidade de tipo de relacionamento
  static double _calculateRelationshipCompatibility(
    String? userType,
    String? matchType,
  ) {
    if (userType == null || matchType == null) return 0.5;

    // Matriz de compatibilidade entre tipos
    const compatibilityMatrix = {
      'amizade': {
        'amizade': 1.0,
        'networking': 0.8,
        'mentoria': 0.6,
        'casual': 0.4,
        'namoro': 0.2,
      },
      'namoro': {
        'namoro': 1.0,
        'casual': 0.7,
        'amizade': 0.3,
        'mentoria': 0.2,
        'networking': 0.1,
      },
      'casual': {
        'casual': 1.0,
        'namoro': 0.8,
        'amizade': 0.6,
        'networking': 0.3,
        'mentoria': 0.2,
      },
      'mentoria': {
        'mentoria': 1.0,
        'networking': 0.8,
        'amizade': 0.6,
        'casual': 0.3,
        'namoro': 0.1,
      },
      'networking': {
        'networking': 1.0,
        'mentoria': 0.8,
        'amizade': 0.7,
        'casual': 0.4,
        'namoro': 0.2,
      },
    };

    return compatibilityMatrix[userType]?[matchType] ?? 0.5;
  }

  /// Calcula compatibilidade de atividade/engajamento
  static double _calculateActivityCompatibility(
    UserModel currentUser,
    UserModel potentialMatch,
  ) {
    // Baseado em nível, XP, última atividade
    double levelScore =
        1.0 -
        (currentUser.level - potentialMatch.level).abs() /
            max(currentUser.level, potentialMatch.level);

    // Usuarios ativos recentemente têm melhor score
    final daysSinceLastLogin = DateTime.now()
        .difference(potentialMatch.lastLoginAt)
        .inDays;
    double activityScore = daysSinceLastLogin <= 1
        ? 1.0
        : daysSinceLastLogin <= 7
        ? 0.8
        : daysSinceLastLogin <= 30
        ? 0.5
        : 0.2;

    return (levelScore * 0.6 + activityScore * 0.4);
  }

  /// Calcula compatibilidade de localização (simulado)
  static double _calculateLocationCompatibility(
    UserModel currentUser,
    UserModel potentialMatch,
  ) {
    // Por enquanto, retorna score aleatório
    // Em produção, seria baseado em distância real
    return 0.7 + (Random().nextDouble() * 0.3);
  }

  /// Calcula compatibilidade demográfica
  static double _calculateDemographicCompatibility(
    UserModel currentUser,
    UserModel potentialMatch,
  ) {
    // Por enquanto, score neutro
    // Em produção, consideraria idade, educação, etc.
    return 0.6 + (Random().nextDouble() * 0.4);
  }

  /// Gera lista de matches potenciais ordenados por compatibilidade
  static List<UnlockMatchModel> generateMatches(
    UserModel currentUser,
    List<UserModel> potentialUsers, {
    int limit = 10,
  }) {
    final matches = <UnlockMatchModel>[];

    for (final user in potentialUsers) {
      if (user.uid == currentUser.uid) continue;

      final compatibility = calculateBaseCompatibility(currentUser, user);
      final commonInterests = _getCommonInterests(
        currentUser.interesses,
        user.interesses,
      );

      matches.add(
        UnlockMatchModel(
          id: _generateMatchId(currentUser.uid, user.uid),
          currentUserId: currentUser.uid,
          targetUserId: user.uid,
          targetUserCodinome: user.codinome ?? 'Anônimo',
          compatibilityScore: compatibility,
          commonInterests: commonInterests,
          isUnlocked: false,
          createdAt: DateTime.now(),
          unlockRequirement: _determineUnlockRequirement(compatibility),
          userId: '',
          targetCodinome: '',
        ),
      );
    }

    // Ordenar por compatibilidade e retornar os melhores
    matches.sort(
      (a, b) => b.compatibilityScore.compareTo(a.compatibilityScore),
    );
    return matches.take(limit).toList();
  }

  /// Gera perguntas de teste de afinidade baseadas nos interesses comuns
  static AffinityTestModel generateAffinityTest(
    String matchId,
    List<String> commonInterests,
    UserModel currentUser,
  ) {
    final questions = <AffinityQuestion>[];
    final usedCategories = <String>{};

    // Gerar perguntas baseadas em interesses comuns
    for (final interest in commonInterests.take(3)) {
      if (!usedCategories.contains(interest)) {
        questions.addAll(_generateQuestionsForCategory(interest));
        usedCategories.add(interest);
      }
    }

    // Adicionar perguntas gerais se necessário
    while (questions.length < 5) {
      questions.addAll(_generateGeneralQuestions());
    }

    // Embaralhar e pegar apenas 5 perguntas
    questions.shuffle();
    final selectedQuestions = questions.take(5).toList();

    return AffinityTestModel(
      id: '${matchId}_test',
      matchId: matchId,
      questions: selectedQuestions,
      createdAt: DateTime.now(),
      timeLimit: const Duration(minutes: 10),
      type: TestType.interests,
      question: '',
      options: [],
    );
  }

  /// Avalia resultado do teste de afinidade
  static AffinityTestResult evaluateAffinityTest(
    AffinityTestModel test,
    Map<String, String> userAnswers,
    Map<String, String> targetAnswers, // Respostas pré-definidas ou simuladas
  ) {
    double totalScore = 0.0;
    int answeredQuestions = 0;

    for (final question in test.questions) {
      final userAnswer = userAnswers[question.id];
      final targetAnswer = targetAnswers[question.id];

      if (userAnswer != null && targetAnswer != null) {
        final questionScore = _evaluateQuestionMatch(
          question,
          userAnswer,
          targetAnswer,
        );
        totalScore += questionScore;
        answeredQuestions++;
      }
    }

    final averageScore = answeredQuestions > 0
        ? totalScore / answeredQuestions
        : 0.0;
    final finalScore = (averageScore * 100).clamp(0.0, 100.0);

    return AffinityTestResult(
      testId: test.id,
      affinityScore: finalScore,
      unlocked: finalScore >= _unlockThreshold,
      completedAt: DateTime.now(),
      breakdown: _generateScoreBreakdown(
        test.questions,
        userAnswers,
        targetAnswers,
      ),
    );
  }

  // Métodos auxiliares privados

  static List<String> _getCommonInterests(
    List<String> interests1,
    List<String> interests2,
  ) {
    return interests1
        .where((interest) => interests2.contains(interest))
        .toList();
  }

  static String _generateMatchId(String userId1, String userId2) {
    final ids = [userId1, userId2]..sort();
    return 'match_${ids[0]}_${ids[1]}_${DateTime.now().millisecondsSinceEpoch}';
  }

  static UnlockRequirement _determineUnlockRequirement(double compatibility) {
    if (compatibility >= 90) return UnlockRequirement.easy;
    if (compatibility >= 70) return UnlockRequirement.medium;
    return UnlockRequirement.hard;
  }

  static List<AffinityQuestion> _generateQuestionsForCategory(String category) {
    final questionsBank = {
      'Música': [
        AffinityQuestion(
          id: 'music_1',
          category: 'Música',
          question: 'Qual gênero musical te faz sentir mais energizado?',
          options: ['Rock/Pop', 'Eletrônica', 'Hip-Hop/Rap', 'Clássica/Jazz'],
        ),
        AffinityQuestion(
          id: 'music_2',
          category: 'Música',
          question: 'Prefere descobrir música nova como?',
          options: [
            'Playlists automáticas',
            'Recomendações de amigos',
            'Shows ao vivo',
            'Rádio/TV',
          ],
        ),
      ],
      'Filmes': [
        AffinityQuestion(
          id: 'movies_1',
          category: 'Filmes',
          question: 'Que tipo de filme escolheria para um primeiro encontro?',
          options: [
            'Comédia romântica',
            'Ação/Aventura',
            'Drama/Indie',
            'Terror/Suspense',
          ],
        ),
        AffinityQuestion(
          id: 'movies_2',
          category: 'Filmes',
          question: 'Prefere assistir filmes:',
          options: [
            'No cinema',
            'Em casa sozinho',
            'Em casa com amigos',
            'Festivais/eventos',
          ],
        ),
      ],
      'Viagens': [
        AffinityQuestion(
          id: 'travel_1',
          category: 'Viagens',
          question: 'Seu tipo ideal de viagem:',
          options: [
            'Aventura e natureza',
            'Cidades e cultura',
            'Praia e relaxamento',
            'Turismo gastronômico',
          ],
        ),
        AffinityQuestion(
          id: 'travel_2',
          category: 'Viagens',
          question: 'Ao planejar uma viagem, você:',
          options: [
            'Planeja tudo com antecedência',
            'Faz um roteiro básico',
            'Prefere improvisar',
            'Segue recomendações locais',
          ],
        ),
      ],
    };

    return questionsBank[category] ?? [];
  }

  static List<AffinityQuestion> _generateGeneralQuestions() {
    return [
      AffinityQuestion(
        id: 'general_1',
        category: 'Personalidade',
        question: 'Em uma festa, você normalmente:',
        options: [
          'Conversa com todos',
          'Fica com amigos próximos',
          'Prefere conversas profundas',
          'Observa mais que participa',
        ],
      ),
      AffinityQuestion(
        id: 'general_2',
        category: 'Estilo de Vida',
        question: 'Seu fim de semana ideal:',
        options: [
          'Aventura ao ar livre',
          'Maratona de séries',
          'Sair com amigos',
          'Aprender algo novo',
        ],
      ),
      AffinityQuestion(
        id: 'general_3',
        category: 'Valores',
        question: 'O que mais valoriza em uma amizade?',
        options: [
          'Lealdade',
          'Diversão',
          'Apoio emocional',
          'Crescimento mútuo',
        ],
      ),
    ];
  }

  static double _evaluateQuestionMatch(
    AffinityQuestion question,
    String userAnswer,
    String targetAnswer,
  ) {
    // Respostas idênticas = 100% compatibilidade
    if (userAnswer == targetAnswer) return 1.0;

    // Lógica de compatibilidade parcial baseada na categoria
    return _calculatePartialCompatibility(
      question.category,
      userAnswer,
      targetAnswer,
    );
  }

  static double _calculatePartialCompatibility(
    String category,
    String answer1,
    String answer2,
  ) {
    // Algumas respostas são parcialmente compatíveis
    final partialMatches = {
      'Música': {
        'Rock/Pop': ['Eletrônica'],
        'Hip-Hop/Rap': ['Eletrônica'],
      },
      'Filmes': {
        'Comédia romântica': ['Drama/Indie'],
        'Ação/Aventura': ['Terror/Suspense'],
      },
    };

    final categoryMatches = partialMatches[category];
    if (categoryMatches != null) {
      final compatibleAnswers = categoryMatches[answer1];
      if (compatibleAnswers != null && compatibleAnswers.contains(answer2)) {
        return 0.6; // 60% de compatibilidade
      }
    }

    return 0.2; // 20% de compatibilidade base para respostas diferentes
  }

  static Map<String, double> _generateScoreBreakdown(
    List<AffinityQuestion> questions,
    Map<String, String> userAnswers,
    Map<String, String> targetAnswers,
  ) {
    final breakdown = <String, double>{};

    for (final question in questions) {
      final userAnswer = userAnswers[question.id];
      final targetAnswer = targetAnswers[question.id];

      if (userAnswer != null && targetAnswer != null) {
        final score = _evaluateQuestionMatch(
          question,
          userAnswer,
          targetAnswer,
        );
        breakdown[question.category] =
            (breakdown[question.category] ?? 0.0) + score;
      }
    }

    // Converter para percentuais
    final result = <String, double>{};
    breakdown.forEach((category, score) {
      final questionsInCategory = questions
          .where((q) => q.category == category)
          .length;
      result[category] = (score / questionsInCategory * 100).clamp(0.0, 100.0);
    });

    return result;
  }

  /// Simula respostas do usuário alvo para testes
  static Map<String, String> generateSimulatedAnswers(
    AffinityTestModel test,
    UserModel targetUser,
    double targetCompatibility,
  ) {
    final answers = <String, String>{};
    final random = Random();

    for (final question in test.questions) {
      // Probabilidade de resposta compatível baseada na compatibilidade alvo
      final shouldMatch = random.nextDouble() < (targetCompatibility / 100);

      if (shouldMatch) {
        // Escolher uma resposta que seria compatível
        answers[question.id] =
            question.options[random.nextInt(question.options.length)];
      } else {
        // Escolher uma resposta menos compatível
        answers[question.id] =
            question.options[random.nextInt(question.options.length)];
      }
    }

    return answers;
  }
}
