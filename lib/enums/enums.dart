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
