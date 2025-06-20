// lib/core/constants/mission_constants.dart
// Constantes para sistema de missões - Fase 3

/// Configurações globais do sistema de missões
class MissionConstants {
  // ================================================================================================
  // LIMITES E QUANTIDADES
  // ================================================================================================

  /// Número de missões diárias geradas por usuário
  static const int dailyMissionsCount = 3;

  /// Número de missões semanais geradas por usuário
  static const int weeklyMissionsCount = 2;

  /// Tempo em horas para reset das missões diárias (00:00)
  static const int dailyResetHour = 0;

  /// Dia da semana para reset das missões semanais (1 = Segunda-feira)
  static const int weeklyResetDay = 1;

  /// Máximo de missões colaborativas simultâneas
  static const int maxCollaborativeMissions = 1;

  /// Tempo limite em minutos para completar missão colaborativa
  static const int collaborativeMissionTimeoutMinutes = 30;

  // ================================================================================================
  // RECOMPENSAS POR TIPO DE MISSÃO
  // ================================================================================================

  /// Recompensas base para missões diárias
  static const Map<String, int> dailyRewards = {
    'xp_min': 20, // Ajustado para exemplos
    'xp_max': 50, // Ajustado para exemplos
    'coins_min': 10, // Ajustado para exemplos
    'coins_max': 30, // Ajustado para exemplos
    'gems': 0, // Missões diárias não dão gems
  };

  /// Recompensas base para missões semanais
  static const Map<String, int> weeklyRewards = {
    'xp_min': 150,
    'xp_max': 500,
    'coins_min': 75,
    'coins_max': 250,
    'gems_min': 5,
    'gems_max': 15,
  };

  /// Recompensas base para missões colaborativas
  static const Map<String, int> collaborativeRewards = {
    'xp_min': 200,
    'xp_max': 400,
    'coins_min': 100,
    'coins_max': 200,
    'gems_min': 2,
    'gems_max': 8,
  };

  // ================================================================================================
  // TIPOS DE MISSÃO
  // ================================================================================================

  /// Tipos disponíveis de missão
  static const List<String> missionTypes = [
    'daily',
    'weekly',
    'collaborative',
    'automatic',
    'special',
  ];

  /// Categorias de missão
  static const List<String> missionCategories = [
    'social', // Relacionadas a conexões
    'profile', // Personalização de perfil
    'exploration', // Descobrir novos usuários
    'gamification', // Ganhar XP, completar challenges
  ];

  // ================================================================================================
  // TEMPLATES DE MISSÕES DIÁRIAS
  // ================================================================================================

  /// Templates para geração automática de missões diárias
  /// - `id_template`: Usado como base para gerar o ID da instância da missão.
  /// - `title`: Título da missão.
  /// - `description_template`: Template da descrição, pode usar `{targetCount}`.
  /// - `category`: Categoria da missão.
  /// - `eventType`: O tipo de evento que aciona o progresso (de MissionEventTypes).
  /// - `targetCountRange`: [min, max] para randomizar o `targetCount`. Se apenas um valor, usar [X, X].
  /// - `reward`: Mapa com `xp`, `coins`, `gems`.
  /// - `difficulty`: Nível de dificuldade.
  /// - `requirements`: (Opcional) Condições para a missão aparecer.
  static const List<Map<String, dynamic>> dailyMissionTemplates = [
    {
      'id_template':
          'daily_login_template', // Já existe uma missão de login no MissionRepository
      'title': 'Check-in Diário',
      'description_template': 'Faça login hoje para sua recompensa diária!',
      'category': 'gamification',
      'eventType': 'LOGIN_DAILY', // Usar MissionEventTypes.LOGIN_DAILY
      'targetCountRange': [1, 1],
      'reward': {'xp': 20, 'coins': 50, 'gems': 0},
      'difficulty': 1,
      'requirements': [],
    },
    {
      'id_template': 'view_profiles_daily',
      'title': 'Explorador Diário',
      'description_template': 'Visualize {targetCount} perfis diferentes hoje.',
      'category': 'exploration',
      'eventType':
          'VIEW_PROFILE_UNIQUE_TODAY', // Usar MissionEventTypes.VIEW_PROFILE_UNIQUE_TODAY
      'targetCountRange': [3, 5],
      'reward': {'xp': 30, 'coins': 15, 'gems': 0},
      'difficulty': 1,
      'requirements': [],
    },
    {
      'id_template': 'send_messages_daily',
      'title': 'Papo em Dia',
      'description_template':
          'Envie mensagens para {targetCount} conexões hoje.',
      'category': 'social',
      'eventType': 'SEND_MESSAGE', // Usar MissionEventTypes.SEND_MESSAGE
      'targetCountRange': [2, 3],
      'reward': {'xp': 40, 'coins': 20, 'gems': 0},
      'difficulty': 2,
      'requirements': [
        // Estrutura de requisitos atualizada
        {'type': 'level', 'value': 3}, // Requer nível 3 ou superior
        {'type': 'connections', 'value': 1}, // Requer pelo menos 1 conexão
      ],
    },
    {
      'id_template': 'comment_posts_daily',
      'title': 'Interaja na Comunidade',
      'description_template': 'Comente em {targetCount} posts hoje.',
      'category': 'social',
      'eventType': 'COMMENT_POST', // Usar MissionEventTypes.COMMENT_POST
      'targetCountRange': [2, 4],
      'reward': {'xp': 35, 'coins': 20, 'gems': 0},
      'difficulty': 2,
      'requirements': [],
    },
    {
      'id_template': 'like_profiles_daily',
      'title': 'Distribua Likes',
      'description_template': 'Curta {targetCount} perfis hoje.',
      'category': 'social',
      'eventType': 'LIKE_PROFILE', // Usar MissionEventTypes.LIKE_PROFILE
      'targetCountRange': [5, 10],
      'reward': {'xp': 25, 'coins': 10, 'gems': 0},
      'difficulty': 1,
      'requirements': [],
    },
  ];

  // ================================================================================================
  // TEMPLATES DE MISSÕES "ONE_TIME" (Exemplos adicionais)
  // Estas podem ser adicionadas diretamente ao MissionRepository ou carregadas de forma similar
  // ================================================================================================
  static const List<Map<String, dynamic>> oneTimeMissionTemplates = [
    {
      'id': 'onetime_complete_profile_about', // ID único da missão
      'title': 'Conte-nos Sobre Você',
      'description_template': 'Preencha o campo "Sobre mim" do seu perfil.',
      'category': 'profile',
      'eventType':
          'PROFILE_FIELD_UPDATED', // Usar MissionEventTypes.PROFILE_FIELD_UPDATED
      // Para 'PROFILE_FIELD_UPDATED', o 'details' do evento pode conter o nome do campo.
      // A lógica de validação no MissionsNotifier precisaria checar details['fieldName'] == 'about_me'.
      // Por simplicidade mockada, o targetCount é 1.
      'targetCountRange': [1, 1],
      'reward': {'xp': 50, 'coins': 25, 'gems': 0},
      'difficulty': 1,
      'requirements': [
        // Exemplo de requisito
        // {'type': 'profile_field_empty', 'value': 'about_me'} // Exemplo: se o campo "sobre mim" estiver vazio
      ],
    },
    {
      'id': 'onetime_first_connection',
      'title': 'Primeira Conexão!',
      'description_template': 'Faça sua primeira conexão com outro usuário.',
      'category': 'social',
      'eventType':
          'NEW_CONNECTION_ACCEPTED', // Usar MissionEventTypes.NEW_CONNECTION_ACCEPTED
      'targetCountRange': [1, 1],
      'reward': {'xp': 100, 'coins': 50, 'gems': 5},
      'difficulty': 2,
      'requirements': [],
    },
    {
      'id': 'onetime_add_interests',
      'title': 'Mostre Seus Interesses',
      'description_template':
          'Adicione pelo menos {targetCount} interesses ao seu perfil.',
      'category': 'gamification',
      'eventType': 'ADD_INTEREST', // Usar MissionEventTypes.ADD_INTEREST
      'targetCountRange': [3, 3],
      'reward': {'xp': 60, 'coins': 30, 'gems': 0},
      'difficulty': 2,
      'requirements': [],
    },
    {
      'id': 'onetime_reach_level_5',
      'title': 'Nível 5 Alcançado!',
      'description_template': 'Parabéns por alcançar o nível 5.',
      'category': 'gamification',
      'eventType': 'LEVEL_UP', // Usar MissionEventTypes.LEVEL_UP
      // A lógica de validação no MissionsNotifier precisaria checar details['newLevel'] == 5.
      'targetCountRange': [5, 5], // O target aqui seria o nível.
      'reward': {'xp': 150, 'coins': 75, 'gems': 10},
      'difficulty': 2,
      'requirements': [],
    },
    {
      'id':
          'onetime_tutorial_completed', // Já existe uma missão de tutorial no MissionRepository
      'title': 'Tutorial Concluído',
      'description_template':
          'Você completou o tutorial e está pronto para começar!',
      'category': 'gamification',
      'eventType':
          'TUTORIAL_COMPLETED', // Usar MissionEventTypes.TUTORIAL_COMPLETED
      'targetCountRange': [1, 1],
      'reward': {'xp': 80, 'coins': 150, 'gems': 10},
      'difficulty': 1,
      'requirements': [],
    },
  ];

  // ================================================================================================
  // TEMPLATES DE MISSÕES SEMANAIS
  // ================================================================================================
  /// Templates para geração automática de missões semanais
  static const List<Map<String, dynamic>> weeklyMissionTemplates = [
    {
      'id_template': 'weekly_complete_daily_missions',
      'title': 'Mestre das missões',
      'description_template':
          'Complete {targetCount} missões diárias esta semana.',
      'category': 'gamification',
      'eventType':
          'DAILY_MISSION_CLAIMED', // Usar MissionEventTypes.DAILY_MISSION_CLAIMED
      'targetCountRange': [3, 5],
      'reward': {'xp': 200, 'coins': 100, 'gems': 5},
      'difficulty': 3,
      'requirements': [],
    },
    {
      'id_template': 'weekly_make_connections',
      'title': 'Conecte-se',
      'description_template': 'Faça {targetCount} novas conexões esta semana.',
      'category': 'social',
      'eventType':
          'NEW_CONNECTION_ACCEPTED', // Usar MissionEventTypes.NEW_CONNECTION_ACCEPTED
      'targetCountRange': [2, 3],
      'reward': {'xp': 250, 'coins': 120, 'gems': 10}, // Ajustado
      'difficulty': 4,
      'requirements': [],
    },
    {
      'id_template': 'weekly_win_minigames',
      'title': 'Jogador expert',
      'description_template': 'Vença {targetCount} minijogos de conexão.',
      'category': 'social',
      'eventType': 'MINIGAME_WON', // Exemplo de novo eventType
      'targetCountRange': [1, 2],
      'reward': {'xp': 300, 'coins': 150, 'gems': 8},
      'difficulty': 4,
      'requirements': [
        // Exemplo de requisito
        {
          'type': 'level',
          'value': 10,
        }, // Requer nível 10 para desbloquear minijogos
      ],
    },
    {
      'id_template': 'weekly_customize_profile',
      'title': 'Personalização única',
      'description_template':
          'Compre e aplique {targetCount} itens de personalização.',
      'category': 'profile',
      'eventType': 'ITEM_PURCHASED_AND_APPLIED', // Exemplo de novo eventType
      'targetCountRange': [1, 3],
      'reward': {'xp': 150, 'coins': 75, 'gems': 5},
      'difficulty': 3,
      'requirements': [
        // Exemplo de requisito
        {
          'type': 'feature_unlocked',
          'value': 'shop',
        }, // Requer que a loja esteja desbloqueada
      ],
    },
    {
      'id_template': 'weekly_post_engagement',
      'title': 'Engajador da Semana',
      'description_template':
          'Receba {targetCount} likes em seus posts esta semana.',
      'category': 'social',
      'eventType': 'POST_RECEIVES_LIKE', // Novo eventType a ser criado
      'targetCountRange': [10, 20],
      'reward': {'xp': 220, 'coins': 110, 'gems': 7},
      'difficulty': 3,
      'requirements': [
        {'type': 'level', 'value': 5},
      ],
    },
  ];

  // ================================================================================================
  // TEMPLATES DE MISSÕES COLABORATIVAS
  // ================================================================================================

  /// Templates para missões em dupla/grupo
  static const List<Map<String, dynamic>> collaborativeMissionTemplates = [
    {
      'id': 'duo_minigame',
      'title': 'Dupla dinâmica',
      'description': 'Complete um minijogo em dupla com sucesso',
      'category': 'social',
      'target': 1,
      'xp': 300,
      'coins': 150,
      'gems': 5,
      'difficulty': 3,
      'participants': 2,
      'requirements': ['has_active_connection'],
    },
    {
      'id': 'compatibility_test',
      'title': 'Teste de compatibilidade',
      'description': 'Complete um teste de compatibilidade em dupla',
      'category': 'social',
      'target': 1,
      'xp': 200,
      'coins': 100,
      'gems': 3,
      'difficulty': 2,
      'participants': 2,
      'requirements': ['has_active_connection'],
    },
    {
      'id': 'group_challenge',
      'title': 'Desafio em grupo',
      'description': 'Participe de um desafio com 4 jogadores',
      'category': 'social',
      'target': 1,
      'xp': 400,
      'coins': 200,
      'gems': 8,
      'difficulty': 5,
      'participants': 4,
      'requirements': ['has_multiple_connections'],
    },
  ];

  // ================================================================================================
  // CONFIGURAÇÕES DE DIFICULDADE
  // ================================================================================================

  /// Multiplicadores de recompensa por dificuldade (1-5)
  static const Map<int, double> difficultyMultipliers = {
    1: 1.0, // Fácil
    2: 1.2, // Normal
    3: 1.5, // Médio
    4: 1.8, // Difícil
    5: 2.0, // Expert
  };

  /// Cores associadas a cada dificuldade
  static const Map<int, int> difficultyColors = {
    1: 0xFF4CAF50, // Verde
    2: 0xFF2196F3, // Azul
    3: 0xFFFF9800, // Laranja
    4: 0xFFE91E63, // Rosa
    5: 0xFF9C27B0, // Roxo
  };

  // ================================================================================================
  // CONFIGURAÇÕES AUTOMÁTICAS
  // ================================================================================================

  /// Intervalo em minutos para verificar missões automáticas
  static const int autoMissionCheckIntervalMinutes = 15;

  /// Máximo de missões automáticas por usuário
  static const int maxAutoMissionsPerUser = 1;

  /// Probabilidade (0-100) de gerar missão automática
  static const int autoMissionGenerationChance = 25;

  // ================================================================================================
  // MÉTODOS UTILITÁRIOS
  // ================================================================================================

  /// Verificar se é hora de reset das missões diárias
  static bool isDailyResetTime(DateTime now) {
    return now.hour == dailyResetHour && now.minute == 0;
  }

  /// Verificar se é dia de reset das missões semanais
  static bool isWeeklyResetDay(DateTime now) {
    return now.weekday == weeklyResetDay && isDailyResetTime(now);
  }

  /// Obter multiplicador de recompensa por dificuldade
  static double getRewardMultiplier(int difficulty) {
    return difficultyMultipliers[difficulty] ?? 1.0;
  }

  /// Obter cor por dificuldade
  static int getDifficultyColor(int difficulty) {
    return difficultyColors[difficulty] ?? 0xFF757575;
  }

  /// Calcular recompensa final com multiplicador
  static int calculateFinalReward(int baseReward, int difficulty) {
    return (baseReward * getRewardMultiplier(difficulty)).round();
  }
}
