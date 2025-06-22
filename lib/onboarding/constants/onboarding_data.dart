// lib/features/onboarding/constants/onboarding_data.dart

import 'package:unlock/models/avatar_model.dart';

class OnboardingConstants {
  // ✅ AVATARES GRATUITOS (12 opções)
  static const List<Map<String, dynamic>> freeAvatarsData = [
    {'id': 'cool', 'emoji': '😎', 'name': 'Cool', 'category': 'classic'},
    {'id': 'happy', 'emoji': '😊', 'name': 'Happy', 'category': 'classic'},
    {'id': 'star', 'emoji': '🤩', 'name': 'Star', 'category': 'fun'},
    {'id': 'think', 'emoji': '🤔', 'name': 'Thinker', 'category': 'smart'},
    {'id': 'party', 'emoji': '🥳', 'name': 'Party', 'category': 'fun'},
    {'id': 'zen', 'emoji': '😌', 'name': 'Zen', 'category': 'chill'},
    {'id': 'wink', 'emoji': '😉', 'name': 'Wink', 'category': 'classic'},
    {'id': 'laugh', 'emoji': '😂', 'name': 'Laugh', 'category': 'fun'},
    {'id': 'love', 'emoji': '😍', 'name': 'Love', 'category': 'romantic'},
    {'id': 'fire', 'emoji': '🔥', 'name': 'Fire', 'category': 'bold'},
    {'id': 'rocket', 'emoji': '🚀', 'name': 'Rocket', 'category': 'ambitious'},
    {'id': 'music', 'emoji': '🎵', 'name': 'Music', 'category': 'creative'},
  ];

  static List<AvatarModel> get freeAvatars {
    return freeAvatarsData
        .map(
          (data) => AvatarModel(
            id: data['id'],
            emoji: data['emoji'],
            name: data['name'],
            isPremium: false,
            category: data['category'],
          ),
        )
        .toList();
  }

  // ✅ INTERESSES PREDEFINIDOS (20 opções)
  static const List<String> availableInterests = [
    // Lifestyle (5)
    '🎵 Música',
    '🎬 Filmes',
    '📚 Leitura',
    '🏃‍♂️ Esportes',
    '🍳 Culinária',

    // Social (5)
    '🎉 Festas',
    '☕ Cafés',
    '🌍 Viagens',
    '🎲 Jogos',
    '🐕 Pets',

    // Creative (5)
    '🎨 Arte',
    '📸 Fotografia',
    '💻 Tecnologia',
    '🌱 Natureza',
    '✍️ Escrita',

    // Chill (5)
    '🧘‍♀️ Yoga',
    '🎯 Objetivos',
    '💼 Carreira',
    '🌟 Moda',
    '🔬 Ciência',
  ];

  // ✅ QUICK FILL POR IDADE
  static Map<String, List<String>> ageBasedInterests = {
    'teen': ['🎵 Música', '🎲 Jogos', '🎬 Filmes', '🏃‍♂️ Esportes'], // 13-17
    'young': ['🎉 Festas', '🌍 Viagens', '💻 Tecnologia', '🎨 Arte'], // 18-25
    'adult': ['💼 Carreira', '🍳 Culinária', '🌍 Viagens', '☕ Cafés'], // 26-35
    'mature': [
      '🌱 Natureza',
      '📚 Leitura',
      '🧘‍♀️ Yoga',
      '🎯 Objetivos',
    ], // 36+
  };

  /// Obter sugestões de interesses baseado na idade
  static List<String> getInterestSuggestionsForAge(int age) {
    if (age <= 17) return ageBasedInterests['teen']!;
    if (age <= 25) return ageBasedInterests['young']!;
    if (age <= 35) return ageBasedInterests['adult']!;
    return ageBasedInterests['mature']!;
  }

  // ✅ CONFIGURAÇÕES DO ONBOARDING
  static const int minInterests = 3;
  static const int maxInterests = 10;
  static const int maxCodinomeLength = 20;
  static const int minAge = 13;
  static const int adultAge = 18;
  static const int defaultConnectionLevel = 5;

  // Welcome bonuses
  static const int welcomeCoins = 200;
  static const int welcomeGems = 20;

  // ✅ VALIDAÇÕES
  static bool isValidAge(DateTime birthDate) {
    final age = DateTime.now().difference(birthDate).inDays ~/ 365;
    return age >= minAge;
  }

  static bool isValidCodinome(String codinome) {
    return codinome.trim().isNotEmpty &&
        codinome.length <= maxCodinomeLength &&
        RegExp(r'^[a-zA-Z0-9\s]+$').hasMatch(codinome);
  }

  static bool isValidInterestSelection(List<String> interests) {
    return interests.length >= minInterests && interests.length <= maxInterests;
  }

  // ✅ TEXTOS MOTIVACIONAIS
  static const Map<int, String> stepTitles = {
    0: 'Bem-vindo ao Unlock! 🔓',
    1: 'Escolha sua identidade anônima',
    2: 'O que te interessa?',
  };

  static const Map<int, String> stepSubtitles = {
    0: 'Vamos criar seu perfil anônimo em 3 passos simples',
    1: 'Como você quer se apresentar para o mundo?',
    2: 'Escolha pelo menos 3 para encontrar pessoas compatíveis',
  };

  static const Map<int, String> stepButtons = {
    0: 'Continuar',
    1: 'Quase pronto!',
    2: 'Começar a conectar!',
  };

  static const Map<int, String> progressTexts = {
    0: 'Etapa 1 de 3',
    1: 'Etapa 2 de 3 - Quase lá!',
    2: 'Etapa 3 de 3 - Última etapa!',
  };
}
