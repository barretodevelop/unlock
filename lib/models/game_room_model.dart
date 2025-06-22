import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

enum GameStatus {
  pending, // Convite enviado, aguardando aceite
  active, // Jogo em andamento
  finished, // Jogo finalizado, conexão formada
  declined, // Convite recusado
  expired, // Convite expirado
  abandoned, // Um dos jogadores abandonou
}

class GameRoomModel {
  final String id;
  final List<String> playerIds; // [convidado, convidante]
  final GameStatus status;
  final String? currentTurnPlayerId;
  final Map<String, double> progress; // { 'playerId': 0.35 }
  final List<Map<String, dynamic>> questions;
  final Map<String, Map<String, dynamic>>
  answers; // { 'questionId': { 'playerId': 'answer' } }
  final DateTime createdAt;
  final DateTime? updatedAt;

  const GameRoomModel({
    required this.id,
    required this.playerIds,
    required this.status,
    this.currentTurnPlayerId,
    required this.progress,
    this.questions = const [],
    this.answers = const {},
    required this.createdAt,
    this.updatedAt,
  });

  factory GameRoomModel.fromJson(String id, Map<String, dynamic> json) {
    return GameRoomModel(
      id: id,
      playerIds: List<String>.from(json['playerIds'] ?? []),
      status: GameStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => GameStatus.pending,
      ),
      currentTurnPlayerId: json['currentTurnPlayerId'],
      progress: Map<String, double>.from(json['progress'] ?? {}),
      questions: List<Map<String, dynamic>>.from(json['questions'] ?? []),
      answers: Map<String, Map<String, dynamic>>.from(json['answers'] ?? {}),
      createdAt: (json['createdAt'] as Timestamp).toDate(),
      updatedAt: (json['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'playerIds': playerIds,
      'status': status.name,
      'currentTurnPlayerId': currentTurnPlayerId,
      'progress': progress,
      'questions': questions,
      'answers': answers,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  GameRoomModel copyWith({
    String? id,
    List<String>? playerIds,
    GameStatus? status,
    String? currentTurnPlayerId,
    Map<String, double>? progress,
    List<Map<String, dynamic>>? questions,
    Map<String, Map<String, dynamic>>? answers,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return GameRoomModel(
      id: id ?? this.id,
      playerIds: playerIds ?? this.playerIds,
      status: status ?? this.status,
      currentTurnPlayerId: currentTurnPlayerId ?? this.currentTurnPlayerId,
      progress: progress ?? this.progress,
      questions: questions ?? this.questions,
      answers: answers ?? this.answers,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is GameRoomModel &&
        other.id == id &&
        listEquals(other.playerIds, playerIds) &&
        other.status == status;
  }

  @override
  int get hashCode => id.hashCode ^ playerIds.hashCode ^ status.hashCode;
}
