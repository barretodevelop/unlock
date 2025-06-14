// AppTheme
// lib/config/app_theme.dart - AppTheme
import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData get lightTheme => ThemeData(
        useMaterial3: true,
        primarySwatch: Colors.purple,
        scaffoldBackgroundColor: const Color(0xFFF8FAFC),
        appBarTheme:
            const AppBarTheme(backgroundColor: Colors.white, foregroundColor: Colors.black),
        cardTheme: CardThemeData(
            color: Colors.white,
            elevation: 4,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(backgroundColor: Colors.white),
      );

  static ThemeData get darkTheme => ThemeData(
        useMaterial3: true,
        primarySwatch: Colors.purple,
        scaffoldBackgroundColor: const Color(0xFF111827),
        appBarTheme:
            const AppBarTheme(backgroundColor: Color(0xFF1F2937), foregroundColor: Colors.white),
        cardTheme: CardThemeData(
            color: const Color(0xFF1F2937),
            elevation: 4,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
        bottomNavigationBarTheme:
            const BottomNavigationBarThemeData(backgroundColor: Color(0xFF1F2937)),
      );
}

