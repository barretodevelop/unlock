// lib/models/affinity_question.dart
import 'package:equatable/equatable.dart';
import 'package:unlock/enums/enums.dart';

class AffinityQuestion extends Equatable {
  final String id;
  final String question;
  final String category;
  final List<AffinityQuestionOption> options;
  final String? description;
  final int weight;
  final AffinityQuestionType type;
  final bool isRequired;
  final Map<String, dynamic>? metadata;

  const AffinityQuestion({
    required this.id,
    required this.question,
    required this.category,
    required this.options,
    this.description,
    this.weight = 1,
    this.type = AffinityQuestionType.multipleChoice,
    this.isRequired = true,
    this.metadata,
  });

  @override
  List<Object?> get props => [
    id,
    question,
    category,
    options,
    description,
    weight,
    type,
    isRequired,
    metadata,
  ];

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'question': question,
      'category': category,
      'options': options.map((option) => option.toJson()).toList(),
      'description': description,
      'weight': weight,
      'type': type.name,
      'isRequired': isRequired,
      'metadata': metadata,
    };
  }

  factory AffinityQuestion.fromJson(Map<String, dynamic> json) {
    return AffinityQuestion(
      id: json['id'] ?? '',
      question: json['question'] ?? '',
      category: json['category'] ?? '',
      options:
          (json['options'] as List?)
              ?.map((option) => AffinityQuestionOption.fromJson(option))
              .toList() ??
          [],
      description: json['description'],
      weight: json['weight'] ?? 1,
      type: AffinityQuestionType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => AffinityQuestionType.multipleChoice,
      ),
      isRequired: json['isRequired'] ?? true,
      metadata: json['metadata'],
    );
  }

  AffinityQuestion copyWith({
    String? id,
    String? question,
    String? category,
    List<AffinityQuestionOption>? options,
    String? description,
    int? weight,
    AffinityQuestionType? type,
    bool? isRequired,
    Map<String, dynamic>? metadata,
  }) {
    return AffinityQuestion(
      id: id ?? this.id,
      question: question ?? this.question,
      category: category ?? this.category,
      options: options ?? this.options,
      description: description ?? this.description,
      weight: weight ?? this.weight,
      type: type ?? this.type,
      isRequired: isRequired ?? this.isRequired,
      metadata: metadata ?? this.metadata,
    );
  }
}

class AffinityQuestionOption extends Equatable {
  final String id;
  final String text;
  final int value;
  final String? description;
  final String? iconEmoji;
  final Map<String, dynamic>? traits;

  const AffinityQuestionOption({
    required this.id,
    required this.text,
    this.value = 1,
    this.description,
    this.iconEmoji,
    this.traits,
  });

  @override
  List<Object?> get props => [id, text, value, description, iconEmoji, traits];

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'text': text,
      'value': value,
      'description': description,
      'iconEmoji': iconEmoji,
      'traits': traits,
    };
  }

  factory AffinityQuestionOption.fromJson(Map<String, dynamic> json) {
    return AffinityQuestionOption(
      id: json['id'] ?? '',
      text: json['text'] ?? '',
      value: json['value'] ?? 1,
      description: json['description'],
      iconEmoji: json['iconEmoji'],
      traits: json['traits'],
    );
  }

  AffinityQuestionOption copyWith({
    String? id,
    String? text,
    int? value,
    String? description,
    String? iconEmoji,
    Map<String, dynamic>? traits,
  }) {
    return AffinityQuestionOption(
      id: id ?? this.id,
      text: text ?? this.text,
      value: value ?? this.value,
      description: description ?? this.description,
      iconEmoji: iconEmoji ?? this.iconEmoji,
      traits: traits ?? this.traits,
    );
  }
}

// Classe para resultados do teste de afinidade
class AffinityTestResult extends Equatable {
  final String testId;
  final String matchId;
  final int score;
  final bool passed;
  final Map<String, String> userAnswers;
  final Map<String, String> partnerAnswers;
  final List<String> matchingAnswers;
  final List<String> conflictingAnswers;
  final Map<String, double> categoryScores;
  final DateTime completedAt;
  final int xpEarned;
  final int coinsEarned;
  final int? gemsEarned;

  const AffinityTestResult({
    required this.testId,
    required this.matchId,
    required this.score,
    required this.passed,
    required this.userAnswers,
    required this.partnerAnswers,
    this.matchingAnswers = const [],
    this.conflictingAnswers = const [],
    this.categoryScores = const {},
    required this.completedAt,
    this.xpEarned = 0,
    this.coinsEarned = 0,
    this.gemsEarned,
  });

  @override
  List<Object?> get props => [
    testId,
    matchId,
    score,
    passed,
    userAnswers,
    partnerAnswers,
    matchingAnswers,
    conflictingAnswers,
    categoryScores,
    completedAt,
    xpEarned,
    coinsEarned,
    gemsEarned,
  ];

  Map<String, dynamic> toJson() {
    return {
      'testId': testId,
      'matchId': matchId,
      'score': score,
      'passed': passed,
      'userAnswers': userAnswers,
      'partnerAnswers': partnerAnswers,
      'matchingAnswers': matchingAnswers,
      'conflictingAnswers': conflictingAnswers,
      'categoryScores': categoryScores,
      'completedAt': completedAt.toIso8601String(),
      'xpEarned': xpEarned,
      'coinsEarned': coinsEarned,
      'gemsEarned': gemsEarned,
    };
  }

  factory AffinityTestResult.fromJson(Map<String, dynamic> json) {
    return AffinityTestResult(
      testId: json['testId'] ?? '',
      matchId: json['matchId'] ?? '',
      score: json['score'] ?? 0,
      passed: json['passed'] ?? false,
      userAnswers: Map<String, String>.from(json['userAnswers'] ?? {}),
      partnerAnswers: Map<String, String>.from(json['partnerAnswers'] ?? {}),
      matchingAnswers: List<String>.from(json['matchingAnswers'] ?? []),
      conflictingAnswers: List<String>.from(json['conflictingAnswers'] ?? []),
      categoryScores: Map<String, double>.from(json['categoryScores'] ?? {}),
      completedAt: DateTime.parse(json['completedAt']),
      xpEarned: json['xpEarned'] ?? 0,
      coinsEarned: json['coinsEarned'] ?? 0,
      gemsEarned: json['gemsEarned'],
    );
  }
}

// Dados predefinidos para testes de afinidade
class AffinityQuestionBank {
  static const List<Map<String, dynamic>> questions = [
    {
      'id': 'lifestyle_1',
      'question': 'Como você prefere passar seu tempo livre?',
      'category': 'lifestyle',
      'weight': 2,
      'options': [
        {
          'id': 'a',
          'text': 'Em casa, relaxando',
          'traits': {'introversion': 1, 'comfort': 1},
        },
        {
          'id': 'b',
          'text': 'Saindo com amigos',
          'traits': {'extroversion': 1, 'social': 1},
        },
        {
          'id': 'c',
          'text': 'Praticando esportes',
          'traits': {'active': 1, 'health': 1},
        },
        {
          'id': 'd',
          'text': 'Aprendendo algo novo',
          'traits': {'curiosity': 1, 'growth': 1},
        },
      ],
    },
    {
      'id': 'values_1',
      'question': 'O que é mais importante para você?',
      'category': 'values',
      'weight': 3,
      'options': [
        {
          'id': 'a',
          'text': 'Honestidade',
          'traits': {'integrity': 1, 'trust': 1},
        },
        {
          'id': 'b',
          'text': 'Lealdade',
          'traits': {'commitment': 1, 'reliability': 1},
        },
        {
          'id': 'c',
          'text': 'Liberdade',
          'traits': {'independence': 1, 'autonomy': 1},
        },
        {
          'id': 'd',
          'text': 'Família',
          'traits': {'family': 1, 'tradition': 1},
        },
      ],
    },
    {
      'id': 'communication_1',
      'question': 'Como você resolve conflitos?',
      'category': 'communication',
      'weight': 3,
      'options': [
        {
          'id': 'a',
          'text': 'Conversando diretamente',
          'traits': {'direct': 1, 'assertive': 1},
        },
        {
          'id': 'b',
          'text': 'Dando um tempo primeiro',
          'traits': {'thoughtful': 1, 'calm': 1},
        },
        {
          'id': 'c',
          'text': 'Buscando compromisso',
          'traits': {'diplomatic': 1, 'flexible': 1},
        },
        {
          'id': 'd',
          'text': 'Evitando o conflito',
          'traits': {'peaceful': 1, 'passive': 1},
        },
      ],
    },
    {
      'id': 'future_1',
      'question': 'Qual é seu maior objetivo nos próximos 5 anos?',
      'category': 'future',
      'weight': 2,
      'options': [
        {
          'id': 'a',
          'text': 'Crescimento profissional',
          'traits': {'ambitious': 1, 'career': 1},
        },
        {
          'id': 'b',
          'text': 'Relacionamento estável',
          'traits': {'romantic': 1, 'commitment': 1},
        },
        {
          'id': 'c',
          'text': 'Viajar pelo mundo',
          'traits': {'adventurous': 1, 'experience': 1},
        },
        {
          'id': 'd',
          'text': 'Estabilidade financeira',
          'traits': {'practical': 1, 'security': 1},
        },
      ],
    },
    {
      'id': 'personality_1',
      'question': 'Como seus amigos te descrevem?',
      'category': 'personality',
      'weight': 2,
      'options': [
        {
          'id': 'a',
          'text': 'Engraçado e espontâneo',
          'traits': {'humor': 1, 'spontaneous': 1},
        },
        {
          'id': 'b',
          'text': 'Confiável e organizado',
          'traits': {'reliable': 1, 'organized': 1},
        },
        {
          'id': 'c',
          'text': 'Criativo e sonhador',
          'traits': {'creative': 1, 'imaginative': 1},
        },
        {
          'id': 'd',
          'text': 'Analítico e lógico',
          'traits': {'logical': 1, 'analytical': 1},
        },
      ],
    },
  ];

  static List<AffinityQuestion> getQuestionsByInterests(
    List<String> interests,
  ) {
    // Em um app real, isso filtraria perguntas baseadas nos interesses
    return questions.map((q) => AffinityQuestion.fromJson(q)).toList();
  }

  static List<AffinityQuestion> getRandomQuestions(int count) {
    final allQuestions = questions
        .map((q) => AffinityQuestion.fromJson(q))
        .toList();
    allQuestions.shuffle();
    return allQuestions.take(count).toList();
  }
}
