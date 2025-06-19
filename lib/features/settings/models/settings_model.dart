// lib/features/settings/models/settings_model.dart
class SettingsModel {
  final bool isDarkTheme;
  final bool notificationsEnabled;
  final bool soundEnabled;
  final String language;
  final DateTime? lastUpdated;

  const SettingsModel({
    this.isDarkTheme = false,
    this.notificationsEnabled = true,
    this.soundEnabled = true,
    this.language = 'pt',
    this.lastUpdated,
  });

  /// Criar configurações padrão
  factory SettingsModel.defaultSettings() {
    return SettingsModel(
      isDarkTheme: false,
      notificationsEnabled: true,
      soundEnabled: true,
      language: 'pt',
      lastUpdated: DateTime.now(),
    );
  }

  /// Criar a partir de JSON
  factory SettingsModel.fromJson(Map<String, dynamic> json) {
    return SettingsModel(
      isDarkTheme: json['isDarkTheme'] ?? false,
      notificationsEnabled: json['notificationsEnabled'] ?? true,
      soundEnabled: json['soundEnabled'] ?? true,
      language: json['language'] ?? 'pt',
      lastUpdated: json['lastUpdated'] != null
          ? DateTime.tryParse(json['lastUpdated'])
          : null,
    );
  }

  /// Converter para JSON
  Map<String, dynamic> toJson() {
    return {
      'isDarkTheme': isDarkTheme,
      'notificationsEnabled': notificationsEnabled,
      'soundEnabled': soundEnabled,
      'language': language,
      'lastUpdated': lastUpdated?.toIso8601String(),
    };
  }

  /// Criar cópia com alterações
  SettingsModel copyWith({
    bool? isDarkTheme,
    bool? notificationsEnabled,
    bool? soundEnabled,
    String? language,
    DateTime? lastUpdated,
  }) {
    return SettingsModel(
      isDarkTheme: isDarkTheme ?? this.isDarkTheme,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      soundEnabled: soundEnabled ?? this.soundEnabled,
      language: language ?? this.language,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }

  @override
  String toString() {
    return 'SettingsModel(isDarkTheme: $isDarkTheme, notificationsEnabled: $notificationsEnabled, soundEnabled: $soundEnabled, language: $language)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SettingsModel &&
        other.isDarkTheme == isDarkTheme &&
        other.notificationsEnabled == notificationsEnabled &&
        other.soundEnabled == soundEnabled &&
        other.language == language;
  }

  @override
  int get hashCode {
    return Object.hash(
      isDarkTheme,
      notificationsEnabled,
      soundEnabled,
      language,
    );
  }
}
