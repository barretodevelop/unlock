// lib/core/constants/app_constants.dart - Constantes Centralizadas
class AppConstants {
  // Informações do App
  static const String appName = 'Unlock';
  static const String appVersion = '1.0.0';
  static const String appDescription =
      'Rede social gamificada com conexões autênticas';

  // Configurações de Idade
  static const int minimumAge = 13;
  static const int adultAge = 18;
  static const int minorAgeRange = 2; // +/- 2 anos para menores

  // Configurações de Gamificação
  static const int initialCoins = 200;
  static const int initialGems = 20;
  static const int initialXP = 0;
  static const int initialLevel = 1;
  static const int xpPerLevel = 100;

  // Configurações de Matching
  static const int maxCardsPerSession = 3;
  static const int compatibilityThreshold =
      70; // % mínimo para passar ao minijogo
  static const int maxDailyInvites = 10;

  // Configurações de Missões
  static const int maxDailyMissions = 3;
  static const int maxWeeklyMissions = 2;

  // Timeouts e Intervalos
  static const Duration splashScreenDuration = Duration(seconds: 2);
  static const Duration onboardingStepDuration = Duration(milliseconds: 300);
  static const Duration animationDuration = Duration(milliseconds: 250);
  static const Duration longAnimationDuration = Duration(milliseconds: 500);
  static const Duration connectionTimeout = Duration(seconds: 30);

  // Configurações de Cache
  static const Duration cacheExpiration = Duration(hours: 24);
  static const int maxCacheSize = 100; // MB

  // Configurações de Notificações
  static const Duration notificationDelay = Duration(seconds: 1);
  static const int maxNotificationsPerDay = 5;

  // Limites de Texto
  static const int maxCodinomeLength = 20;
  static const int maxBioLength = 150;
  static const int maxMessageLength = 500;
  static const int maxInterestsCount = 10;

  // URLs e Links
  static const String privacyPolicyUrl = 'https://unlock.app/privacy';
  static const String termsOfServiceUrl = 'https://unlock.app/terms';
  static const String supportUrl = 'https://unlock.app/support';
  static const String websiteUrl = 'https://unlock.app';

  // Firebase Collections
  static const String usersCollection = 'users';
  static const String connectionsCollection = 'connections';
  static const String invitesCollection = 'connection_invites';
  static const String missionsCollection = 'missions';
  static const String reportsCollection = 'reports';
  static const String shopItemsCollection = 'shop_items';
  static const String compatibilityTestsCollection = 'compatibility_tests';
  static const String minigamesCollection = 'minigames';

  // SharedPreferences Keys
  static const String firstLaunchKey = 'first_launch';
  static const String themeKey = 'theme_mode';
  static const String languageKey = 'language';
  static const String onboardingCompleteKey = 'onboarding_complete';
  static const String lastSyncKey = 'last_sync';

  // Configurações de Segurança
  static const int maxLoginAttempts = 5;
  static const Duration loginCooldown = Duration(minutes: 15);
  static const int sessionTimeoutMinutes = 60;

  // Configurações de Performance
  static const int imageQuality = 85;
  static const int thumbnailSize = 150;
  static const int avatarSize = 100;
  static const int maxImageSizeMB = 5;
}

/// Constantes específicas para missões
class MissionConstants {
  // Tipos de Missão
  static const String typDaily = 'daily';
  static const String typeWeekly = 'weekly';
  static const String typeAchievement = 'achievement';

  // Categorias de Missão
  static const String categoryProfile = 'profile';
  static const String categoryConnection = 'connection';
  static const String categorySocial = 'social';
  static const String categoryGame = 'game';
  static const String categoryShop = 'shop';

  // Recompensas padrão
  static const int dailyMissionReward = 30;
  static const int weeklyMissionReward = 100;
  static const int achievementReward = 200;
  static const int bonusGemsReward = 5;

  // IDs de missões especiais
  static const String firstConnectionMission = 'first_connection';
  static const String completeProfileMission = 'complete_profile';
  static const String firstGameMission = 'first_game';
}

/// Constantes específicas para conexões
class ConnectionConstants {
  // Status de Convite
  static const String inviteStatusPending = 'pending';
  static const String inviteStatusAccepted = 'accepted';
  static const String inviteStatusDeclined = 'declined';
  static const String inviteStatusCanceled = 'canceled';

  // Status de Conexão
  static const String connectionStatusActive = 'active';
  static const String connectionStatusBlocked = 'blocked';
  static const String connectionStatusRemoved = 'removed';

  // Tipos de Interação
  static const String interactionLike = 'like';
  static const String interactionPass = 'pass';
  static const String interactionSuperLike = 'super_like';
}

/// Constantes para o shop
class ShopConstants {
  // Categorias de Itens
  static const String categoryAvatar = 'avatar';
  static const String categoryAccessory = 'accessory';
  static const String categoryTheme = 'theme';
  static const String categoryBoost = 'boost';
  static const String categoryPremium = 'premium';

  // Tipos de Moeda
  static const String currencyCoins = 'coins';
  static const String currencyGems = 'gems';
  static const String currencyReal = 'real';

  // Pacotes de Moedas
  static const Map<String, Map<String, dynamic>> coinPackages = {
    'small': {'coins': 500, 'price': 1.99, 'bonus': 0},
    'medium': {'coins': 1200, 'price': 4.99, 'bonus': 200},
    'large': {'coins': 2500, 'price': 9.99, 'bonus': 500},
  };

  static const Map<String, Map<String, dynamic>> gemPackages = {
    'small': {'gems': 50, 'price': 2.99, 'bonus': 0},
    'medium': {'gems': 120, 'price': 6.99, 'bonus': 20},
    'large': {'gems': 250, 'price': 12.99, 'bonus': 50},
  };
}

/// Constantes para minijogos
class GameConstants {
  // Configurações do Jogo da Memória
  static const int memoryGameRows = 4;
  static const int memoryGameCols = 4;
  static const int memoryGameMinScore = 50;
  static const Duration memoryGameTurnTime = Duration(seconds: 30);
  static const Duration cardFlipDuration = Duration(milliseconds: 600);

  // Configurações Gerais
  static const int maxGameDuration = 10; // minutos
  static const int minPlayersRequired = 2;
}

/// Constantes para validação
class ValidationConstants {
  // Expressões regulares
  static const String emailRegex = r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$';
  static const String usernameRegex = r'^[a-zA-Z0-9_]{3,20}$';
  static const String codinomeRegex = r'^[a-zA-Z0-9\s]{2,20}$';

  // Mensagens de erro
  static const String requiredFieldError = 'Este campo é obrigatório';
  static const String invalidEmailError = 'Email inválido';
  static const String shortPasswordError = 'Senha muito curta';
  static const String weakPasswordError = 'Senha muito fraca';
  static const String passwordMismatchError = 'Senhas não coincidem';
  static const String invalidUsernameError = 'Nome de usuário inválido';
  static const String ageTooYoungError = 'Idade mínima não atingida';
}

/// Constantes para animações
class AnimationConstants {
  // Durações
  static const Duration fastAnimation = Duration(milliseconds: 150);
  static const Duration normalAnimation = Duration(milliseconds: 300);
  static const Duration slowAnimation = Duration(milliseconds: 500);

  // Curves
  static const String defaultCurve = 'easeInOut';
  static const String bounceCurve = 'bounceOut';
  static const String elasticCurve = 'elasticOut';
}

/// Constantes para cores (complementa o tema)
class ColorConstants {
  // Cores de status
  static const int successColor = 0xFF4CAF50;
  static const int warningColor = 0xFFFF9800;
  static const int errorColor = 0xFFF44336;
  static const int infoColor = 0xFF2196F3;

  // Cores de gamificação
  static const int coinsColor = 0xFFFFD700;
  static const int gemsColor = 0xFF9C27B0;
  static const int xpColor = 0xFF4CAF50;
  static const int levelColor = 0xFF2196F3;
}

/// Utilitários para constantes
class ConstantsUtils {
  // Calcular level baseado no XP
  static int calculateLevel(int xp) {
    return (xp / AppConstants.xpPerLevel).floor() + 1;
  }

  // Calcular XP necessário para próximo level
  static int xpForNextLevel(int currentLevel) {
    return currentLevel * AppConstants.xpPerLevel;
  }

  // Verificar se é menor de idade
  static bool isMinor(DateTime birthDate) {
    final age = DateTime.now().difference(birthDate).inDays ~/ 365;
    return age < AppConstants.adultAge;
  }

  // Verificar idade mínima
  static bool meetsMinimumAge(DateTime birthDate) {
    final age = DateTime.now().difference(birthDate).inDays ~/ 365;
    return age >= AppConstants.minimumAge;
  }

  // Gerar ID único para documentos
  static String generateId() {
    return DateTime.now().millisecondsSinceEpoch.toString();
  }
}
