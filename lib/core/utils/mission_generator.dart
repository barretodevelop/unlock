// lib/core/utils/mission_generator.dart
// Gerador inteligente de missões - Fase 3

import 'dart:math' as math;

import 'package:unlock/core/constants/mission_constants.dart';
import 'package:unlock/core/utils/logger.dart';
import 'package:unlock/features/missions/models/mission_model.dart';
import 'package:unlock/models/user_model.dart';

/// Gerador inteligente de missões baseado no perfil do usuário
class MissionGenerator {
  static final _random = math.Random();

  // ================================================================================================
  // GERAÇÃO DE MISSÕES DIÁRIAS
  // ================================================================================================

  /// Gerar missões diárias personalizadas para o usuário
  static List<MissionModel> generateDailyMissions(
    UserModel user, {
    Map<String, bool> userRequirements = const {},
    List<String> completedMissionIds = const [],
  }) {
    try {
      AppLogger.debug('🎯 Gerando missões diárias para usuário ${user.uid}');

      final missions = <MissionModel>[];
      final usedTemplates = <String>{};

      // Filtrar templates disponíveis baseados nos requisitos do usuário
      final availableTemplates = MissionConstants.dailyMissionTemplates
          .where(
            (template) => _canUseTemplate(
              template,
              user,
              userRequirements,
              completedMissionIds,
            ),
          )
          .toList();

      if (availableTemplates.isEmpty) {
        AppLogger.warning(
          '⚠️ Nenhum template de missão diária disponível para usuário ${user.uid}',
        );
        return _generateFallbackDailyMissions(user);
      }

      // Gerar missões garantindo variedade de categorias
      for (int i = 0; i < MissionConstants.dailyMissionsCount; i++) {
        final template = _selectBestTemplate(
          availableTemplates,
          usedTemplates,
          user,
          missions,
        );

        if (template != null) {
          final mission = _createMissionFromTemplate(
            template,
            user,
            MissionType.daily,
          );
          missions.add(mission);
          usedTemplates.add(template['id'] as String);
        }
      }

      // Se não conseguimos gerar missões suficientes, completar com missões básicas
      while (missions.length < MissionConstants.dailyMissionsCount) {
        final basicMission = _generateBasicDailyMission(user, missions.length);
        missions.add(basicMission);
      }

      AppLogger.info(
        '✅ Geradas ${missions.length} missões diárias para usuário ${user.uid}',
      );
      return missions;
    } catch (e, stackTrace) {
      AppLogger.error('❌ Erro ao gerar missões diárias', error: e);
      return _generateFallbackDailyMissions(user);
    }
  }

  // ================================================================================================
  // GERAÇÃO DE MISSÕES SEMANAIS
  // ================================================================================================

  /// Gerar missões semanais personalizadas para o usuário
  static List<MissionModel> generateWeeklyMissions(
    UserModel user, {
    Map<String, bool> userRequirements = const {},
    List<String> completedMissionIds = const [],
  }) {
    try {
      AppLogger.debug('🎯 Gerando missões semanais para usuário ${user.uid}');

      final missions = <MissionModel>[];
      final usedTemplates = <String>{};

      final availableTemplates = MissionConstants.weeklyMissionTemplates
          .where(
            (template) => _canUseTemplate(
              template,
              user,
              userRequirements,
              completedMissionIds,
            ),
          )
          .toList();

      if (availableTemplates.isEmpty) {
        AppLogger.warning(
          '⚠️ Nenhum template de missão semanal disponível para usuário ${user.uid}',
        );
        return _generateFallbackWeeklyMissions(user);
      }

      // Gerar missões semanais (sempre desafiadoras)
      for (int i = 0; i < MissionConstants.weeklyMissionsCount; i++) {
        final template = _selectBestWeeklyTemplate(
          availableTemplates,
          usedTemplates,
          user,
        );

        if (template != null) {
          final mission = _createMissionFromTemplate(
            template,
            user,
            MissionType.weekly,
          );
          missions.add(mission);
          usedTemplates.add(template['id'] as String);
        }
      }

      // Completar com missões básicas se necessário
      while (missions.length < MissionConstants.weeklyMissionsCount) {
        final basicMission = _generateBasicWeeklyMission(user, missions.length);
        missions.add(basicMission);
      }

      AppLogger.info(
        '✅ Geradas ${missions.length} missões semanais para usuário ${user.uid}',
      );
      return missions;
    } catch (e, stackTrace) {
      AppLogger.error('❌ Erro ao gerar missões semanais', error: e);

      return _generateFallbackWeeklyMissions(user);
    }
  }

  // ================================================================================================
  // GERAÇÃO DE MISSÕES COLABORATIVAS
  // ================================================================================================

  /// Gerar missão colaborativa entre dois usuários
  static MissionModel? generateCollaborativeMission(
    UserModel user1,
    UserModel user2,
  ) {
    try {
      AppLogger.debug(
        '🤝 Gerando missão colaborativa entre ${user1.uid} e ${user2.uid}',
      );

      // Encontrar interesses em comum
      final commonInterests = _findCommonInterests(user1, user2);

      // Selecionar template baseado nos interesses
      final availableTemplates = MissionConstants.collaborativeMissionTemplates
          .where(
            (template) => _isCollaborativeTemplateValid(template, user1, user2),
          )
          .toList();

      if (availableTemplates.isEmpty) {
        AppLogger.warning(
          '⚠️ Nenhum template colaborativo disponível para usuários',
        );
        return null;
      }

      final template =
          availableTemplates[_random.nextInt(availableTemplates.length)];
      final mission = _createCollaborativeMission(
        template,
        user1,
        user2,
        commonInterests,
      );

      AppLogger.info('✅ Missão colaborativa gerada: ${mission.id}');
      return mission;
    } catch (e, stackTrace) {
      AppLogger.error('❌ Erro ao gerar missão colaborativa', error: e);
      return null;
    }
  }

  /// Sugerir missão automática baseada em padrões do usuário
  static MissionModel? generateAutomaticMission(
    UserModel user,
    Map<String, dynamic> userActivity,
  ) {
    try {
      AppLogger.debug('🤖 Gerando missão automática para usuário ${user.uid}');

      // Analisar atividade do usuário para personalizar
      final suggestion = _analyzeUserActivity(user, userActivity);
      if (suggestion == null) return null;

      final mission = _createAutomaticMission(user, suggestion);

      AppLogger.info('✅ Missão automática gerada: ${mission.id}');
      return mission;
    } catch (e, stackTrace) {
      AppLogger.error('❌ Erro ao gerar missão automática', error: e);
      return null;
    }
  }

  // ================================================================================================
  // MÉTODOS AUXILIARES PRIVADOS
  // ================================================================================================

  /// Verificar se um template pode ser usado pelo usuário
  static bool _canUseTemplate(
    Map<String, dynamic> template,
    UserModel user,
    Map<String, bool> userRequirements,
    List<String> completedMissionIds,
  ) {
    // Verificar se já foi usada recentemente
    if (completedMissionIds.contains(template['id'])) {
      return false;
    }

    // Verificar requisitos
    final requirements = List<String>.from(template['requirements'] ?? []);
    for (final requirement in requirements) {
      if (userRequirements[requirement] != true) {
        return false;
      }
    }

    // Verificar se adequado para o nível do usuário
    final difficulty = template['difficulty'] as int? ?? 1;
    return _isDifficultyAppropriate(difficulty, user.level);
  }

  /// Selecionar o melhor template disponível
  static Map<String, dynamic>? _selectBestTemplate(
    List<Map<String, dynamic>> availableTemplates,
    Set<String> usedTemplates,
    UserModel user,
    List<MissionModel> existingMissions,
  ) {
    // Filtrar templates não usados
    final unusedTemplates = availableTemplates
        .where((template) => !usedTemplates.contains(template['id']))
        .toList();

    if (unusedTemplates.isEmpty) return null;

    // Priorizar variedade de categorias
    final usedCategories = existingMissions
        .map((m) => m.category.value)
        .toSet();
    final diverseTemplates = unusedTemplates
        .where((template) => !usedCategories.contains(template['category']))
        .toList();

    final candidateTemplates = diverseTemplates.isNotEmpty
        ? diverseTemplates
        : unusedTemplates;

    // Selecionar template com dificuldade apropriada
    candidateTemplates.sort((a, b) {
      final aDiff = (a['difficulty'] as int? ?? 1);
      final bDiff = (b['difficulty'] as int? ?? 1);
      final targetDiff = _getTargetDifficulty(user.level);

      return (aDiff - targetDiff).abs().compareTo((bDiff - targetDiff).abs());
    });

    return candidateTemplates.first;
  }

  /// Selecionar o melhor template semanal
  static Map<String, dynamic>? _selectBestWeeklyTemplate(
    List<Map<String, dynamic>> availableTemplates,
    Set<String> usedTemplates,
    UserModel user,
  ) {
    final unusedTemplates = availableTemplates
        .where((template) => !usedTemplates.contains(template['id']))
        .toList();

    if (unusedTemplates.isEmpty) return null;

    // Para missões semanais, priorizar dificuldade maior
    unusedTemplates.sort((a, b) {
      final aDiff = (a['difficulty'] as int? ?? 1);
      final bDiff = (b['difficulty'] as int? ?? 1);
      return bDiff.compareTo(aDiff); // Ordem decrescente
    });

    return unusedTemplates.first;
  }

  /// Criar missão a partir de template
  static MissionModel _createMissionFromTemplate(
    Map<String, dynamic> template,
    UserModel user,
    MissionType type,
  ) {
    final baseXP = template['xp'] as int? ?? 50;
    final baseCoins = template['coins'] as int? ?? 25;
    final baseGems = template['gems'] as int? ?? 0;
    final difficulty = template['difficulty'] as int? ?? 1;

    // Aplicar multiplicadores baseados no nível do usuário
    final finalXP = _applyLevelMultiplier(baseXP, user.level);
    final finalCoins = _applyLevelMultiplier(baseCoins, user.level);

    // Calcular tempo de expiração
    final expiresAt = type == MissionType.daily
        ? _getNextDailyReset()
        : _getNextWeeklyReset();

    return MissionModel(
      id: '${template['id']}_${user.uid}_${DateTime.now().millisecondsSinceEpoch}',
      title: template['title'] as String,
      description: template['description'] as String,
      type: type,
      category: MissionCategory.fromString(
        template['category'] as String? ?? 'social',
      ),
      xpReward: finalXP,
      coinsReward: finalCoins,
      gemsReward: baseGems,
      targetValue: template['target'] as int? ?? 1,
      difficulty: difficulty,
      createdAt: DateTime.now(),
      expiresAt: expiresAt,
      requirements: List<String>.from(template['requirements'] ?? []),
      isActive: true,
      metadata: {
        'templateId': template['id'],
        'generatedFor': user.uid,
        'userLevel': user.level,
      },
    );
  }

  /// Criar missão colaborativa
  static MissionModel _createCollaborativeMission(
    Map<String, dynamic> template,
    UserModel user1,
    UserModel user2,
    List<String> commonInterests,
  ) {
    final baseXP = template['xp'] as int? ?? 200;
    final baseCoins = template['coins'] as int? ?? 100;
    final baseGems = template['gems'] as int? ?? 5;

    // Personalizar descrição com interesses comuns
    String description = template['description'] as String;
    if (commonInterests.isNotEmpty) {
      final interest = commonInterests[_random.nextInt(commonInterests.length)];
      description = description.replaceAll('[interesse]', interest);
    }

    return MissionModel(
      id: 'collab_${template['id']}_${DateTime.now().millisecondsSinceEpoch}',
      title: template['title'] as String,
      description: description,
      type: MissionType.collaborative,
      category: MissionCategory.fromString(
        template['category'] as String? ?? 'social',
      ),
      xpReward: baseXP,
      coinsReward: baseCoins,
      gemsReward: baseGems,
      targetValue: template['target'] as int? ?? 1,
      difficulty: template['difficulty'] as int? ?? 3,
      createdAt: DateTime.now(),
      expiresAt: DateTime.now().add(
        Duration(minutes: MissionConstants.collaborativeMissionTimeoutMinutes),
      ),
      participantsRequired: template['participants'] as int? ?? 2,
      metadata: {
        'templateId': template['id'],
        'participants': [user1.uid, user2.uid],
        'commonInterests': commonInterests,
      },
    );
  }

  /// Gerar missões de fallback quando templates falham
  static List<MissionModel> _generateFallbackDailyMissions(UserModel user) {
    return [
      _generateBasicDailyMission(user, 0),
      _generateBasicDailyMission(user, 1),
      _generateBasicDailyMission(user, 2),
    ];
  }

  static List<MissionModel> _generateFallbackWeeklyMissions(UserModel user) {
    return [
      _generateBasicWeeklyMission(user, 0),
      _generateBasicWeeklyMission(user, 1),
    ];
  }

  /// Gerar missão diária básica
  static MissionModel _generateBasicDailyMission(UserModel user, int index) {
    final basicMissions = [
      {
        'title': 'Explorar perfis',
        'description': 'Visualize 3 perfis de outros usuários',
        'category': 'exploration',
        'target': 3,
        'xp': 30,
        'coins': 15,
      },
      {
        'title': 'Fazer login',
        'description': 'Mantenha sua sequência de login ativa',
        'category': 'gamification',
        'target': 1,
        'xp': 25,
        'coins': 10,
      },
      {
        'title': 'Atualizar perfil',
        'description': 'Adicione mais informações ao seu perfil',
        'category': 'profile',
        'target': 1,
        'xp': 40,
        'coins': 20,
      },
    ];

    final template = basicMissions[index % basicMissions.length];
    return _createMissionFromTemplate(template, user, MissionType.daily);
  }

  /// Gerar missão semanal básica
  static MissionModel _generateBasicWeeklyMission(UserModel user, int index) {
    final basicMissions = [
      {
        'title': 'Mestre semanal',
        'description': 'Complete 5 missões diárias esta semana',
        'category': 'gamification',
        'target': 5,
        'xp': 200,
        'coins': 100,
        'gems': 5,
      },
      {
        'title': 'Explorador ativo',
        'description': 'Visualize 20 perfis esta semana',
        'category': 'exploration',
        'target': 20,
        'xp': 150,
        'coins': 75,
        'gems': 3,
      },
    ];

    final template = basicMissions[index % basicMissions.length];
    return _createMissionFromTemplate(template, user, MissionType.weekly);
  }

  // ================================================================================================
  // MÉTODOS UTILITÁRIOS
  // ================================================================================================

  static List<String> _findCommonInterests(UserModel user1, UserModel user2) {
    return user1.interesses
        .where((interest) => user2.interesses.contains(interest))
        .toList();
  }

  static bool _isCollaborativeTemplateValid(
    Map<String, dynamic> template,
    UserModel user1,
    UserModel user2,
  ) {
    // Verificar se ambos usuários atendem requisitos
    final requirements = List<String>.from(template['requirements'] ?? []);
    // Implementar lógica específica de validação colaborativa
    return true; // Simplificado por ora
  }

  static bool _isDifficultyAppropriate(int difficulty, int userLevel) {
    final targetDiff = _getTargetDifficulty(userLevel);
    return (difficulty - targetDiff).abs() <= 1;
  }

  static int _getTargetDifficulty(int userLevel) {
    if (userLevel < 5) return 1;
    if (userLevel < 10) return 2;
    if (userLevel < 20) return 3;
    if (userLevel < 35) return 4;
    return 5;
  }

  static int _applyLevelMultiplier(int baseValue, int userLevel) {
    final multiplier = 1.0 + (userLevel * 0.05); // 5% por nível
    return (baseValue * multiplier).round();
  }

  static DateTime _getNextDailyReset() {
    final now = DateTime.now();
    final nextReset = DateTime(now.year, now.month, now.day + 1);
    return nextReset;
  }

  static DateTime _getNextWeeklyReset() {
    final now = DateTime.now();
    final daysUntilMonday = (8 - now.weekday) % 7;
    final nextMonday = now.add(Duration(days: daysUntilMonday));
    return DateTime(nextMonday.year, nextMonday.month, nextMonday.day);
  }

  static Map<String, dynamic>? _analyzeUserActivity(
    UserModel user,
    Map<String, dynamic> activity,
  ) {
    // Implementar análise de atividade para sugestões automáticas
    // Por ora, retorna null (funcionalidade futura)
    return null;
  }

  static MissionModel _createAutomaticMission(
    UserModel user,
    Map<String, dynamic> suggestion,
  ) {
    // Implementar criação de missão automática
    // Por ora, gera missão básica
    return _generateBasicDailyMission(user, 0);
  }
}
