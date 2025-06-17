// lib/core/theme/app_theme.dart - Sistema de Tema do Unlock
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:unlock/core/constants/app_constants.dart';

/// Sistema de tema centralizado para o app Unlock
class AppTheme {
  // Cores principais
  static const Color primaryColor = Color(0xFF6366F1); // Indigo moderno
  static const Color primaryVariant = Color(0xFF4F46E5);
  static const Color secondaryColor = Color(0xFF10B981); // Verde esmeralda
  static const Color accentColor = Color(0xFFF59E0B); // Âmbar

  // Cores de gamificação
  static const Color coinsColor = Color(ColorConstants.coinsColor);
  static const Color gemsColor = Color(ColorConstants.gemsColor);
  static const Color xpColor = Color(ColorConstants.xpColor);
  static const Color levelColor = Color(ColorConstants.levelColor);

  // Cores de status
  static const Color successColor = Color(ColorConstants.successColor);
  static const Color warningColor = Color(ColorConstants.warningColor);
  static const Color errorColor = Color(ColorConstants.errorColor);
  static const Color infoColor = Color(ColorConstants.infoColor);

  // Cores neutras
  static const Color backgroundLight = Color(0xFFFAFAFA);
  static const Color backgroundDark = Color(0xFF121212);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color surfaceDark = Color(0xFF1E1E1E);
  static const Color cardLight = Color(0xFFFFFFFF);
  static const Color cardDark = Color(0xFF2D2D2D);

  // Tema claro
  static ThemeData get lightTheme {
    return ThemeData(
      // Configurações básicas
      brightness: Brightness.light,
      useMaterial3: true,

      // Esquema de cores
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        brightness: Brightness.light,
        primary: primaryColor,
        secondary: secondaryColor,
        tertiary: accentColor,
        surface: surfaceLight,
        background: backgroundLight,
        error: errorColor,
      ),

      // Tipografia
      textTheme: _buildTextTheme(Brightness.light),

      // Componentes
      appBarTheme: _buildAppBarTheme(Brightness.light),
      bottomNavigationBarTheme: _buildBottomNavTheme(Brightness.light),
      cardTheme: _buildCardTheme(Brightness.light),
      elevatedButtonTheme: _buildElevatedButtonTheme(Brightness.light),
      outlinedButtonTheme: _buildOutlinedButtonTheme(Brightness.light),
      textButtonTheme: _buildTextButtonTheme(Brightness.light),
      floatingActionButtonTheme: _buildFabTheme(Brightness.light),
      inputDecorationTheme: _buildInputTheme(Brightness.light),
      chipTheme: _buildChipTheme(Brightness.light),
      dividerTheme: _buildDividerTheme(Brightness.light),
      dialogTheme: _buildDialogTheme(Brightness.light),

      // Configurações adicionais
      scaffoldBackgroundColor: backgroundLight,
      splashColor: primaryColor.withOpacity(0.1),
      highlightColor: primaryColor.withOpacity(0.05),
    );
  }

  // Tema escuro
  static ThemeData get darkTheme {
    return ThemeData(
      // Configurações básicas
      brightness: Brightness.dark,
      useMaterial3: true,

      // Esquema de cores
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        brightness: Brightness.dark,
        primary: primaryColor,
        secondary: secondaryColor,
        tertiary: accentColor,
        surface: surfaceDark,
        background: backgroundDark,
        error: errorColor,
      ),

      // Tipografia
      textTheme: _buildTextTheme(Brightness.dark),

      // Componentes
      appBarTheme: _buildAppBarTheme(Brightness.dark),
      bottomNavigationBarTheme: _buildBottomNavTheme(Brightness.dark),
      cardTheme: _buildCardTheme(Brightness.dark),
      elevatedButtonTheme: _buildElevatedButtonTheme(Brightness.dark),
      outlinedButtonTheme: _buildOutlinedButtonTheme(Brightness.dark),
      textButtonTheme: _buildTextButtonTheme(Brightness.dark),
      floatingActionButtonTheme: _buildFabTheme(Brightness.dark),
      inputDecorationTheme: _buildInputTheme(Brightness.dark),
      chipTheme: _buildChipTheme(Brightness.dark),
      dividerTheme: _buildDividerTheme(Brightness.dark),
      dialogTheme: _buildDialogTheme(Brightness.dark),

      // Configurações adicionais
      scaffoldBackgroundColor: backgroundDark,
      splashColor: primaryColor.withOpacity(0.1),
      highlightColor: primaryColor.withOpacity(0.05),
    );
  }

  // Construir tema de tipografia
  static TextTheme _buildTextTheme(Brightness brightness) {
    final baseTextTheme = GoogleFonts.interTextTheme();
    final color = brightness == Brightness.light
        ? Colors.black87
        : Colors.white70;

    return baseTextTheme.copyWith(
      displayLarge: baseTextTheme.displayLarge?.copyWith(
        color: color,
        fontWeight: FontWeight.bold,
      ),
      displayMedium: baseTextTheme.displayMedium?.copyWith(
        color: color,
        fontWeight: FontWeight.bold,
      ),
      displaySmall: baseTextTheme.displaySmall?.copyWith(
        color: color,
        fontWeight: FontWeight.w600,
      ),
      headlineLarge: baseTextTheme.headlineLarge?.copyWith(
        color: color,
        fontWeight: FontWeight.bold,
      ),
      headlineMedium: baseTextTheme.headlineMedium?.copyWith(
        color: color,
        fontWeight: FontWeight.w600,
      ),
      headlineSmall: baseTextTheme.headlineSmall?.copyWith(
        color: color,
        fontWeight: FontWeight.w500,
      ),
      titleLarge: baseTextTheme.titleLarge?.copyWith(
        color: color,
        fontWeight: FontWeight.w600,
      ),
      titleMedium: baseTextTheme.titleMedium?.copyWith(
        color: color,
        fontWeight: FontWeight.w500,
      ),
      titleSmall: baseTextTheme.titleSmall?.copyWith(
        color: color,
        fontWeight: FontWeight.w500,
      ),
      bodyLarge: baseTextTheme.bodyLarge?.copyWith(color: color),
      bodyMedium: baseTextTheme.bodyMedium?.copyWith(color: color),
      bodySmall: baseTextTheme.bodySmall?.copyWith(
        color: color.withOpacity(0.7),
      ),
      labelLarge: baseTextTheme.labelLarge?.copyWith(
        color: color,
        fontWeight: FontWeight.w500,
      ),
      labelMedium: baseTextTheme.labelMedium?.copyWith(color: color),
      labelSmall: baseTextTheme.labelSmall?.copyWith(
        color: color.withOpacity(0.7),
      ),
    );
  }

  // App Bar Theme
  static AppBarTheme _buildAppBarTheme(Brightness brightness) {
    return AppBarTheme(
      backgroundColor: brightness == Brightness.light
          ? surfaceLight
          : surfaceDark,
      foregroundColor: brightness == Brightness.light
          ? Colors.black87
          : Colors.white70,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: GoogleFonts.inter(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: brightness == Brightness.light ? Colors.black87 : Colors.white70,
      ),
    );
  }

  // Bottom Navigation Theme
  static BottomNavigationBarThemeData _buildBottomNavTheme(
    Brightness brightness,
  ) {
    return BottomNavigationBarThemeData(
      backgroundColor: brightness == Brightness.light
          ? surfaceLight
          : surfaceDark,
      selectedItemColor: primaryColor,
      unselectedItemColor: brightness == Brightness.light
          ? Colors.grey.shade600
          : Colors.grey.shade400,
      type: BottomNavigationBarType.fixed,
      elevation: 8,
    );
  }

  // Card Theme
  static CardThemeData _buildCardTheme(Brightness brightness) {
    return CardThemeData(
      color: brightness == Brightness.light ? cardLight : cardDark,
      elevation: 2,
      shadowColor: Colors.black.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );
  }

  // Elevated Button Theme
  static ElevatedButtonThemeData _buildElevatedButtonTheme(
    Brightness brightness,
  ) {
    return ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 2,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        textStyle: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w500),
      ),
    );
  }

  // Outlined Button Theme
  static OutlinedButtonThemeData _buildOutlinedButtonTheme(
    Brightness brightness,
  ) {
    return OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: primaryColor,
        side: const BorderSide(color: primaryColor, width: 1.5),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        textStyle: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w500),
      ),
    );
  }

  // Text Button Theme
  static TextButtonThemeData _buildTextButtonTheme(Brightness brightness) {
    return TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: primaryColor,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        textStyle: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500),
      ),
    );
  }

  // Floating Action Button Theme
  static FloatingActionButtonThemeData _buildFabTheme(Brightness brightness) {
    return FloatingActionButtonThemeData(
      backgroundColor: primaryColor,
      foregroundColor: Colors.white,
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    );
  }

  // Input Decoration Theme
  static InputDecorationTheme _buildInputTheme(Brightness brightness) {
    return InputDecorationTheme(
      filled: true,
      fillColor: brightness == Brightness.light
          ? Colors.grey.shade50
          : Colors.grey.shade900,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(
          color: brightness == Brightness.light
              ? Colors.grey.shade300
              : Colors.grey.shade700,
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(
          color: brightness == Brightness.light
              ? Colors.grey.shade300
              : Colors.grey.shade700,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: primaryColor, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: errorColor, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    );
  }

  // Chip Theme
  static ChipThemeData _buildChipTheme(Brightness brightness) {
    return ChipThemeData(
      backgroundColor: brightness == Brightness.light
          ? Colors.grey.shade100
          : Colors.grey.shade800,
      labelStyle: GoogleFonts.inter(
        fontSize: 14,
        color: brightness == Brightness.light ? Colors.black87 : Colors.white70,
      ),
      side: BorderSide.none,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    );
  }

  // Divider Theme
  static DividerThemeData _buildDividerTheme(Brightness brightness) {
    return DividerThemeData(
      color: brightness == Brightness.light
          ? Colors.grey.shade300
          : Colors.grey.shade700,
      thickness: 1,
      space: 1,
    );
  }

  // Dialog Theme
  static DialogThemeData _buildDialogTheme(Brightness brightness) {
    return DialogThemeData(
      backgroundColor: brightness == Brightness.light
          ? surfaceLight
          : surfaceDark,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 8,
    );
  }
}

/// Extensões para cores de gamificação
extension GameColors on ColorScheme {
  Color get coins => AppTheme.coinsColor;
  Color get gems => AppTheme.gemsColor;
  Color get xp => AppTheme.xpColor;
  Color get level => AppTheme.levelColor;
}

/// Extensões para cores de status
extension StatusColors on ColorScheme {
  Color get success => AppTheme.successColor;
  Color get warning => AppTheme.warningColor;
  Color get info => AppTheme.infoColor;
}

/// Utilitários de tema
class ThemeUtils {
  // Verificar se é tema escuro
  static bool isDark(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark;
  }

  // Obter cor de contraste
  static Color getContrastColor(BuildContext context) {
    return isDark(context) ? Colors.white : Colors.black;
  }

  // Obter cor de superfície elevada
  static Color getElevatedSurface(
    BuildContext context, [
    double elevation = 1,
  ]) {
    return Theme.of(context).colorScheme.surface.withOpacity(
      isDark(context) ? 0.08 * elevation : 0.05 * elevation,
    );
  }
}
