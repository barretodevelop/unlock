// lib/providers/discovery_provider.dart
import 'dart:async';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:unlock/models/user_model.dart';
import 'package:unlock/providers/auth_provider.dart';

// ============== DISCOVERY STATE ==============
@immutable
class DiscoveryState {
  final List<UserModel> availableUsers;
  final List<UserModel> compatibleUsers;
  final bool isLoading;
  final bool isSearching;
  final String? error;
  final DateTime? lastSearch;
  final bool initialUsersLoaded; // Add this flag
  final int searchStep;

  const DiscoveryState({
    this.availableUsers = const [],
    this.compatibleUsers = const [],
    this.isLoading = false,
    this.isSearching = false,
    this.error,
    this.lastSearch,
    this.initialUsersLoaded = false, // Initialize it
    this.searchStep = 0,
  });

  DiscoveryState copyWith({
    List<UserModel>? availableUsers,
    List<UserModel>? compatibleUsers,
    bool? isLoading,
    bool? isSearching,
    String? error,
    DateTime? lastSearch,
    bool? initialUsersLoaded, // Add this parameter
    int? searchStep,
  }) {
    return DiscoveryState(
      availableUsers: availableUsers ?? this.availableUsers,
      compatibleUsers: compatibleUsers ?? this.compatibleUsers,
      isLoading: isLoading ?? this.isLoading,
      isSearching: isSearching ?? this.isSearching,
      error: error,
      lastSearch: lastSearch ?? this.lastSearch,
      initialUsersLoaded:
          initialUsersLoaded ?? this.initialUsersLoaded, // Assign it
      searchStep: searchStep ?? this.searchStep,
    );
  }

  bool get hasResults => compatibleUsers.isNotEmpty;
  bool get canSearch => !isLoading && !isSearching;
}

// ============== DISCOVERY PROVIDER ==============
final discoveryProvider =
    StateNotifierProvider<DiscoveryNotifier, DiscoveryState>((ref) {
      return DiscoveryNotifier(ref);
    });

class DiscoveryNotifier extends StateNotifier<DiscoveryState> {
  final Ref _ref;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  StreamSubscription<QuerySnapshot>? _onlineUsersSubscription;
  ProviderSubscription<AuthState>? _authSubscription;
  Timer? _searchTimer;

  static const List<String> _searchSteps = [
    'Analisando seus interesses...',
    'Encontrando pessoas compatíveis...',
    'Calculando distâncias...',
    'Verificando disponibilidade...',
    'Preparando resultados...',
  ];

  DiscoveryNotifier(this._ref) : super(const DiscoveryState()) {
    // Não inicialize o listener diretamente aqui.
    // Em vez disso, escute as mudanças de autenticação.
    _authSubscription = _ref.listen<AuthState>(authProvider, (previous, next) {
      final prevUser = previous?.user;
      final nextUser = next.user;

      if (nextUser != null && prevUser == null) {
        // Usuário fez login
        _initializeOnlineUsersListener();
      } else if (nextUser == null && prevUser != null) {
        // Usuário fez logout
        _disposeOnlineUsersListener();
        state = const DiscoveryState(); // Reseta o estado
      }
    }, fireImmediately: true); // fireImmediately para pegar o estado inicial
  }

  // ============== INICIALIZAÇÃO ==============
  void _initializeOnlineUsersListener() {
    final currentUser = _ref.read(authProvider).user;
    // Se já existe uma subscrição, cancele antes de criar uma nova.
    _onlineUsersSubscription?.cancel();
    if (currentUser == null) {
      if (kDebugMode) {
        print(
          '⚠️ DiscoveryProvider: Usuário atual nulo, não inicializando listener.',
        );
      }
      return;
    }

    try {
      // Escutar usuários online (última atividade < 5 minutos)
      final fiveMinutesAgo = DateTime.now().subtract(
        const Duration(minutes: 5),
      );

      _onlineUsersSubscription = _firestore
          .collection('users')
          .where(
            'isOnline',
            isEqualTo: true,
            // 'lastActivity',
            // isGreaterThan: fiveMinutesAgo.toIso8601String(),
          )
          .where('uid', isNotEqualTo: currentUser.uid) // Excluir usuário atual
          .limit(50) // Limitar para performance
          .snapshots()
          .listen(
            _handleOnlineUsersUpdate,
            onError: (error, stackTrace) =>
                _handleError('Erro no listener de usuários online: $error'),
          );

      if (kDebugMode) {
        print('✅ DiscoveryProvider: Listener de usuários online inicializado');
      }
    } catch (e) {
      _handleError('Erro ao inicializar listener de usuários online: $e');
    }
  }

  void _disposeOnlineUsersListener() {
    _onlineUsersSubscription?.cancel();
    _onlineUsersSubscription = null;
    if (kDebugMode) {
      print('🗑️ DiscoveryProvider: Listener de usuários online finalizado.');
    }
  }

  void _handleOnlineUsersUpdate(QuerySnapshot snapshot) {
    try {
      // Add detailed logging here
      if (kDebugMode) {
        print(
          '📡 DiscoveryProvider: Raw snapshot.docs.length: ${snapshot.docs.length}',
        );
        // Optional: Log raw data for a few documents if snapshot.docs.isNotEmpty
        if (snapshot.docs.isNotEmpty) {
          for (int i = 0; i < snapshot.docs.length && i < 3; i++) {
            print(
              '📡 DiscoveryProvider: Raw user data for ${snapshot.docs[i].id}: ${snapshot.docs[i].data()}',
            );
          }
        }
      }

      if (snapshot.docs.isEmpty) {
        state = state.copyWith(
          availableUsers: [],
          initialUsersLoaded: true, // Mark as loaded even if empty
        );
        if (kDebugMode) {
          print(
            '📡 DiscoveryProvider: No documents returned from Firestore query.',
          );
          print('✅ DiscoveryProvider: Initial users list loaded (empty).');
        }
        return;
      }

      // Process documents
      final List<UserModel> parsedUsers = [];
      for (var doc in snapshot.docs) {
        try {
          final user = UserModel.fromJson(doc.data() as Map<String, dynamic>);
          parsedUsers.add(user);
        } catch (e, s) {
          if (kDebugMode) {
            print(
              '❌ DiscoveryProvider: Error parsing UserModel for doc ${doc.id}: $e',
            );
            print(s); // Stacktrace
          }
        }
      }

      if (kDebugMode) {
        print(
          '📡 DiscoveryProvider: Parsed ${parsedUsers.length} users successfully (before needsOnboarding filter).',
        );
      }

      if (kDebugMode) {
        print(
          '📡 DiscoveryProvider: Parsed ${parsedUsers.length} users successfully (before needsOnboarding filter).',
        );
        // Optional: Log parsed users with onboarding status
        if (kDebugMode) {
          for (var user in parsedUsers) {
            print(
              '📡 DiscoveryProvider: Parsed User: ${user.uid}, needsOnboarding: ${user.needsOnboarding}',
            );
          }
        }
      }

      final filteredUsers = parsedUsers
          .where(
            (user) => !user.needsOnboarding,
          ) // Apenas usuários com perfil completo
          .toList();

      state = state.copyWith(
        availableUsers: filteredUsers,
        initialUsersLoaded: true,
      ); // Set the flag here

      if (kDebugMode) {
        print(
          '📡 DiscoveryProvider: ${filteredUsers.length} usuários online encontrados (after needsOnboarding filter).',
        );
      }
    } catch (e, s) {
      // Ensure the flag is set to true even on error, to avoid infinite waiting
      _handleError('Erro ao processar usuários online: $e. Stacktrace: $s');
    }
  }

  // ============== BUSCA DE COMPATIBILIDADE ==============
  Future<void> findCompatibleUsers() async {
    final currentUser = _ref.read(authProvider).user;
    if (currentUser == null || !state.canSearch) return;

    try {
      if (kDebugMode) {
        print('🔍 DiscoveryProvider: Iniciando busca de usuários compatíveis');
      }

      state = state.copyWith(isSearching: true, error: null, searchStep: 0);

      // Simular progresso de busca com steps
      await _simulateSearchProgress();

      // Calcular compatibilidade com usuários online
      final compatibleUsers = _calculateCompatibility(
        currentUser,
        state.availableUsers,
      );

      state = state.copyWith(
        compatibleUsers: compatibleUsers,
        isSearching: false,
        lastSearch: DateTime.now(),
      );

      if (kDebugMode) {
        print(
          '✅ DiscoveryProvider: ${compatibleUsers.length} usuários compatíveis encontrados',
        );
      }
    } catch (e) {
      _handleError('Erro na busca de usuários compatíveis: $e');
    }
  }

  Future<void> _simulateSearchProgress() async {
    for (int i = 0; i < _searchSteps.length; i++) {
      if (!state.isSearching) break; // Se cancelado, sair

      state = state.copyWith(searchStep: i);
      await Future.delayed(const Duration(milliseconds: 800));
    }
  }

  List<UserModel> _calculateCompatibility(
    UserModel currentUser,
    List<UserModel> availableUsers,
  ) {
    final userInterests = currentUser.interesses;
    final userRelationshipInterest = currentUser.relationshipInterest;

    // Calcular score de compatibilidade para cada usuário
    final usersWithScore = availableUsers.map((user) {
      final score = _calculateCompatibilityScore(
        userInterests,
        userRelationshipInterest ?? '',
        user,
      );
      return _UserWithScore(user, score);
    }).toList();

    // Ordenar por score (maior primeiro)
    usersWithScore.sort((a, b) => b.score.compareTo(a.score));

    // Retornar top 3 usuários mais compatíveis
    return usersWithScore
        .take(3)
        .map((userWithScore) => userWithScore.user)
        .toList();
  }

  double _calculateCompatibilityScore(
    List<String> userInterests,
    String userRelationshipInterest,
    UserModel otherUser,
  ) {
    double score = 0.0;

    // 1. Compatibilidade de interesses (60% do score)
    final commonInterests = userInterests
        .where((interest) => otherUser.interesses.contains(interest))
        .length;

    final maxInterests = max(userInterests.length, otherUser.interesses.length);
    if (maxInterests > 0) {
      score += (commonInterests / maxInterests) * 60;
    }

    // 2. Compatibilidade de relacionamento (25% do score)
    if (userRelationshipInterest == otherUser.relationshipInterest) {
      score += 25;
    } else if (_areRelationshipTypesCompatible(
      userRelationshipInterest,
      otherUser.relationshipInterest ?? '',
    )) {
      score += 15; // Parcialmente compatível
    }

    // 3. Fator de atividade (10% do score)
    // Usuários mais ativos recebem score maior
    score += min(10, otherUser.level.toDouble());

    // 4. Fator de verificação (5% do score)
    // TODO: Implementar verificação de perfil
    // if (otherUser.isVerified) score += 5;

    return min(100, score); // Score máximo é 100
  }

  bool _areRelationshipTypesCompatible(String type1, String type2) {
    // Definir compatibilidade entre tipos de relacionamento
    final compatibilityMap = {
      'amizade': ['amizade', 'casual', 'networking'],
      'namoro': ['namoro', 'casual'],
      'casual': ['casual', 'amizade', 'namoro'],
      'mentoria': ['mentoria', 'networking'],
      'networking': ['networking', 'mentoria', 'amizade'],
    };

    return compatibilityMap[type1]?.contains(type2) ?? false;
  }

  // ============== ATUALIZAR ATIVIDADE ==============
  Future<void> updateUserActivity() async {
    final currentUser = _ref.read(authProvider).user;
    if (currentUser == null) return;

    try {
      await _firestore.collection('users').doc(currentUser.uid).update({
        'lastActivity': DateTime.now().toIso8601String(),
        'isOnline': true,
      });

      if (kDebugMode) {
        print('✅ DiscoveryProvider: Atividade do usuário atualizada');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ DiscoveryProvider: Erro ao atualizar atividade: $e');
      }
    }
  }

  Future<void> setUserOffline() async {
    final currentUser = _ref.read(authProvider).user;
    if (currentUser == null) return;

    try {
      await _firestore.collection('users').doc(currentUser.uid).update({
        'isOnline': false,
        'lastActivity': DateTime.now().toIso8601String(),
      });

      if (kDebugMode) {
        print('✅ DiscoveryProvider: Usuário marcado como offline');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ DiscoveryProvider: Erro ao marcar como offline: $e');
      }
    }
  }

  // ============== CONTROLE DE ESTADO ==============
  void clearResults() {
    state = state.copyWith(compatibleUsers: [], error: null);
  }

  void cancelSearch() {
    _searchTimer?.cancel();
    state = state.copyWith(isSearching: false, searchStep: 0);
  }

  void _handleError(String error) {
    if (kDebugMode) {
      print('❌ DiscoveryProvider: $error');
    }

    state = state.copyWith(
      isLoading: false,
      isSearching: false,
      error: error,
      initialUsersLoaded:
          true, // Ensure UI doesn't get stuck if error happens early
    );
  }

  String get currentSearchStep {
    if (!state.isSearching || state.searchStep >= _searchSteps.length) {
      return '';
    }
    return _searchSteps[state.searchStep];
  }

  @override
  void dispose() {
    _onlineUsersSubscription?.cancel();
    _authSubscription?.close();
    _searchTimer?.cancel();
    super.dispose();
  }
}

// ============== HELPER CLASSES ==============
class _UserWithScore {
  final UserModel user;
  final double score;

  _UserWithScore(this.user, this.score);
}

// ============== EXTENSION PARA FACILITAR USO ==============
extension DiscoveryProviderX on WidgetRef {
  DiscoveryNotifier get discovery => read(discoveryProvider.notifier);
  DiscoveryState get discoveryState => watch(discoveryProvider);
}
