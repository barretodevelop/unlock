import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class QuebraCabecaColaborativo extends StatefulWidget {
  final bool conexaoEstabelecida;

  // Você pode passar o status da conexão real por aqui ou atualizar via callback/stream
  const QuebraCabecaColaborativo({Key? key, this.conexaoEstabelecida = false})
    : super(key: key);

  @override
  _QuebraCabecaColaborativoState createState() =>
      _QuebraCabecaColaborativoState();
}

class _QuebraCabecaColaborativoState extends State<QuebraCabecaColaborativo> {
  static const int boardSize = 4;
  static const int totalPairs = (boardSize * boardSize) ~/ 2;
  static const int gameTimeSeconds = 60;
  static const Duration flipDelay = Duration(seconds: 1);

  final List<String> emojis = ['🐶', '🐱', '🦊', '🐼', '🐨', '🐯', '🦁', '🐸'];

  late List<String> board;

  List<int> flipped = [];
  List<int> matched = [];
  int turn = 1;
  bool waiting = false;
  Map<int, int> score = {1: 0, 2: 0};
  String message = 'Jogador 1, é sua vez!';
  int timeLeft = gameTimeSeconds;
  Timer? timer;
  bool gameOver = false;

  @override
  void initState() {
    super.initState();
    board = _generateBoard();
    _startTimer();
  }

  @override
  void didUpdateWidget(covariant QuebraCabecaColaborativo oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.conexaoEstabelecida != oldWidget.conexaoEstabelecida &&
        widget.conexaoEstabelecida) {
      setState(() {
        message = "✅ Conexão real estabelecida! Bom jogo!";
      });
    }
  }

  List<String> _generateBoard() {
    List<String> pairs = [];
    for (int i = 0; i < totalPairs; i++) {
      pairs.add(emojis[i]);
      pairs.add(emojis[i]);
    }
    pairs.shuffle();
    return pairs;
  }

  void _startTimer() {
    timer?.cancel();
    timer = Timer.periodic(Duration(seconds: 1), (t) {
      if (timeLeft <= 1) {
        t.cancel();
        setState(() {
          gameOver = true;
          message = '⏰ Tempo esgotado! Jogo terminado.';
          context.pop(false);
        });
      } else {
        setState(() {
          timeLeft--;
        });
      }
    });
  }

  void _handleFlip(int index) {
    if (waiting || gameOver) return;
    if (flipped.contains(index) || matched.contains(index)) return;
    if (flipped.length == 2) return;

    setState(() {
      flipped.add(index);
    });

    if (flipped.length == 2) {
      final first = flipped[0];
      final second = flipped[1];

      if (board[first] == board[second]) {
        setState(() {
          matched.addAll(flipped);
          score[turn] = (score[turn] ?? 0) + 1;
          message = "🎉 Par encontrado! Jogador $turn pontuou.";
          flipped.clear();
        });

        if (matched.length == board.length) {
          timer?.cancel();
          setState(() {
            gameOver = true;
          });

          int s1 = score[1] ?? 0;
          int s2 = score[2] ?? 0;
          String winnerMsg;
          if (s1 > s2)
            winnerMsg = "🏆 Jogador 1 venceu!";
          else if (s2 > s1)
            winnerMsg = "🏆 Jogador 2 venceu!";
          else
            winnerMsg = "🤝 Empate!";

          setState(() {
            message = "🎊 Parabéns! Jogo terminado. $winnerMsg";
            context.pop(true);
          });
        }
      } else {
        setState(() {
          message = "😕 Não combinou, tentando novamente...";
          waiting = true;
        });

        Future.delayed(flipDelay, () {
          setState(() {
            flipped.clear();
            waiting = false;
            turn = turn == 1 ? 2 : 1;
            message = "Agora é a vez do Jogador $turn.";
          });
        });
      }
    } else {
      setState(() {
        message =
            "Jogador $turn virou uma peça. Agora é a vez do outro jogador.";
        turn = turn == 1 ? 2 : 1;
      });
    }
  }

  void _restartGame() {
    timer?.cancel();
    setState(() {
      board = _generateBoard();
      flipped.clear();
      matched.clear();
      turn = 1;
      waiting = false;
      score = {1: 0, 2: 0};
      message = 'Jogador 1, é sua vez!';
      timeLeft = gameTimeSeconds;
      gameOver = false;
    });
    _startTimer();
  }

  Widget _buildPiece(int index) {
    bool isFlipped = flipped.contains(index) || matched.contains(index);

    return GestureDetector(
      onTap: () => _handleFlip(index),
      child: AnimatedContainer(
        duration: Duration(milliseconds: 300),
        margin: EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: isFlipped ? Colors.teal[300] : Colors.blueGrey[700],
          borderRadius: BorderRadius.circular(12),
          boxShadow: isFlipped
              ? [
                  BoxShadow(
                    color: Colors.tealAccent.withOpacity(0.7),
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
                ]
              : [],
        ),
        width: 80,
        height: 80,
        alignment: Alignment.center,
        child: Text(
          isFlipped ? board[index] : '❓',
          style: TextStyle(fontSize: 42),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[900],
      body: SafeArea(
        child: Center(
          child: Container(
            constraints: BoxConstraints(maxWidth: 420),
            padding: EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.grey[850],
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: Colors.black54, blurRadius: 25)],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '🧩 Quebra-Cabeça Colaborativo',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 12),
                Text(
                  message,
                  style: TextStyle(color: Colors.white70, fontSize: 16),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 8),
                Text(
                  '⏳ Tempo restante: $timeLeft s',
                  style: TextStyle(
                    color: Colors.amberAccent,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 16),
                GridView.builder(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: boardSize,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                  ),
                  itemCount: board.length,
                  itemBuilder: (_, i) => _buildPiece(i),
                ),
                SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _scoreBox(1, score[1] ?? 0, Colors.tealAccent),
                    _scoreBox(2, score[2] ?? 0, Colors.pinkAccent),
                  ],
                ),
                if (gameOver)
                  Padding(
                    padding: const EdgeInsets.only(top: 20),
                    child: ElevatedButton.icon(
                      icon: Icon(Icons.replay),
                      label: Text('Reiniciar Jogo'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal[400],
                        padding: EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 14,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(28),
                        ),
                        textStyle: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      onPressed: _restartGame,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _scoreBox(int player, int pts, Color color) {
    return Column(
      children: [
        Text(
          'Jogador $player',
          style: TextStyle(color: color, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 6),
        Text(
          '$pts',
          style: TextStyle(
            color: color,
            fontSize: 22,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }
}
