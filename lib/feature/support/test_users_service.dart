// lib/services/support/test_users_service.dart
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
    'Valmira',
    'Enzo',
    'yann',
    'Matheus',
    'Gabriele',
    'Maria Eduarda',
    'Humberto',
    'Graciane',
    'Leilane',
    'Silma',
    'Marcia',
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
    'networking',
    'mentoria',
  ];

  static const List<String> _avatarIds = [
    'star',
    'bolt',
    'heart',
    'diamond',
    'crown',
    'fire',
    'leaf',
    'wave',
    'moon',
    'sun',
    'palette',
    'music',
    'camera',
    'plane',
    'rocket',
  ];

  // ============== CRIAR USUÁRIOS ALEATÓRIOS ==============
  static Future<List<UserModel>> createTestUsers({int count = 10}) async {
    final List<UserModel> users = [];

    try {
      if (kDebugMode) {
        print('🎯 TestUsersService: Criando $count usuários de teste...');
      }

      for (int i = 0; i < count; i++) {
        final user = _generateRandomUser(i);
        await _firestore.collection('users').doc(user.uid).set(user.toJson());
        await _setUserOnline(user.uid);
        users.add(user);
      }

      if (kDebugMode) {
        print('✅ TestUsersService: $count usuários criados com sucesso');
      }

      return users;
    } catch (e) {
      if (kDebugMode) {
        print('❌ TestUsersService: Erro ao criar usuários: $e');
      }
      rethrow;
    }
  }

  static UserModel _generateRandomUser(int index) {
    final nome = _nomes[_random.nextInt(_nomes.length)];
    final sobrenome = _sobrenomes[_random.nextInt(_sobrenomes.length)];
    final codinome = _codinomes[_random.nextInt(_codinomes.length)];
    final uid = 'test_user_${DateTime.now().millisecondsSinceEpoch}_$index';
    final email = '${nome.toLowerCase()}.${sobrenome.toLowerCase()}@test.com';

    // Gerar interesses aleatórios (2-5 interesses)
    final numInteresses = 2 + _random.nextInt(4);
    final interessesUsuario = <String>[];
    final interessesDisponiveis = List<String>.from(_interesses);

    for (int i = 0; i < numInteresses; i++) {
      if (interessesDisponiveis.isNotEmpty) {
        final interesse = interessesDisponiveis.removeAt(
          _random.nextInt(interessesDisponiveis.length),
        );
        interessesUsuario.add(interesse);
      }
    }

    final level = 1 + _random.nextInt(25);
    final xp = level * 100 + _random.nextInt(50);

    return UserModel(
      uid: uid,
      username: '${nome.toLowerCase()}_${sobrenome.toLowerCase()}',
      displayName: '$nome $sobrenome',
      avatar: _avatarIds[_random.nextInt(_avatarIds.length)],
      email: email,
      level: level,
      xp: xp,
      coins: 50 + _random.nextInt(200),
      gems: 1 + _random.nextInt(10),
      createdAt: DateTime.now().subtract(Duration(days: _random.nextInt(90))),
      lastLoginAt: DateTime.now().subtract(
        Duration(minutes: _random.nextInt(30)),
      ),
      aiConfig: {},
      codinome: '$codinome${10 + _random.nextInt(90)}',
      interesses: interessesUsuario,
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

  // ============== CRIAR CENÁRIOS DE TESTE ==============
  static Future<void> createTestScenarios() async {
    try {
      if (kDebugMode) {
        print('🎯 TestUsersService: Criando cenários de teste...');
      }

      // Cenário 1: Grupo de usuários interessados em música
      await _createCompatibilityGroup(
        theme: 'Music',
        interests: ['Música', 'Dança', 'Teatro', 'Artes'],
        relationshipType: 'amizade',
        count: 3,
      );

      // Cenário 2: Grupo tech
      await _createCompatibilityGroup(
        theme: 'Tech',
        interests: ['Tecnologia', 'Programação', 'Jogos', 'Ciência'],
        relationshipType: 'networking',
        count: 3,
      );

      // Cenário 3: Grupo fitness
      await _createCompatibilityGroup(
        theme: 'Fitness',
        interests: ['Fitness', 'Esportes', 'Yoga', 'Natureza'],
        relationshipType: 'namoro',
        count: 2,
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
          .where('uid', isGreaterThanOrEqualTo: 'test_user_')
          // .where('email', isGreaterThanOrEqualTo: '@test.com')
          // .where('email', isLessThanOrEqualTo: '@test.com\uf8ff')
          .get();

      // Deletar usuários específicos (@specific.com)
      final specificSnapshot = await _firestore
          .collection('users')
          .where('uid', isGreaterThanOrEqualTo: 'specific_user_')
          // .where('email', isGreaterThanOrEqualTo: '@specific.com')
          // .where('email', isLessThanOrEqualTo: '@specific.com\uf8ff')
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
        print('✅ TestUsersService: $totalDeleted usuários removidos');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ TestUsersService: Erro ao deletar usuários: $e');
      }
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

  // ============== GERAR CONVITE ALEATÓRIO - NOVA FUNCIONALIDADE ==============
  static Future<Map<String, dynamic>?> createRandomInviteForCurrentUser(
    String currentUserId,
  ) async {
    try {
      if (kDebugMode) {
        print(
          '🎯 TestUsersService: Gerando convite aleatório para $currentUserId',
        );
      }

      // 1. Buscar usuários de teste disponíveis (excluindo o usuário atual)
      final testUsersSnapshot = await _firestore
          .collection('users')
          // .where('email', isGreaterThanOrEqualTo: '@test.com')
          // .where('email', isLessThanOrEqualTo: '@test.com\uf8ff')
          .get();

      final specificUsersSnapshot = await _firestore
          .collection('users')
          // .where('email', isGreaterThanOrEqualTo: '@specific.com')
          // .where('email', isLessThanOrEqualTo: '@specific.com\uf8ff')
          .get();

      // Combinar todos os usuários disponíveis
      final allAvailableUsers = [
        ...testUsersSnapshot.docs,
        ...specificUsersSnapshot.docs,
      ].where((doc) => doc.id != currentUserId).toList();

      if (allAvailableUsers.isEmpty) {
        if (kDebugMode) {
          print('❌ TestUsersService: Nenhum usuário disponível para convite');
        }
        return null;
      }

      // 2. Selecionar usuário aleatório
      final randomUser =
          allAvailableUsers[_random.nextInt(allAvailableUsers.length)];
      final userData = randomUser.data() as Map<String, dynamic>;

      // 3. Verificar se já existe convite pendente entre esses usuários
      final existingInvite = await _checkExistingInvite(
        randomUser.id,
        currentUserId,
      );
      if (existingInvite != null) {
        if (kDebugMode) {
          print('⚠️ TestUsersService: Já existe convite entre usuários');
        }
        return {
          'status': 'existing',
          'message': 'Já existe um convite entre vocês',
          'senderUser': userData,
        };
      }

      // 4. Criar convite no Firestore
      final inviteRef = _firestore.collection('test_invites').doc();

      final inviteData = {
        'id': inviteRef.id,
        'senderId': randomUser.id,
        'receiverId': currentUserId,
        'participants': [randomUser.id, currentUserId],
        'status': 'pending',
        'createdAt': DateTime.now().toIso8601String(),
        'expiresAt': DateTime.now()
            .add(const Duration(hours: 24))
            .toIso8601String(),
        'senderName': userData['displayName'] ?? 'Usuário de Teste',
        'senderAvatar': userData['avatar'] ?? 'default',
        // 'testData': {
        //   'senderInterests': userData['interesses'] ?? [],
        //   'senderName': userData['displayName'] ?? 'Usuário de Teste',
        //   'senderAvatar': userData['avatar'] ?? 'default',
        //   'compatibility': 70 + _random.nextInt(25), // Simular compatibilidade
        // },
      };

      await inviteRef.set(inviteData);

      if (kDebugMode) {
        print(
          '✅ TestUsersService: Convite criado de ${userData['displayName']} para usuário atual',
        );
      }

      return {
        'status': 'created',
        'message': 'Convite criado com sucesso!',
        'inviteId': inviteRef.id,
        'senderUser': userData,
        'senderName': userData['displayName'] ?? 'Usuário de Teste',
        'senderInterests': userData['interesses'] ?? [],
      };
    } catch (e) {
      if (kDebugMode) {
        print('❌ TestUsersService: Erro ao criar convite aleatório: $e');
      }
      return {'status': 'error', 'message': 'Erro ao criar convite: $e'};
    }
  }

  // ============== VERIFICAR CONVITE EXISTENTE ==============
  static Future<Map<String, dynamic>?> _checkExistingInvite(
    String userId1,
    String userId2,
  ) async {
    try {
      // Verificar convites em ambas as direções
      final query1 = await _firestore
          .collection('test_invites')
          .where('senderId', isEqualTo: userId1)
          .where('receiverId', isEqualTo: userId2)
          .where('status', whereIn: ['pending', 'accepted'])
          .limit(1)
          .get();

      if (query1.docs.isNotEmpty) {
        return query1.docs.first.data();
      }

      final query2 = await _firestore
          .collection('test_invites')
          .where('senderId', isEqualTo: userId2)
          .where('receiverId', isEqualTo: userId1)
          .where('status', whereIn: ['pending', 'accepted'])
          .limit(1)
          .get();

      if (query2.docs.isNotEmpty) {
        return query2.docs.first.data();
      }

      return null;
    } catch (e) {
      if (kDebugMode) {
        print('❌ TestUsersService: Erro ao verificar convite existente: $e');
      }
      return null;
    }
  }

  // ============== LISTAR CONVITES ATIVOS PARA USUÁRIO ==============
  static Future<List<Map<String, dynamic>>> getActiveInvitesForUser(
    String userId,
  ) async {
    try {
      final receivedInvites = await _firestore
          .collection('test_invites')
          .where('receiverId', isEqualTo: userId)
          .where('status', isEqualTo: 'pending')
          .orderBy('createdAt', descending: true)
          .limit(10)
          .get();

      final sentInvites = await _firestore
          .collection('test_invites')
          .where('senderId', isEqualTo: userId)
          .where('status', isEqualTo: 'pending')
          .orderBy('createdAt', descending: true)
          .limit(10)
          .get();

      final allInvites = <Map<String, dynamic>>[];

      for (final doc in receivedInvites.docs) {
        final data = doc.data();
        data['type'] = 'received';
        allInvites.add(data);
      }

      for (final doc in sentInvites.docs) {
        final data = doc.data();
        data['type'] = 'sent';
        allInvites.add(data);
      }

      // Ordenar por data de criação
      allInvites.sort((a, b) {
        final dateA = DateTime.tryParse(a['createdAt'] ?? '') ?? DateTime.now();
        final dateB = DateTime.tryParse(b['createdAt'] ?? '') ?? DateTime.now();
        return dateB.compareTo(dateA);
      });

      return allInvites;
    } catch (e) {
      if (kDebugMode) {
        print('❌ TestUsersService: Erro ao buscar convites ativos: $e');
      }
      return [];
    }
  }
}
