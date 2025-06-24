// lib/core/theme/app_colors.dart
import 'package:flutter/material.dart';

/// Paleta de cores centralizada do app Unlock
/// 
/// Define todas as cores utilizadas no aplicativo, seguindo
/// princípios de design system e acessibilidade.
class AppColors {
  AppColors._(); // Construtor privado para evitar instanciação

  // ========================================
  // CORES PRINCIPAIS (BRAND)
  // ========================================

  /// Cor primária do app - Roxo vibrante para conexões
  static const Color primary = Color(0xFF6C63FF);
  
  /// Variação mais escura da cor primária
  static const Color primaryDark = Color(0xFF5A52E8);
  
  /// Variação mais clara da cor primária
  static const Color primaryLight = Color(0xFF8B84FF);

  /// Cor secundária - Rosa para descobertas e revelações
  static const Color secondary = Color(0xFFFF6B9D);
  
  /// Variação mais escura da cor secundária
  static const Color secondaryDark = Color(0xFFE8528A);
  
  /// Variação mais clara da cor secundária
  static const Color secondaryLight = Color(0xFFFF8FB3);

  /// Cor de destaque - Laranja para ações importantes
  static const Color accent = Color(0xFFFF9500);

  // ========================================
  // CORES FUNCIONAIS
  // ========================================

  /// Verde para sucessos, confirmações e valores positivos
  static const Color success = Color(0xFF00C896);
  
  /// Variação mais escura do verde de sucesso
  static const Color successDark = Color(0xFF00A87D);
  
  /// Variação mais clara do verde de sucesso
  static const Color successLight = Color(0xFF33D4A9);

  /// Vermelho para erros, alertas e ações destrutivas
  static const Color error = Color(0xFFFF5722);
  
  /// Variação mais escura do vermelho de erro
  static const Color errorDark = Color(0xFFE64A19);
  
  /// Variação mais clara do vermelho de erro
  static const Color errorLight = Color(0xFFFF7043);

  /// Amarelo/laranja para avisos e notificações importantes
  static const Color warning = Color(0xFFFFC107);
  
  /// Variação mais escura do amarelo de aviso
  static const Color warningDark = Color(0xFFF57F17);
  
  /// Variação mais clara do amarelo de aviso
  static const Color warningLight = Color(0xFFFFD54F);

  /// Azul para informações neutras e links
  static const Color info = Color(0xFF2196F3);
  
  /// Variação mais escura do azul de informação
  static const Color infoDark = Color(0xFF1976D2);
  
  /// Variação mais clara do azul de informação
  static const Color infoLight = Color(0xFF42A5F5);

  // ========================================
  // CORES NEUTRAS
  // ========================================

  /// Preto puro
  static const Color black = Color(0xFF000000);
  
  /// Branco puro
  static const Color white = Color(0xFFFFFFFF);

  /// Cinza muito escuro - para textos principais
  static const Color grey900 = Color(0xFF212121);
  
  /// Cinza escuro - para textos secundários
  static const Color grey800 = Color(0xFF424242);
  
  /// Cinza médio escuro - para textos de baixa hierarquia
  static const Color grey700 = Color(0xFF616161);
  
  /// Cinza médio - para divisores e bordas
  static const Color grey600 = Color(0xFF757575);
  
  /// Cinza médio claro - para elementos desabilitados
  static const Color grey500 = Color(0xFF9E9E9E);
  
  /// Cinza claro - para backgrounds sutis
  static const Color grey400 = Color(0xFFBDBDBD);
  
  /// Cinza muito claro - para backgrounds de cards
  static const Color grey300 = Color(0xFFE0E0E0);
  
  /// Cinza quase branco - para backgrounds principais
  static const Color grey200 = Color(0xFFEEEEEE);
  
  /// Cinza mínimo - para backgrounds alternativos
  static const Color grey100 = Color(0xFFF5F5F5);
  
  /// Cinza quase imperceptível
  static const Color grey50 = Color(0xFFFAFAFA);

  // ========================================
  // CORES TEMÁTICAS DO APP
  // ========================================

  /// Cor para elementos de gamificação (moedas, pontos)
  static const Color coin = Color(0xFFFFD700);
  
  /// Cor para elementos premium (gemas, VIP)
  static const Color gem = Color(0xFF8E44AD);
  
  /// Cor para streaks e sequências
  static const Color streak = Color(0xFFE74C3C);
  
  /// Cor para conexões formadas
  static const Color connection = Color(0xFFE91E63);
  
  /// Cor para descobertas e revelações
  static const Color discovery = Color(0xFF00BCD4);

  // ========================================
  // GRADIENTES
  // ========================================

  /// Gradiente primário - usado em botões principais e headers
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primary, primaryDark],
  );

  /// Gradiente secundário - usado em elementos de destaque
  static const LinearGradient secondaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [secondary, secondaryDark],
  );

  /// Gradiente de sucesso - usado em confirmações
  static const LinearGradient successGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [success, successDark],
  );

  /// Gradiente colorido - usado em elementos especiais
  static const LinearGradient rainbowGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primary, secondary, accent, warning],
  );

  /// Gradiente sutil - usado em backgrounds
  static const LinearGradient subtleGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFFAFAFA), Color(0xFFF5F5F5)],
  );

  /// Gradiente escuro - usado no tema dark
  static const LinearGradient darkGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF1A1A1A), Color(0xFF121212)],
  );

  // ========================================
  // SOMBRAS E ELEVAÇÃO
  // ========================================

  /// Sombra suave para cards e elementos elevados
  static List<BoxShadow> get softShadow => [
    BoxShadow(
      color: grey500.withOpacity(0.1),
      blurRadius: 8,
      offset: const Offset(0, 2),
    ),
  ];

  /// Sombra média para elementos importantes
  static List<BoxShadow> get mediumShadow => [
    BoxShadow(
      color: grey600.withOpacity(0.15),
      blurRadius: 12,
      offset: const Offset(0, 4),
    ),
  ];

  /// Sombra forte para modals e dialogs
  static List<BoxShadow> get strongShadow => [
    BoxShadow(
      color: grey700.withOpacity(0.2),
      blurRadius: 16,
      offset: const Offset(0, 8),
    ),
  ];

  /// Sombra colorida para elementos especiais
  static List<BoxShadow> getPrimaryShadow({double opacity = 0.3}) => [
    BoxShadow(
      color: primary.withOpacity(opacity),
      blurRadius: 12,
      offset: const Offset(0, 4),
    ),
  ];

  /// Sombra secundária colorida
  static List<BoxShadow> getSecondaryShadow({double opacity = 0.3}) => [
    BoxShadow(
      color: secondary.withOpacity(opacity),
      blurRadius: 12,
      offset: const Offset(0, 4),
    ),
  ];

  // ========================================
  // CORES POR CONTEXTO
  // ========================================

  /// Cores para diferentes tipos de notificação
  static const Map<String, Color> notificationColors = {
    'success': success,
    'error': error,
    'warning': warning,
    'info': info,
    'streak': streak,
    'connection': connection,
    'achievement': accent,
  };

  /// Cores para diferentes raridades
  static const Map<String, Color> rarityColors = {
    'common': success,
    'rare': info,
    'epic': secondary,
    'legendary': warning,
    'exclusive': accent,
  };

  /// Cores para diferentes tipos de power-ups
  static const Map<String, Color> powerUpColors = {
    'extraHint': info,
    'superQuestion': secondary,
    'matchBooster': accent,
    'timeFreeze': Color(0xFF00BCD4),
    'skipQuestion': warning,
    'doubleChance': success,
    'xrayVision': Color(0xFF9C27B0),
    'luckyGuess': Color(0xFFFF5722),
  };

  // ========================================
  // MÉTODOS UTILITÁRIOS
  // ========================================

  /// Retorna uma cor com opacidade aplicada
  static Color withOpacity(Color color, double opacity) {
    return color.withOpacity(opacity);
  }

  /// Retorna uma versão mais escura de uma cor
  static Color darken(Color color, [double amount = 0.1]) {
    final hsl = HSLColor.fromColor(color);
    return hsl.withLightness((hsl.lightness - amount).clamp(0.0, 1.0)).toColor();
  }

  /// Retorna uma versão mais clara de uma cor
  static Color lighten(Color color, [double amount = 0.1]) {
    final hsl = HSLColor.fromColor(color);
    return hsl.withLightness((hsl.lightness + amount).clamp(0.0, 1.0)).toColor();
  }

  /// Retorna uma cor baseada no tipo de notificação
  static Color getNotificationColor(String type) {
    return notificationColors[type] ?? info;
  }

  /// Retorna uma cor baseada na raridade
  static Color getRarityColor(String rarity) {
    return rarityColors[rarity] ?? grey500;
  }

  /// Retorna uma cor baseada no tipo de power-up
  static Color getPowerUpColor(String type) {
    return powerUpColors[type] ?? primary;
  }

  /// Verifica se uma cor é escura
  static bool isDark(Color color) {
    return color.computeLuminance() < 0.5;
  }

  /// Retorna cor de texto contrastante
  static Color getContrastingTextColor(Color backgroundColor) {
    return isDark(backgroundColor) ? white : grey900;
  }

  /// Cria um MaterialColor a partir de uma cor
  static MaterialColor createMaterialColor(Color color) {
    final strengths = <double>[.05];
    final swatch = <int, Color>{};
    final r = color.red;
    final g = color.green;
    final b = color.blue;

    for (int i = 1; i < 10; i++) {
      strengths.add(0.1 * i);
    }

    for (final strength in strengths) {
      final double ds = 0.5 - strength;
      swatch[(strength * 1000).round()] = Color.fromRGBO(
        r + ((ds < 0 ? r : (255 - r)) * ds).round(),
        g + ((ds < 0 ? g : (255 - g)) * ds).round(),
        b + ((ds < 0 ? b : (255 - b)) * ds).round(),
        1,
      );
    }

    return MaterialColor(color.value, swatch);
  }

  // ========================================
  // CORES ESPECÍFICAS DO TEMA ESCURO
  // ========================================

  /// Cores específicas para o tema escuro
  static const Color darkBackground = Color(0xFF121212);
  static const Color darkSurface = Color(0xFF1E1E1E);
  static const Color darkCard = Color(0xFF2D2D2D);
  static const Color darkDivider = Color(0xFF404040);

  // ========================================
  // VALIDAÇÃO DE ACESSIBILIDADE
  // ========================================

  /// Verifica se há contraste suficiente entre duas cores
  static bool hasGoodContrast(Color color1, Color color2) {
    final luminance1 = color1.computeLuminance();
    final luminance2 = color2.computeLuminance();
    final ratio = (luminance1 + 0.05) / (luminance2 + 0.05);
    
    // WCAG AA requires a contrast ratio of at least 4.5:1
    return ratio >= 4.5 || (1 / ratio) >= 4.5;
  }

  /// Retorna a melhor cor de texto para um fundo
  static Color getBestTextColor(Color backgroundColor) {
    return hasGoodContrast(white, backgroundColor) ? white : grey900;
  }
}