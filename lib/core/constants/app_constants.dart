// lib/core/constants/app_constants.dart - VERSÃO CORRIGIDA COMPLETA
import 'package:flutter/material.dart';

/// Constantes principais da aplicação ClashUp
class AppConstants {
  // ========== INFORMAÇÕES DO APP ==========
  static const String appName = 'ClashUp';
  static const String appVersion = '1.0.0';
  static const String appDescription = 'Onde a competição acende a conexão';
  static const String appSlogan = 'Conecte-se de forma autêntica';

  // ========== CONFIGURAÇÕES DE DEBUG ==========
  static const bool isDebugMode = true; // Mude para false em produção
  static const bool enableAnalytics = true;
  static const bool enableCrashlytics = true;
  static const bool enablePerformanceMonitoring = true;

  // ========== LIMITES BÁSICOS ==========
  static const int maxUsernameLength = 20;
  static const int maxDisplayNameLength = 30;
  static const int maxCodinomeLength = 20;
  static const int maxBioLength = 150;
  static const int maxInterestsCount = 10;
  static const int minAge = 13;
  static const int maxAge = 120;

  // ========== CONFIGURAÇÕES DE GRUPOS ==========
  static const int maxGroupNameLength = 30;
  static const int maxGroupDescriptionLength = 150;
  static const int minGroupMembers = 2;
  static const int maxGroupMembers = 100;
  static const int defaultMaxGroupMembers = 20;
  static const int maxGroupsPerUser = 50;
  static const int inviteCodeLength = 6;
  static const Duration inviteCodeExpiry = Duration(days: 7);

  // ========== CONFIGURAÇÕES DE DESAFIOS ==========
  static const int maxChallengeNameLength = 50;
  static const int maxChallengeDescriptionLength = 300;
  static const int maxChallengeParticipants = 1000;
  static const int minChallengeDurationMinutes = 60; // 1 hora
  static const int maxChallengeDurationDays = 30; // 30 dias
  static const Duration defaultChallengeDuration = Duration(days: 7);

  // ✅ ALIASES PARA COMPATIBILIDADE
  static const int challengeTitleMaxLength = maxChallengeNameLength;
  static const int challengeDescriptionMaxLength =
      maxChallengeDescriptionLength;
  static const int challengeMaxParticipants = maxChallengeParticipants;

  // ========== CONFIGURAÇÕES DE GAMIFICAÇÃO ==========
  static const int xpPerLevel = 1000;
  static const int baseXpReward = 10;
  static const int winChallengeXp = 100;
  static const int participateChallengeXp = 25;
  static const int createChallengeXp = 50;
  static const int inviteFriendXp = 75;
  static const int dailyLoginXp = 5;
  static const int streakBonusXp = 15;

  // Moedas virtuais (Faíscas e Gemas)
  static const int startingCoins = 100; // Faíscas iniciais
  static const int startingGems = 10; // Gemas iniciais
  static const int dailyLoginCoins = 10;
  static const int winChallengeCoins = 50;
  static const int streakBonusCoins = 25;
  static const int maxEntryFee =
      100; // Máximo de Faíscas para entrar em desafio

  // ========== ANIMAÇÕES ==========
  static const Duration animationDuration = Duration(milliseconds: 300);
  static const Duration fastAnimation = Duration(milliseconds: 150);
  static const Duration slowAnimation = Duration(milliseconds: 500);
  static const Duration microAnimation = Duration(milliseconds: 100);

  // Delays sequenciais
  static const Duration staggerDelay = Duration(milliseconds: 100);
  static const Duration cascadeDelay = Duration(milliseconds: 150);

  // Durações específicas
  static const Duration splashMinDuration = Duration(seconds: 2);
  static const Duration snackBarDuration = Duration(seconds: 4);
  static const Duration toastDuration = Duration(seconds: 3);
  static const Duration loadingTimeout = Duration(seconds: 30);

  // Curves
  static const Curve defaultCurve = Curves.easeInOut;
  static const Curve enterCurve = Curves.easeOut;
  static const Curve exitCurve = Curves.easeIn;
  static const Curve bounceCurve = Curves.bounceOut;
  static const Curve elasticCurve = Curves.elasticOut;

  // ========== URLS E LINKS ==========
  static const String websiteUrl = 'https://clashup.app';
  static const String privacyPolicyUrl = 'https://clashup.app/privacy';
  static const String termsOfServiceUrl = 'https://clashup.app/terms';
  static const String supportUrl = 'https://clashup.app/support';
  static const String feedbackUrl = 'https://clashup.app/feedback';
  static const String discordUrl = 'https://discord.gg/clashup';
  static const String twitterUrl = 'https://twitter.com/clashupapp';

  // ========== FIREBASE COLLECTIONS ==========
  static const String usersCollection = 'users';
  static const String groupsCollection = 'groups';
  static const String challengesCollection = 'challenges';
  static const String submissionsCollection = 'submissions';
  static const String connectionsCollection = 'connections';
  static const String invitesCollection = 'invites';
  static const String notificationsCollection = 'notifications';
  static const String reportsCollection = 'reports';
  static const String achievementsCollection = 'achievements';
  static const String rankingsCollection = 'rankings';

  // Subcoleções
  static const String membersSubcollection = 'members';
  static const String participantsSubcollection = 'participants';
  static const String activitiesSubcollection = 'activities';
  static const String messagesSubcollection = 'messages';

  // ========== SHARED PREFERENCES KEYS ==========
  static const String firstLaunchKey = 'first_launch';
  static const String themeKey = 'theme_mode';
  static const String languageKey = 'language';
  static const String onboardingCompleteKey = 'onboarding_complete';
  static const String moodKey = 'user_mood';
  static const String lastSyncKey = 'last_sync';
  static const String cacheVersionKey = 'cache_version';
  static const String notificationsEnabledKey = 'notifications_enabled';
  static const String soundEnabledKey = 'sound_enabled';
  static const String hapticEnabledKey = 'haptic_enabled';

  // ========== CONFIGURAÇÕES DE SEGURANÇA ==========
  static const int maxLoginAttempts = 5;
  static const Duration loginCooldown = Duration(minutes: 15);
  static const int sessionTimeoutMinutes = 60;
  static const Duration tokenRefreshBuffer = Duration(minutes: 5);
  static const int maxReportingActions = 3;
  static const Duration reportingCooldown = Duration(hours: 24);

  // ========== CONFIGURAÇÕES DE PERFORMANCE ==========
  static const int imageQuality = 85;
  static const int thumbnailSize = 150;
  static const int avatarSize = 100;
  static const int maxImageSizeMB = 5;
  static const int cacheMaxAge = 7; // dias
  static const int maxCachedItems = 1000;
  static const Duration networkTimeout = Duration(seconds: 30);

  // ========== CONFIGURAÇÕES DE PAGINAÇÃO ==========
  static const int defaultPageSize = 20;
  static const int maxPageSize = 100;
  static const int groupsPageSize = 15;
  static const int challengesPageSize = 10;
  static const int membersPageSize = 50;
  static const int activitiesPageSize = 25;

  // ========== CONFIGURAÇÕES DE BUSCA ==========
  static const int minSearchLength = 2;
  static const int maxSearchLength = 50;
  static const Duration searchDebounce = Duration(milliseconds: 500);
  static const int maxSearchResults = 20;

  // ========== CONFIGURAÇÕES DE NOTIFICAÇÕES ==========
  static const String fcmTopic = 'all_users';
  static const String challengesTopic = 'challenges';
  static const String groupsTopic = 'groups';
  static const Duration notificationThrottle = Duration(minutes: 5);
}

/// Constantes para validação
class ValidationConstants {
  // Expressões regulares
  static const String emailRegex = r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$';
  static const String usernameRegex = r'^[a-zA-Z0-9_]{3,20}$';
  static const String codinomeRegex = r'^[a-zA-Z0-9\s]{2,20}$';
  static const String groupNameRegex = r'^[a-zA-Z0-9\s\-_]{3,30}$';
  static const String inviteCodeRegex = r'^[A-Z0-9]{6}$';
  static const String challengeTitleRegex = r'^[a-zA-Z0-9\s\-_!?]{5,50}$';

  // Mensagens de erro padrão
  static const String requiredFieldError = 'Este campo é obrigatório';
  static const String invalidEmailError = 'Email inválido';
  static const String shortPasswordError =
      'Senha deve ter pelo menos 8 caracteres';
  static const String weakPasswordError = 'Senha muito fraca';
  static const String passwordMismatchError = 'Senhas não coincidem';
  static const String invalidUsernameError =
      'Nome de usuário inválido (3-20 caracteres, apenas letras, números e _)';
  static const String invalidCodinomeError =
      'Codinome inválido (2-20 caracteres)';
  static const String ageTooYoungError =
      'Idade mínima: ${AppConstants.minAge} anos';
  static const String ageTooOldError =
      'Idade máxima: ${AppConstants.maxAge} anos';
  static const String invalidGroupNameError =
      'Nome do grupo inválido (3-30 caracteres)';
  static const String groupFullError = 'Grupo está cheio';
  static const String alreadyMemberError = 'Você já é membro deste grupo';
  static const String notMemberError = 'Você não é membro deste grupo';
  static const String invalidInviteCodeError = 'Código de convite inválido';
  static const String expiredInviteCodeError = 'Código de convite expirado';
  static const String invalidChallengeTitleError =
      'Título do desafio inválido (5-50 caracteres)';
  static const String challengeDescriptionTooLongError =
      'Descrição muito longa (máximo ${AppConstants.maxChallengeDescriptionLength} caracteres)';
  static const String challengeStartDateError =
      'Data de início deve ser no futuro';
  static const String challengeEndDateError =
      'Data de fim deve ser após data de início';
  static const String challengeDurationError =
      'Duração mínima: ${AppConstants.minChallengeDurationMinutes} minutos';
}

/// Constantes de cores personalizadas
class ColorConstants {
  // Cores de status
  static const Color successColor = Color(0xFF4CAF50);
  static const Color warningColor = Color(0xFFFF9800);
  static const Color errorColor = Color(0xFFF44336);
  static const Color infoColor = Color(0xFF2196F3);

  // Cores de gamificação
  static const Color coinsColor = Color(0xFFFFD700); // Faíscas
  static const Color gemsColor = Color(0xFF9C27B0); // Gemas
  static const Color xpColor = Color(0xFF4CAF50); // XP
  static const Color levelColor = Color(0xFF2196F3); // Nível

  // Cores dos tipos de grupo
  static const Color casualGroupColor = Color(0xFF4CAF50);
  static const Color competitiveGroupColor = Color(0xFFFF5722);
  static const Color familyGroupColor = Color(0xFF9C27B0);
  static const Color workGroupColor = Color(0xFF607D8B);
  static const Color hobbyGroupColor = Color(0xFFFF9800);
  static const Color studyGroupColor = Color(0xFF3F51B5);

  // Cores dos tipos de desafio
  static const Color creativeColor = Color(0xFF9C27B0);
  static const Color performanceColor = Color(0xFFFF9800);
  static const Color knowledgeColor = Color(0xFF2196F3);
  static const Color realWorldColor = Color(0xFF4CAF50);

  // Gradientes
  static const List<Color> primaryGradient = [
    Color(0xFF6366F1),
    Color(0xFF8B5CF6),
  ];

  static const List<Color> successGradient = [
    Color(0xFF10B981),
    Color(0xFF059669),
  ];

  static const List<Color> warningGradient = [
    Color(0xFFF59E0B),
    Color(0xFFD97706),
  ];
}

/// Constantes para emojis e avatares
class EmojiConstants {
  // Emojis de humor
  static const Map<String, Map<String, dynamic>> moodEmojis = {
    'social': {
      'emoji': '🤝',
      'label': 'Social',
      'description': 'Pronto para fazer conexões',
      'color': ColorConstants.infoColor,
    },
    'creative': {
      'emoji': '🎨',
      'label': 'Criativo',
      'description': 'Inspirado e artístico',
      'color': ColorConstants.creativeColor,
    },
    'chill': {
      'emoji': '😌',
      'label': 'Relaxar',
      'description': 'Momento zen e tranquilo',
      'color': ColorConstants.successColor,
    },
    'adventure': {
      'emoji': '🌟',
      'label': 'Aventura',
      'description': 'Buscando novas experiências',
      'color': ColorConstants.warningColor,
    },
    'competitive': {
      'emoji': '🔥',
      'label': 'Competitivo',
      'description': 'Pronto para o desafio',
      'color': ColorConstants.errorColor,
    },
    'focused': {
      'emoji': '🎯',
      'label': 'Focado',
      'description': 'Concentrado em objetivos',
      'color': ColorConstants.levelColor,
    },
  };

  // Avatares padrão para grupos
  static const List<String> groupAvatars = [
    '👥',
    '🏆',
    '🎮',
    '🎨',
    '💼',
    '👨‍👩‍👧‍👦',
    '📚',
    '🌟',
    '⚡',
    '🔥',
    '💎',
    '🎯',
    '🚀',
    '🎪',
    '🎭',
    '🎵',
    '⚽',
    '🏀',
    '🎳',
    '🎲',
    '🃏',
    '🎨',
    '📱',
    '💻',
  ];

  // Avatares padrão para usuários
  static const List<String> userAvatars = [
    '👤',
    '🧑‍💻',
    '👩‍🎨',
    '🧑‍🔬',
    '👩‍💼',
    '🧑‍🎓',
    '👩‍⚕️',
    '🧑‍🏫',
    '👮‍♀️',
    '🧑‍🚒',
    '👩‍✈️',
    '🧑‍🎤',
    '👩‍🏭',
    '🧑‍🌾',
    '👩‍🍳',
    '🧑‍⚖️',
    '👩‍🔧',
    '🧑‍🎨',
  ];
}

/// Utilitários de formatação e cálculo
class AppUtils {
  /// Formatar números para gamificação
  static String formatGameNumber(int number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    }
    return number.toString();
  }

  /// Calcular nível baseado no XP
  static int calculateLevel(int xp) {
    return (xp / AppConstants.xpPerLevel).floor() + 1;
  }

  /// Calcular XP restante para próximo nível
  static int xpToNextLevel(int currentXp) {
    final currentLevel = calculateLevel(currentXp);
    final nextLevelXp = currentLevel * AppConstants.xpPerLevel;
    return nextLevelXp - currentXp;
  }

  /// Verificar se usuário pode criar grupo
  static bool canCreateGroup(int currentGroupsCount) {
    return currentGroupsCount < AppConstants.maxGroupsPerUser;
  }

  /// Formatar duração
  static String formatDuration(Duration duration) {
    if (duration.inDays > 0) {
      return '${duration.inDays}d ${duration.inHours % 24}h';
    } else if (duration.inHours > 0) {
      return '${duration.inHours}h ${duration.inMinutes % 60}m';
    } else if (duration.inMinutes > 0) {
      return '${duration.inMinutes}m';
    } else {
      return 'Menos de 1m';
    }
  }

  /// Validar email
  static bool isValidEmail(String email) {
    return RegExp(ValidationConstants.emailRegex).hasMatch(email);
  }

  /// Validar username
  static bool isValidUsername(String username) {
    return RegExp(ValidationConstants.usernameRegex).hasMatch(username);
  }

  /// Validar nome do grupo
  static bool isValidGroupName(String name) {
    return RegExp(ValidationConstants.groupNameRegex).hasMatch(name);
  }

  /// Validar título do desafio
  static bool isValidChallengeTitle(String title) {
    return title.length >= 5 &&
        title.length <= AppConstants.maxChallengeNameLength &&
        title.trim().isNotEmpty;
  }

  /// Validar descrição do desafio
  static bool isValidChallengeDescription(String description) {
    return description.length >= 10 &&
        description.length <= AppConstants.maxChallengeDescriptionLength &&
        description.trim().isNotEmpty;
  }

  /// Gerar código de convite aleatório
  static String generateInviteCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = DateTime.now().millisecondsSinceEpoch;
    var result = '';

    for (int i = 0; i < AppConstants.inviteCodeLength; i++) {
      result += chars[(random + i) % chars.length];
    }

    return result;
  }
}

/// Configurações de ambiente
class EnvironmentConfig {
  static const bool isProduction = false; // Mude para true em produção
  static const bool enableDebugLogs = !isProduction;
  static const bool enableAnalyticsInDebug = false;
  static const bool showPerformanceOverlay = false;

  // URLs baseadas no ambiente
  static String get apiBaseUrl {
    return isProduction
        ? 'https://api.clashup.app'
        : 'https://staging-api.clashup.app';
  }

  static String get webSocketUrl {
    return isProduction
        ? 'wss://ws.clashup.app'
        : 'wss://staging-ws.clashup.app';
  }
}
