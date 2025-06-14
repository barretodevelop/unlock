// ThemeProvider
// lib/providers/theme_provider.dart - ThemeProvider
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final themeProvider = StateNotifierProvider<ThemeNotifier, bool>((ref) => ThemeNotifier());

class ThemeNotifier extends StateNotifier<bool> {
  ThemeNotifier() : super(false) {
    _loadTheme();
  }

  void toggleTheme() async {
    state = !state;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDark', state);
  }

  void _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getBool('isDark') ?? false;
  }
}

