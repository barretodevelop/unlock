// ============== DATA PROVIDERS E MOCKS CENTRALIZADOS ==============

import 'package:flutter/material.dart';

class MockDataProvider {
  // Singleton para acesso global
  static final MockDataProvider _instance = MockDataProvider._internal();
  factory MockDataProvider() => _instance;
  MockDataProvider._internal();

  // ============== MOCK DE USUÁRIOS POTENCIAIS ==============
  static final List<Map<String, dynamic>> potentialConnections = [
    {
      'id': '1',
      'nome': 'Ayla ✨',
      'idade': 23,
      'bio': 'Adoro descobrir novos sabores e viajar pelo mundo! 🌍',
      'interesses': ['Música', 'Culinária', 'Viagens', 'Dança'],
      'relationshipInterest': 'Namoro',
      'avatarId': 'star',
      'borderId': 'blue',
      'badgeId': 'social',
      'lastSeen': 'Online',
      'distance': '2 km',
      'verified': true,
      'photos': ['photo1', 'photo2', 'photo3'],
    },
    {
      'id': '2',
      'nome': 'Lucas 🎮',
      'idade': 26,
      'bio': 'Desenvolvedor apaixonado por tecnologia e games retro! 🎯',
      'interesses': ['Jogos', 'Tecnologia', 'Filmes', 'Programação'],
      'relationshipInterest': 'Amizade',
      'avatarId': 'bolt',
      'borderId': 'green',
      'badgeId': 'connected',
      'lastSeen': '5 min atrás',
      'distance': '1.5 km',
      'verified': true,
      'photos': ['photo1', 'photo2'],
    },
    {
      'id': '3',
      'nome': 'Sofia 📚',
      'idade': 24,
      'bio':
          'Escritora e amante da natureza. Sempre em busca de novas histórias! 📖',
      'interesses': ['Leitura', 'Artes', 'Natureza', 'Escrita'],
      'relationshipInterest': 'Casual',
      'avatarId': 'palette',
      'borderId': 'purple',
      'badgeId': 'legendary',
      'lastSeen': '1h atrás',
      'distance': '3.2 km',
      'verified': false,
      'photos': ['photo1', 'photo2', 'photo3', 'photo4'],
    },
    {
      'id': '4',
      'nome': 'Diego ⚽',
      'idade': 29,
      'bio': 'Personal trainer e coach. Vamos treinar juntos? 💪',
      'interesses': ['Esportes', 'Fitness', 'Nutrição', 'Podcasts'],
      'relationshipInterest': 'Mentoria',
      'avatarId': 'diamond',
      'borderId': 'rainbow',
      'badgeId': 'social',
      'lastSeen': 'Online',
      'distance': '800m',
      'verified': true,
      'photos': ['photo1', 'photo2'],
    },
    {
      'id': '5',
      'nome': 'Bia 🎨',
      'idade': 27,
      'bio':
          'Designer gráfica e barista nas horas vagas. Café e arte = vida! ☕',
      'interesses': ['Design', 'Arte', 'Café', 'Fotografia'],
      'relationshipInterest': 'Networking',
      'avatarId': 'palette',
      'borderId': 'blue',
      'badgeId': 'connected',
      'lastSeen': '30 min atrás',
      'distance': '1.2 km',
      'verified': true,
      'photos': ['photo1', 'photo2', 'photo3'],
    },
  ];

  // ============== MOCK DE CONEXÕES RECENTES ==============
  static final List<Map<String, dynamic>> recentConnections = [
    {
      'id': '1',
      'nome': 'Ana S.',
      'status': 'Online',
      'avatarId': 'star',
      'lastMessage': 'Oi! Como foi seu dia?',
      'lastMessageTime': '2 min atrás',
      'unreadCount': 2,
      'interesses': ['Música', 'Viagens'],
    },
    {
      'id': '2',
      'nome': 'Pedro R.',
      'status': 'Última conexão: 2h',
      'avatarId': 'bolt',
      'lastMessage': 'Vamos jogar mais tarde?',
      'lastMessageTime': '1h atrás',
      'unreadCount': 0,
      'interesses': ['Jogos', 'Tecnologia'],
    },
    {
      'id': '3',
      'nome': 'Sofia G.',
      'status': 'Online',
      'avatarId': 'palette',
      'lastMessage': 'Adorei o livro que você recomendou!',
      'lastMessageTime': '5 min atrás',
      'unreadCount': 1,
      'interesses': ['Leitura', 'Artes'],
    },
  ];

  // ============== MOCK DE MISSÕES DIÁRIAS ==============
  static final List<Map<String, dynamic>> allDailyMissions = [
    {
      'id': 'm1',
      'title': 'Conecte-se!',
      'description': 'Envie 3 mensagens no chat.',
      'xp': 10,
      'moedas': 5,
      'type': 'chat',
      'target': 3,
      'icon': Icons.chat,
      'difficulty': 'easy',
    },
    {
      'id': 'm2',
      'title': 'Jogador!',
      'description': 'Jogue um mini-jogo com uma conexão.',
      'xp': 15,
      'moedas': 8,
      'type': 'minigame',
      'target': 1,
      'icon': Icons.videogame_asset,
      'difficulty': 'medium',
    },
    {
      'id': 'm3',
      'title': 'Explorador!',
      'description': 'Visite um perfil de conexão.',
      'xp': 8,
      'moedas': 4,
      'type': 'profile_visit',
      'target': 1,
      'icon': Icons.person_search,
      'difficulty': 'easy',
    },
    {
      'id': 'm4',
      'title': 'Matchmaker!',
      'description': 'Conecte-se com alguém com interesse em "Filmes".',
      'xp': 12,
      'moedas': 6,
      'type': 'specific_match',
      'target': 1,
      'icon': Icons.movie,
      'difficulty': 'medium',
    },
    {
      'id': 'm5',
      'title': 'Expressivo!',
      'description': 'Reaja a uma mensagem no chat.',
      'xp': 7,
      'moedas': 3,
      'type': 'reaction',
      'target': 1,
      'icon': Icons.emoji_emotions,
      'difficulty': 'easy',
    },
    {
      'id': 'm6',
      'title': 'Personalizado!',
      'description': 'Compre um item na loja.',
      'xp': 20,
      'moedas': 10,
      'type': 'purchase',
      'target': 1,
      'icon': Icons.shopping_bag,
      'difficulty': 'hard',
    },
  ];

  // ============== MOCK DE ITENS DA LOJA ==============
  static final Map<String, List<Map<String, dynamic>>> shopItems = {
    'avatars': [
      {
        'id': 'person',
        'name': 'Avatar Padrão',
        'icon': Icons.person,
        'cost': 0,
        'currency': 'moedas',
        'rarity': 'common',
        'description': 'Seu avatar inicial clássico',
        'isDefault': true,
      },
      {
        'id': 'star',
        'name': 'Avatar Estrela',
        'icon': Icons.star,
        'cost': 20,
        'currency': 'moedas',
        'rarity': 'common',
        'description': 'Brilhe como uma estrela!',
        'isDefault': false,
      },
      {
        'id': 'bolt',
        'name': 'Avatar Raio',
        'icon': Icons.bolt,
        'cost': 30,
        'currency': 'moedas',
        'rarity': 'uncommon',
        'description': 'Energia pura em formato de avatar',
        'isDefault': false,
      },
      {
        'id': 'palette',
        'name': 'Avatar Artístico',
        'icon': Icons.palette,
        'cost': 40,
        'currency': 'moedas',
        'rarity': 'uncommon',
        'description': 'Para os criativos de plantão',
        'isDefault': false,
      },
      {
        'id': 'diamond',
        'name': 'Avatar Diamante',
        'icon': Icons.diamond,
        'cost': 2,
        'currency': 'gemas',
        'rarity': 'rare',
        'description': 'Preciosidade rara e valiosa',
        'isDefault': false,
      },
    ],
    'borders': [
      {
        'id': 'none',
        'name': 'Sem Borda',
        'color': Colors.transparent,
        'cost': 0,
        'currency': 'moedas',
        'rarity': 'common',
        'description': 'Visual limpo e minimalista',
        'isDefault': true,
      },
      {
        'id': 'blue',
        'name': 'Borda Azul',
        'color': Colors.blue,
        'cost': 15,
        'currency': 'moedas',
        'rarity': 'common',
        'description': 'Calma e confiança',
        'isDefault': false,
      },
      {
        'id': 'green',
        'name': 'Borda Verde',
        'color': Colors.green,
        'cost': 25,
        'currency': 'moedas',
        'rarity': 'uncommon',
        'description': 'Natureza e prosperidade',
        'isDefault': false,
      },
      {
        'id': 'purple',
        'name': 'Borda Roxa',
        'color': Colors.purple,
        'cost': 35,
        'currency': 'moedas',
        'rarity': 'uncommon',
        'description': 'Mistério e criatividade',
        'isDefault': false,
      },
      {
        'id': 'rainbow',
        'name': 'Borda Arco-Íris',
        'color': Colors.cyanAccent,
        'cost': 1,
        'currency': 'gemas',
        'rarity': 'epic',
        'description': 'Todas as cores em harmonia',
        'isDefault': false,
      },
    ],
    'badges': [
      {
        'id': 'connected',
        'name': 'Emblema Conectado',
        'icon': Icons.link,
        'cost': 10,
        'currency': 'moedas',
        'rarity': 'common',
        'description': 'Para quem faz boas conexões',
        'isDefault': false,
      },
      {
        'id': 'social',
        'name': 'Emblema Social',
        'icon': Icons.sentiment_very_satisfied,
        'cost': 20,
        'currency': 'moedas',
        'rarity': 'uncommon',
        'description': 'Mestre das interações sociais',
        'isDefault': false,
      },
      {
        'id': 'legendary',
        'name': 'Emblema Lendário',
        'icon': Icons.star_border,
        'cost': 3,
        'currency': 'gemas',
        'rarity': 'legendary',
        'description': 'Para os verdadeiros lendários',
        'isDefault': false,
      },
    ],
    'themes': [
      {
        'id': 'default',
        'name': 'Tema Padrão',
        'primaryColor': Colors.blueGrey,
        'backgroundColor': Colors.white,
        'cost': 0,
        'currency': 'moedas',
        'rarity': 'common',
        'description': 'Visual clássico e limpo',
        'isDefault': true,
      },
      {
        'id': 'dark_theme',
        'name': 'Tema Noturno',
        'primaryColor': Colors.black,
        'backgroundColor': Colors.grey.shade900,
        'cost': 50,
        'currency': 'moedas',
        'rarity': 'uncommon',
        'description': 'Para os notívagos',
        'isDefault': false,
      },
      {
        'id': 'pastel_theme',
        'name': 'Tema Pastel',
        'primaryColor': Colors.pink.shade300,
        'backgroundColor': Colors.pink.shade50,
        'cost': 70,
        'currency': 'moedas',
        'rarity': 'uncommon',
        'description': 'Suave e relaxante',
        'isDefault': false,
      },
      {
        'id': 'golden_theme',
        'name': 'Tema Dourado',
        'primaryColor': Colors.amber.shade700,
        'backgroundColor': Colors.amber.shade50,
        'cost': 5,
        'currency': 'gemas',
        'rarity': 'epic',
        'description': 'Luxo e elegância',
        'isDefault': false,
      },
    ],
  };

  // ============== MOCK DE PERGUNTAS PARA TESTE DE CONEXÃO ==============
  static final List<Map<String, dynamic>> connectionQuestions = [
    {
      'id': 'q1',
      'text': 'Qual sua visão sobre filmes de ficção científica?',
      'category': 'Filmes',
      'difficulty': 'easy',
    },
    {
      'id': 'q2',
      'text':
          'Se você pudesse viajar para qualquer lugar agora, para onde iria?',
      'category': 'Viagens',
      'difficulty': 'easy',
    },
    {
      'id': 'q3',
      'text': 'Qual seu hobby favorito para relaxar?',
      'category': 'Geral',
      'difficulty': 'easy',
    },
    {
      'id': 'q4',
      'text': 'O que você mais gosta em música pop?',
      'category': 'Música',
      'difficulty': 'medium',
    },
    {
      'id': 'q5',
      'text': 'Você prefere ler livros de fantasia ou de mistério?',
      'category': 'Leitura',
      'difficulty': 'medium',
    },
    {
      'id': 'q6',
      'text': 'Qual esporte você mais gosta de assistir?',
      'category': 'Esportes',
      'difficulty': 'easy',
    },
    {
      'id': 'q7',
      'text': 'Como a tecnologia mudou sua forma de se conectar com pessoas?',
      'category': 'Tecnologia',
      'difficulty': 'hard',
    },
    {
      'id': 'q8',
      'text': 'Qual foi a última experiência culinária que te surpreendeu?',
      'category': 'Culinária',
      'difficulty': 'medium',
    },
  ];

  // ============== CONFIGURAÇÕES E CONSTANTES ==============
  static final Map<String, dynamic> appConfig = {
    'maxDailyMissions': 3,
    'maxMatchesPerDay': 10,
    'maxFreeMessagesPerDay': 20,
    'connectionTestQuestions': 2,
    'miniGameSuccessRate': 0.6, // 60% de chance de sucesso
    'initialResources': {'xp': 100, 'moedas': 50, 'gemas': 5, 'dailyStreak': 1},
    'rarityColors': {
      'common': Colors.grey,
      'uncommon': Colors.green,
      'rare': Colors.blue,
      'epic': Colors.purple,
      'legendary': Colors.orange,
    },
  };

  // ============== INTERESSES DISPONÍVEIS ==============
  static final List<String> availableInterests = [
    'Jogos',
    'Filmes',
    'Música',
    'Leitura',
    'Viagens',
    'Culinária',
    'Esportes',
    'Tecnologia',
    'Artes',
    'Moda',
    'Natureza',
    'Ciência',
    'Fotografia',
    'Dança',
    'Teatro',
    'Fitness',
    'Yoga',
    'Meditação',
    'Podcasts',
    'Séries',
    'Animação',
    'Design',
    'Programação',
    'Empreendedorismo',
    'Investimentos',
  ];

  // ============== TIPOS DE RELACIONAMENTO ==============
  static final List<Map<String, dynamic>> relationshipTypes = [
    {
      'id': 'amizade',
      'name': 'Amizade',
      'icon': Icons.people_alt,
      'color': Colors.blue,
      'description': 'Conhecer pessoas legais para uma amizade duradoura',
    },
    {
      'id': 'namoro',
      'name': 'Namoro',
      'icon': Icons.favorite,
      'color': Colors.red,
      'description': 'Encontrar alguém especial para um relacionamento sério',
    },
    {
      'id': 'casual',
      'name': 'Casual',
      'icon': Icons.emoji_emotions,
      'color': Colors.orange,
      'description': 'Conexões descontraídas sem compromisso',
    },
    {
      'id': 'mentoria',
      'name': 'Mentoria',
      'icon': Icons.school,
      'color': Colors.green,
      'description': 'Aprender ou ensinar algo novo',
    },
    {
      'id': 'networking',
      'name': 'Networking',
      'icon': Icons.business_center,
      'color': Colors.purple,
      'description': 'Fazer contatos profissionais',
    },
  ];

  // ============== MÉTODOS HELPER ==============

  List<Map<String, dynamic>> getRandomConnections({int count = 3}) {
    final shuffled = List<Map<String, dynamic>>.from(potentialConnections);
    shuffled.shuffle();
    return shuffled.take(count).toList();
  }

  List<Map<String, dynamic>> getDailyMissions({int count = 3}) {
    final shuffled = List<Map<String, dynamic>>.from(allDailyMissions);
    shuffled.shuffle();
    return shuffled.take(count).toList();
  }

  List<Map<String, dynamic>> getQuestionsByCategory(
    String category, {
    int count = 2,
  }) {
    var filtered = connectionQuestions
        .where((q) => q['category'] == category || q['category'] == 'Geral')
        .toList();

    if (filtered.length < count) {
      filtered.addAll(connectionQuestions.where((q) => !filtered.contains(q)));
    }

    filtered.shuffle();
    return filtered.take(count).toList();
  }

  Map<String, dynamic>? getItemById(String category, String id) {
    return shopItems[category]?.firstWhere(
      (item) => item['id'] == id,
      orElse: () => shopItems[category]!.first,
    );
  }

  Color getRarityColor(String rarity) {
    return appConfig['rarityColors'][rarity] ?? Colors.grey;
  }

  Map<String, dynamic>? getRelationshipTypeById(String id) {
    return relationshipTypes.firstWhere(
      (type) => type['id'] == id,
      orElse: () => relationshipTypes.first,
    );
  }
}
