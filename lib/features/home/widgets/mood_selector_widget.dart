// lib/features/home/widgets/mood_selector_widget.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:unlock/core/constants/app_constants.dart';
import 'package:unlock/models/user_model.dart';
import 'package:unlock/providers/auth_provider.dart';

/// Widget seletor de humor com emojis animadas e feedback visual
class MoodSelectorWidget extends ConsumerStatefulWidget {
  final UserModel user;

  const MoodSelectorWidget({super.key, required this.user});

  @override
  ConsumerState<MoodSelectorWidget> createState() => _MoodSelectorWidgetState();
}

class _MoodSelectorWidgetState extends ConsumerState<MoodSelectorWidget>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  String? _selectedMood;

  // Dados dos humores com emojis
  static const List<Map<String, dynamic>> _moods = [
    {
      'id': 'social',
      'emoji': '🤝',
      'label': 'Social',
      'description': 'Pronto para fazer conexões',
      'color': Color(0xFF2196F3),
    },
    {
      'id': 'creative',
      'emoji': '🎨',
      'label': 'Criativo',
      'description': 'Inspirado e artístico',
      'color': Color(0xFF9C27B0),
    },
    {
      'id': 'chill',
      'emoji': '😌',
      'label': 'Relaxar',
      'description': 'Momento zen e tranquilo',
      'color': Color(0xFF4CAF50),
    },
    {
      'id': 'adventure',
      'emoji': '🌟',
      'label': 'Aventura',
      'description': 'Buscando novas experiências',
      'color': Color(0xFFFF9800),
    },
  ];

  @override
  void initState() {
    super.initState();
    _selectedMood = widget.user.currentMood;

    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: AppConstants.paddingMedium,
        vertical: AppConstants.paddingSmall,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Como você está se sentindo?',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppConstants.spacingLarge),

          // Lista horizontal de humores
          SizedBox(
            height: 80,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _moods.length,
              padding: EdgeInsets.zero,
              itemBuilder: (context, index) {
                final mood = _moods[index];
                final isSelected = _selectedMood == mood['id'];

                return _buildMoodItem(context, theme, mood, isSelected, index);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMoodItem(
    BuildContext context,
    ThemeData theme,
    Map<String, dynamic> mood,
    bool isSelected,
    int index,
  ) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        _selectMood(mood['id'] as String);
      },
      onTapCancel: () => _controller.reverse(),
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: isSelected ? _scaleAnimation.value : 1.0,
            child: Container(
              width: 70,
              margin: EdgeInsets.only(
                right: index < _moods.length - 1
                    ? AppConstants.spacingLarge
                    : 0,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Container do emoji com animação
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.elasticOut,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? mood['color']
                          : theme.colorScheme.surfaceVariant,
                      shape: BoxShape.circle,
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: mood['color'].withOpacity(0.3),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ]
                          : null,
                      border: Border.all(
                        color: isSelected
                            ? mood['color']
                            : theme.colorScheme.outline.withOpacity(0.2),
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: AnimatedDefaultTextStyle(
                      duration: const Duration(milliseconds: 200),
                      style: TextStyle(fontSize: isSelected ? 28 : 24),
                      child: Text(
                        mood['emoji'] as String,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),

                  const SizedBox(height: AppConstants.spacingSmall),

                  // Label do humor
                  AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 200),
                    style:
                        theme.textTheme.labelSmall?.copyWith(
                          color: isSelected
                              ? mood['color']
                              : theme.colorScheme.onSurfaceVariant,
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ) ??
                        const TextStyle(),
                    child: Text(
                      mood['label'] as String,
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _selectMood(String moodId) {
    if (_selectedMood == moodId) return;

    HapticFeedback.lightImpact();

    setState(() {
      _selectedMood = moodId;
    });

    // Mostrar emoji flutuante como feedback
    _showEmojiFloating(moodId);

    // Atualizar no provider
    ref.read(authProvider.notifier).updateUserMood(moodId);
  }

  void _showEmojiFloating(String moodId) {
    final mood = _moods.firstWhere((m) => m['id'] == moodId);

    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.transparent,
      builder: (context) => _EmojiFloatingAnimation(
        emoji: mood['emoji'] as String,
        color: mood['color'] as Color,
      ),
    );

    // Auto-fechar após animação
    Future.delayed(const Duration(milliseconds: 1000), () {
      if (mounted && Navigator.canPop(context)) {
        Navigator.pop(context);
      }
    });
  }
}

/// Widget de animação do emoji flutuante
class _EmojiFloatingAnimation extends StatefulWidget {
  final String emoji;
  final Color color;

  const _EmojiFloatingAnimation({required this.emoji, required this.color});

  @override
  State<_EmojiFloatingAnimation> createState() =>
      _EmojiFloatingAnimationState();
}

class _EmojiFloatingAnimationState extends State<_EmojiFloatingAnimation>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _floatAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _floatAnimation = Tween<double>(
      begin: 0,
      end: -100,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _fadeAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.6, 1.0)),
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.5).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.3, curve: Curves.elasticOut),
      ),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Positioned(
      left: size.width / 2 - 25,
      top: size.height / 2 - 25,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(0, _floatAnimation.value),
            child: Transform.scale(
              scale: _scaleAnimation.value,
              child: Opacity(
                opacity: _fadeAnimation.value,
                child: Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: widget.color.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      widget.emoji,
                      style: const TextStyle(fontSize: 24),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
