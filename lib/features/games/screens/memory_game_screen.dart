// lib/features/games/screens/memory_game_screen.dart

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
 
/// Representa uma carta do jogo da memória
class MemoryCard {
  final int id;
  final String symbol;
  final Color color;
  bool isFlipped;
  bool isMatched;

  MemoryCard({
    required this.id,
    required this.symbol,
    required this.color,
    this.isFlipped = false,
    this.isMatched = false,
  });
}

/// Tela do Jogo da Memória.
///
/// Um jogo clássico onde o jogador deve encontrar pares de cartas
/// iguais, virando duas cartas por vez.
class MemoryGameScreen extends ConsumerStatefulWidget {
  final GameModel game;

  const MemoryGameScreen({super.key, required this.game});

  @override
  ConsumerState<MemoryGameScreen> createState() => _MemoryGameScreenState();
}

class _MemoryGameScreenState extends ConsumerState<MemoryGameScreen>
    with TickerProviderStateMixin {
  
  final _rewardAnimationController = RewardAnimationController();
  late AnimationController _flipController;
  late AnimationController _shakeController;
  late AnimationController _matchController;

  List<MemoryCard> _cards = [];
  List<int> _flippedCards = [];
  int _moves = 0;
  int _matches = 0;
  bool _canFlip = true;
  bool _isFinishing = false;
  DateTime? _startTime;

  // Símbolos e cores para as cartas
  static const List<String> _symbols = [
    '🎮', '🎯', '🎲', '🎨', '🎭', '🎪', '🎺', '🎸',
    '⚽', '🏀', '🎾', '🏈', '🏐', '🏓', '🏸', '🥎',
  ];

  static const List<Color> _colors = [
    Colors.red,
    Colors.blue,
    Colors.green,
    Colors.orange,
    Colors.purple,
    Colors.teal,
    Colors.pink,
    Colors.amber,
  ];

  @override
  void initState() {
    super.initState();
    
    _flipController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    
    _matchController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _initializeGame();
    _startTime = DateTime.now();
  }

  @override
  void dispose() {
    _flipController.dispose();
    _shakeController.dispose();
    _matchController.dispose();
    super.dispose();
  }

  void _initializeGame() {
    const gridSize = 4; // 4x4 = 16 cartas (8 pares)
    const pairCount = (gridSize * gridSize) ~/ 2;
    
    final selectedSymbols = _symbols.take(pairCount).toList();
    final selectedColors = _colors.take(pairCount).toList();
    
    _cards.clear();
    
    // Cria pares de cartas
    for (int i = 0; i < pairCount; i++) {
      final symbol = selectedSymbols[i];
      final color = selectedColors[i];
      
      // Adiciona duas cartas iguais
      _cards.add(MemoryCard(
        id: i * 2,
        symbol: symbol,
        color: color,
      ));
      
      _cards.add(MemoryCard(
        id: i * 2 + 1,
        symbol: symbol,
        color: color,
      ));
    }
    
    // Embaralha as cartas
    _cards.shuffle(Random());
    
    setState(() {
      _moves = 0;
      _matches = 0;
      _flippedCards.clear();
      _canFlip = true;
    });
  }

  void _flipCard(int index) {
    if (!_canFlip || 
        _cards[index].isFlipped || 
        _cards[index].isMatched ||
        _flippedCards.length >= 2) {
      return;
    }

    setState(() {
      _cards[index].isFlipped = true;
      _flippedCards.add(index);
    });

    _flipController.forward();

    if (_flippedCards.length == 2) {
      _moves++;
      _canFlip = false;
      
      Future.delayed(const Duration(milliseconds: 600), () {
        _checkForMatch();
      });
    }
  }

  void _checkForMatch() {
    final firstCard = _cards[_flippedCards[0]];
    final secondCard = _cards[_flippedCards[1]];

    if (firstCard.symbol == secondCard.symbol) {
      // Match encontrado!
      setState(() {
        firstCard.isMatched = true;
        secondCard.isMatched = true;
        _matches++;
      });
      
      _matchController.forward().then((_) {
        _matchController.reset();
      });
      
      _checkGameComplete();
    } else {
      // Não é um match, vira as cartas de volta
      _shakeController.forward().then((_) {
        setState(() {
          firstCard.isFlipped = false;
          secondCard.isFlipped = false;
        });
        _shakeController.reset();
      });
    }

    setState(() {
      _flippedCards.clear();
      _canFlip = true;
    });
    
    _flipController.reset();
  }

  void _checkGameComplete() {
    if (_matches == _cards.length ~/ 2) {
      _finishGame();
    }
  }

  void _finishGame() async {
    if (_isFinishing) return;
    setState(() => _isFinishing = true);

    final user = ref.read(authProvider).user;
    if (user == null) return;

    // Calcula recompensas baseadas na performance
    final timeElapsed = DateTime.now().difference(_startTime!);
    final efficiency = _calculateEfficiency(timeElapsed.inSeconds, _moves);
    
    final baseXp = widget.game.baseRewards[RewardType.xp] ?? 0;
    final baseCoins = widget.game.baseRewards[RewardType.coins] ?? 0;
    
    final xpEarned = (baseXp * efficiency).round();
    final coinsEarned = (baseCoins * efficiency).round();
    final gemsEarned = efficiency >= 0.8 ? 2 : (efficiency >= 0.6 ? 1 : 0);

    // Aguarda um momento para o usuário ver o último match
    await Future.delayed(const Duration(seconds: 1));

    // Concede as recompensas
    await ref.read(rewardsProvider.notifier).grantGameRewards(
      widget.game,
      user,
      xpAmount: xpEarned,
      coinsAmount: coinsEarned,
      gemsAmount: gemsEarned,
    );

    // Mostra as recompensas
    _rewardAnimationController.show(
      RewardAnimationValues(
        xp: xpEarned,
        coins: coinsEarned,
        gems: gemsEarned,
      ),
    );

    // Mostra dialog de resultado
    _showCompletionDialog(timeElapsed, xpEarned, coinsEarned, gemsEarned);
  }

  double _calculateEfficiency(int timeSeconds, int moves) {
    // Movimentos ideais seria igual ao número de pares
    final idealMoves = _cards.length / 2;
    final moveEfficiency = (idealMoves / moves).clamp(0.3, 1.0);
    
    // Tempo ideal seria cerca de 30 segundos
    final idealTime = 30;
    final timeEfficiency = (idealTime / timeSeconds).clamp(0.3, 1.0);
    
    return (moveEfficiency + timeEfficiency) / 2;
  }

  void _showCompletionDialog(Duration time, int xp, int coins, int gems) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.psychology,
              size: 64,
              color: Colors.purple,
            ),
            const SizedBox(height: 16),
            Text(
              'Memória Incrível!',
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Você encontrou todos os pares!',
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            _buildGameStat('Movimentos', _moves.toString()),
            const SizedBox(height: 8),
            _buildGameStat('Tempo', _formatDuration(time)),
            const SizedBox(height: 8),
            _buildGameStat('Precisão', '${(((_cards.length / 2) / _moves) * 100).round()}%'),
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
                  if (coins > 0) _buildRewardChip('${coins}🪙', Icons.monetization_on),
                  if (gems > 0) _buildRewardChip('${gems}💎', Icons.diamond),
                ],
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => _resetGame(),
            child: const Text('Jogar Novamente'),
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
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
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

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes}:${seconds.toString().padLeft(2, '0')}';
  }

  void _resetGame() {
    Navigator.of(context).pop(); // Fecha o dialog
    setState(() {
      _isFinishing = false;
      _startTime = DateTime.now();
    });
    _initializeGame();
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
            tooltip: 'Reiniciar Jogo',
          ),
        ],
      ),
      body: RewardGainOverlay(
        controller: _rewardAnimationController,
        child: Column(
          children: [
            _buildGameInfo(),
            Expanded(
              child: _buildGameGrid(),
            ),
            _buildInstructions(),
          ],
        ),
      ),
    );
  }

  Widget _buildGameInfo() {
    final timeElapsed = _startTime != null
        ? DateTime.now().difference(_startTime!).inSeconds
        : 0;

    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildInfoCard('Movimentos', _moves.toString(), Icons.touch_app),
          _buildInfoCard('Pares', '$_matches/${_cards.length ~/ 2}', Icons.favorite),
          _buildInfoCard('Tempo', _formatDuration(Duration(seconds: timeElapsed)), Icons.timer),
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
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGameGrid() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
          childAspectRatio: 1.0,
        ),
        itemCount: _cards.length,
        itemBuilder: (context, index) {
          return _buildMemoryCard(index);
        },
      ),
    );
  }

  Widget _buildMemoryCard(int index) {
    final card = _cards[index];
    final isShaking = _flippedCards.contains(index) && 
                    _shakeController.isAnimating;
    final isMatching = card.isMatched && _matchController.isAnimating;

    return GestureDetector(
      onTap: () => _flipCard(index),
      child: AnimatedBuilder(
        animation: Listenable.merge([_shakeController, _matchController]),
        builder: (context, child) {
          Widget cardWidget = AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: card.isFlipped || card.isMatched
                  ? card.color.withOpacity(0.9)
                  : Theme.of(context).colorScheme.primary,
              border: Border.all(
                color: card.isMatched 
                    ? Colors.amber 
                    : Theme.of(context).colorScheme.outline,
                width: card.isMatched ? 3 : 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Center(
              child: card.isFlipped || card.isMatched
                  ? Text(
                      card.symbol,
                      style: const TextStyle(
                        fontSize: 24,
                      ),
                    )
                  : Icon(
                      Icons.help_outline,
                      color: Colors.white,
                      size: 32,
                    ),
            ),
          );

          if (isShaking) {
            return Transform.translate(
              offset: Offset(
                (Random().nextDouble() - 0.5) * 10 * _shakeController.value,
                0,
              ),
              child: cardWidget,
            );
          }

          if (isMatching) {
            return Transform.scale(
              scale: 1.0 + (0.1 * _matchController.value),
              child: cardWidget,
            );
          }

          return cardWidget;
        },
      ),
    );
  }

  Widget _buildInstructions() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Icon(
                Icons.lightbulb_outline,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Toque nas cartas para virá-las e encontre os pares iguais!',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}