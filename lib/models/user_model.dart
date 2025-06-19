// lib/models/user_model.dart - Versão Corrigida com Onboarding (Atualizada conforme seu código)

class UserModel {
  final String uid;
  final String username;
  final String displayName;
  final String avatar;
  final String email;
  final int level;
  final int xp;
  final int coins;
  final int gems;
  final DateTime createdAt;
  final Map<String, dynamic> aiConfig;

  // ✅ NOVOS CAMPOS PARA ONBOARDING
  final String? codinome; // Nome anônimo escolhido
  final String? avatarId; // ID do avatar selecionado
  final DateTime? birthDate; // Data de nascimento
  final List<String> interesses; // Lista de interesses
  final String? relationshipGoal; // Objetivo: amizade, namoro, etc
  final int connectionLevel; // Nível de exigência 1-10
  final bool onboardingCompleted; // Se completou onboarding
  final DateTime? onboardingCompletedAt; // Quando completou

  const UserModel({
    required this.uid,
    required this.username,
    required this.displayName,
    required this.avatar,
    required this.email,
    required this.level,
    required this.xp,
    required this.coins,
    required this.gems,
    required this.createdAt,
    required this.aiConfig,
    // Novos campos com defaults seguros
    this.codinome,
    this.avatarId,
    this.birthDate,
    this.interesses = const [],
    this.relationshipGoal,
    this.connectionLevel = 5,
    this.onboardingCompleted = false, // ✅ DEFAULT FALSE
    this.onboardingCompletedAt,
  });

  // ✅ GETTER PARA VERIFICAR SE PRECISA DE ONBOARDING
  bool get needsOnboarding {
    // Se já marcou como completado, não precisa
    if (onboardingCompleted) return false;

    // Verificar se tem os dados mínimos necessários
    final hasBasicData =
        codinome != null &&
        codinome!.isNotEmpty &&
        avatarId != null &&
        birthDate != null &&
        interesses.length >= 3 &&
        relationshipGoal != null;

    // Se não tem dados básicos, precisa de onboarding
    return !hasBasicData;
  }

  // ✅ GETTER PARA VERIFICAR SE É MENOR DE IDADE
  bool get isMinor {
    if (birthDate == null) return false;
    final age = DateTime.now().difference(birthDate!).inDays ~/ 365;
    return age < 18;
  }

  // ✅ GETTER PARA IDADE
  int? get age {
    if (birthDate == null) return null;
    return DateTime.now().difference(birthDate!).inDays ~/ 365;
  }

  /// Cria uma instância a partir de um Map (ex: vindo de JSON ou Firebase)
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      uid: json['uid'] ?? '',
      username: json['username'] ?? '',
      displayName: json['displayName'] ?? '',
      avatar: json['avatar'] ?? '',
      email: json['email'] ?? '',
      level: json['level'] ?? 1,
      xp: json['xp'] ?? 0,
      coins: json['coins'] ?? 200,
      gems: json['gems'] ?? 20,
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
      aiConfig: Map<String, dynamic>.from(json['aiConfig'] ?? {}),

      // ✅ NOVOS CAMPOS COM FALLBACKS SEGUROS
      codinome: json['codinome'],
      avatarId: json['avatarId'],
      birthDate: json['birthDate'] != null
          ? DateTime.tryParse(json['birthDate'])
          : null,
      interesses: List<String>.from(json['interesses'] ?? []),
      relationshipGoal: json['relationshipGoal'],
      connectionLevel: json['connectionLevel'] ?? 5,
      onboardingCompleted:
          json['onboardingCompleted'] ?? false, // ✅ DEFAULT FALSE
      onboardingCompletedAt: json['onboardingCompletedAt'] != null
          ? DateTime.tryParse(json['onboardingCompletedAt'])
          : null,
    );
  }

  /// Converte a instância para JSON (ex: salvar no SharedPreferences ou Firebase)
  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'username': username,
      'displayName': displayName,
      'avatar': avatar,
      'email': email,
      'level': level,
      'xp': xp,
      'coins': coins,
      'gems': gems,
      'createdAt': createdAt.toIso8601String(),
      'aiConfig': aiConfig,

      // ✅ NOVOS CAMPOS
      'codinome': codinome,
      'avatarId': avatarId,
      'birthDate': birthDate?.toIso8601String(),
      'interesses': interesses,
      'relationshipGoal': relationshipGoal,
      'connectionLevel': connectionLevel,
      'onboardingCompleted': onboardingCompleted,
      'onboardingCompletedAt': onboardingCompletedAt?.toIso8601String(),
    };
  }

  /// Método para atualizar os pontos de XP, moedas e gemas do usuário.
  /// Também recalcula o nível do usuário com base no XP total.
  // ATENÇÃO: Adicionado este método para integrar com o sistema de missões.
  // Certifique-se de que a lógica de recalculateLevel está correta para seu jogo.
  UserModel addRewards(int addedXp, int addedCoins, int addedGems) {
    int newXp = xp + addedXp;
    int newCoins = coins + addedCoins;
    int newGems = gems + addedGems;

    // Lógica para recalcular o nível com base no XP.
    // Isso deve ser adaptado à sua curva de XP/nível.
    int newLevel = level; // Começa com o nível atual
    // String? newTitle = title;

    // Exemplo simples: 100 XP por nível
    if (newXp >= (newLevel * 100)) {
      // Se o XP atingir ou exceder o necessário para o próximo nível
      newLevel = (newXp ~/ 100) + 1;
      // Atualize o título se houver uma lógica associada ao nível
      //  newTitle = getTitleForLevel(newLevel); // Descomente e implemente se tiver um método getTitleForLevel
    }

    return copyWith(
      xp: newXp,
      coins: newCoins,
      gems: newGems,
      level: newLevel,
      // title: newTitle,
    );
  }

  /// Recalcula o nível do usuário com base no XP.
  /// Este é um exemplo simples; sua lógica de nivelamento pode ser mais complexa.
  // ATENÇÃO: Este método agora retorna um novo UserModel,
  // e é chamado dentro de addRewards.
  UserModel _recalculateLevel() {
    // Exemplo: 100 XP por nível
    int newLevel = (xp ~/ 100) + 1;
    if (newLevel != level) {
      return copyWith(level: newLevel);
      // Lógica para atualizar o título com base no novo nível
      // this.title = getTitleForLevel(level); // Descomente e implemente se tiver um método getTitleForLevel
    }
    return this; // Retorna a instância atual se o nível não mudar
  }

  /// Permite copiar a instância com modificações
  UserModel copyWith({
    String? uid,
    String? username,
    String? displayName,
    String? avatar,
    String? email,
    int? level,
    int? xp,
    int? coins,
    int? gems,
    DateTime? createdAt,
    Map<String, dynamic>? aiConfig,
    String? codinome,
    String? avatarId,
    DateTime? birthDate,
    List<String>? interesses,
    String? relationshipGoal,
    int? connectionLevel,
    bool? onboardingCompleted,
    DateTime? onboardingCompletedAt,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      username: username ?? this.username,
      displayName: displayName ?? this.displayName,
      avatar: avatar ?? this.avatar,
      email: email ?? this.email,
      level: level ?? this.level,
      xp: xp ?? this.xp,
      coins: coins ?? this.coins,
      gems: gems ?? this.gems,
      createdAt: createdAt ?? this.createdAt,
      aiConfig: aiConfig ?? this.aiConfig,
      codinome: codinome ?? this.codinome,
      avatarId: avatarId ?? this.avatarId,
      birthDate: birthDate ?? this.birthDate,
      interesses: interesses ?? this.interesses,
      relationshipGoal: relationshipGoal ?? this.relationshipGoal,
      connectionLevel: connectionLevel ?? this.connectionLevel,
      onboardingCompleted: onboardingCompleted ?? this.onboardingCompleted,
      onboardingCompletedAt:
          onboardingCompletedAt ?? this.onboardingCompletedAt,
    );
  }

  @override
  String toString() {
    return 'UserModel(uid: $uid, username: $username, onboardingCompleted: $onboardingCompleted, needsOnboarding: $needsOnboarding)';
  }

  /// Factory para criar usuário inicial após login (pré-onboarding)
  factory UserModel.createInitial({
    required String uid,
    required String email,
    String? displayName,
    String? photoURL,
  }) {
    return UserModel(
      uid: uid,
      username: displayName ?? 'Usuário',
      displayName: displayName ?? 'Usuário',
      avatar: photoURL ?? '👤',
      email: email,
      level: 1,
      xp: 0,
      coins: 200, // bonus inicial
      gems: 20, // bonus inicial
      createdAt: DateTime.now(),
      aiConfig: {'apiUrl': '', 'apiKey': '', 'enabled': false},

      // Campos de onboarding vazios/padrão
      codinome: '',
      avatarId: '',
      birthDate: null,
      interesses: [],
      connectionLevel: 5,
      onboardingCompleted: false,
      onboardingCompletedAt: null,
      relationshipGoal: null,
    );
  }
}
