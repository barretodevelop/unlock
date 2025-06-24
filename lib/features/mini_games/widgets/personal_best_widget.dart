// lib/features/mini_games/widgets/personal_best_widget.dart
import 'package:flutter/material.dart';
import 'package:unlock/models/mini_game_model.dart';

/// Widget mostrando personal bests do usuário
class PersonalBestWidget extends StatefulWidget {
  final Map<GameType, GameResult?> personalBests;

  const PersonalBestWidget({
    super.key,
    required this.personalBests,
  });

  @override
  State<PersonalBestWidget> createState() => _PersonalBestWidgetState();
}

class _PersonalBestWidgetState extends State<PersonalBestWidget>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late List<AnimationController> _itemControllers;
  late List<Animation<Offset>> _slideAnimations;
  late List<Animation<double>> _fadeAnimations;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    // Criar animações para cada item
    _itemControllers = List.generate(
      GameType.values.length,
      (index) => AnimationController(
        duration: Duration(milliseconds: 400 + (index * 100)),
        vsync: this,
      ),
    );

    _slideAnimations = _itemControllers.map((controller) {
      return Tween<Offset>(
        begin: const Offset(0.0, 0.5),
        end: Offset.zero,
      ).animate(CurvedAnimation(
        parent: controller,
        curve: Curves.easeOutBack,
      ));
    }).toList();

    _fadeAnimations = _itemControllers.map((controller) {
      return Tween<double>(
        begin: 0.0,
        end: 1.0,
      ).animate(CurvedAnimation(
        parent: controller,
        curve: Curves.easeIn,
      ));
    }).toList();

    // Iniciar animações em sequência
    _startAnimations();
  }

  void _startAnimations() async {
    for (int i = 0; i < _itemControllers.length; i++) {
      await Future.delayed(Duration(milliseconds: i * 50));
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
    // Se não há personal bests, mostrar widget vazio ou placeholder
    if (widget.personalBests.isEmpty || 
        widget.personalBests.values.every((best) => best == null)) {
      return _buildEmptyState();
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(),
          const SizedBox(height: 16),
          _buildPersonalBestsList(),
        ],
      ),
    );
  }

  /// Cabeçalho da seção
  Widget _buildSectionHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.amber.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            Icons.emoji_events,
            color: Colors.amber,
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Seus Recordes',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'Melhores pontuações em cada jogo',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withOpacity(0.7),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Lista de personal bests
  Widget _buildPersonalBestsList() {
    return SizedBox(
      height: 120,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: GameType.values.length,
        itemBuilder: (context, index) {
          final gameType = GameType.values[index];
          final personalBest = widget.personalBests[gameType];

          return AnimatedBuilder(
            animation: _itemControllers[index],
            builder: (context, child) {
              return SlideTransition(
                position: _slideAnimations[index],
                child: FadeTransition(
                  opacity: _fadeAnimations[index],
                  child: Padding(
                    padding: EdgeInsets.only(
                      right: index == GameType.values.length - 1 ? 0 : 12,
                    ),
                    child: _buildPersonalBestCard(gameType, personalBest),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  /// Card individual de personal best
  Widget _buildPersonalBestCard(GameType gameType, GameResult? personalBest) {
    final hasRecord = personalBest != null;

    return Container(
      width: 160,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: hasRecord
              ? [
                  gameType.themeColor.withOpacity(0.15),
                  gameType.themeColor.withOpacity(0.05),
                ]
              : [
                  Colors.grey.withOpacity(0.1),
                  Colors.grey.withOpacity(0.05),
                ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: hasRecord
              ? gameType.themeColor.withOpacity(0.3)
              : Colors.grey.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCardHeader(gameType, hasRecord),
          const Spacer(),
          if (hasRecord) ...[
            _buildScoreInfo(personalBest!),
          ] else ...[
            _buildNoRecordInfo(),
          ],
        ],
      ),
    );
  }

  /// Header do card
  Widget _buildCardHeader(GameType gameType, bool hasRecord) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: hasRecord
                ? gameType.themeColor.withOpacity(0.2)
                : Colors.grey.withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            gameType.icon,
            style: const TextStyle(fontSize: 16),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            gameType.name,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: hasRecord
                  ? gameType.themeColor
                  : Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  /// Informações do score
  Widget _buildScoreInfo(GameResult personalBest) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: personalBest.rankColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: personalBest.rankColor.withOpacity(0.5),
                ),
              ),
              child: Text(
                personalBest.rank,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: personalBest.rankColor,
                ),
              ),
            ),
            const Spacer(),
            Text(
              _formatDate(personalBest.completedAt),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                fontSize: 10,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          '${personalBest.finalScore}',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: personalBest.type.themeColor,
          ),
        ),
        Text(
          'pontos',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
          ),
        ),
      ],
    );
  }

  /// Informações quando não há record
  Widget _buildNoRecordInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          Icons.timer,
          size: 16,
          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
        ),
        const SizedBox(height: 4),
        Text(
          'Sem record',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            fontStyle: FontStyle.italic,
          ),
        ),
        Text(
          'Jogue para criar!',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
            fontSize: 10,
          ),
        ),
      ],
    );
  }

  /// Estado vazio
  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
          ),
        ),
        child: Column(
          children: [
            Icon(
              Icons.emoji_events_outlined,
              size: 48,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
            ),
            const SizedBox(height: 12),
            Text(
              'Nenhum recorde ainda',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Comece jogando para estabelecer seus primeiros recordes!',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
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
      return '${difference.inDays}d atrás';
    } else {
      return '${date.day}/${date.month}';
    }
  }
}