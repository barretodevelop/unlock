class QuestionModel {
  final String id;
  final String text;
  final List<String> options; // Para múltipla escolha
  final String? correctAnswer; // Para validação (opcional, se houver resposta "certa")
  final String type; // 'text_input', 'multiple_choice', 'emoji_choice'
  final List<String> relatedInterests; // Para selecionar perguntas relevantes

  QuestionModel({
    required this.id,
    required this.text,
    this.options = const [],
    this.correctAnswer,
    required this.type,
    required this.relatedInterests,
  });

  factory QuestionModel.fromJson(Map<String, dynamic> json) {
    return QuestionModel(
      id: json['id'] as String,
      text: json['text'] as String,
      options: List<String>.from(json['options'] ?? []),
      correctAnswer: json['correctAnswer'] as String?,
      type: json['type'] as String,
      relatedInterests: List<String>.from(json['relatedInterests'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'text': text,
      'options': options,
      'correctAnswer': correctAnswer,
      'type': type,
      'relatedInterests': relatedInterests,
    };
  }

  @override
  String toString() =>
      'QuestionModel(id: $id, text: $text, type: $type, interests: $relatedInterests)';
}