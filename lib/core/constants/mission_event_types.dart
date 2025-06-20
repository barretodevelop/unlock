// lib/core/constants/mission_event_types.dart

/// Define os tipos de eventos que podem acionar o progresso das missões.
/// Usar constantes ajuda a evitar erros de digitação e centraliza os eventos.
class MissionEventTypes {
  static const String LOGIN_DAILY = 'LOGIN_DAILY';
  static const String LIKE_PROFILE = 'LIKE_PROFILE';
  static const String CREATE_POST = 'CREATE_POST';
  static const String TUTORIAL_COMPLETED = 'TUTORIAL_COMPLETED';

  // Novos Eventos Sugeridos
  static const String SEND_MESSAGE = 'SEND_MESSAGE';
  static const String COMMENT_POST = 'COMMENT_POST';
  static const String VIEW_PROFILE_UNIQUE_TODAY =
      'VIEW_PROFILE_UNIQUE_TODAY'; // Para "Visite X perfis ÚNICOS hoje"
  static const String PROFILE_FIELD_UPDATED =
      'PROFILE_FIELD_UPDATED'; // Ex: preencher "Sobre mim"
  static const String ADD_INTEREST = 'ADD_INTEREST';
  static const String LEVEL_UP = 'LEVEL_UP';
  static const String DAILY_MISSION_CLAIMED =
      'DAILY_MISSION_CLAIMED'; // Para meta-missões
  static const String POST_RECEIVES_LIKE = 'POST_RECEIVES_LIKE'; // Novo evento
  static const String NEW_CONNECTION_ACCEPTED = 'NEW_CONNECTION_ACCEPTED';
}
