import 'package:unlock/feature/games/social/providers/enums/enums.dart';

class AuthError {
  final AuthErrorType type;
  final String message;
  final String? technicalDetails;
  final DateTime timestamp;
  final bool canRetry;

  AuthError({
    required this.type,
    required this.message,
    this.technicalDetails,
    DateTime? timestamp,
    this.canRetry = false,
  }) : timestamp = timestamp ?? DateTime.now();

  @override
  String toString() => message;

  // Factory methods para erros comuns
  factory AuthError.network([String? details]) => AuthError(
    type: AuthErrorType.networkError,
    message: 'Sem conexão com a internet',
    technicalDetails: details,
    canRetry: true,
  );

  factory AuthError.authFailed([String? details]) => AuthError(
    type: AuthErrorType.authenticationFailed,
    message: 'Falha na autenticação',
    technicalDetails: details,
    canRetry: true,
  );

  factory AuthError.userData([String? details]) => AuthError(
    type: AuthErrorType.userDataError,
    message: 'Erro ao carregar dados do usuário',
    technicalDetails: details,
    canRetry: true,
  );

  factory AuthError.backgroundService([String? details]) => AuthError(
    type: AuthErrorType.backgroundServiceError,
    message: 'Erro no serviço em segundo plano',
    technicalDetails: details,
    canRetry: false,
  );

  factory AuthError.unknown([String? details]) => AuthError(
    type: AuthErrorType.unknown,
    message: 'Erro inesperado',
    technicalDetails: details,
    canRetry: true,
  );
}

class AppError {
  final AuthErrorType type;
  final String message;
  final String? technicalDetails;
  final DateTime timestamp;
  final bool isRetryable;

  AppError({
    required this.type,
    required this.message,
    this.technicalDetails,
    DateTime? timestamp,
    this.isRetryable = true,
  }) : timestamp = timestamp ?? DateTime.now();

  factory AppError.fromException(dynamic exception) {
    if (exception.toString().contains('network')) {
      return AppError(
        type: AuthErrorType.networkError,
        message: 'Erro de conexão. Verifique sua internet.',
        technicalDetails: exception.toString(),
        isRetryable: true,
      );
    } else if (exception.toString().contains('user-disabled')) {
      return AppError(
        type: AuthErrorType.accountDisabled,
        message: 'Conta desabilitada. Entre em contato com o suporte.',
        technicalDetails: exception.toString(),
        isRetryable: false,
      );
    } else if (exception.toString().contains('too-many-requests')) {
      return AppError(
        type: AuthErrorType.tooManyRequests,
        message: 'Muitas tentativas. Tente novamente em alguns minutos.',
        technicalDetails: exception.toString(),
        isRetryable: true,
      );
    }

    return AppError(
      type: AuthErrorType.unknown,
      message: 'Erro inesperado. Tente novamente.',
      technicalDetails: exception.toString(),
      isRetryable: true,
    );
  }
}
