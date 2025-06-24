// lib/providers/streak_provider.dart
import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:unlock/core/utils/logger.dart';
import 'package:unlock/models/currency_model.dart';
import 'package:unlock/providers/auth_provider.dart';
import 'package:unlock/providers/currency_provider.dart';
import 'package:unlock/services/firestore_service.dart';

/// Provider para gerenciar streaks de login
final streakProvider = StateNotifierProvider<StreakNotifier, StreakState>((
  ref,
) {
  final authState = ref.watch(authProvider);
  final firestoreService = ref.watch(firestoreServiceProvider);

  return StreakNotifier(
    firestoreService: firestoreService,
    userId: authState.user?.uid,
    ref: ref,
  );
});

/// Provider computado para verificar se o streak foi quebrado hoje
final streakBrokenTodayProvider = Provider<bool>((ref) {
  final streakState = ref.watch(streakProvider);
  final today = DateTime.now();

  if (streakState.lastLoginDate == null) return false;

  final daysSinceLastLogin = today
      .difference(streakState.lastLoginDate!)
      .inDays;
  return daysSinceLastLogin > 1; // Streak quebra se passou mais de 1 dia
});

/// Provider para calcular o próximo milestone de streak
final nextStreakMilestoneProvider = Provider<StreakMilestone?>((ref) {
  final streakState = ref.watch(streakProvider);
  return StreakMilestone.getNextMilestone(streakState.currentStreak);
});

/// Estado do sistema de streaks
class StreakState {
  final int currentStreak;
  final int longestStreak;
  final DateTime? lastLoginDate;
  final bool isLoading;
  final String? error;
  final Map<String, DateTime> streakHistory; // Data -> streak naquele dia
  final bool hasClaimedTodaysReward;

  const StreakState({
    this.currentStreak = 0,
    this.longestStreak = 0,
    this.lastLoginDate,
    this.isLoading = false,
    this.error,
    this.streakHistory = const {},
    this.hasClaimedTodaysReward = false,
  });

  StreakState copyWith({
    int? currentStreak,
    int? longestStreak,
    DateTime? lastLoginDate,
    bool? isLoading,
    String? error,
    Map<String, DateTime>? streakHistory,
    bool? hasClaimedTodaysReward,
  }) {
    return StreakState(
      currentStreak: currentStreak ?? this.currentStreak,
      longestStreak: longestStreak ?? this.longestStreak,
      lastLoginDate: lastLoginDate ?? this.lastLoginDate,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      streakHistory: streakHistory ?? this.streakHistory,
      hasClaimedTodaysReward:
          hasClaimedTodaysReward ?? this.hasClaimedTodaysReward,
    );
  }

  /// Verifica se o usuário logou hoje
  bool get hasLoggedInToday {
    if (lastLoginDate == null) return false;
    final today = DateTime.now();
    final loginDate = lastLoginDate!;

    return today.year == loginDate.year &&
        today.month == loginDate.month &&
        today.day == loginDate.day;
  }

  /// Verifica se o streak está ativo (não foi quebrado)
  bool get isStreakActive {
    if (lastLoginDate == null) return false;
    final today = DateTime.now();
    final daysSinceLastLogin = today.difference(lastLoginDate!).inDays;
    return daysSinceLastLogin <= 1;
  }

  /// Calcula quantos dias até o próximo milestone
  int get daysToNextMilestone {
    final nextMilestone = StreakMilestone.getNextMilestone(currentStreak);
    return nextMilestone?.days != null
        ? nextMilestone!.days - currentStreak
        : 0;
  }

  @override
  String toString() {
    return 'StreakState(current: $currentStreak, longest: $longestStreak, '
        'lastLogin: $lastLoginDate, isActive: $isStreakActive, '
        'loggedToday: $hasLoggedInToday)';
  }
}

/// Notifier para gerenciar streaks de login
class StreakNotifier extends StateNotifier<StreakState> {
  final FirestoreService _firestoreService;
  final String? _userId;
  final Ref _ref;
  Timer? _midnightTimer;

  StreakNotifier({
    required FirestoreService firestoreService,
    required String? userId,
    required Ref ref,
  }) : _firestoreService = firestoreService,
       _userId = userId,
       _ref = ref,
       super(const StreakState()) {
    if (_userId != null) {
      _initializeStreak();
      _scheduleMidnightReset();
    }
  }

  @override
  void dispose() {
    _midnightTimer?.cancel();
    super.dispose();
  }

  /// Inicializa o streak do usuário
  Future<void> _initializeStreak() async {
    if (_userId == null) return;

    try {
      state = state.copyWith(isLoading: true);

      final user = await _firestoreService.getUser(_userId!);
      if (user != null) {
        state = state.copyWith(
          currentStreak: user.loginStreak ?? 0,
          lastLoginDate: user.lastLoginDate,
          isLoading: false,
        );

        // Carrega histórico de streaks
        await _loadStreakHistory();

        AppLogger.info(
          '🔥 Streak initialized',
          data: {
            'userId': _userId,
            'currentStreak': state.currentStreak,
            'lastLogin': state.lastLoginDate?.toIso8601String(),
          },
        );
      }
    } catch (e, stackTrace) {
      AppLogger.error(
        '❌ Failed to initialize streak',
        error: e,
        stackTrace: stackTrace,
      );
      state = state.copyWith(
        isLoading: false,
        error: 'Erro ao carregar streak',
      );
    }
  }

  /// Carrega histórico de streaks do Firestore
  Future<void> _loadStreakHistory() async {
    try {
      // Implementar busca do histórico de streaks
      // Por enquanto, mantém vazio - pode ser implementado posteriormente
      final history = <String, DateTime>{};
      state = state.copyWith(streakHistory: history);
    } catch (e) {
      AppLogger.warning('⚠️ Failed to load streak history', error: e);
    }
  }

  /// Processa login diário e atualiza streak
  Future<void> processLogin() async {
    if (_userId == null) return;

    try {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      // Verifica se já logou hoje
      if (state.hasLoggedInToday) {
        AppLogger.debug('✅ User already logged in today');
        return;
      }

      int newStreak = 1;
      bool streakContinued = false;

      // Calcula novo streak
      if (state.lastLoginDate != null) {
        final lastLoginDay = DateTime(
          state.lastLoginDate!.year,
          state.lastLoginDate!.month,
          state.lastLoginDate!.day,
        );

        final daysSinceLastLogin = today.difference(lastLoginDay).inDays;

        if (daysSinceLastLogin == 1) {
          // Continuou o streak
          newStreak = state.currentStreak + 1;
          streakContinued = true;
        } else if (daysSinceLastLogin > 1) {
          // Streak foi quebrado
          newStreak = 1;
          AppLogger.info(
            '💔 Streak broken',
            data: {
              'previousStreak': state.currentStreak,
              'daysSinceLastLogin': daysSinceLastLogin,
            },
          );
        }
      }

      // Atualiza no Firestore
      await _firestoreService.updateUser(_userId!, {
        'loginStreak': newStreak,
        'lastLoginDate': now,
        'longestStreak': newStreak > (state.longestStreak)
            ? newStreak
            : state.longestStreak,
      });

      // Atualiza estado local
      state = state.copyWith(
        currentStreak: newStreak,
        longestStreak: newStreak > state.longestStreak
            ? newStreak
            : state.longestStreak,
        lastLoginDate: now,
        hasClaimedTodaysReward: false,
      );

      // Processa recompensas de login e streak
      await _processLoginRewards(newStreak, streakContinued);

      AppLogger.info(
        '🔥 Streak updated',
        data: {
          'userId': _userId,
          'newStreak': newStreak,
          'continued': streakContinued,
        },
      );
    } catch (e, stackTrace) {
      AppLogger.error(
        '❌ Failed to process login streak',
        error: e,
        stackTrace: stackTrace,
      );
      state = state.copyWith(error: 'Erro ao atualizar streak');
    }
  }

  /// Processa recompensas de login e milestone de streak
  Future<void> _processLoginRewards(
    int currentStreak,
    bool streakContinued,
  ) async {
    try {
      final currencyNotifier = _ref.read(currencyProvider.notifier);

      // Recompensa básica de login diário (20 moedas)
      await currencyNotifier.processAutomaticReward(CurrencyReason.dailyLogin);

      // Recompensas de milestone de streak
      final milestone = StreakMilestone.getMilestoneForDay(currentStreak);
      if (milestone != null && streakContinued) {
        // Recompensa de milestone
        await currencyNotifier.addCoins(
          milestone.reward,
          'streak_milestone_${milestone.days}',
        );

        AppLogger.info(
          '🏆 Streak milestone reached',
          data: {
            'streak': currentStreak,
            'milestone': milestone.days,
            'reward': milestone.reward,
          },
        );
      }

      // Recompensas progressivas para streaks longos
      if (currentStreak >= 3 && streakContinued) {
        int bonusCoins = _calculateStreakBonus(currentStreak);
        if (bonusCoins > 0) {
          await currencyNotifier.addCoins(bonusCoins, 'loginStreak');
        }
      }

      state = state.copyWith(hasClaimedTodaysReward: true);
    } catch (e, stackTrace) {
      AppLogger.error(
        '❌ Failed to process login rewards',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Calcula bônus progressivo baseado no streak
  int _calculateStreakBonus(int streak) {
    if (streak >= 30) return 25; // 1 mês
    if (streak >= 14) return 15; // 2 semanas
    if (streak >= 7) return 10; // 1 semana
    if (streak >= 3) return 5; // 3 dias
    return 0;
  }

  /// Agenda reset automático à meia-noite
  void _scheduleMidnightReset() {
    final now = DateTime.now();
    final tomorrow = DateTime(now.year, now.month, now.day + 1);
    final timeUntilMidnight = tomorrow.difference(now);

    _midnightTimer = Timer(timeUntilMidnight, () {
      _onMidnightReset();
      _scheduleMidnightReset(); // Reagenda para a próxima meia-noite
    });
  }

  /// Callback executado à meia-noite
  void _onMidnightReset() {
    state = state.copyWith(hasClaimedTodaysReward: false);

    // Verifica se o streak foi quebrado
    if (!state.isStreakActive) {
      AppLogger.info(
        '💔 Streak broken at midnight reset',
        data: {
          'previousStreak': state.currentStreak,
          'lastLogin': state.lastLoginDate?.toIso8601String(),
        },
      );

      // Reset do streak no próximo login será automático
    }
  }

  /// Força um refresh dos dados de streak
  Future<void> refresh() async {
    await _initializeStreak();
  }

  /// Simula um reset manual do streak (apenas para debug/admin)
  Future<void> resetStreak() async {
    if (_userId == null) return;

    try {
      await _firestoreService.updateUser(_userId!, {
        'loginStreak': 0,
        'lastLoginDate': null,
      });

      state = state.copyWith(
        currentStreak: 0,
        lastLoginDate: null,
        hasClaimedTodaysReward: false,
      );

      AppLogger.info('🔄 Streak manually reset', data: {'userId': _userId});
    } catch (e, stackTrace) {
      AppLogger.error(
        '❌ Failed to reset streak',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }
}

/// Milestones de streak com recompensas
class StreakMilestone {
  final int days;
  final String title;
  final String description;
  final int reward;
  final String emoji;

  const StreakMilestone({
    required this.days,
    required this.title,
    required this.description,
    required this.reward,
    required this.emoji,
  });

  static const List<StreakMilestone> milestones = [
    StreakMilestone(
      days: 3,
      title: 'Iniciante',
      description: '3 dias consecutivos',
      reward: 50,
      emoji: '🔥',
    ),
    StreakMilestone(
      days: 7,
      title: 'Dedicado',
      description: 'Uma semana inteira',
      reward: 100,
      emoji: '⭐',
    ),
    StreakMilestone(
      days: 14,
      title: 'Comprometido',
      description: 'Duas semanas seguidas',
      reward: 200,
      emoji: '💎',
    ),
    StreakMilestone(
      days: 30,
      title: 'Lendário',
      description: 'Um mês completo',
      reward: 500,
      emoji: '👑',
    ),
    StreakMilestone(
      days: 60,
      title: 'Épico',
      description: 'Dois meses seguidos',
      reward: 1000,
      emoji: '🏆',
    ),
    StreakMilestone(
      days: 100,
      title: 'Imortal',
      description: 'Cem dias de glória',
      reward: 2000,
      emoji: '🌟',
    ),
  ];

  /// Retorna o milestone para um dia específico
  static StreakMilestone? getMilestoneForDay(int day) {
    return milestones.where((m) => m.days == day).firstOrNull;
  }

  /// Retorna o próximo milestone baseado no streak atual
  static StreakMilestone? getNextMilestone(int currentStreak) {
    return milestones.where((m) => m.days > currentStreak).firstOrNull;
  }

  /// Retorna o milestone atual (último alcançado)
  static StreakMilestone? getCurrentMilestone(int currentStreak) {
    return milestones.where((m) => m.days <= currentStreak).lastOrNull;
  }
}

/// Extensão para adicionar firstOrNull se não existir
extension IterableExtension<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
  T? get lastOrNull => isEmpty ? null : last;
}
