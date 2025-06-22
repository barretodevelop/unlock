// lib/features/home/widgets/connection_suggestions_carousel.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:unlock/core/constants/app_constants.dart';
import 'package:unlock/core/router/app_router.dart';

/// Carrossel de sugestões de conexão com animações e design moderno
class ConnectionSuggestionsCarousel extends StatefulWidget {
  const ConnectionSuggestionsCarousel({super.key});

  @override
  State<ConnectionSuggestionsCarousel> createState() =>
      _ConnectionSuggestionsCarouselState();
}

class _ConnectionSuggestionsCarouselState
    extends State<ConnectionSuggestionsCarousel>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late PageController _pageController;

  int _currentPage = 0;

  // Mock data das sugestões
  static const List<Map<String, dynamic>> _suggestions = [
    {
      'id': '1',
      'avatar': '🎨',
      'name': 'Artista Criativo',
      'match': 95,
      'interests': ['Arte', 'Música'],
      'color': Color(0xFF9C27B0),
    },
    {
      'id': '2',
      'avatar': '🏃',
      'name': 'Esportista',
      'match': 88,
      'interests': ['Esportes', 'Fitness'],
      'color': Color(0xFF4CAF50),
    },
    {
      'id': '3',
      'avatar': '📚',
      'name': 'Bookworm',
      'match': 92,
      'interests': ['Leitura', 'Filosofia'],
      'color': Color(0xFF2196F3),
    },
    {
      'id': '4',
      'avatar': '🎮',
      'name': 'Gamer',
      'match': 90,
      'interests': ['Jogos', 'Tecnologia'],
      'color': Color(0xFFFF9800),
    },
    {
      'id': '5',
      'avatar': '🌍',
      'name': 'Aventureiro',
      'match': 85,
      'interests': ['Viagens', 'Natureza'],
      'color': Color(0xFF795548),
    },
  ];

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _pageController = PageController(viewportFraction: 0.85, initialPage: 0);

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AnimatedBuilder(
      animation: _fadeAnimation,
      builder: (context, child) {
        return Opacity(
          opacity: _fadeAnimation.value,
          child: Container(
            margin: const EdgeInsets.symmetric(
              vertical: AppConstants.paddingMedium,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(theme),
                const SizedBox(height: AppConstants.spacingLarge),
                _buildCarousel(),
                const SizedBox(height: AppConstants.spacingMedium),
                _buildPageIndicator(theme),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppConstants.paddingMedium,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Sugestões de Conexão',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Pessoas compatíveis com você',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
            ],
          ),
          TextButton.icon(
            onPressed: () {
              HapticFeedback.lightImpact();
              context.go(AppRoutes.connections);
            },
            icon: const Icon(Icons.arrow_forward, size: 16),
            label: const Text('Ver mais'),
          ),
        ],
      ),
    );
  }

  Widget _buildCarousel() {
    return SizedBox(
      height: 140,
      child: PageView.builder(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() {
            _currentPage = index;
          });
        },
        itemCount: _suggestions.length,
        itemBuilder: (context, index) {
          final suggestion = _suggestions[index];
          final isCenter = index == _currentPage;

          return AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
            margin: EdgeInsets.symmetric(
              horizontal: 8,
              vertical: isCenter ? 0 : 10,
            ),
            child: _SuggestionCard(
              suggestion: suggestion,
              isSelected: isCenter,
              onTap: () => _handleSuggestionTap(suggestion),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPageIndicator(ThemeData theme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        _suggestions.length,
        (index) => AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: _currentPage == index ? 24 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: _currentPage == index
                ? theme.colorScheme.primary
                : theme.colorScheme.onSurface.withOpacity(0.3),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ),
    );
  }

  void _handleSuggestionTap(Map<String, dynamic> suggestion) {
    HapticFeedback.lightImpact();

    // Mostrar detalhes da sugestão
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _SuggestionDetails(suggestion: suggestion),
    );
  }
}

/// Card individual de sugestão
class _SuggestionCard extends StatefulWidget {
  final Map<String, dynamic> suggestion;
  final bool isSelected;
  final VoidCallback onTap;

  const _SuggestionCard({
    required this.suggestion,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_SuggestionCard> createState() => _SuggestionCardState();
}

class _SuggestionCardState extends State<_SuggestionCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _hoverController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    _hoverController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.05,
    ).animate(CurvedAnimation(parent: _hoverController, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _hoverController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final suggestion = widget.suggestion;
    final cardColor = suggestion['color'] as Color;

    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: GestureDetector(
            onTapDown: (_) => _hoverController.forward(),
            onTapUp: (_) {
              _hoverController.reverse();
              widget.onTap();
            },
            onTapCancel: () => _hoverController.reverse(),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [cardColor, cardColor.withOpacity(0.8)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(
                  AppConstants.cardBorderRadius,
                ),
                boxShadow: [
                  BoxShadow(
                    color: cardColor.withOpacity(0.3),
                    blurRadius: widget.isSelected ? 12 : 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Avatar emoji
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          suggestion['avatar'] as String,
                          style: const TextStyle(fontSize: 28),
                        ),
                      ),
                    ),

                    const SizedBox(height: 8),

                    // Nome
                    Text(
                      suggestion['name'] as String,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),

                    const SizedBox(height: 4),

                    // Match percentage
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${suggestion['match']}% match',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Modal de detalhes da sugestão
class _SuggestionDetails extends StatelessWidget {
  final Map<String, dynamic> suggestion;

  const _SuggestionDetails({required this.suggestion});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cardColor = suggestion['color'] as Color;
    final interests = suggestion['interests'] as List<String>;

    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: theme.colorScheme.onSurface.withOpacity(0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          const SizedBox(height: 24),

          // Avatar e info principal
          Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: cardColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    suggestion['avatar'] as String,
                    style: const TextStyle(fontSize: 32),
                  ),
                ),
              ),

              const SizedBox(width: 16),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      suggestion['name'] as String,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${suggestion['match']}% de compatibilidade',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: cardColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Interesses
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Interesses em comum:',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          const SizedBox(height: 8),

          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: interests.map((interest) {
              return Chip(
                label: Text(interest),
                backgroundColor: cardColor.withOpacity(0.1),
                labelStyle: TextStyle(
                  color: cardColor,
                  fontWeight: FontWeight.w500,
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 32),

          // Botões de ação
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Depois'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    // Navegar para conexões ou iniciar chat
                    context.go(AppRoutes.connections);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: cardColor,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Conectar'),
                ),
              ),
            ],
          ),

          // Espaço para o bottom safe area
          SizedBox(height: MediaQuery.of(context).padding.bottom),
        ],
      ),
    );
  }
}
