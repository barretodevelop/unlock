// lib/features/games/screens/word_game_screen.dart

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

/// Representa uma palavra no caça-palavras
class WordInfo {
  final String word;
  final List<Position> positions;
  bool isFound;

  WordInfo({required this.word, required this.positions, this.isFound = false});
}

/// Posição no grid
class Position {
  final int row;
  final int col;

  Position(this.row, this.col);

  @override
  bool operator ==(Object other) {
    return other is Position && other.row == row && other.col == col;
  }

  @override
  int get hashCode => row.hashCode ^ col.hashCode;
}

/// Célula do grid
class GridCell {
  String letter;
  bool isSelected;
  bool isInFoundWord;
  Color? highlightColor;

  GridCell({
    required this.letter,
    this.isSelected = false,
    this.isInFoundWord = false,
    this.highlightColor,
  });
}

/// Tela do Caça Palavras.
///
/// Um jogo onde o jogador deve encontrar palavras escondidas
/// em um grid de letras, selecionando-as em sequência.
class WordGameScreen extends ConsumerStatefulWidget {
  final GameModel game;

  const WordGameScreen({super.key, required this.game});

  @override
  ConsumerState<WordGameScreen> createState() => _WordGameScreenState();
}

class _WordGameScreenState extends ConsumerState<WordGameScreen>
    with TickerProviderStateMixin {
  final _rewardAnimationController = RewardAnimationController();
  late AnimationController _findController;
  late AnimationController _hintController;

  List<List<GridCell>> _grid = [];
  List<WordInfo> _words = [];
  List<Position> _currentSelection = [];
  bool _isSelecting = false;
  bool _isFinishing = false;
  DateTime? _startTime;
  int _hintsUsed = 0;

  static const int _gridSize = 12;
  static const List<String> _wordList = [
    'FLUTTER',
    'DART',
    'CODIGO',
    'JOGO',
    'MEMORIA',
    'QUIZ',
    'PUZZLE',
    'SNAKE',
    'CORES',
    'NUMERO',
    'REACAO',
    'MATH',
    'PROGRAMA',
    'MOBILE',
    'APP',
    'TELA',
    'BOTAO',
    'TEXTO',
    'IMAGEM',
    'DADOS',
  ];

  static const List<Color> _wordColors = [
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

    _findController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _hintController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _initializeGame();
  }

  @override
  void dispose() {
    _findController.dispose();
    _hintController.dispose();
    super.dispose();
  }

  void _initializeGame() {
    _generateGrid();
    _startTime = DateTime.now();
    _hintsUsed = 0;

    setState(() {
      _isFinishing = false;
    });
  }

  void _generateGrid() {
    final random = Random();

    // Inicializa grid vazio
    _grid = List.generate(
      _gridSize,
      (row) => List.generate(_gridSize, (col) => GridCell(letter: '')),
    );

    // Seleciona palavras aleatórias
    final shuffledWords = List<String>.from(_wordList)..shuffle(random);
    final selectedWords = shuffledWords.take(8).toList();

    _words.clear();

    // Coloca palavras no grid
    for (int i = 0; i < selectedWords.length; i++) {
      final word = selectedWords[i];
      final color = _wordColors[i % _wordColors.length];

      final positions = _placeWordInGrid(word, random);
      if (positions.isNotEmpty) {
        _words.add(WordInfo(word: word, positions: positions));

        // Marca as posições no grid com a cor da palavra
        for (final pos in positions) {
          _grid[pos.row][pos.col].highlightColor = color;
        }
      }
    }

    // Preenche espaços vazios com letras aleatórias
    _fillEmptySpaces(random);
  }

  List<Position> _placeWordInGrid(String word, Random random) {
    const maxAttempts = 100;

    for (int attempt = 0; attempt < maxAttempts; attempt++) {
      final direction = random.nextInt(8); // 8 direções possíveis
      final startRow = random.nextInt(_gridSize);
      final startCol = random.nextInt(_gridSize);

      final positions = _getWordPositions(word, startRow, startCol, direction);

      if (positions.isNotEmpty && _canPlaceWord(positions)) {
        // Coloca a palavra
        for (int i = 0; i < word.length; i++) {
          final pos = positions[i];
          _grid[pos.row][pos.col].letter = word[i];
        }
        return positions;
      }
    }

    return [];
  }

  List<Position> _getWordPositions(
    String word,
    int startRow,
    int startCol,
    int direction,
  ) {
    List<Position> positions = [];

    // Direções: 0=E, 1=SE, 2=S, 3=SO, 4=O, 5=NO, 6=N, 7=NE
    final directions = [
      [0, 1], // Leste
      [1, 1], // Sudeste
      [1, 0], // Sul
      [1, -1], // Sudoeste
      [0, -1], // Oeste
      [-1, -1], // Noroeste
      [-1, 0], // Norte
      [-1, 1], // Nordeste
    ];

    final dir = directions[direction];

    for (int i = 0; i < word.length; i++) {
      final row = startRow + (dir[0] * i);
      final col = startCol + (dir[1] * i);

      if (row < 0 || row >= _gridSize || col < 0 || col >= _gridSize) {
        return [];
      }

      positions.add(Position(row, col));
    }

    return positions;
  }

  bool _canPlaceWord(List<Position> positions) {
    for (final pos in positions) {
      if (_grid[pos.row][pos.col].letter.isNotEmpty) {
        return false;
      }
    }
    return true;
  }

  void _fillEmptySpaces(Random random) {
    const letters = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';

    for (int row = 0; row < _gridSize; row++) {
      for (int col = 0; col < _gridSize; col++) {
        if (_grid[row][col].letter.isEmpty) {
          _grid[row][col].letter = letters[random.nextInt(letters.length)];
        }
      }
    }
  }

  void _onCellTap(int row, int col) {
    if (_isFinishing) return;

    final position = Position(row, col);

    if (!_isSelecting) {
      // Inicia seleção
      _startSelection(position);
    } else {
      // Continua ou finaliza seleção
      _updateSelection(position);
    }
  }

  void _startSelection(Position position) {
    setState(() {
      _isSelecting = true;
      _currentSelection = [position];
      _grid[position.row][position.col].isSelected = true;
    });
  }

  void _updateSelection(Position position) {
    if (_currentSelection.contains(position)) {
      // Clicou em uma posição já selecionada - finaliza seleção
      _finishSelection();
    } else if (_isValidNextPosition(position)) {
      // Adiciona à seleção
      setState(() {
        _currentSelection.add(position);
        _grid[position.row][position.col].isSelected = true;
      });
    } else {
      // Posição inválida - cancela seleção
      _cancelSelection();
    }
  }

  bool _isValidNextPosition(Position position) {
    if (_currentSelection.isEmpty) return true;

    final last = _currentSelection.last;
    final first = _currentSelection.first;

    // Verifica se está na mesma direção que a seleção atual
    if (_currentSelection.length == 1) {
      return true; // Qualquer direção é válida para o segundo ponto
    }

    // Calcula direção da seleção atual
    final currentDirRow = last.row - first.row;
    final currentDirCol = last.col - first.col;

    // Calcula direção para a nova posição
    final newDirRow = position.row - first.row;
    final newDirCol = position.col - first.col;

    // Verifica se está na mesma linha de direção
    if (currentDirRow == 0 && newDirRow == 0) {
      // Horizontal
      return (currentDirCol > 0 && newDirCol > currentDirCol) ||
          (currentDirCol < 0 && newDirCol < currentDirCol);
    } else if (currentDirCol == 0 && newDirCol == 0) {
      // Vertical
      return (currentDirRow > 0 && newDirRow > currentDirRow) ||
          (currentDirRow < 0 && newDirRow < currentDirRow);
    } else if (currentDirRow != 0 &&
        currentDirCol != 0 &&
        newDirRow != 0 &&
        newDirCol != 0) {
      // Diagonal
      final currentRatio = currentDirRow / currentDirCol;
      final newRatio = newDirRow / newDirCol;
      return (currentRatio - newRatio).abs() < 0.1 &&
          ((currentDirRow > 0 && newDirRow > currentDirRow) ||
              (currentDirRow < 0 && newDirRow < currentDirRow));
    }

    return false;
  }

  void _finishSelection() {
    final selectedWord = _getSelectedWord();
    final wordInfo = _findWordBySequence(_currentSelection);

    if (wordInfo != null && !wordInfo.isFound) {
      // Palavra encontrada!
      _markWordAsFound(wordInfo);
      _findController.forward().then((_) => _findController.reset());

      if (_allWordsFound()) {
        _finishGame();
      }
    }

    _cancelSelection();
  }

  String _getSelectedWord() {
    return _currentSelection
        .map((pos) => _grid[pos.row][pos.col].letter)
        .join();
  }

  WordInfo? _findWordBySequence(List<Position> sequence) {
    for (final wordInfo in _words) {
      if (_sequencesMatch(sequence, wordInfo.positions) ||
          _sequencesMatch(sequence.reversed.toList(), wordInfo.positions)) {
        return wordInfo;
      }
    }
    return null;
  }

  bool _sequencesMatch(List<Position> seq1, List<Position> seq2) {
    if (seq1.length != seq2.length) return false;

    for (int i = 0; i < seq1.length; i++) {
      if (seq1[i] != seq2[i]) return false;
    }

    return true;
  }

  void _markWordAsFound(WordInfo wordInfo) {
    setState(() {
      wordInfo.isFound = true;

      for (final pos in wordInfo.positions) {
        _grid[pos.row][pos.col].isInFoundWord = true;
      }
    });
  }

  void _cancelSelection() {
    setState(() {
      for (final pos in _currentSelection) {
        _grid[pos.row][pos.col].isSelected = false;
      }
      _currentSelection.clear();
      _isSelecting = false;
    });
  }

  bool _allWordsFound() {
    return _words.every((word) => word.isFound);
  }

  void _useHint() {
    if (_hintsUsed >= 3 || _allWordsFound()) return;

    final unFoundWords = _words.where((w) => !w.isFound).toList();
    if (unFoundWords.isEmpty) return;

    final wordToHint = unFoundWords.first;
    _hintsUsed++;

    // Destaca a primeira letra da palavra
    final firstPos = wordToHint.positions.first;

    setState(() {
      _grid[firstPos.row][firstPos.col].isSelected = true;
    });

    _hintController.forward().then((_) {
      setState(() {
        _grid[firstPos.row][firstPos.col].isSelected = false;
      });
      _hintController.reset();
    });
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

    final efficiency = _calculateEfficiency(timeElapsed, _hintsUsed);

    final baseXp = widget.game.baseRewards[RewardType.xp] ?? 0;
    final baseGems = widget.game.baseRewards[RewardType.gems] ?? 0;

    final xpEarned = (baseXp * efficiency).round();
    final gemsEarned = (baseGems * efficiency).round();
    final coinsEarned = _hintsUsed == 0
        ? 25
        : (15 - (_hintsUsed * 5)).clamp(5, 15);

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

  double _calculateEfficiency(int timeSeconds, int hintsUsed) {
    // Eficiência baseada no tempo (ideal: 3 minutos)
    final timeEfficiency = (180 / timeSeconds.clamp(60, 600)).clamp(0.3, 1.2);

    // Penalidade por usar dicas
    final hintPenalty = 1.0 - (hintsUsed * 0.2);

    return (timeEfficiency * hintPenalty).clamp(0.3, 1.0);
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
            Icon(Icons.text_fields, size: 64, color: Colors.orange),
            const SizedBox(height: 16),
            Text(
              'Palavras Encontradas!',
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Você encontrou todas as palavras!',
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            _buildGameStat('Palavras', '${_words.length}'),
            const SizedBox(height: 8),
            _buildGameStat(
              'Tempo',
              '${minutes}:${seconds.toString().padLeft(2, '0')}',
            ),
            const SizedBox(height: 8),
            _buildGameStat('Dicas Usadas', '$_hintsUsed/3'),
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
            icon: const Icon(Icons.lightbulb),
            onPressed: _hintsUsed < 3 ? _useHint : null,
            tooltip: 'Dica (${3 - _hintsUsed} restantes)',
          ),
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
            Expanded(child: _buildGameGrid()),
            _buildWordsList(),
          ],
        ),
      ),
    );
  }

  Widget _buildGameInfo() {
    final foundWords = _words.where((w) => w.isFound).length;
    final timeElapsed = _startTime != null
        ? DateTime.now().difference(_startTime!).inSeconds
        : 0;

    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildInfoCard(
            'Palavras',
            '$foundWords/${_words.length}',
            Icons.text_fields,
          ),
          _buildInfoCard(
            'Tempo',
            '${timeElapsed ~/ 60}:${(timeElapsed % 60).toString().padLeft(2, '0')}',
            Icons.timer,
          ),
          _buildInfoCard('Dicas', '${3 - _hintsUsed}', Icons.lightbulb),
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

  Widget _buildGameGrid() {
    return Container(
      margin: const EdgeInsets.all(16),
      child: AspectRatio(
        aspectRatio: 1.0,
        child: GridView.builder(
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: _gridSize,
            crossAxisSpacing: 1,
            mainAxisSpacing: 1,
          ),
          itemCount: _gridSize * _gridSize,
          itemBuilder: (context, index) {
            final row = index ~/ _gridSize;
            final col = index % _gridSize;
            return _buildGridCell(row, col);
          },
        ),
      ),
    );
  }

  Widget _buildGridCell(int row, int col) {
    final cell = _grid[row][col];

    Color backgroundColor = Colors.white;
    Color textColor = Colors.black;

    if (cell.isInFoundWord) {
      backgroundColor = cell.highlightColor ?? Colors.grey;
      textColor = Colors.white;
    } else if (cell.isSelected) {
      backgroundColor = Colors.blue;
      textColor = Colors.white;
    }

    return GestureDetector(
      onTap: () => _onCellTap(row, col),
      child: AnimatedBuilder(
        animation: Listenable.merge([_findController, _hintController]),
        builder: (context, child) {
          return AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              color: backgroundColor,
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Center(
              child: Text(
                cell.letter,
                style: TextStyle(
                  color: textColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildWordsList() {
    return Container(
      height: 120,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Palavras para encontrar:',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Expanded(
            child: Wrap(
              spacing: 8,
              runSpacing: 4,
              children: _words.map((wordInfo) {
                return Chip(
                  label: Text(
                    wordInfo.word,
                    style: TextStyle(
                      decoration: wordInfo.isFound
                          ? TextDecoration.lineThrough
                          : null,
                    ),
                  ),
                  backgroundColor: wordInfo.isFound
                      ? Colors.green.withOpacity(0.3)
                      : Colors.grey.withOpacity(0.3),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
