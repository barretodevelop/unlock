// lib/services/test_users_service.dart
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:unlock/models/user_model.dart';

class TestUsersService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final Random _random = Random();

  // ============== DADOS DE TESTE ==============
  static const List<String> _nomes = [
    'Ana',
    'Bruno',
    'Carla',
    'Daniel',
    'Elena',
    'Felipe',
    'Gabriela',
    'Hugo',
    'Isabela',
    'João',
    'Kelly',
    'Lucas',
    'Marina',
    'Nicolas',
    'Olivia',
    'Pedro',
    'Quintessa',
    'Rafael',
    'Sofia',
    'Thiago',
    'Ursula',
    'Victor',
    'Wendy',
    'Xavier',
    'Yasmin',
    'Zeca',
    'Amanda',
    'Bernardo',
    'Camila',
    'Diego',
    'Eduarda',
    'Fabio',
    'Giovanna',
    'Henrique',
    'Ingrid',
    'Julio',
    'Larissa',
    'Mateus',
    'Natalia',
    'Otavio',
  ];

  static const List<String> _sobrenomes = [
    'Silva',
    'Santos',
    'Oliveira',
    'Souza',
    'Rodrigues',
    'Ferreira',
    'Alves',
    'Pereira',
    'Lima',
    'Gomes',
    'Costa',
    'Ribeiro',
    'Martins',
    'Carvalho',
    'Almeida',
    'Lopes',
    'Soares',
    'Fernandes',
    'Vieira',
    'Barbosa',
    'Rocha',
    'Dias',
    'Monteiro',
    'Cardoso',
    'Reis',
    'Araújo',
    'Castro',
    'Andrade',
    'Nascimento',
    'Correia',
    'Marques',
    'Campos',
  ];

  static const List<String> _codinomes = [
    'Aventureiro',
    'Explorador',
    'Sonhador',
    'Criativo',
    'Curioso',
    'Alegre',
    'Zen',
    'Artista',
    'Pensador',
    'Viajante',
    'Músico',
    'Leitor',
    'Gamer',
    'Foodie',
    'Fitness',
    'Tech',
    'Nature',
    'Urban',
    'Chill',
    'Energy',
    'Wisdom',
    'Magic',
    'Spark',
    'Bright',
    'Clever',
    'Swift',
    'Bold',
    'Gentle',
    'Witty',
    'Calm',
    'Wild',
    'Pure',
    'Noble',
  ];

  static const List<String> _interesses = [
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

  static const List<String> _relationshipTypes = [
    'amizade',
    'namoro',
    'casual',
    'mentoria',
    'networking',
  ];

  static const List<String> _avatarIds = [
    'person',
    'star',
    'bolt',
    'palette',
    'diamond',
  ];

  static const List<String> _bordersIds = [
    'none',
    'blue',
    'green',
    'purple',
    'rainbow',
  ];

  static const List<String> _badgesIds = ['connected', 'social', 'legendary'];

  // ============== CRIAR USUÁRIOS DE TESTE ==============
  static Future<List<UserModel>> createTestUsers({int count = 20}) async {
    final List<UserModel> createdUsers = [];

    try {
      if (kDebugMode) {
        print('🧪 TestUsersService: Criando $count usuários de teste...');
      }

      for (int i = 0; i < count; i++) {
        final user = _generateRandomUser(i);

        // Salvar no Firestore
        await _firestore.collection('users').doc(user.uid).set(user.toJson());

        // Marcar como online
        await _setUserOnline(user.uid);

        createdUsers.add(user);

        if (kDebugMode && (i + 1) % 5 == 0) {
          print('✅ TestUsersService: ${i + 1}/$count usuários criados');
        }
      }

      if (kDebugMode) {
        print(
          '🎉 TestUsersService: $count usuários de teste criados com sucesso!',
        );
      }

      return createdUsers;
    } catch (e) {
      if (kDebugMode) {
        print('❌ TestUsersService: Erro ao criar usuários: $e');
      }
      rethrow;
    }
  }

  // ============== GERAR USUÁRIO ALEATÓRIO ==============
  static UserModel _generateRandomUser(int index) {
    final nome = _nomes[_random.nextInt(_nomes.length)];
    final sobrenome = _sobrenomes[_random.nextInt(_sobrenomes.length)];
    final codinome =
        '${_codinomes[_random.nextInt(_codinomes.length)]}${10 + _random.nextInt(90)}';

    // Gerar UID único
    final uid = 'test_user_${DateTime.now().millisecondsSinceEpoch}_$index';

    // Gerar email
    final email = '${nome.toLowerCase()}.${sobrenome.toLowerCase()}@test.com';

    // Selecionar interesses (3-7 aleatórios)
    final numInteresses = 3 + _random.nextInt(5);
    final interessesEscolhidos = <String>[];
    final interessesDisponiveis = List<String>.from(_interesses);
    interessesDisponiveis.shuffle();

    for (
      int i = 0;
      i < numInteresses && i < interessesDisponiveis.length;
      i++
    ) {
      interessesEscolhidos.add(interessesDisponiveis[i]);
    }

    // Gerar dados variados
    final level = 1 + _random.nextInt(30);
    final xp = level * 100 + _random.nextInt(100);
    final coins = 50 + _random.nextInt(500);
    final gems = 1 + _random.nextInt(20);

    return UserModel(
      uid: uid,
      username: '${nome.toLowerCase()}_${sobrenome.toLowerCase()}',
      displayName: '$nome $sobrenome',
      avatar: _avatarIds[_random.nextInt(_avatarIds.length)],
      email: email,
      level: level,
      xp: xp,
      coins: coins,
      gems: gems,
      createdAt: DateTime.now().subtract(Duration(days: _random.nextInt(365))),
      lastLoginAt: DateTime.now().subtract(
        Duration(minutes: _random.nextInt(10)),
      ),
      aiConfig: {},
      // Campos específicos do social matching
      codinome: codinome,
      interesses: interessesEscolhidos,
      relationshipInterest:
          _relationshipTypes[_random.nextInt(_relationshipTypes.length)],
      onboardingCompleted: true,
    );
  }

  // ============== MARCAR USUÁRIO COMO ONLINE ==============
  static Future<void> _setUserOnline(String uid) async {
    try {
      await _firestore.collection('users').doc(uid).update({
        'isOnline': true,
        'lastActivity': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      if (kDebugMode) {
        print(
          '❌ TestUsersService: Erro ao marcar usuário $uid como online: $e',
        );
      }
    }
  }

  // ============== CRIAR USUÁRIOS ESPECÍFICOS ==============
  static Future<List<UserModel>> createSpecificTestUsers() async {
    final List<UserModel> specificUsers = [];

    try {
      if (kDebugMode) {
        print(
          '🎯 TestUsersService: Criando usuários específicos para teste...',
        );
      }

      // Usuário 1: Alta compatibilidade com música e viagens
      final user1 = _createSpecificUser(
        index: 1001,
        nome: 'Luna',
        sobrenome: 'Melodia',
        codinome: 'MusicVibes23',
        interesses: ['Música', 'Viagens', 'Fotografia', 'Artes'],
        relationshipInterest: 'amizade',
        level: 15,
      );

      // Usuário 2: Gamer e tech
      final user2 = _createSpecificUser(
        index: 1002,
        nome: 'Alex',
        sobrenome: 'Code',
        codinome: 'TechMaster',
        interesses: ['Jogos', 'Tecnologia', 'Programação', 'Séries'],
        relationshipInterest: 'amizade',
        level: 22,
      );

      // Usuário 3: Fitness e natureza
      final user3 = _createSpecificUser(
        index: 1003,
        nome: 'Maya',
        sobrenome: 'Verde',
        codinome: 'NatureFit',
        interesses: ['Fitness', 'Natureza', 'Yoga', 'Meditação'],
        relationshipInterest: 'namoro',
        level: 18,
      );

      // Usuário 4: Artista criativo
      final user4 = _createSpecificUser(
        index: 1004,
        nome: 'Dante',
        sobrenome: 'Arte',
        codinome: 'CreativeWave',
        interesses: ['Artes', 'Design', 'Fotografia', 'Teatro'],
        relationshipInterest: 'networking',
        level: 25,
      );

      // Usuário 5: Aventureiro
      final user5 = _createSpecificUser(
        index: 1005,
        nome: 'Zara',
        sobrenome: 'Wild',
        codinome: 'Adventurer99',
        interesses: ['Viagens', 'Esportes', 'Natureza', 'Fotografia'],
        relationshipInterest: 'casual',
        level: 20,
      );

      final users = [user1, user2, user3, user4, user5];

      for (final user in users) {
        await _firestore.collection('users').doc(user.uid).set(user.toJson());
        await _setUserOnline(user.uid);
        specificUsers.add(user);
      }

      if (kDebugMode) {
        print(
          '✅ TestUsersService: ${users.length} usuários específicos criados',
        );
      }

      return specificUsers;
    } catch (e) {
      if (kDebugMode) {
        print('❌ TestUsersService: Erro ao criar usuários específicos: $e');
      }
      rethrow;
    }
  }

  static UserModel _createSpecificUser({
    required int index,
    required String nome,
    required String sobrenome,
    required String codinome,
    required List<String> interesses,
    required String relationshipInterest,
    required int level,
  }) {
    final uid = 'specific_user_${DateTime.now().millisecondsSinceEpoch}_$index';
    final email =
        '${nome.toLowerCase()}.${sobrenome.toLowerCase()}@specific.com';
    final xp = level * 100 + _random.nextInt(50);

    return UserModel(
      uid: uid,
      username: '${nome.toLowerCase()}_${sobrenome.toLowerCase()}',
      displayName: '$nome $sobrenome',
      avatar: _avatarIds[_random.nextInt(_avatarIds.length)],
      email: email,
      level: level,
      xp: xp,
      coins: 100 + _random.nextInt(300),
      gems: 5 + _random.nextInt(15),
      createdAt: DateTime.now().subtract(Duration(days: _random.nextInt(180))),
      lastLoginAt: DateTime.now().subtract(
        Duration(minutes: _random.nextInt(5)),
      ),
      aiConfig: {},
      codinome: codinome,
      interesses: interesses,
      relationshipInterest: relationshipInterest,
      onboardingCompleted: true,
    );
  }

  // ============== MANTER USUÁRIOS ONLINE ==============
  static Future<void> keepUsersOnline() async {
    try {
      final now = DateTime.now();
      final batch = _firestore.batch();

      // Buscar usuários de teste
      final snapshot = await _firestore
          .collection('users')
          .where('email', isGreaterThanOrEqualTo: '@test.com')
          .where('email', isLessThanOrEqualTo: '@test.com\uf8ff')
          .get();

      for (final doc in snapshot.docs) {
        batch.update(doc.reference, {
          'isOnline': true,
          'lastActivity': now.toIso8601String(),
        });
      }

      // Buscar usuários específicos também
      final specificSnapshot = await _firestore
          .collection('users')
          .where('email', isGreaterThanOrEqualTo: '@specific.com')
          .where('email', isLessThanOrEqualTo: '@specific.com\uf8ff')
          .get();

      for (final doc in specificSnapshot.docs) {
        batch.update(doc.reference, {
          'isOnline': true,
          'lastActivity': now.toIso8601String(),
        });
      }

      await batch.commit();

      if (kDebugMode) {
        final totalUsers = snapshot.docs.length + specificSnapshot.docs.length;
        print('🔄 TestUsersService: $totalUsers usuários marcados como online');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ TestUsersService: Erro ao manter usuários online: $e');
      }
    }
  }

  // ============== LIMPAR USUÁRIOS DE TESTE ==============
  static Future<void> deleteAllTestUsers() async {
    try {
      if (kDebugMode) {
        print('🗑️ TestUsersService: Removendo usuários de teste...');
      }

      // Deletar usuários de teste (@test.com)
      final testSnapshot = await _firestore
          .collection('users')
          .where('email', isGreaterThanOrEqualTo: '@test.com')
          .where('email', isLessThanOrEqualTo: '@test.com\uf8ff')
          .get();

      // Deletar usuários específicos (@specific.com)
      final specificSnapshot = await _firestore
          .collection('users')
          .where('email', isGreaterThanOrEqualTo: '@specific.com')
          .where('email', isLessThanOrEqualTo: '@specific.com\uf8ff')
          .get();

      final batch = _firestore.batch();

      for (final doc in testSnapshot.docs) {
        batch.delete(doc.reference);
      }

      for (final doc in specificSnapshot.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();

      final totalDeleted =
          testSnapshot.docs.length + specificSnapshot.docs.length;

      if (kDebugMode) {
        print('✅ TestUsersService: $totalDeleted usuários de teste removidos');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ TestUsersService: Erro ao remover usuários de teste: $e');
      }
      rethrow;
    }
  }

  // ============== CRIAR CENÁRIOS DE TESTE ==============
  static Future<void> createTestScenarios() async {
    try {
      if (kDebugMode) {
        print('🎬 TestUsersService: Criando cenários de teste...');
      }

      // Cenário 1: Usuários com alta compatibilidade musical
      await _createCompatibilityGroup(
        theme: 'Música',
        interests: ['Música', 'Podcasts', 'Artes'],
        relationshipType: 'amizade',
        count: 3,
      );

      // Cenário 2: Grupo de gamers
      await _createCompatibilityGroup(
        theme: 'Gaming',
        interests: ['Jogos', 'Tecnologia', 'Séries'],
        relationshipType: 'amizade',
        count: 3,
      );

      // Cenário 3: Pessoas buscando namoro com interesses fitness
      await _createCompatibilityGroup(
        theme: 'Fitness',
        interests: ['Fitness', 'Esportes', 'Yoga', 'Natureza'],
        relationshipType: 'namoro',
        count: 4,
      );

      if (kDebugMode) {
        print('✅ TestUsersService: Cenários de teste criados');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ TestUsersService: Erro ao criar cenários: $e');
      }
    }
  }

  static Future<void> _createCompatibilityGroup({
    required String theme,
    required List<String> interests,
    required String relationshipType,
    required int count,
  }) async {
    for (int i = 0; i < count; i++) {
      final user = _createSpecificUser(
        index: 2000 + DateTime.now().millisecondsSinceEpoch % 1000 + i,
        nome: '${theme}User${i + 1}',
        sobrenome: 'Test',
        codinome: '${theme}Lover${10 + i}',
        interesses: interests,
        relationshipInterest: relationshipType,
        level: 10 + _random.nextInt(15),
      );

      await _firestore.collection('users').doc(user.uid).set(user.toJson());
      await _setUserOnline(user.uid);
    }
  }

  // ============== ESTATÍSTICAS ==============
  static Future<Map<String, dynamic>> getTestUsersStats() async {
    try {
      final testSnapshot = await _firestore
          .collection('users')
          .where('email', isGreaterThanOrEqualTo: '@test.com')
          .where('email', isLessThanOrEqualTo: '@test.com\uf8ff')
          .get();

      final specificSnapshot = await _firestore
          .collection('users')
          .where('email', isGreaterThanOrEqualTo: '@specific.com')
          .where('email', isLessThanOrEqualTo: '@specific.com\uf8ff')
          .get();

      final onlineUsers = await _firestore
          .collection('users')
          .where('isOnline', isEqualTo: true)
          .get();

      return {
        'totalTestUsers': testSnapshot.docs.length,
        'totalSpecificUsers': specificSnapshot.docs.length,
        'totalUsers': testSnapshot.docs.length + specificSnapshot.docs.length,
        'onlineUsers': onlineUsers.docs.length,
        'lastUpdated': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      if (kDebugMode) {
        print('❌ TestUsersService: Erro ao obter estatísticas: $e');
      }
      return {'error': e.toString()};
    }
  }
}
