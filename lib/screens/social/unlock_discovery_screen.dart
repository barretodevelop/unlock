// lib/screens/social/unlock_discovery_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:unlock/enums/enums.dart';
import 'package:unlock/models/affinity_test_model.dart';
import 'package:unlock/models/unlock_match_model.dart';
import 'package:unlock/providers/auth_provider.dart';
import 'package:unlock/providers/unlock_matching_provider.dart';
import 'package:unlock/widgets/animated/bounce_widget.dart';
import 'package:unlock/widgets/animated/fade_in_widget.dart';

class UnlockDiscoveryScreen extends ConsumerStatefulWidget {
  const UnlockDiscoveryScreen({super.key});

  @override
  ConsumerState<UnlockDiscoveryScreen> createState() =>
      _UnlockDiscoveryScreenState();
}

class _UnlockDiscoveryScreenState extends ConsumerState<UnlockDiscoveryScreen>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadMatches();
    });
  }

  void _initializeAnimations() {
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  void _loadMatches() {
    final user = ref.read(authProvider).user;
    if (user != null) {
      ref.read(unlockMatchingProvider.notifier).findPotentialMatches(user);
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final potentialMatches = ref.watch(potentialMatchesProvider);
    final activeMatches = ref.watch(activeMatchesProvider);
    final unlockedMatches = ref.watch(unlockedMatchesProvider);
    final isLoading = ref.watch(isMatchingLoadingProvider);
    final canCreateMatches = ref.watch(canCreateMatchesProvider);
    final stats = ref.watch(matchingStatsProvider);

    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      appBar: AppBar(
        title: const Text('🔓 Descobrir'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(onPressed: _loadMatches, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => _loadMatches(),
        child: CustomScrollView(
          slivers: [
            // Header com estatísticas
            SliverToBoxAdapter(
              child: _buildStatsHeader(theme, stats, canCreateMatches),
            ),

            // Matches ativos (se houver)
            if (activeMatches.isNotEmpty) ...[
              SliverToBoxAdapter(
                child: _buildSectionTitle('Testes em Andamento', theme),
              ),
              SliverToBoxAdapter(
                child: _buildActiveMatchesSection(activeMatches, theme),
              ),
            ],

            // Matches desbloqueados (se houver)
            if (unlockedMatches.isNotEmpty) ...[
              SliverToBoxAdapter(
                child: _buildSectionTitle('Perfis Desbloqueados', theme),
              ),
              SliverToBoxAdapter(
                child: _buildUnlockedMatchesSection(unlockedMatches, theme),
              ),
            ],

            // Novos matches potenciais
            SliverToBoxAdapter(
              child: _buildSectionTitle('Descobrir Novas Conexões', theme),
            ),

            if (isLoading)
              const SliverToBoxAdapter(
                child: Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: CircularProgressIndicator(),
                  ),
                ),
              )
            else if (potentialMatches.isEmpty)
              SliverToBoxAdapter(child: _buildEmptyState(theme))
            else
              SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 0.8,
                  ),
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final match = potentialMatches[index];
                    return FadeInWidget(
                      delay: Duration(milliseconds: index * 100),
                      child: _buildMatchCard(match, theme, canCreateMatches),
                    );
                  }, childCount: potentialMatches.length),
                ),
              ),

            // Espaço extra no final
            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsHeader(
    ThemeData theme,
    Map<String, dynamic> stats,
    bool canCreateMatches,
  ) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primary.withOpacity(0.1),
            theme.colorScheme.secondary.withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.primary.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem(
                '${stats['unlockedMatches']}',
                'Desbloqueados',
                Icons.lock_open,
                Colors.green,
                theme,
              ),
              _buildStatItem(
                '${stats['activeMatches']}',
                'Em Teste',
                Icons.psychology,
                Colors.orange,
                theme,
              ),
              _buildStatItem(
                '${stats['dailyMatchesRemaining']}',
                'Restantes Hoje',
                Icons.today,
                canCreateMatches ? Colors.blue : Colors.red,
                theme,
              ),
            ],
          ),
          const SizedBox(height: 16),
          LinearProgressIndicator(
            value: stats['successRate'] / 100,
            backgroundColor: theme.colorScheme.surfaceVariant,
            valueColor: AlwaysStoppedAnimation<Color>(
              theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Taxa de Sucesso: ${stats['successRate'].toStringAsFixed(1)}%',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(
    String value,
    String label,
    IconData icon,
    Color color,
    ThemeData theme,
  ) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Text(
        title,
        style: theme.textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildActiveMatchesSection(
    List<UnlockMatchModel> matches,
    ThemeData theme,
  ) {
    return SizedBox(
      height: 200,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: matches.length,
        itemBuilder: (context, index) {
          final match = matches[index];
          return Container(
            width: 160,
            margin: const EdgeInsets.only(right: 16),
            child: _buildActiveMatchCard(match, theme),
          );
        },
      ),
    );
  }

  Widget _buildUnlockedMatchesSection(
    List<UnlockMatchModel> matches,
    ThemeData theme,
  ) {
    return SizedBox(
      height: 120,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: matches.length,
        itemBuilder: (context, index) {
          final match = matches[index];
          return Container(
            width: 100,
            margin: const EdgeInsets.only(right: 16),
            child: _buildUnlockedMatchCard(match, theme),
          );
        },
      ),
    );
  }

  Widget _buildMatchCard(
    UnlockMatchModel match,
    ThemeData theme,
    bool canCreateMatches,
  ) {
    return BounceWidget(
      onTap: canCreateMatches
          ? () => _startMatch(match)
          : () => _showDailyLimitReached(),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              theme.colorScheme.primary.withOpacity(0.1),
              theme.colorScheme.secondary.withOpacity(0.1),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: theme.colorScheme.primary.withOpacity(0.3)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Avatar/Emoji
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary,
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Center(
                  child: Text(
                    match.targetCodinome.isNotEmpty
                        ? match.targetCodinome[0].toUpperCase()
                        : '?',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // Codinome
              Text(
                match.targetCodinome,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),

              const SizedBox(height: 8),

              // Score de compatibilidade
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getScoreColor(
                    match.compatibilityScore,
                  ).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${match.compatibilityScore.round()}% compatível',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: _getScoreColor(match.compatibilityScore),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),

              const SizedBox(height: 8),

              // Interesses comuns
              if (match.commonInterests.isNotEmpty)
                Wrap(
                  spacing: 4,
                  children: match.commonInterests.take(3).map((interest) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceVariant,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(interest, style: theme.textTheme.bodySmall),
                    );
                  }).toList(),
                ),

              const Spacer(),

              // Botão de ação
              if (canCreateMatches)
                AnimatedBuilder(
                  animation: _pulseAnimation,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.psychology,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _pulseAnimation.value,
                      child: child,
                    );
                  },
                )
              else
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.outline,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.lock, color: Colors.white, size: 20),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActiveMatchCard(UnlockMatchModel match, ThemeData theme) {
    return BounceWidget(
      onTap: () => _continueTest(match),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.orange.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: Colors.orange.withOpacity(0.2),
              child: Text(
                match.targetCodinome[0].toUpperCase(),
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              match.targetCodinome,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: match.testProgress,
              backgroundColor: theme.colorScheme.surfaceVariant,
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.orange),
            ),
            const SizedBox(height: 4),
            Text(
              '${match.completedTests.length}/${match.totalTestsRequired} testes',
              style: theme.textTheme.bodySmall,
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.orange,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.play_arrow,
                color: Colors.white,
                size: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUnlockedMatchCard(UnlockMatchModel match, ThemeData theme) {
    return BounceWidget(
      onTap: () => _openUnlockedProfile(match),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [Colors.green, Colors.teal]),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            CircleAvatar(
              radius: 25,
              backgroundColor: Colors.white.withOpacity(0.2),
              child: Text(
                match.targetCodinome[0].toUpperCase(),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              match.targetCodinome,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const Icon(Icons.lock_open, color: Colors.white, size: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          Icon(Icons.search_off, size: 64, color: theme.colorScheme.outline),
          const SizedBox(height: 16),
          Text(
            'Nenhuma nova conexão encontrada',
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Volte mais tarde para descobrir novas pessoas',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadMatches,
            child: const Text('Tentar Novamente'),
          ),
        ],
      ),
    );
  }

  Color _getScoreColor(double score) {
    if (score >= 80) return Colors.green;
    if (score >= 60) return Colors.orange;
    return Colors.red;
  }

  void _startMatch(UnlockMatchModel match) {
    ref.read(unlockMatchingProvider.notifier).startMatch(match.targetUserId);

    // Navegar para tela de teste
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => UnlockAffinityTestScreen(match: match),
      ),
    );
  }

  void _continueTest(UnlockMatchModel match) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => UnlockAffinityTestScreen(match: match),
      ),
    );
  }

  void _openUnlockedProfile(UnlockMatchModel match) {
    // Navegar para perfil completo desbloqueado
    // Navigator.push(context, MaterialPageRoute(...));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Perfil de ${match.targetCodinome} desbloqueado! 🎉'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _showDailyLimitReached() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Limite diário de matches atingido. Volte amanhã!'),
        backgroundColor: Colors.red,
      ),
    );
  }
}

// lib/screens/social/unlock_affinity_test_screen.dart
class UnlockAffinityTestScreen extends ConsumerStatefulWidget {
  final UnlockMatchModel match;

  const UnlockAffinityTestScreen({super.key, required this.match});

  @override
  ConsumerState<UnlockAffinityTestScreen> createState() =>
      _UnlockAffinityTestScreenState();
}

class _UnlockAffinityTestScreenState
    extends ConsumerState<UnlockAffinityTestScreen>
    with TickerProviderStateMixin {
  late AnimationController _timerController;
  late AnimationController _questionController;
  late Animation<double> _questionAnimation;

  String? _selectedAnswer;
  DateTime? _testStartTime;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startTest();
    });
  }

  void _initializeAnimations() {
    _timerController = AnimationController(
      duration: const Duration(minutes: 2), // 2 minutos por teste
      vsync: this,
    );

    _questionController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _questionAnimation = CurvedAnimation(
      parent: _questionController,
      curve: Curves.easeOutBack,
    );

    _timerController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _autoSubmit();
      }
    });
  }

  void _startTest() {
    _testStartTime = DateTime.now();
    ref
        .read(unlockMatchingProvider.notifier)
        .startAffinityTest(widget.match.id);
    _questionController.forward();
    _timerController.forward();
  }

  void _autoSubmit() {
    if (_selectedAnswer == null) {
      _submitAnswer(''); // Resposta vazia por timeout
    } else {
      _submitAnswer(_selectedAnswer!);
    }
  }

  void _submitAnswer(String answer) {
    ref.read(unlockMatchingProvider.notifier).submitTestAnswer(answer);
    _showResultAndContinue();
  }

  void _showResultAndContinue() {
    // Aguardar um pouco para mostrar resultado
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        final match = ref
            .read(unlockMatchingProvider.notifier)
            .getMatchById(widget.match.id);

        if (match?.isUnlocked == true) {
          _showUnlockSuccess();
        } else if (match?.canTakeTests == true) {
          _startNextTest();
        } else {
          _navigateBack();
        }
      }
    });
  }

  void _showUnlockSuccess() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('🎉 Perfil Desbloqueado!'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.lock_open, size: 64, color: Colors.green),
            const SizedBox(height: 16),
            Text(
              'Você desbloqueou o perfil de ${widget.match.targetCodinome}!',
            ),
            const SizedBox(height: 8),
            const Text('Agora vocês podem conversar livremente.'),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _navigateBack();
            },
            child: const Text('Continuar'),
          ),
        ],
      ),
    );
  }

  void _startNextTest() {
    _selectedAnswer = null;
    _testStartTime = DateTime.now();
    _timerController.reset();
    _questionController.reset();

    ref
        .read(unlockMatchingProvider.notifier)
        .startAffinityTest(widget.match.id);
    _questionController.forward();
    _timerController.forward();
  }

  void _navigateBack() {
    Navigator.of(context).pop();
  }

  @override
  void dispose() {
    _timerController.dispose();
    _questionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currentTest = ref.watch(currentTestProvider);
    final isTakingTest = ref.watch(isTakingTestProvider);
    final isLoading = ref.watch(isMatchingLoadingProvider);

    if (currentTest == null || !isTakingTest) {
      return Scaffold(
        appBar: AppBar(title: const Text('Teste de Afinidade')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Teste com ${widget.match.targetCodinome}'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () => _showSkipDialog(),
            icon: const Icon(Icons.skip_next),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Timer e progresso
            _buildTimerSection(theme),

            const SizedBox(height: 24),

            // Pergunta
            _buildQuestionSection(currentTest, theme),

            const SizedBox(height: 32),

            // Opções de resposta
            _buildAnswerOptions(currentTest, theme),

            const Spacer(),

            // Botão de submeter
            _buildSubmitButton(theme, isLoading),
          ],
        ),
      ),
    );
  }

  Widget _buildTimerSection(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Progresso: ${widget.match.completedTests.length + 1}/${widget.match.totalTestsRequired}',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Icon(Icons.timer, size: 20),
            ],
          ),
          const SizedBox(height: 8),
          AnimatedBuilder(
            animation: _timerController,
            builder: (context, child) {
              return LinearProgressIndicator(
                value: _timerController.value,
                backgroundColor: theme.colorScheme.outline.withOpacity(0.3),
                valueColor: AlwaysStoppedAnimation<Color>(
                  _timerController.value > 0.7
                      ? Colors.red
                      : theme.colorScheme.primary,
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionSection(AffinityTestModel test, ThemeData theme) {
    return ScaleTransition(
      scale: _questionAnimation,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              theme.colorScheme.primary.withOpacity(0.1),
              theme.colorScheme.secondary.withOpacity(0.1),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: theme.colorScheme.primary.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(
              _getTestTypeIcon(test.type),
              size: 32,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              test.question,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                _getTestTypeLabel(test.type),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnswerOptions(AffinityTestModel test, ThemeData theme) {
    return Column(
      children: test.options.asMap().entries.map((entry) {
        final index = entry.key;
        final option = entry.value;
        final isSelected = _selectedAnswer == option;

        return FadeInWidget(
          delay: Duration(milliseconds: 200 + (index * 100)),
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            child: BounceWidget(
              onTap: () => setState(() => _selectedAnswer = option),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isSelected
                      ? theme.colorScheme.primary.withOpacity(0.2)
                      : theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected
                        ? theme.colorScheme.primary
                        : theme.colorScheme.outline.withOpacity(0.3),
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isSelected
                            ? theme.colorScheme.primary
                            : Colors.transparent,
                        border: Border.all(
                          color: isSelected
                              ? theme.colorScheme.primary
                              : theme.colorScheme.outline,
                        ),
                      ),
                      child: isSelected
                          ? const Icon(
                              Icons.check,
                              size: 16,
                              color: Colors.white,
                            )
                          : null,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        option,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          fontWeight: isSelected
                              ? FontWeight.w600
                              : FontWeight.normal,
                          color: isSelected ? theme.colorScheme.primary : null,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSubmitButton(ThemeData theme, bool isLoading) {
    final canSubmit = _selectedAnswer != null && !isLoading;

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: canSubmit ? () => _submitAnswer(_selectedAnswer!) : null,
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.all(16),
          backgroundColor: theme.colorScheme.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Text(
                'Confirmar Resposta',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }

  void _showSkipDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Pular Teste'),
        content: const Text(
          'Tem certeza que deseja pular este teste? '
          'Você receberá pontuação mínima.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              ref.read(unlockMatchingProvider.notifier).skipCurrentTest();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text('Pular'),
          ),
        ],
      ),
    );
  }

  IconData _getTestTypeIcon(TestType type) {
    switch (type) {
      case TestType.interests:
        return Icons.favorite;
      case TestType.personality:
        return Icons.psychology;
      case TestType.lifestyle:
        return Icons.library_add_check;
      case TestType.values1:
        return Icons.stars;
      case TestType.quickFire:
        return Icons.flash_on;
    }
  }

  String _getTestTypeLabel(TestType type) {
    switch (type) {
      case TestType.interests:
        return 'Interesses';
      case TestType.personality:
        return 'Personalidade';
      case TestType.lifestyle:
        return 'Estilo de Vida';
      case TestType.values1:
        return 'Valores';
      case TestType.quickFire:
        return 'Resposta Rápida';
    }
  }
}
