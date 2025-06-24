// lib/features/mini_games/widgets/difficulty_selector.dart
import 'package:flutter/material.dart';
import 'package:unlock/models/mini_game_model.dart';

/// Widget para seleção de dificuldade
class DifficultySelector extends StatefulWidget {
  final GameDifficulty selectedDifficulty;
  final Function(GameDifficulty) onDifficultyChanged;

  const DifficultySelector({
    super.key,
    required this.selectedDifficulty,
    required this.onDifficultyChanged,
  });

  @override
  State<DifficultySelector> createState() => _DifficultySelectorState();
}

class _DifficultySelectorState extends State<DifficultySelector>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late List<AnimationController> _itemControllers;
  late List<Animation<double>> _scaleAnimations;
  late List<Animation<double>> _fadeAnimations;

  @override
  void initState() {
    super.initState();

    // Controlador principal
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    // Controladores individuais para cada dificuldade
    _itemControllers = List.generate(
      GameDifficulty.values.length,
      (index) => AnimationController(
        duration: Duration(milliseconds: 400 + (index * 100)),
        vsync: this,
      ),
    );

    // Animações de escala
    _scaleAnimations = _itemControllers.map((controller) {
      return Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: controller, curve: Curves.elasticOut),
      );
    }).toList();

    // Animações de fade
    _fadeAnimations = _itemControllers.map((controller) {
      return Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: controller, curve: Curves.easeIn),
      );
    }).toList();

    // Iniciar animações em sequência
    _startAnimations();
  }

  void _startAnimations() async {
    for (int i = 0; i < _itemControllers.length; i++) {
      await Future.delayed(Duration(milliseconds: i * 100));
      if (mounted) {
        _itemControllers[i].forward();
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    for (final controller in _itemControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: GameDifficulty.values.asMap().entries.map((entry) {
        final index = entry.key;
        final difficulty = entry.value;
        
        return AnimatedBuilder(
          animation: _itemControllers[index],
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnimations[index].value,
              child: FadeTransition(
                opacity: _fadeAnimations[index],
                child: Padding(
                  padding: EdgeInsets.only(
                    bottom: index == GameDifficulty.values.length - 1 ? 0 : 12,
                  ),
                  child: _buildDifficultyCard(difficulty),
                ),
              ),
            );
          },
        );
      }).toList(),
    );
  }

  /// Card individual de dificuldade
  Widget _buildDifficultyCard(GameDifficulty difficulty) {
    final isSelected = widget.selectedDifficulty == difficulty;
    final difficultyColor = _getDifficultyColor(difficulty);

    return GestureDetector(
      onTap: () => widget.onDifficultyChanged(difficulty),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    difficultyColor.withOpacity(0.2),
                    difficultyColor.withOpacity(0.1),
                  ],
                )
              : null,
          color: isSelected ? null : Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? difficultyColor
                : Theme.of(context).colorScheme.outline.withOpacity(0.2),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: difficultyColor.withOpacity(0.3),
                    blurRadius: 12,
                    spreadRadius: 2,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Row(
          children: [
            _buildDifficultyIcon(difficulty, difficultyColor, isSelected),
            const SizedBox(width: 16),
            Expanded(
              child: _buildDifficultyInfo(difficulty, difficultyColor, isSelected),
            ),
            _buildSelectionIndicator(isSelected, difficultyColor),
          ],
        ),
      ),
    );
  }

  /// Ícone da dificuldade
  Widget _buildDifficultyIcon(
    GameDifficulty difficulty,
    Color color,
    bool isSelected,
  ) {
    final icon = _getDifficultyIcon(difficulty);
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isSelected ? color : color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(isSelected ? 1.0 : 0.3),
        ),
      ),
      child: Icon(
        icon,
        color: isSelected ? Colors.white : color,
        size: 24,
      ),
    );
  }

  /// Informações da dificuldade
  Widget _buildDifficultyInfo(
    GameDifficulty difficulty,
    Color color,
    bool isSelected,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              difficulty.label,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: isSelected ? color : null,
              ),
            ),
            const SizedBox(width: 8),
            _buildMultiplierBadge(difficulty, color, isSelected),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          _getDifficultyDescription(difficulty),
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context)
                .colorScheme
                .onSurface
                .withOpacity(0.7),
          ),
        ),
        const SizedBox(height: 8),
        _buildDifficultyFeatures(difficulty),
      ],
    );
  }

  /// Badge do multiplicador
  Widget _buildMultiplierBadge(
    GameDifficulty difficulty,
    Color color,
    bool isSelected,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(isSelected ? 0.3 : 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color.withOpacity(0.5),
        ),
      ),
      child: Text(
        '${difficulty.multiplier}x',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  /// Características da dificuldade
  Widget _buildDifficultyFeatures(GameDifficulty difficulty) {
    final features = _getDifficultyFeatures(difficulty);
    
    return Wrap(
      spacing: 8,
      runSpacing: 4,
      children: features.map((feature) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            feature,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        );
      }).toList(),
    );
  }

  /// Indicador de seleção
  Widget _buildSelectionIndicator(bool isSelected, Color color) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        color: isSelected ? color : Colors.transparent,
        shape: BoxShape.circle,
        border: Border.all(
          color: color,
          width: 2,
        ),
      ),
      child: isSelected
          ? const Icon(
              Icons.check,
              color: Colors.white,
              size: 16,
            )
          : null,
    );
  }

  // ========== MÉTODOS AUXILIARES ==========

  /// Obter cor da dificuldade
  Color _getDifficultyColor(GameDifficulty difficulty) {
    switch (difficulty) {
      case GameDifficulty.easy:
        return Colors.green;
      case GameDifficulty.normal:
        return Colors.blue;
      case GameDifficulty.hard:
        return Colors.orange;
      case GameDifficulty.expert:
        return Colors.red;
    }
  }

  /// Obter ícone da dificuldade
  IconData _getDifficultyIcon(GameDifficulty difficulty) {
    switch (difficulty) {
      case GameDifficulty.easy:
        return Icons.sentiment_satisfied;
      case GameDifficulty.normal:
        return Icons.sentiment_neutral;
      case GameDifficulty.hard:
        return Icons.sentiment_dissatisfied;
      case GameDifficulty.expert:
        return Icons.warning;
    }
  }

  /// Obter descrição da dificuldade
  String _getDifficultyDescription(GameDifficulty difficulty) {
    switch (difficulty) {
      case GameDifficulty.easy:
        return 'Perfeito para iniciantes e relaxar';
      case GameDifficulty.normal:
        return 'Equilíbrio entre desafio e diversão';
      case GameDifficulty.hard:
        return 'Para jogadores experientes';
      case GameDifficulty.expert:
        return 'Apenas para os mais habilidosos';
    }
  }

  /// Obter características da dificuldade
  List<String> _getDifficultyFeatures(GameDifficulty difficulty) {
    switch (difficulty) {
      case GameDifficulty.easy:
        return ['Mais tempo', 'Menos pressão', 'Pontos básicos'];
      case GameDifficulty.normal:
        return ['Tempo moderado', 'Desafio equilibrado', '+50% pontos'];
      case GameDifficulty.hard:
        return ['Menos tempo', 'Mais complexo', '+100% pontos'];
      case GameDifficulty.expert:
        return ['Tempo limitado', 'Máxima dificuldade', '+200% pontos'];
    }
  }
}