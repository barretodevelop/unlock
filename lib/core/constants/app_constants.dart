// lib/core/constants/app_constants.dart - Constantes Centralizadas
import 'package:flutter/material.dart';

class AppConstants {
  // Espaçamentos Comuns
  static const double paddingSmall = 8.0;
  static const double paddingMedium = 16.0;
  static const double paddingLarge = 20.0;
  static const double spacingSmall = 4.0;
  static const double spacingMedium = 8.0;
  static const double spacingLarge = 12.0;
  static const double spacingExtraLarge = 20.0;

  // Tamanhos de Fonte Comuns (além do TextTheme)
  static const double fontSizeSmall = 10.0; // Usado em rótulos de stats
  static const double fontSizeMedium =
      12.0; // Usado em títulos de ações rápidas
  static const double fontSizeLarge = 16.0; // Usado em valores de stats
  static const double fontSizeExtraLarge =
      20.0; // Usado em títulos de stats e inicial do avatar
  static const double fontSizeAvatarInitial =
      20.0; // Tamanho específico para a inicial do avatar

  // Dimensões de Componentes
  static const double avatarSize = 48.0; // Tamanho do avatar na AppBar
  static const double avatarBorderWidth = 4.0; // Espessura da borda do avatar
  static const double cardBorderRadius = 12.0; // Raio da borda de cards
  static const double cardElevation = 1.0; // Elevação padrão de cards
  static const double cardPadding = 16.0; // Padding interno padrão de cards
  static const double statsCardPadding =
      20.0; // Padding interno do card de stats
  static const double bottomNavHeight =
      80.0; // Altura para evitar sobreposição do BottomNav/FAB

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
  static const String moodKey = 'user_mood';
  static const String lastSyncKey = 'last_sync';

  // Configurações de Segurança
  static const int maxLoginAttempts = 5;
  static const Duration loginCooldown = Duration(minutes: 15);
  static const int sessionTimeoutMinutes = 60;

  // Configurações de Performance
  static const int imageQuality = 85;
  static const int thumbnailSize = 150;
  // static const int avatarSize = 100;
  static const int maxImageSizeMB = 5;
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

/// Constantes específicas para animações
class AnimationConstants {
  // Durações padrão
  static const Duration microDelay = Duration(milliseconds: 50);
  static const Duration shortDelay = Duration(milliseconds: 150);
  static const Duration mediumDelay = Duration(milliseconds: 300);
  static const Duration longDelay = Duration(milliseconds: 500);
  static const Duration extraLongDelay = Duration(milliseconds: 800);

  // Durações específicas para elementos
  static const Duration cardHover = Duration(milliseconds: 150);
  static const Duration pageTransition = Duration(milliseconds: 300);
  static const Duration modalSlide = Duration(milliseconds: 400);
  static const Duration fabAnimation = Duration(milliseconds: 200);
  static const Duration listItemAnimation = Duration(milliseconds: 250);

  // Delays sequenciais
  static const Duration staggerDelay = Duration(milliseconds: 100);
  static const Duration cascadeDelay = Duration(milliseconds: 150);

  // Curves específicas
  static const Curve enterCurve = Curves.easeOut;
  static const Curve exitCurve = Curves.easeIn;
  static const Curve bounceCurve = Curves.bounceOut;
  static const Curve elasticCurve = Curves.elasticOut;
  static const Curve smoothCurve = Curves.easeInOut;

  // Durações
  static const Duration fastAnimation = Duration(milliseconds: 150);
  static const Duration normalAnimation = Duration(milliseconds: 300);
  static const Duration slowAnimation = Duration(milliseconds: 500);

  // Curves
  static const String defaultCurve = 'easeInOut';
  // static const String bounceCurve = 'bounceOut';
  // static const String elasticCurve = 'elasticOut';
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

/// Constantes para emojis de humor
class MoodConstants {
  static const Map<String, Map<String, dynamic>> moodEmojis = {
    'social': {
      'emoji': '🤝',
      'label': 'Social',
      'description': 'Pronto para fazer conexões',
    },
    'creative': {
      'emoji': '🎨',
      'label': 'Criativo',
      'description': 'Inspirado e artístico',
    },
    'chill': {
      'emoji': '😌',
      'label': 'Relaxar',
      'description': 'Momento zen e tranquilo',
    },
    'adventure': {
      'emoji': '🌟',
      'label': 'Aventura',
      'description': 'Buscando novas experiências',
    },
    'happy': {
      'emoji': '😊',
      'label': 'Feliz',
      'description': 'Estado de alegria',
    },
    'focused': {
      'emoji': '🎯',
      'label': 'Focado',
      'description': 'Concentrado em objetivos',
    },
  };
}

/// Utilitários de formatação e cálculo
class AppUtils {
  // Formatação de números para gamificação
  static String formatGameNumber(int number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    }
    return number.toString();
  }
}
