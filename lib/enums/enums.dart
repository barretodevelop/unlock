// =============================================
// 1. TIPOS DE ERRO E ESTADOS - NOVO
// =============================================
enum AuthErrorType {
  networkError,
  serverError,
  userCancelled,
  invalidCredentials,
  accountDisabled,
  tooManyRequests,
  unknown,
  backgroundServiceError,
  userDataError,
  authenticationFailed,
}

enum AppInitializationState { notStarted, initializing, ready, error }

enum MatchStatus { pending, testing, unlocked, declined, expired }

enum TestType { interests, personality, lifestyle, values1, quickFire }

enum AffinityQuestionType { multipleChoice, scale, yesNo, ranking, openText }

enum AffinityQuestionCategory {
  lifestyle,
  values1,
  interests,
  goals,
  personality,
  relationship,
  communication,
  future,
}
