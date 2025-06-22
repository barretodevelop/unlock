// lib/features/games/screens/reaction_game_screen.dart

import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:unlock/features/games/widgets/reward_animation_controller.dart';
import 'package:unlock/features/games/widgets/reward_gain_overlay.dart';
import 'package:unlock/features/rewards/models/reward_model.dart';
import 'package:unlock/features/rewards/providers/rewards_provider.dart';
import 'package:unlock/models/game_model.dart';
import 'package:unlock/providers/auth_provider.dart';

/// Estados possíveis do teste de reflexo
enum ReactionState {
  waiting, // Aguardando início
  preparing, // Preparando para mostrar o estímulo
  ready, // Mostrando o estímulo (pode clicar)
  measuring, // Medindo tempo de reação
  result, // Mostrando resultado
  finished, // Teste finalizado
}

/// Tipos de estímulo para testar reflexo
enum StimulusType {
  color, // Mudança de cor
  text, // Aparição de texto
  shape, // Mudança de forma
  sound, // Estímulo sonoro (visual neste caso)
}

/// Resultado de um teste de reflexo
class ReactionResult {
  final double reactionTime;
  final StimulusType stimulusType;
  final bool isValid;

  ReactionResult({
    required this.reactionTime,
    required this.stimulusType,
    this.isValid = true,
  });
}

/// Tela do Teste de Reflexo.
///
/// Mede o tempo de reação do jogador a diferentes estímulos visuais,
/// testando velocidade e precisão dos reflexos.
class ReactionGameScreen extends ConsumerStatefulWidget {
  final GameModel game;

  const ReactionGameScreen({super.key, required this.game});

  @override
  ConsumerState<ReactionGameScreen> createState() => _ReactionGameScreenState();
}

class _ReactionGameScreenState extends ConsumerState<ReactionGameScreen>
    with TickerProviderStateMixin {
  final _rewardAnimationController = RewardAnimationController();
  late AnimationController _pulseController;
  late AnimationController _flashController;
  late AnimationController _resultController;

  ReactionState _currentState = ReactionState.waiting;
  StimulusType _currentStimulus = StimulusType.color;
  Timer? _stimulusTimer;
  DateTime? _stimulusStartTime;
  List<ReactionResult> _results = [];
  int _currentRound = 0;
  bool _isFinishing = false;

  static const int _totalRounds = 10;
  static const int _minWaitTime = 2000; // ms
  static const int _maxWaitTime = 5000; // ms
  static const double _maxValidReactionTime = 1000; // ms

  // Cores para estímulos
  final List<Color> _stimulusColors = [
    Colors.red,
    Colors.green,
    Colors.blue,
    Colors.yellow,
    Colors.purple,
    Colors.orange,
  ];

  // Formas para estímulos
  final List<IconData> _stimulusShapes = [
    Icons.circle,
    Icons.square,
    Icons.star,
    Icons.favorite,
    Icons.diamond,
    Icons.hexagon,
  ];

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _flashController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _resultController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _pulseController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _stimulusTimer?.cancel();
    _pulseController.dispose();
    _flashController.dispose();
    _resultController.dispose();
    super.dispose();
  }

  void _startTest() {
    setState(() {
      _currentState = ReactionState.waiting;
      _currentRound = 0;
      _results.clear();
    });

    _nextRound();
  }

  void _nextRound() {
    if (_currentRound >= _totalRounds) {
      _finishTest();
      return;
    }

    _currentRound++;

    // Escolhe tipo de estímulo aleatório
    final random = Random();
    _currentStimulus =
        StimulusType.values[random.nextInt(StimulusType.values.length)];

    setState(() => _currentState = ReactionState.preparing);

    // Aguarda tempo aleatório antes de mostrar estímulo
    final waitTime = _minWaitTime + random.nextInt(_maxWaitTime - _minWaitTime);

    _stimulusTimer = Timer(Duration(milliseconds: waitTime), () {
      _showStimulus();
    });
  }

  void _showStimulus() {
    setState(() {
      _currentState = ReactionState.ready;
      _stimulusStartTime = DateTime.now();
    });

    _flashController.forward().then((_) => _flashController.reset());

    // Timeout após 2 segundos
    _stimulusTimer = Timer(const Duration(seconds: 2), () {
      if (_currentState == ReactionState.ready) {
        _recordResult(double.infinity, false); // Timeout
      }
    });
  }

  void _onScreenTapped() {
    if (_currentState == ReactionState.preparing) {
      // Clicou muito cedo!
      _recordResult(0, false);
    } else if (_currentState == ReactionState.ready) {
      // Tempo de reação válido
      final reactionTime = DateTime.now()
          .difference(_stimulusStartTime!)
          .inMilliseconds
          .toDouble();
      _recordResult(reactionTime, true);
    }
  }

  void _recordResult(double reactionTime, bool isValid) {
    _stimulusTimer?.cancel();

    final result = ReactionResult(
      reactionTime: reactionTime,
      stimulusType: _currentStimulus,
      isValid: isValid && reactionTime <= _maxValidReactionTime,
    );

    _results.add(result);

    setState(() => _currentState = ReactionState.result);

    _resultController.forward().then((_) {
      _resultController.reset();

      // Aguarda um momento antes do próximo round
      Future.delayed(const Duration(milliseconds: 1500), () {
        _nextRound();
      });
    });
  }

  void _finishTest() {
    setState(() => _currentState = ReactionState.finished);
    _finishGame();
  }

  void _finishGame() async {
    if (_isFinishing) return;
    setState(() => _isFinishing = true);

    final user = ref.read(authProvider).user;
    if (user == null) return;

    // Calcula estatísticas
    final validResults = _results.where((r) => r.isValid).toList();
    final avgReactionTime = validResults.isNotEmpty
        ? validResults.map((r) => r.reactionTime).reduce((a, b) => a + b) /
              validResults.length
        : double.infinity;

    final bestReactionTime = validResults.isNotEmpty
        ? validResults.map((r) => r.reactionTime).reduce(min)
        : double.infinity;

    final accuracy = validResults.length / _totalRounds;

    // Calcula recompensas baseadas na performance
    final efficiency = _calculateEfficiency(
      avgReactionTime,
      bestReactionTime,
      accuracy,
    );

    final baseXp = widget.game.baseRewards[RewardType.xp] ?? 0;
    final baseCoins = widget.game.baseRewards[RewardType.coins] ?? 0;

    final xpEarned = (baseXp * efficiency).round();
    final coinsEarned = (baseCoins * efficiency).round();
    final gemsEarned = bestReactionTime < 200
        ? 5
        : (bestReactionTime < 300 ? 3 : (bestReactionTime < 400 ? 1 : 0));

    // Aguarda um momento
    await Future.delayed(const Duration(seconds: 1));

    // Concede as recompensas
    await ref
        .read(rewardsProvider.notifier)
        .grantGameRewards(
          widget.game,
          user,
          xpAmount: xpEarned,
          coinsAmount: coinsEarned,
          gemsAmount: gemsEarned,
        );

    // Mostra as recompensas
    _rewardAnimationController.show(
      RewardAnimationValues(xp: xpEarned, coins: coinsEarned, gems: gemsEarned),
    );

    _showCompletionDialog(
      avgReactionTime,
      bestReactionTime,
      accuracy,
      xpEarned,
      coinsEarned,
      gemsEarned,
    );
  }

  double _calculateEfficiency(
    double avgReactionTime,
    double bestReactionTime,
    double accuracy,
  ) {
    // Eficiência baseada no tempo médio (ideal: < 300ms)
    final avgTimeEfficiency = avgReactionTime != double.infinity
        ? (300 / avgReactionTime.clamp(150, 800)).clamp(0.3, 1.5)
        : 0.3;

    // Eficiência baseada no melhor tempo (ideal: < 250ms)
    final bestTimeEfficiency = bestReactionTime != double.infinity
        ? (250 / bestReactionTime.clamp(100, 600)).clamp(0.3, 1.3)
        : 0.3;

    // Eficiência baseada na precisão
    final accuracyEfficiency = accuracy.clamp(0.3, 1.0);

    return ((avgTimeEfficiency * 0.4) +
            (bestTimeEfficiency * 0.3) +
            (accuracyEfficiency * 0.3))
        .clamp(0.3, 1.2);
  }

  void _showCompletionDialog(
    double avgTime,
    double bestTime,
    double accuracy,
    int xp,
    int coins,
    int gems,
  ) {
    final accuracyPercent = (accuracy * 100).round();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.flash_on, size: 64, color: Colors.amber),
            const SizedBox(height: 16),
            Text(
              'Teste Completo!',
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Seus reflexos foram testados!',
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            _buildGameStat(
              'Tempo Médio',
              avgTime != double.infinity ? '${avgTime.round()}ms' : 'N/A',
            ),
            const SizedBox(height: 8),
            _buildGameStat(
              'Melhor Tempo',
              bestTime != double.infinity ? '${bestTime.round()}ms' : 'N/A',
            ),
            const SizedBox(height: 8),
            _buildGameStat('Precisão', '$accuracyPercent%'),
            const SizedBox(height: 8),
            _buildGameStat(
              'Testes Válidos',
              '${_results.where((r) => r.isValid).length}/$_totalRounds',
            ),
            const SizedBox(height: 16),
            if (xp > 0 || coins > 0 || gems > 0) ...[
              const Divider(),
              Text(
                'Recompensas:',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  if (xp > 0) _buildRewardChip('${xp}XP', Icons.star),
                  if (coins > 0)
                    _buildRewardChip('${coins}🪙', Icons.monetization_on),
                  if (gems > 0) _buildRewardChip('${gems}💎', Icons.diamond),
                ],
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => _resetGame(),
            child: const Text('Testar Novamente'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.goNamed('games');
            },
            child: const Text('Voltar aos Jogos'),
          ),
        ],
      ),
    );
  }

  Widget _buildGameStat(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodyMedium),
          Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildRewardChip(String text, IconData icon) {
    return Chip(
      avatar: Icon(icon, size: 16),
      label: Text(text),
      backgroundColor: Theme.of(context).colorScheme.primaryContainer,
    );
  }

  void _resetGame() {
    Navigator.of(context).pop();
    setState(() {
      _currentState = ReactionState.waiting;
      _isFinishing = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.game.name),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _resetGame,
            tooltip: 'Reiniciar',
          ),
        ],
      ),
      body: RewardGainOverlay(
        controller: _rewardAnimationController,
        child: Column(
          children: [
            _buildGameInfo(),
            Expanded(child: _buildTestArea()),
            if (_currentState == ReactionState.waiting) _buildStartButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildGameInfo() {
    final validResults = _results.where((r) => r.isValid).length;
    final lastResult = _results.isNotEmpty ? _results.last : null;

    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildInfoCard(
            'Round',
            '$_currentRound/$_totalRounds',
            Icons.numbers,
          ),
          _buildInfoCard(
            'Válidos',
            '$validResults/${_results.length}',
            Icons.check_circle,
          ),
          _buildInfoCard(
            'Último',
            lastResult?.isValid == true
                ? '${lastResult!.reactionTime.round()}ms'
                : _results.isNotEmpty
                ? 'Inválido'
                : '-',
            Icons.timer,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(String label, String value, IconData icon) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Icon(icon, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 4),
            Text(
              value,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            Text(label, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }

  Widget _buildTestArea() {
    return GestureDetector(
      onTap: _onScreenTapped,
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey),
        ),
        child: _buildStateContent(),
      ),
    );
  }

  Widget _buildStateContent() {
    switch (_currentState) {
      case ReactionState.waiting:
        return _buildWaitingContent();
      case ReactionState.preparing:
        return _buildPreparingContent();
      case ReactionState.ready:
        return _buildReadyContent();
      case ReactionState.result:
        return _buildResultContent();
      case ReactionState.finished:
        return _buildFinishedContent();
      default:
        return Container();
    }
  }

  Widget _buildWaitingContent() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.flash_on, size: 80, color: Colors.grey),
        const SizedBox(height: 20),
        Text(
          'Teste de Reflexo',
          style: Theme.of(context).textTheme.headlineMedium,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Text(
            'Teste sua velocidade de reação! Toque na tela assim que ver o estímulo aparecer.',
            style: Theme.of(context).textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }

  Widget _buildPreparingContent() {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Transform.scale(
              scale: 1.0 + (0.2 * _pulseController.value),
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(
                    0.3 + (0.7 * _pulseController.value),
                  ),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.hourglass_empty,
                  size: 50,
                  color: Colors.orange,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Prepare-se...',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'Aguarde o estímulo aparecer',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        );
      },
    );
  }

  Widget _buildReadyContent() {
    return AnimatedBuilder(
      animation: _flashController,
      builder: (context, child) {
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Transform.scale(
              scale: 1.0 + (0.5 * _flashController.value),
              child: _buildStimulus(),
            ),
            const SizedBox(height: 20),
            Text(
              'TOQUE AGORA!',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStimulus() {
    final random = Random();

    switch (_currentStimulus) {
      case StimulusType.color:
        final color = _stimulusColors[random.nextInt(_stimulusColors.length)];
        return Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.5),
                blurRadius: 20,
                spreadRadius: 5,
              ),
            ],
          ),
        );

      case StimulusType.text:
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.blue,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            'GO!',
            style: TextStyle(
              color: Colors.white,
              fontSize: 48,
              fontWeight: FontWeight.bold,
            ),
          ),
        );

      case StimulusType.shape:
        final shape = _stimulusShapes[random.nextInt(_stimulusShapes.length)];
        return Icon(shape, size: 120, color: Colors.purple);

      case StimulusType.sound:
        return Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            color: Colors.green,
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.volume_up, size: 60, color: Colors.white),
        );
    }
  }

  Widget _buildResultContent() {
    final lastResult = _results.last;

    return AnimatedBuilder(
      animation: _resultController,
      builder: (context, child) {
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Transform.scale(
              scale: 1.0 + (0.2 * _resultController.value),
              child: Icon(
                lastResult.isValid ? Icons.check_circle : Icons.cancel,
                size: 80,
                color: lastResult.isValid ? Colors.green : Colors.red,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              lastResult.isValid
                  ? '${lastResult.reactionTime.round()}ms'
                  : lastResult.reactionTime == 0
                  ? 'Muito cedo!'
                  : 'Muito lento!',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: lastResult.isValid ? Colors.green : Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (lastResult.isValid) ...[
              const SizedBox(height: 8),
              Text(
                _getReactionRating(lastResult.reactionTime),
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ],
          ],
        );
      },
    );
  }

  String _getReactionRating(double reactionTime) {
    if (reactionTime < 200) return 'Incrível! ⚡';
    if (reactionTime < 250) return 'Muito bom! 🔥';
    if (reactionTime < 300) return 'Bom! 👍';
    if (reactionTime < 400) return 'Razoável 👌';
    return 'Pode melhorar! 💪';
  }

  Widget _buildFinishedContent() {
    final validResults = _results.where((r) => r.isValid).toList();
    final avgTime = validResults.isNotEmpty
        ? validResults.map((r) => r.reactionTime).reduce((a, b) => a + b) /
              validResults.length
        : 0.0;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.emoji_events, size: 80, color: Colors.amber),
        const SizedBox(height: 20),
        Text(
          'Teste Finalizado!',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 16),
        Text(
          'Tempo médio: ${avgTime.round()}ms',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        Text(
          'Testes válidos: ${validResults.length}/$_totalRounds',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
      ],
    );
  }

  Widget _buildStartButton() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: ElevatedButton.icon(
        onPressed: _startTest,
        icon: const Icon(Icons.play_arrow),
        label: const Text('Iniciar Teste'),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          textStyle: const TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}
