// lib/features/games/screens/color_match_game_screen.dart

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

/// Representa uma peça colorida
class ColorPiece {
  final Color color;
  final int id;
  bool isMatched;
  bool isSelected;

  ColorPiece({
    required this.color,
    required this.id,
    this.isMatched = false,
    this.isSelected = false,
  });
}

/// Tela do Jogo de Combinação de Cores.
///
/// O jogador deve combinar peças da mesma cor em grupos,
/// ganhando pontos por cada combinação feita.
class ColorMatchGameScreen extends ConsumerStatefulWidget {
  final GameModel game;

  const ColorMatchGameScreen({super.key, required this.game});

  @override
  ConsumerState<ColorMatchGameScreen> createState() =>
      _ColorMatchGameScreenState();
}

class _ColorMatchGameScreenState extends ConsumerState<ColorMatchGameScreen>
    with TickerProviderStateMixin {
  final _rewardAnimationController = RewardAnimationController();
  late AnimationController _matchController;
  late AnimationController _comboController;
  late AnimationController _gameController;

  List<List<ColorPiece?>> _grid = [];
  List<ColorPiece> _selectedPieces = [];
  int _score = 0;
  int _matches = 0;
  int _combo = 0;
  int _maxCombo = 0;
  bool _isProcessing = false;
  bool _isGameOver = false;
  bool _isFinishing = false;
  DateTime? _startTime;

  static const int _gridWidth = 8;
  static const int _gridHeight = 10;
  static const int _minMatchCount = 3;

  static const List<Color> _gameColors = [
    Colors.red,
    Colors.blue,
    Colors.green,
    Colors.yellow,
    Colors.purple,
    Colors.orange,
  ];

  @override
  void initState() {
    super.initState();

    _matchController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _comboController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _gameController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _initializeGame();
  }

  @override
  void dispose() {
    _matchController.dispose();
    _comboController.dispose();
    _gameController.dispose();
    super.dispose();
  }

  void _initializeGame() {
    _generateGrid();
    _startTime = DateTime.now();

    setState(() {
      _score = 0;
      _matches = 0;
      _combo = 0;
      _maxCombo = 0;
      _isGameOver = false;
      _isFinishing = false;
      _selectedPieces.clear();
    });
  }

  void _generateGrid() {
    final random = Random();
    _grid = [];

    for (int row = 0; row < _gridHeight; row++) {
      List<ColorPiece?> currentRow = [];
      for (int col = 0; col < _gridWidth; col++) {
        final color = _gameColors[random.nextInt(_gameColors.length)];
        final piece = ColorPiece(color: color, id: row * _gridWidth + col);
        currentRow.add(piece);
      }
      _grid.add(currentRow);
    }
  }

  void _onPieceTapped(int row, int col) {
    if (_isProcessing || _isGameOver) return;

    final piece = _grid[row][col];
    if (piece == null || piece.isMatched) return;

    if (piece.isSelected) {
      // Deseleciona a peça
      setState(() {
        piece.isSelected = false;
        _selectedPieces.remove(piece);
      });
    } else {
      // Seleciona a peça se for da mesma cor das já selecionadas
      if (_selectedPieces.isEmpty ||
          _selectedPieces.first.color == piece.color) {
        setState(() {
          piece.isSelected = true;
          _selectedPieces.add(piece);
        });

        // Verifica se há peças adjacentes selecionadas
        if (_selectedPieces.length >= _minMatchCount &&
            _areSelectedPiecesConnected()) {
          _processMatch();
        }
      }
    }
  }

  bool _areSelectedPiecesConnected() {
    if (_selectedPieces.length < _minMatchCount) return false;

    // Verifica se todas as peças selecionadas estão conectadas
    final visited = <ColorPiece>{};
    final toVisit = <ColorPiece>[_selectedPieces.first];
    visited.add(_selectedPieces.first);

    while (toVisit.isNotEmpty) {
      final current = toVisit.removeAt(0);
      final neighbors = _getAdjacentSelectedPieces(current);

      for (final neighbor in neighbors) {
        if (!visited.contains(neighbor)) {
          visited.add(neighbor);
          toVisit.add(neighbor);
        }
      }
    }

    return visited.length == _selectedPieces.length;
  }

  List<ColorPiece> _getAdjacentSelectedPieces(ColorPiece piece) {
    final adjacent = <ColorPiece>[];
    final piecePosition = _findPiecePosition(piece);

    if (piecePosition == null) return adjacent;

    final directions = [
      [-1, 0], [1, 0], [0, -1], [0, 1], // cima, baixo, esquerda, direita
    ];

    for (final dir in directions) {
      final newRow = piecePosition['row']! + dir[0];
      final newCol = piecePosition['col']! + dir[1];

      if (newRow >= 0 &&
          newRow < _gridHeight &&
          newCol >= 0 &&
          newCol < _gridWidth) {
        final adjacentPiece = _grid[newRow][newCol];
        if (adjacentPiece != null &&
            adjacentPiece.isSelected &&
            _selectedPieces.contains(adjacentPiece)) {
          adjacent.add(adjacentPiece);
        }
      }
    }

    return adjacent;
  }

  Map<String, int>? _findPiecePosition(ColorPiece piece) {
    for (int row = 0; row < _gridHeight; row++) {
      for (int col = 0; col < _gridWidth; col++) {
        if (_grid[row][col] == piece) {
          return {'row': row, 'col': col};
        }
      }
    }
    return null;
  }

  void _processMatch() async {
    if (_selectedPieces.length < _minMatchCount) return;

    setState(() => _isProcessing = true);

    // Calcula pontuação
    final matchPoints = _selectedPieces.length * 10 * (_combo + 1);
    _score += matchPoints;
    _matches++;
    _combo++;
    _maxCombo = max(_maxCombo, _combo);

    // Animação de match
    _matchController.forward().then((_) => _matchController.reset());

    if (_combo >= 3) {
      _comboController.forward().then((_) => _comboController.reset());
    }

    // Remove peças combinadas
    for (final piece in _selectedPieces) {
      setState(() => piece.isMatched = true);
    }

    await Future.delayed(const Duration(milliseconds: 400));

    // Remove fisicamente as peças e aplica gravidade
    _removePiecesAndApplyGravity();

    // Adiciona novas peças
    _addNewPieces();

    setState(() {
      _selectedPieces.clear();
      _isProcessing = false;
    });

    // Verifica se ainda há movimentos possíveis
    if (!_hasValidMoves()) {
      _gameOver();
    }
  }

  void _removePiecesAndApplyGravity() {
    // Remove peças combinadas
    for (int row = 0; row < _gridHeight; row++) {
      for (int col = 0; col < _gridWidth; col++) {
        if (_grid[row][col]?.isMatched == true) {
          _grid[row][col] = null;
        }
      }
    }

    // Aplica gravidade
    for (int col = 0; col < _gridWidth; col++) {
      final columnPieces = <ColorPiece?>[];

      // Coleta peças não nulas da coluna
      for (int row = _gridHeight - 1; row >= 0; row--) {
        if (_grid[row][col] != null) {
          columnPieces.add(_grid[row][col]);
        }
      }

      // Reposiciona as peças na coluna
      for (int row = 0; row < _gridHeight; row++) {
        if (row < columnPieces.length) {
          _grid[_gridHeight - 1 - row][col] = columnPieces[row];
        } else {
          _grid[_gridHeight - 1 - row][col] = null;
        }
      }
    }
  }

  void _addNewPieces() {
    final random = Random();

    for (int col = 0; col < _gridWidth; col++) {
      for (int row = 0; row < _gridHeight; row++) {
        if (_grid[row][col] == null) {
          final color = _gameColors[random.nextInt(_gameColors.length)];
          _grid[row][col] = ColorPiece(
            color: color,
            id: DateTime.now().millisecondsSinceEpoch + row * _gridWidth + col,
          );
        }
      }
    }
  }

  bool _hasValidMoves() {
    // Verifica se há pelo menos 3 peças adjacentes da mesma cor
    for (int row = 0; row < _gridHeight; row++) {
      for (int col = 0; col < _gridWidth; col++) {
        final piece = _grid[row][col];
        if (piece != null) {
          final sameColorGroup = _findConnectedSameColorPieces(
            row,
            col,
            piece.color,
          );
          if (sameColorGroup.length >= _minMatchCount) {
            return true;
          }
        }
      }
    }
    return false;
  }

  List<ColorPiece> _findConnectedSameColorPieces(
    int startRow,
    int startCol,
    Color color,
  ) {
    final visited = <String>{};
    final connected = <ColorPiece>[];
    final toVisit = <Map<String, int>>[
      {'row': startRow, 'col': startCol},
    ];

    while (toVisit.isNotEmpty) {
      final current = toVisit.removeAt(0);
      final row = current['row']!;
      final col = current['col']!;
      final key = '$row,$col';

      if (visited.contains(key)) continue;
      visited.add(key);

      final piece = _grid[row][col];
      if (piece != null && piece.color == color) {
        connected.add(piece);

        // Adiciona vizinhos
        final directions = [
          [-1, 0],
          [1, 0],
          [0, -1],
          [0, 1],
        ];
        for (final dir in directions) {
          final newRow = row + dir[0];
          final newCol = col + dir[1];

          if (newRow >= 0 &&
              newRow < _gridHeight &&
              newCol >= 0 &&
              newCol < _gridWidth &&
              !visited.contains('$newRow,$newCol')) {
            toVisit.add({'row': newRow, 'col': newCol});
          }
        }
      }
    }

    return connected;
  }

  void _gameOver() {
    setState(() {
      _isGameOver = true;
      _combo = 0;
    });

    _gameController.forward();
    _finishGame();
  }

  void _finishGame() async {
    if (_isFinishing) return;
    setState(() => _isFinishing = true);

    final user = ref.read(authProvider).user;
    if (user == null) return;

    // Calcula recompensas baseadas na performance
    final timeElapsed = _startTime != null
        ? DateTime.now().difference(_startTime!).inSeconds
        : 0;

    final efficiency = _calculateEfficiency(
      _score,
      _matches,
      _maxCombo,
      timeElapsed,
    );

    final baseXp = widget.game.baseRewards[RewardType.xp] ?? 0;
    final baseGems = widget.game.baseRewards[RewardType.gems] ?? 0;
    final baseCoins = widget.game.baseRewards[RewardType.coins] ?? 0;

    final xpEarned = (baseXp * efficiency).round();
    final gemsEarned = (baseGems * efficiency).round();
    final coinsEarned = (baseCoins * efficiency).round();

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

    _showCompletionDialog(timeElapsed, xpEarned, coinsEarned, gemsEarned);
  }

  double _calculateEfficiency(
    int score,
    int matches,
    int maxCombo,
    int timeElapsed,
  ) {
    // Eficiência baseada na pontuação
    final scoreEfficiency = (score / 1000).clamp(0.3, 1.5);

    // Eficiência baseada nas combinações
    final matchEfficiency = (matches / 20).clamp(0.3, 1.2);

    // Eficiência baseada no combo máximo
    final comboEfficiency = (maxCombo / 10).clamp(0.3, 1.3);

    // Eficiência baseada no tempo (ideal: 5+ minutos)
    final timeEfficiency = (timeElapsed / 300).clamp(0.5, 1.0);

    return ((scoreEfficiency * 0.4) +
            (matchEfficiency * 0.2) +
            (comboEfficiency * 0.3) +
            (timeEfficiency * 0.1))
        .clamp(0.3, 1.2);
  }

  void _showCompletionDialog(int timeElapsed, int xp, int coins, int gems) {
    final minutes = timeElapsed ~/ 60;
    final seconds = timeElapsed % 60;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.palette, size: 64, color: Colors.yellow),
            const SizedBox(height: 16),
            Text(
              'Fim do Jogo!',
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Que combinação incrível!',
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            _buildGameStat('Pontuação Final', _score.toString()),
            const SizedBox(height: 8),
            _buildGameStat('Combinações', _matches.toString()),
            const SizedBox(height: 8),
            _buildGameStat('Combo Máximo', '${_maxCombo}x'),
            const SizedBox(height: 8),
            _buildGameStat(
              'Tempo',
              '${minutes}:${seconds.toString().padLeft(2, '0')}',
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
    _gameController.reset();
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
            tooltip: 'Reiniciar',
          ),
        ],
      ),
      body: RewardGainOverlay(
        controller: _rewardAnimationController,
        child: Column(
          children: [
            _buildGameInfo(),
            Expanded(child: _buildColorGrid()),
            _buildInstructions(),
          ],
        ),
      ),
    );
  }

  Widget _buildGameInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildInfoCard('Pontos', _score.toString(), Icons.star),
          _buildInfoCard('Combinações', _matches.toString(), Icons.link),
          _buildInfoCard('Combo', '${_combo}x', Icons.flash_on),
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

  Widget _buildColorGrid() {
    return Container(
      margin: const EdgeInsets.all(16),
      child: GridView.builder(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: _gridWidth,
          crossAxisSpacing: 2,
          mainAxisSpacing: 2,
          childAspectRatio: 1.0,
        ),
        itemCount: _gridWidth * _gridHeight,
        itemBuilder: (context, index) {
          final row = index ~/ _gridWidth;
          final col = index % _gridWidth;
          return _buildColorPiece(row, col);
        },
      ),
    );
  }

  Widget _buildColorPiece(int row, int col) {
    final piece = _grid[row][col];

    if (piece == null) {
      return Container(
        decoration: BoxDecoration(
          color: Colors.grey[300],
          borderRadius: BorderRadius.circular(4),
        ),
      );
    }

    return AnimatedBuilder(
      animation: Listenable.merge([_matchController, _comboController]),
      builder: (context, child) {
        double scale = 1.0;
        double opacity = 1.0;

        if (piece.isMatched && _matchController.isAnimating) {
          scale = 1.0 - _matchController.value;
          opacity = 1.0 - _matchController.value;
        }

        if (piece.isSelected && _combo >= 3 && _comboController.isAnimating) {
          scale = 1.0 + (0.2 * sin(_comboController.value * pi * 4));
        }

        return Transform.scale(
          scale: scale,
          child: Opacity(
            opacity: opacity,
            child: GestureDetector(
              onTap: () => _onPieceTapped(row, col),
              child: Container(
                decoration: BoxDecoration(
                  color: piece.color,
                  borderRadius: BorderRadius.circular(4),
                  border: piece.isSelected
                      ? Border.all(color: Colors.white, width: 3)
                      : null,
                  boxShadow: piece.isSelected
                      ? [
                          BoxShadow(
                            color: Colors.white.withOpacity(0.5),
                            blurRadius: 8,
                            spreadRadius: 2,
                          ),
                        ]
                      : null,
                ),
              ),
            ),
          ),
        );
      },
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
                Icons.info_outline,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Selecione 3+ peças da mesma cor conectadas para fazer combinações!',
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
