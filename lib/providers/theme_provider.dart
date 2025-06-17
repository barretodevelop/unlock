// lib/providers/theme_provider.dart - Com Analytics Integrado
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:unlock/core/utils/logger.dart';
import 'package:unlock/services/analytics/analytics_integration.dart';
import 'package:unlock/services/analytics/interfaces/analytics_interface.dart';

final themeProvider = StateNotifierProvider<ThemeNotifier, bool>(
  (ref) => ThemeNotifier(),
);

class ThemeNotifier extends StateNotifier<bool> {
  static const String _themeKey = 'isDark';

  DateTime? _initTime;
  DateTime? _lastThemeChange;
  int _themeChangeCount = 0;

  ThemeNotifier() : super(false) {
    _initTime = DateTime.now();
    AppLogger.debug('🎨 ThemeNotifier: Inicializando...');

    // 📊 Analytics: Inicialização do theme provider
    _trackAnalyticsEvent('theme_provider_initialized');

    _loadTheme();
  }

  /// Alternar entre tema claro e escuro
  Future<void> toggleTheme() async {
    final newTheme = !state;
    final changeStartTime = DateTime.now();

    AppLogger.info(
      '🎨 ThemeNotifier: Alternando tema',
      data: {
        'previousTheme': state ? 'dark' : 'light',
        'newTheme': newTheme ? 'dark' : 'light',
      },
    );

    try {
      // 📊 Analytics: Tentativa de mudança de tema
      await _trackAnalyticsEvent(
        'theme_change_attempt',
        data: {
          'from_theme': state ? 'dark' : 'light',
          'to_theme': newTheme ? 'dark' : 'light',
          'change_count': _themeChangeCount,
          'session_time_ms': _initTime != null
              ? DateTime.now().difference(_initTime!).inMilliseconds
              : null,
        },
      );

      // Atualizar estado imediatamente para resposta rápida da UI
      state = newTheme;
      _themeChangeCount++;
      _lastThemeChange = DateTime.now();

      // Salvar preferência
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_themeKey, newTheme);

      final changeDuration = DateTime.now().difference(changeStartTime);

      AppLogger.info(
        '✅ ThemeNotifier: Tema alterado e salvo',
        data: {
          'theme': newTheme ? 'dark' : 'light',
          'saved': true,
          'duration_ms': changeDuration.inMilliseconds,
        },
      );

      // 📊 Analytics: Mudança de tema bem-sucedida
      await _trackAnalyticsEvent(
        'theme_changed',
        data: {
          'new_theme': newTheme ? 'dark' : 'light',
          'change_duration_ms': changeDuration.inMilliseconds,
          'change_count': _themeChangeCount,
          'persistence_success': true,
        },
      );

      // 📊 Analytics: Uso específico do método toggle
      await AnalyticsIntegration.manager.trackThemeChange(
        newTheme ? 'dark' : 'light',
      );
    } catch (e) {
      // Reverter estado em caso de erro
      state = !newTheme;
      _themeChangeCount = _themeChangeCount > 0 ? _themeChangeCount - 1 : 0;

      final changeDuration = DateTime.now().difference(changeStartTime);

      AppLogger.error('❌ ThemeNotifier: Erro ao salvar tema: $e');

      // 📊 Analytics: Erro na mudança de tema
      await _trackAnalyticsEvent(
        'theme_change_error',
        data: {
          'intended_theme': newTheme ? 'dark' : 'light',
          'error_type': e.runtimeType.toString(),
          'change_duration_ms': changeDuration.inMilliseconds,
        },
      );

      rethrow;
    }
  }

  /// Definir tema específico
  Future<void> setTheme(bool isDark) async {
    if (state == isDark) {
      AppLogger.debug(
        '🎨 ThemeNotifier: Tema já está definido',
        data: {'currentTheme': isDark ? 'dark' : 'light'},
      );
      return;
    }

    final changeStartTime = DateTime.now();

    AppLogger.info(
      '🎨 ThemeNotifier: Definindo tema',
      data: {
        'previousTheme': state ? 'dark' : 'light',
        'newTheme': isDark ? 'dark' : 'light',
      },
    );

    try {
      // 📊 Analytics: Definição específica de tema
      await _trackAnalyticsEvent(
        'theme_set_attempt',
        data: {
          'from_theme': state ? 'dark' : 'light',
          'to_theme': isDark ? 'dark' : 'light',
          'method': 'setTheme',
        },
      );

      state = isDark;
      _themeChangeCount++;
      _lastThemeChange = DateTime.now();

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_themeKey, isDark);

      final changeDuration = DateTime.now().difference(changeStartTime);

      AppLogger.info(
        '✅ ThemeNotifier: Tema definido e salvo',
        data: {
          'theme': isDark ? 'dark' : 'light',
          'duration_ms': changeDuration.inMilliseconds,
        },
      );

      // 📊 Analytics: Tema definido com sucesso
      await _trackAnalyticsEvent(
        'theme_set_success',
        data: {
          'theme': isDark ? 'dark' : 'light',
          'change_duration_ms': changeDuration.inMilliseconds,
          'method': 'setTheme',
        },
      );
    } catch (e) {
      AppLogger.error('❌ ThemeNotifier: Erro ao definir tema: $e');

      // 📊 Analytics: Erro ao definir tema
      await _trackAnalyticsEvent(
        'theme_set_error',
        data: {
          'intended_theme': isDark ? 'dark' : 'light',
          'error_type': e.runtimeType.toString(),
          'method': 'setTheme',
        },
      );

      rethrow;
    }
  }

  /// Carregar tema salvo das preferências
  Future<void> _loadTheme() async {
    final loadStartTime = DateTime.now();

    try {
      AppLogger.debug('📱 ThemeNotifier: Carregando tema das preferências...');

      final prefs = await SharedPreferences.getInstance();
      final savedTheme = prefs.getBool(_themeKey);

      final loadDuration = DateTime.now().difference(loadStartTime);

      if (savedTheme != null) {
        state = savedTheme;
        AppLogger.info(
          '✅ ThemeNotifier: Tema carregado das preferências',
          data: {
            'theme': savedTheme ? 'dark' : 'light',
            'source': 'SharedPreferences',
            'load_duration_ms': loadDuration.inMilliseconds,
          },
        );

        // 📊 Analytics: Tema carregado com sucesso
        await _trackAnalyticsEvent(
          'theme_loaded',
          data: {
            'theme': savedTheme ? 'dark' : 'light',
            'source': 'preferences',
            'load_duration_ms': loadDuration.inMilliseconds,
            'has_saved_preference': true,
          },
        );
      } else {
        // Usar tema padrão (claro)
        state = false;
        AppLogger.info(
          '🎨 ThemeNotifier: Usando tema padrão',
          data: {
            'theme': 'light',
            'source': 'default',
            'load_duration_ms': loadDuration.inMilliseconds,
          },
        );

        // 📊 Analytics: Usando tema padrão
        await _trackAnalyticsEvent(
          'theme_loaded',
          data: {
            'theme': 'light',
            'source': 'default',
            'load_duration_ms': loadDuration.inMilliseconds,
            'has_saved_preference': false,
          },
        );
      }
    } catch (e) {
      // Em caso de erro, usar tema padrão
      state = false;
      final loadDuration = DateTime.now().difference(loadStartTime);

      AppLogger.warning(
        '⚠️ ThemeNotifier: Erro ao carregar tema, usando padrão: $e',
      );

      // 📊 Analytics: Erro ao carregar tema
      await _trackAnalyticsEvent(
        'theme_load_error',
        data: {
          'error_type': e.runtimeType.toString(),
          'load_duration_ms': loadDuration.inMilliseconds,
          'fallback_theme': 'light',
        },
      );
    }
  }

  /// Resetar tema para padrão
  Future<void> resetToDefault() async {
    final resetStartTime = DateTime.now();

    AppLogger.info('🔄 ThemeNotifier: Resetando tema para padrão');

    try {
      // 📊 Analytics: Tentativa de reset
      await _trackAnalyticsEvent(
        'theme_reset_attempt',
        data: {
          'current_theme': state ? 'dark' : 'light',
          'change_count_before_reset': _themeChangeCount,
        },
      );

      state = false; // Tema claro como padrão
      _themeChangeCount = 0;
      _lastThemeChange = null;

      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_themeKey);

      final resetDuration = DateTime.now().difference(resetStartTime);

      AppLogger.info(
        '✅ ThemeNotifier: Tema resetado para padrão',
        data: {'theme': 'light', 'duration_ms': resetDuration.inMilliseconds},
      );

      // 📊 Analytics: Reset bem-sucedido
      await _trackAnalyticsEvent(
        'theme_reset_success',
        data: {
          'reset_duration_ms': resetDuration.inMilliseconds,
          'preference_removed': true,
        },
      );
    } catch (e) {
      AppLogger.error('❌ ThemeNotifier: Erro ao resetar tema: $e');

      // 📊 Analytics: Erro no reset
      await _trackAnalyticsEvent(
        'theme_reset_error',
        data: {'error_type': e.runtimeType.toString()},
      );

      rethrow;
    }
  }

  /// Obter tema atual como string
  String get currentThemeString => state ? 'dark' : 'light';

  /// Verificar se é tema escuro
  bool get isDark => state;

  /// Verificar se é tema claro
  bool get isLight => !state;

  /// Log do estado atual
  void logCurrentTheme() {
    AppLogger.debug(
      '🎨 ThemeNotifier: Estado atual',
      data: {
        'theme': currentThemeString,
        'isDark': isDark,
        'isLight': isLight,
        'changeCount': _themeChangeCount,
        'lastChange': _lastThemeChange?.toIso8601String(),
        'sessionTime': _initTime != null
            ? DateTime.now().difference(_initTime!).inMilliseconds
            : null,
      },
    );
  }

  /// Obter estatísticas de uso do tema
  Map<String, dynamic> getThemeStats() {
    return {
      'current_theme': currentThemeString,
      'change_count': _themeChangeCount,
      'last_change': _lastThemeChange?.toIso8601String(),
      'session_duration_ms': _initTime != null
          ? DateTime.now().difference(_initTime!).inMilliseconds
          : null,
      'time_since_last_change_ms': _lastThemeChange != null
          ? DateTime.now().difference(_lastThemeChange!).inMilliseconds
          : null,
    };
  }

  /// Método helper para rastrear eventos de analytics
  Future<void> _trackAnalyticsEvent(
    String eventName, {
    Map<String, dynamic>? data,
  }) async {
    try {
      if (AnalyticsIntegration.isEnabled) {
        await AnalyticsIntegration.manager.trackEvent(
          eventName,
          parameters: data,
          category: EventCategory.user,
          priority: EventPriority.low,
        );
      }
    } catch (e) {
      // Não interromper fluxo principal por falha em analytics
      AppLogger.debug('Falha ao rastrear evento de tema: $e');
    }
  }
}

/// Provider para acessar utilitários do tema
final themeUtilsProvider = Provider<ThemeUtils>((ref) {
  final isDark = ref.watch(themeProvider);
  return ThemeUtils(isDark: isDark);
});

/// Classe utilitária para helpers do tema
class ThemeUtils {
  final bool isDark;

  const ThemeUtils({required this.isDark});

  String get themeString => isDark ? 'dark' : 'light';
  bool get isLight => !isDark;

  /// Log das informações do tema
  void logThemeInfo() {
    AppLogger.debug(
      '🎨 ThemeUtils: Informações do tema',
      data: {'theme': themeString, 'isDark': isDark, 'isLight': isLight},
    );
  }

  /// Rastrear uso de componente específico com tema
  Future<void> trackThemeComponentUsage(String componentName) async {
    try {
      if (AnalyticsIntegration.isEnabled) {
        await AnalyticsIntegration.manager.trackEvent(
          'theme_component_used',
          parameters: {'component': componentName, 'theme': themeString},
        );
      }
    } catch (e) {
      AppLogger.debug('Falha ao rastrear uso de componente com tema: $e');
    }
  }
}

/// Extensão para rastrear preferências de tema
extension ThemeAnalytics on ThemeNotifier {
  /// Rastrear preferência de tema do usuário
  Future<void> trackThemePreference() async {
    final stats = getThemeStats();

    try {
      if (AnalyticsIntegration.isEnabled) {
        await AnalyticsIntegration.manager.trackEvent(
          'theme_preference_analysis',
          parameters: {
            'preferred_theme': currentThemeString,
            'change_frequency': _themeChangeCount,
            'session_duration_ms': stats['session_duration_ms'],
            'stability_score': _calculateThemeStability(),
          },
        );
      }
    } catch (e) {
      AppLogger.debug('Falha ao rastrear preferência de tema: $e');
    }
  }

  /// Calcular score de estabilidade do tema (menos mudanças = mais estável)
  double _calculateThemeStability() {
    if (_initTime == null) return 1.0;

    final sessionDurationHours = DateTime.now().difference(_initTime!).inHours;
    if (sessionDurationHours == 0) return 1.0;

    final changesPerHour = _themeChangeCount / sessionDurationHours;

    // Score de 0 a 1, onde 1 é mais estável (menos mudanças)
    return (1.0 / (1.0 + changesPerHour)).clamp(0.0, 1.0);
  }

  /// Rastrear padrão de uso de tema (chamado periodicamente)
  Future<void> trackThemeUsagePattern() async {
    try {
      if (AnalyticsIntegration.isEnabled) {
        final now = DateTime.now();
        final timeOfDay =
            '${now.hour.toString().padLeft(2, '0')}:${(now.minute ~/ 15 * 15).toString().padLeft(2, '0')}'; // 15min intervals

        await AnalyticsIntegration.manager.trackEvent(
          'theme_usage_pattern',
          parameters: {
            'current_theme': currentThemeString,
            'time_of_day': timeOfDay,
            'day_of_week': now.weekday,
            'is_weekend': now.weekday >= 6,
          },
        );
      }
    } catch (e) {
      AppLogger.debug('Falha ao rastrear padrão de uso de tema: $e');
    }
  }
}
