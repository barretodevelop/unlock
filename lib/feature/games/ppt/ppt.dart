// widgets/game_widgets.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

// models/game_models.dart
enum GameChoice { rock, paper, scissors }

enum GameMode { cpu, player }

enum GameResult { win, lose, draw }

class GameState {
  final GameMode mode;
  final int playerScore;
  final int opponentScore;
  final int gems;
  final int streak;
  final int level;
  final int totalWins;
  final bool isPlaying;
  final GameChoice? playerChoice;
  final GameChoice? opponentChoice;
  final GameResult? lastResult;
  final String resultMessage;

  const GameState({
    this.mode = GameMode.cpu,
    this.playerScore = 0,
    this.opponentScore = 0,
    this.gems = 0,
    this.streak = 0,
    this.level = 1,
    this.totalWins = 0,
    this.isPlaying = false,
    this.playerChoice,
    this.opponentChoice,
    this.lastResult,
    this.resultMessage = '',
  });

  GameState copyWith({
    GameMode? mode,
    int? playerScore,
    int? opponentScore,
    int? gems,
    int? streak,
    int? level,
    int? totalWins,
    bool? isPlaying,
    GameChoice? playerChoice,
    GameChoice? opponentChoice,
    GameResult? lastResult,
    String? resultMessage,
  }) {
    return GameState(
      mode: mode ?? this.mode,
      playerScore: playerScore ?? this.playerScore,
      opponentScore: opponentScore ?? this.opponentScore,
      gems: gems ?? this.gems,
      streak: streak ?? this.streak,
      level: level ?? this.level,
      totalWins: totalWins ?? this.totalWins,
      isPlaying: isPlaying ?? this.isPlaying,
      playerChoice: playerChoice ?? this.playerChoice,
      opponentChoice: opponentChoice ?? this.opponentChoice,
      lastResult: lastResult ?? this.lastResult,
      resultMessage: resultMessage ?? this.resultMessage,
    );
  }
}

// utils/game_utils.dart
class GameUtils {
  static const Map<GameChoice, String> choiceEmojis = {
    GameChoice.rock: '🗿',
    GameChoice.paper: '📄',
    GameChoice.scissors: '✂️',
  };

  static const Map<GameResult, List<String>> resultMessages = {
    GameResult.win: [
      '🎉 VITÓRIA ÉPICA!',
      '🔥 DESTRUIÇÃO!',
      '⚡ DOMINAÇÃO!',
      '💎 PERFEITO!',
    ],
    GameResult.lose: [
      '😤 REVANCHE!',
      '💪 QUASE LÁ!',
      '🎯 FOCO TOTAL!',
      '🔄 NOVA CHANCE!',
    ],
    GameResult.draw: [
      '🤝 EMPATE!',
      '⚖️ EQUILÍBRIO!',
      '🎭 ESPELHADO!',
      '🔄 REPITA!',
    ],
  };

  static GameResult determineWinner(GameChoice player, GameChoice opponent) {
    if (player == opponent) return GameResult.draw;

    const winConditions = {
      GameChoice.rock: GameChoice.scissors,
      GameChoice.paper: GameChoice.rock,
      GameChoice.scissors: GameChoice.paper,
    };

    return winConditions[player] == opponent ? GameResult.win : GameResult.lose;
  }

  static GameChoice getRandomChoice() {
    return GameChoice.values[DateTime.now().millisecondsSinceEpoch % 3];
  }

  static String getRandomMessage(GameResult result) {
    final messages = resultMessages[result]!;
    return messages[DateTime.now().millisecondsSinceEpoch % messages.length];
  }
}

class GameNotifier extends StateNotifier<GameState> {
  GameNotifier() : super(const GameState());

  void setMode(GameMode mode) {
    state = state.copyWith(mode: mode);
  }

  Future<void> playRound(GameChoice playerChoice) async {
    if (state.isPlaying) return;

    state = state.copyWith(
      isPlaying: true,
      playerChoice: null,
      opponentChoice: null,
      lastResult: null,
      resultMessage: '',
    );

    // Simula countdown
    await Future.delayed(const Duration(milliseconds: 500));

    state = state.copyWith(playerChoice: playerChoice);

    // Delay para mostrar escolha do oponente
    await Future.delayed(const Duration(milliseconds: 800));

    final opponentChoice = state.mode == GameMode.cpu
        ? GameUtils.getRandomChoice()
        : GameUtils.getRandomChoice(); // Simula jogador 2

    state = state.copyWith(opponentChoice: opponentChoice);

    // Delay para mostrar resultado
    await Future.delayed(const Duration(milliseconds: 500));

    final result = GameUtils.determineWinner(playerChoice, opponentChoice);
    _updateGameState(result);
  }

  void _updateGameState(GameResult result) {
    int newPlayerScore = state.playerScore;
    int newOpponentScore = state.opponentScore;
    int newStreak = state.streak;
    int newTotalWins = state.totalWins;
    int newGems = state.gems;
    int newLevel = state.level;

    switch (result) {
      case GameResult.win:
        newPlayerScore++;
        newStreak++;
        newTotalWins++;
        newGems += 10 + (newStreak * 2);

        if (newTotalWins % 5 == 0) {
          newLevel++;
          newGems += 50;
        }
        break;
      case GameResult.lose:
        newOpponentScore++;
        newStreak = 0;
        break;
      case GameResult.draw:
        newGems += 5;
        break;
    }

    state = state.copyWith(
      playerScore: newPlayerScore,
      opponentScore: newOpponentScore,
      streak: newStreak,
      totalWins: newTotalWins,
      gems: newGems,
      level: newLevel,
      lastResult: result,
      resultMessage: GameUtils.getRandomMessage(result),
      isPlaying: false,
    );
  }

  void resetGame() {
    state = const GameState();
  }
}

final gameProvider = StateNotifierProvider<GameNotifier, GameState>((ref) {
  return GameNotifier();
});

class GameHeader extends StatelessWidget {
  const GameHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          '⚡ BATTLE ARENA ⚡',
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            shadows: [
              Shadow(
                color: Colors.black26,
                offset: Offset(0, 2),
                blurRadius: 10,
              ),
            ],
          ),
        ),
        SizedBox(height: 8),
        Text(
          'Pedra • Papel • Tesoura',
          style: TextStyle(fontSize: 16, color: Colors.white70),
        ),
      ],
    );
  }
}

class ModeSelector extends ConsumerWidget {
  const ModeSelector({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gameState = ref.watch(gameProvider);
    final gameNotifier = ref.read(gameProvider.notifier);

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _ModeButton(
          text: '🤖 vs CPU',
          mode: GameMode.cpu,
          isActive: gameState.mode == GameMode.cpu,
          onTap: () => gameNotifier.setMode(GameMode.cpu),
        ),
        SizedBox(width: 16),
        _ModeButton(
          text: '👥 vs Jogador',
          mode: GameMode.player,
          isActive: gameState.mode == GameMode.player,
          onTap: () => gameNotifier.setMode(GameMode.player),
        ),
      ],
    );
  }
}

class _ModeButton extends StatelessWidget {
  final String text;
  final GameMode mode;
  final bool isActive;
  final VoidCallback onTap;

  const _ModeButton({
    required this.text,
    required this.mode,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: Duration(milliseconds: 200),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(15),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            decoration: BoxDecoration(
              color: isActive ? Colors.white24 : Colors.white12,
              border: Border.all(
                color: isActive ? Colors.white38 : Colors.white24,
                width: 2,
              ),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Text(
              text,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class ScoreBoard extends ConsumerWidget {
  const ScoreBoard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gameState = ref.watch(gameProvider);

    return Row(
      children: [
        Expanded(
          child: _ScoreCard(label: 'VOCÊ', score: gameState.playerScore),
        ),
        SizedBox(width: 20),
        Expanded(
          child: _ScoreCard(
            label: gameState.mode == GameMode.cpu ? 'CPU' : 'OPONENTE',
            score: gameState.opponentScore,
          ),
        ),
      ],
    );
  }
}

class _ScoreCard extends StatelessWidget {
  final String label;
  final int score;

  const _ScoreCard({required this.label, required this.score});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: Colors.white12,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.white24),
      ),
      child: Column(
        children: [
          Text(label, style: TextStyle(color: Colors.white70, fontSize: 14)),
          SizedBox(height: 5),
          Text(
            score.toString(),
            style: TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class BattleArena extends ConsumerWidget {
  const BattleArena({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gameState = ref.watch(gameProvider);

    return Container(
      height: 120,
      padding: EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white10,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          AnimatedContainer(
            duration: Duration(milliseconds: 500),
            curve: Curves.elasticOut,
            transform: Matrix4.identity()
              ..scale(gameState.playerChoice != null ? 1.0 : 0.5),
            child: AnimatedOpacity(
              duration: Duration(milliseconds: 300),
              opacity: gameState.playerChoice != null ? 1.0 : 0.0,
              child: Text(
                gameState.playerChoice != null
                    ? GameUtils.choiceEmojis[gameState.playerChoice]!
                    : '',
                style: TextStyle(fontSize: 64),
              ),
            ),
          ),
          AnimatedOpacity(
            duration: Duration(milliseconds: 300),
            opacity: gameState.playerChoice != null ? 1.0 : 0.0,
            child: Text(
              'VS',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          AnimatedContainer(
            duration: Duration(milliseconds: 500),
            curve: Curves.elasticOut,
            transform: Matrix4.identity()
              ..scale(gameState.opponentChoice != null ? 1.0 : 0.5),
            child: AnimatedOpacity(
              duration: Duration(milliseconds: 300),
              opacity: gameState.opponentChoice != null ? 1.0 : 0.0,
              child: Text(
                gameState.opponentChoice != null
                    ? GameUtils.choiceEmojis[gameState.opponentChoice]!
                    : '',
                style: TextStyle(fontSize: 64),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class GameScreen extends ConsumerWidget {
  const GameScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(actions: [ResetButton()]),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF667eea), Color(0xFF764ba2)],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(20),
            child: Column(
              children: [
                GameHeader(),
                SizedBox(height: 20),
                ModeSelector(),
                SizedBox(height: 20),
                ScoreBoard(),
                SizedBox(height: 20),
                BattleArena(),
                SizedBox(height: 20),
                ResultMessage(),
                SizedBox(height: 20),
                ChoicesContainer(),
                SizedBox(height: 20),
                RewardsContainer(),
                SizedBox(height: 10),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class ResultMessage extends ConsumerWidget {
  const ResultMessage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gameState = ref.watch(gameProvider);

    return AnimatedContainer(
      duration: Duration(milliseconds: 500),
      height: 40,
      child: AnimatedOpacity(
        duration: Duration(milliseconds: 300),
        opacity: gameState.resultMessage.isNotEmpty ? 1.0 : 0.0,
        child: Text(
          gameState.resultMessage,
          style: TextStyle(
            color: _getResultColor(gameState.lastResult),
            fontSize: 24,
            fontWeight: FontWeight.bold,
            shadows: [
              Shadow(
                color: _getResultColor(gameState.lastResult).withOpacity(0.3),
                blurRadius: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getResultColor(GameResult? result) {
    switch (result) {
      case GameResult.win:
        return Color(0xFF4ade80);
      case GameResult.lose:
        return Color(0xFFf87171);
      case GameResult.draw:
        return Color(0xFFfbbf24);
      default:
        return Colors.white;
    }
  }
}

class ChoicesContainer extends ConsumerWidget {
  const ChoicesContainer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gameState = ref.watch(gameProvider);
    final gameNotifier = ref.read(gameProvider.notifier);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: GameChoice.values.map((choice) {
        return ChoiceButton(
          choice: choice,
          isEnabled: !gameState.isPlaying,
          onTap: () => gameNotifier.playRound(choice),
        );
      }).toList(),
    );
  }
}

class ChoiceButton extends StatefulWidget {
  final GameChoice choice;
  final bool isEnabled;
  final VoidCallback onTap;

  const ChoiceButton({
    super.key,
    required this.choice,
    required this.isEnabled,
    required this.onTap,
  });

  @override
  _ChoiceButtonState createState() => _ChoiceButtonState();
}

class _ChoiceButtonState extends State<ChoiceButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) => _controller.reverse(),
      onTapCancel: () => _controller.reverse(),
      onTap: widget.isEnabled ? widget.onTap : null,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.white12,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white24, width: 3),
                boxShadow: widget.isEnabled
                    ? [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 10,
                          offset: Offset(0, 5),
                        ),
                      ]
                    : null,
              ),
              child: Center(
                child: Text(
                  GameUtils.choiceEmojis[widget.choice]!,
                  style: TextStyle(fontSize: 32),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class RewardsContainer extends ConsumerWidget {
  const RewardsContainer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gameState = ref.watch(gameProvider);

    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white10,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.white24),
      ),
      child: Column(
        children: [
          Text(
            '🏆 SUAS CONQUISTAS',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 15),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _RewardStat(
                icon: '💎',
                value: gameState.gems.toString(),
                label: 'Gemas',
              ),
              _RewardStat(
                icon: '🔥',
                value: gameState.streak.toString(),
                label: 'Sequência',
              ),
              _RewardStat(
                icon: '⭐',
                value: gameState.level.toString(),
                label: 'Nível',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RewardStat extends StatelessWidget {
  final String icon;
  final String value;
  final String label;

  const _RewardStat({
    required this.icon,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(icon, style: TextStyle(fontSize: 24)),
        SizedBox(height: 5),
        Text(
          value,
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        Text(label, style: TextStyle(color: Colors.white70, fontSize: 12)),
      ],
    );
  }
}

class ResetButton extends ConsumerWidget {
  const ResetButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gameNotifier = ref.read(gameProvider.notifier);

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: ElevatedButton(
        onPressed: () {
          gameNotifier.resetGame();
          context.go('/home');
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Color(0xFFff6b6b),
          foregroundColor: Colors.white,
          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          elevation: 3,
        ),
        child: Text('🔄 Sair', style: TextStyle(fontWeight: FontWeight.w600)),
      ),
    );
  }
}
