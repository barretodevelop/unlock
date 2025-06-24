// lib/features/mini_games/screens/game_play_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:unlock/core/constants/app_constants.dart';
import 'package:unlock/core/utils/logger.dart';
import 'package:unlock/features/home/widgets/modern_app_bar.dart';
import 'package:unlock/features/mini_games/games/memory_game_widget.dart';
import 'package:unlock/features/mini_games/games/puzzle_game_widget.dart';
import 'package:unlock/features/mini_games/games/reaction_game_widget.dart';
import 'package:unlock/features/mini_games/widgets/difficulty_selector.dart';
import 'package:unlock/features/mini_games/widgets/game_result_dialog.dart';
import 'package:unlock/models/mini_game_model.dart';
import 'package:unlock/providers/auth_provider.dart';
import 'package:unlock/providers/mini_game_provider.dart';

/// Tela de gameplay individual para mini-games
class GamePlayScreen extends ConsumerStatefulWidget {
  final String gameTypeId;

  const GamePlayScreen({super.key, required this.gameTypeId});

  @override
  ConsumerState<GamePlayScreen> createState() => _GamePlayScreenState();
}

class _GamePlayScreenState extends ConsumerState<GamePlayScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  GameType? _gameType;
  GameDifficulty _selectedDifficulty = GameDifficulty.normal;
  bool _isGameStarted = false;

  @override
  void initState() {
    super.initState();

    // Encontrar tipo do jogo
    _gameType = GameType.values
        .where((type) => type.id == widget.gameTypeId)
        .firstOrNull;

    if (_gameType == null) {
      AppLogger.error('🎮 Tipo de jogo inválido: ${widget.gameTypeId}');
      return;
    }

    AppLogger.info(
      '🎮 GamePlayScreen: Iniciada',
      data: {'gameType': _gameType!.name},
    );

    // Configurar animações
    _animationController = AnimationController(
      duration: AppConstants.animationDuration,
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0.0, 0.3), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Curves.easeOutBack,
          ),
        );

    // Iniciar animação
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    AppLogger.info('🧹 GamePlayScreen: Disposed');
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider.select((state) => state.user));

    if (user == null) {
      return _buildUnauthorizedScreen();
    }

    if (_gameType == null) {
      return _buildInvalidGameScreen();
    }

    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: Scaffold(
              appBar: ModernAppBarVariant(
                title: _gameType!.name,
                // subtitle: _gameType!.description,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: _handleBackPressed,
                ),
                actions: [
                  if (_isGameStarted) ...[
                    IconButton(
                      icon: const Icon(Icons.pause),
                      onPressed: _pauseGame,
                      tooltip: 'Pausar',
                    ),
                    IconButton(
                      icon: const Icon(Icons.stop),
                      onPressed: _showQuitDialog,
                      tooltip: 'Sair do Jogo',
                    ),
                  ] else ...[
                    IconButton(
                      icon: const Icon(Icons.leaderboard),
                      onPressed: _showLeaderboard,
                      tooltip: 'Ranking',
                    ),
                  ],
                ],
              ),
              body: _buildBody(),
            ),
          ),
        );
      },
    );
  }

  /// Corpo principal da tela
  Widget _buildBody() {
    if (_isGameStarted) {
      return _buildGameWidget();
    } else {
      return _buildGameSetup();
    }
  }

  /// Configuração do jogo
  Widget _buildGameSetup() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildGameInfo(),
          const SizedBox(height: 32),
          _buildDifficultySection(),
          const SizedBox(height: 32),
          _buildPersonalBestSection(),
          const SizedBox(height: 32),
          _buildStartGameSection(),
        ],
      ),
    );
  }

  /// Informações do jogo
  Widget _buildGameInfo() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _gameType!.themeColor.withOpacity(0.1),
            _gameType!.themeColor.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _gameType!.themeColor.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _gameType!.themeColor,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(_gameType!.icon, style: const TextStyle(fontSize: 32)),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _gameType!.name,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: _gameType!.themeColor,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _gameType!.description,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Seção de seleção de dificuldade
  Widget _buildDifficultySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          'Escolha a Dificuldade',
          'Afeta pontuação e desafio',
          Icons.trending_up,
        ),
        const SizedBox(height: 16),
        DifficultySelector(
          selectedDifficulty: _selectedDifficulty,
          onDifficultyChanged: (difficulty) {
            setState(() {
              _selectedDifficulty = difficulty;
            });
          },
        ),
      ],
    );
  }

  /// Seção de personal best
  Widget _buildPersonalBestSection() {
    final personalBestQuery = GameTypeQuery(
      userId: ref.watch(authProvider.select((s) => s.user?.uid)) ?? '',
      type: _gameType!,
      difficulty: _selectedDifficulty,
    );

    final personalBestAsync = ref.watch(
      personalBestProvider(personalBestQuery),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          'Seu Recorde',
          'Nesta dificuldade',
          Icons.emoji_events,
        ),
        const SizedBox(height: 16),
        personalBestAsync.when(
          data: (personalBest) => _buildPersonalBestCard(personalBest),
          loading: () => _buildPersonalBestLoading(),
          error: (error, stack) => _buildPersonalBestError(),
        ),
      ],
    );
  }

  /// Card de personal best
  Widget _buildPersonalBestCard(GameResult? personalBest) {
    if (personalBest == null) {
      return _buildNoPersonalBest();
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: personalBest.rankColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: personalBest.rankColor.withOpacity(0.3),
              ),
            ),
            child: Text(
              personalBest.rank,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: personalBest.rankColor,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${personalBest.finalScore} pontos',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: _gameType!.themeColor,
                  ),
                ),
                Text(
                  'Tempo: ${_formatDuration(personalBest.duration)}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
                Text(
                  _formatDate(personalBest.completedAt),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Sem personal best
  Widget _buildNoPersonalBest() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.star_border,
            size: 32,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Primeiro Jogo',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  'Estabeleça seu primeiro recorde!',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Loading personal best
  Widget _buildPersonalBestLoading() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: const Row(
        children: [
          SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          SizedBox(width: 16),
          Text('Carregando recorde...'),
        ],
      ),
    );
  }

  /// Erro personal best
  Widget _buildPersonalBestError() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.errorContainer.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.error.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: Theme.of(context).colorScheme.error),
          const SizedBox(width: 16),
          const Expanded(child: Text('Erro ao carregar recorde')),
        ],
      ),
    );
  }

  /// Seção de iniciar jogo
  Widget _buildStartGameSection() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _startGame,
        style: ElevatedButton.styleFrom(
          backgroundColor: _gameType!.themeColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 4,
        ),
        icon: const Icon(Icons.play_arrow, size: 24),
        label: Text(
          'Jogar ${_selectedDifficulty.label}',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  /// Widget do jogo
  Widget _buildGameWidget() {
    switch (_gameType!) {
      case GameType.memory:
        return MemoryGameWidget(
          difficulty: _selectedDifficulty,
          onGameCompleted: _onGameCompleted,
        );
      case GameType.reaction:
        return ReactionGameWidget(
          difficulty: _selectedDifficulty,
          onGameCompleted: _onGameCompleted,
        );
      case GameType.puzzle:
        return PuzzleGameWidget(
          difficulty: _selectedDifficulty,
          onGameCompleted: _onGameCompleted,
        );
    }
  }

  /// Cabeçalho de seção
  Widget _buildSectionHeader(String title, String subtitle, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: _gameType!.themeColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: _gameType!.themeColor, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Tela não autorizada
  Widget _buildUnauthorizedScreen() {
    return Scaffold(
      appBar: AppBar(title: const Text('Mini Game')),
      body: const Center(child: Text('Você precisa estar logado para jogar.')),
    );
  }

  /// Tela de jogo inválido
  Widget _buildInvalidGameScreen() {
    return Scaffold(
      appBar: AppBar(title: const Text('Jogo Não Encontrado')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              'Jogo não encontrado',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'ID do jogo: ${widget.gameTypeId}',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.pop(),
              child: const Text('Voltar'),
            ),
          ],
        ),
      ),
    );
  }

  // ========== MÉTODOS DE CONTROLE ==========

  /// Iniciar jogo
  void _startGame() {
    setState(() {
      _isGameStarted = true;
    });

    AppLogger.info(
      '🎮 Iniciando jogo',
      data: {
        'gameType': _gameType!.name,
        'difficulty': _selectedDifficulty.label,
      },
    );
  }

  /// Pausar jogo
  void _pauseGame() {
    ref.read(gameSessionProvider(_gameType!).notifier).pauseGame();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Jogo Pausado'),
        content: const Text('O jogo foi pausado. Deseja continuar?'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              ref.read(gameSessionProvider(_gameType!).notifier).resumeGame();
            },
            child: const Text('Continuar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _quitGame();
            },
            child: const Text('Sair'),
          ),
        ],
      ),
    );
  }

  /// Mostrar diálogo de sair
  void _showQuitDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sair do Jogo'),
        content: const Text(
          'Tem certeza que deseja sair? O progresso será perdido.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _quitGame();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Sair'),
          ),
        ],
      ),
    );
  }

  /// Sair do jogo
  void _quitGame() {
    setState(() {
      _isGameStarted = false;
    });

    AppLogger.info('🎮 Jogo abandonado');
  }

  /// Voltar
  void _handleBackPressed() {
    if (_isGameStarted) {
      _showQuitDialog();
    } else {
      context.pop();
    }
  }

  /// Jogo completado
  void _onGameCompleted(GameResult result) {
    setState(() {
      _isGameStarted = false;
    });

    AppLogger.info(
      '🎮 Jogo completado',
      data: {
        'score': result.finalScore,
        'rank': result.rank,
        'duration': result.duration.inSeconds,
      },
    );

    // Mostrar resultado
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => GameResultDialog(
        result: result,
        onPlayAgain: () {
          Navigator.of(context).pop();
          _startGame();
        },
        onBackToMenu: () {
          Navigator.of(context).pop();
        },
      ),
    );
  }

  /// Mostrar leaderboard
  void _showLeaderboard() {
    // Implementar navegação para leaderboard
    AppLogger.info('🏆 Mostrar leaderboard: ${_gameType!.name}');
  }

  // ========== MÉTODOS AUXILIARES ==========

  /// Formatar duração
  String _formatDuration(Duration duration) {
    if (duration.inMinutes > 0) {
      final minutes = duration.inMinutes;
      final seconds = duration.inSeconds % 60;
      return '${minutes}:${seconds.toString().padLeft(2, '0')}';
    } else {
      return '${duration.inSeconds}s';
    }
  }

  /// Formatar data
  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Hoje';
    } else if (difference.inDays == 1) {
      return 'Ontem';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} dias atrás';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}
