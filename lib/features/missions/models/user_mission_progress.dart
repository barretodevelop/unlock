// lib/features/missions/models/user_mission_progress.dart

/// Rastreia o progresso de um usuário em uma missão específica.
/// userId: ID do usuário.
/// missionId: ID da missão à qual este progresso se refere.
/// currentProgress: O progresso atual do usuário para o critério da missão.
/// isCompleted: Indica se a missão foi concluída pelo usuário.
/// isClaimed: Indica se as recompensas da missão já foram resgatadas pelo usuário.
/// lastUpdateDate: Data da última atualização, útil para missões diárias/semanais para controlar resets.
class UserMissionProgress {
  final String userId;
  final String missionId;
  int currentProgress;
  bool isCompleted;
  bool isClaimed;
  DateTime? lastUpdateDate;

  /// Construtor para criar uma instância de UserMissionProgress.
  UserMissionProgress({
    required this.userId,
    required this.missionId,
    this.currentProgress = 0,
    this.isCompleted = false,
    this.isClaimed = false,
    this.lastUpdateDate,
  });

  /// Converte a instância de UserMissionProgress para um mapa JSON.
  /// Útil para serialização para o backend ou armazenamento local.
  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'missionId': missionId,
      'currentProgress': currentProgress,
      'isCompleted': isCompleted,
      'isClaimed': isClaimed,
      'lastUpdateDate': lastUpdateDate
          ?.toIso8601String(), // Converte DateTime para String ISO 8601
    };
  }

  /// Factory para criar uma instância de UserMissionProgress a partir de um mapa JSON.
  /// Útil para desserialização de dados do backend ou armazenamento local.
  factory UserMissionProgress.fromJson(Map<String, dynamic> json) {
    return UserMissionProgress(
      userId: json['userId'],
      missionId: json['missionId'],
      currentProgress: json['currentProgress'] ?? 0,
      isCompleted: json['isCompleted'] ?? false,
      isClaimed: json['isClaimed'] ?? false,
      // Converte a string ISO 8601 de volta para DateTime, se presente.
      lastUpdateDate: json['lastUpdateDate'] != null
          ? DateTime.parse(json['lastUpdateDate'])
          : null,
    );
  }
}
