// lib/features/settings/providers/settings_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:unlock/core/utils/logger.dart';
import 'package:unlock/features/settings/models/settings_model.dart';
import 'package:unlock/providers/theme_provider.dart';

/// Provider para configurações do usuário
final settingsProvider = StateNotifierProvider<SettingsNotifier, SettingsModel>(
  (ref) => SettingsNotifier(ref),
);

class SettingsNotifier extends StateNotifier<SettingsModel> {
  static const String _settingsKey = 'user_settings';
  final Ref _ref;
  bool _isInitialized = false;

  SettingsNotifier(this._ref) : super(SettingsModel.defaultSettings()) {
    _loadSettings();
  }

  /// Verificar se foi inicializado
  bool get isInitialized => _isInitialized;

  /// Carregar configurações salvas
  Future<void> _loadSettings() async {
    try {
      AppLogger.debug('⚙️ SettingsNotifier: Carregando configurações...');

      final prefs = await SharedPreferences.getInstance();
      final settingsJson = prefs.getString(_settingsKey);

      if (settingsJson != null) {
        final settingsMap = Map<String, dynamic>.from(
          // Simular parsing JSON - em produção usar json.decode
          _parseSettingsString(settingsJson),
        );

        state = SettingsModel.fromJson(settingsMap);
        AppLogger.info(
          '✅ SettingsNotifier: Configurações carregadas',
          data: {
            'isDarkTheme': state.isDarkTheme,
            'notifications': state.notificationsEnabled,
          },
        );
      } else {
        AppLogger.info('📱 SettingsNotifier: Usando configurações padrão');
      }

      // Sincronizar tema com ThemeProvider
      await _syncThemeWithProvider();

      _isInitialized = true;
    } catch (e) {
      AppLogger.error('❌ SettingsNotifier: Erro ao carregar configurações: $e');
      _isInitialized = true; // Marcar como inicializado mesmo com erro
    }
  }

  /// Salvar configurações
  Future<void> _saveSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final settingsString = _settingsToString(state.toJson());
      await prefs.setString(_settingsKey, settingsString);

      AppLogger.debug('💾 SettingsNotifier: Configurações salvas');
    } catch (e) {
      AppLogger.error('❌ SettingsNotifier: Erro ao salvar configurações: $e');
      rethrow;
    }
  }

  /// Alternar tema
  Future<void> toggleTheme() async {
    try {
      AppLogger.info(
        '🎨 SettingsNotifier: Alternando tema',
        data: {'current': state.isDarkTheme ? 'dark' : 'light'},
      );

      // Atualizar estado local
      state = state.copyWith(
        isDarkTheme: !state.isDarkTheme,
        lastUpdated: DateTime.now(),
      );

      // Sincronizar com ThemeProvider
      await _ref.read(themeProvider.notifier).setTheme(state.isDarkTheme);

      // Salvar configurações
      await _saveSettings();

      AppLogger.info(
        '✅ SettingsNotifier: Tema alterado',
        data: {'newTheme': state.isDarkTheme ? 'dark' : 'light'},
      );
    } catch (e) {
      AppLogger.error('❌ SettingsNotifier: Erro ao alternar tema: $e');
      rethrow;
    }
  }

  /// Alternar notificações
  Future<void> toggleNotifications() async {
    try {
      AppLogger.info(
        '🔔 SettingsNotifier: Alternando notificações',
        data: {'current': state.notificationsEnabled},
      );

      state = state.copyWith(
        notificationsEnabled: !state.notificationsEnabled,
        lastUpdated: DateTime.now(),
      );

      await _saveSettings();

      AppLogger.info(
        '✅ SettingsNotifier: Notificações alteradas',
        data: {'enabled': state.notificationsEnabled},
      );
    } catch (e) {
      AppLogger.error('❌ SettingsNotifier: Erro ao alternar notificações: $e');
      rethrow;
    }
  }

  /// Alternar som
  Future<void> toggleSound() async {
    try {
      state = state.copyWith(
        soundEnabled: !state.soundEnabled,
        lastUpdated: DateTime.now(),
      );

      await _saveSettings();

      AppLogger.debug(
        '🔊 SettingsNotifier: Som alterado',
        data: {'enabled': state.soundEnabled},
      );
    } catch (e) {
      AppLogger.error('❌ SettingsNotifier: Erro ao alternar som: $e');
      rethrow;
    }
  }

  /// Redefinir para configurações padrão
  Future<void> resetToDefaults() async {
    try {
      AppLogger.info('🔄 SettingsNotifier: Redefinindo configurações padrão');

      state = SettingsModel.defaultSettings();

      // Sincronizar tema
      await _ref.read(themeProvider.notifier).setTheme(state.isDarkTheme);

      await _saveSettings();

      AppLogger.info('✅ SettingsNotifier: Configurações redefinidas');
    } catch (e) {
      AppLogger.error(
        '❌ SettingsNotifier: Erro ao redefinir configurações: $e',
      );
      rethrow;
    }
  }

  /// Sincronizar tema com ThemeProvider
  Future<void> _syncThemeWithProvider() async {
    try {
      final currentTheme = _ref.read(themeProvider);
      if (currentTheme != state.isDarkTheme) {
        await _ref.read(themeProvider.notifier).setTheme(state.isDarkTheme);
      }
    } catch (e) {
      AppLogger.warning('⚠️ SettingsNotifier: Erro ao sincronizar tema: $e');
    }
  }

  /// Helper para converter settings para string (simular JSON)
  String _settingsToString(Map<String, dynamic> settings) {
    return settings.entries.map((e) => '${e.key}:${e.value}').join(',');
  }

  /// Helper para converter string para map (simular JSON parse)
  Map<String, dynamic> _parseSettingsString(String settingsString) {
    final Map<String, dynamic> result = {};
    final pairs = settingsString.split(',');

    for (final pair in pairs) {
      final keyValue = pair.split(':');
      if (keyValue.length == 2) {
        final key = keyValue[0];
        final value = keyValue[1];

        // Converter tipos básicos
        if (value == 'true' || value == 'false') {
          result[key] = value == 'true';
        } else if (double.tryParse(value) != null) {
          result[key] = double.parse(value);
        } else {
          result[key] = value;
        }
      }
    }

    return result;
  }
}
