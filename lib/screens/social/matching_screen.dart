import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:unlock/data/mock_data_provider.dart';
import 'package:unlock/utils/helpers.dart';
import 'package:unlock/widgets/animated/animated_button.dart';

class MatchingScreen extends StatefulWidget {
  final List<String> interessesUsuario;

  const MatchingScreen({super.key, required this.interessesUsuario});

  @override
  State<MatchingScreen> createState() => _MatchingScreenState();
}

class _MatchingScreenState extends State<MatchingScreen>
    with TickerProviderStateMixin {
  late AnimationController _searchController;
  late AnimationController _resultsController;
  late Animation<double> _searchAnimation;
  late Animation<double> _pulseAnimation;

  bool _isSearching = true;
  List<Map<String, dynamic>> _foundConnections = [];
  String _searchingText = 'Buscando suas melhores conexões...';
  int _searchStep = 0;

  final List<String> _searchSteps = [
    'Analisando seus interesses...',
    'Encontrando pessoas compatíveis...',
    'Calculando distâncias...',
    'Verificando disponibilidade...',
    'Preparando resultados...',
  ];

  @override
  void initState() {
    super.initState();

    _searchController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _resultsController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _searchAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(_searchController);

    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _searchController, curve: Curves.easeInOut),
    );

    _startMatching();
  }

  _startMatching() async {
    _searchController.repeat(reverse: true);

    // Simula busca com etapas
    for (int i = 0; i < _searchSteps.length; i++) {
      await Future.delayed(const Duration(milliseconds: 800));
      if (mounted) {
        setState(() {
          _searchStep = i;
          _searchingText = _searchSteps[i];
        });
      }
    }

    // Gera conexões baseadas nos interesses do usuário
    final potentialConnections = _generateSmartConnections();

    setState(() {
      _foundConnections = potentialConnections;
      _isSearching = false;
    });

    _searchController.stop();
    _resultsController.forward();
  }

  List<Map<String, dynamic>> _generateSmartConnections() {
    final connections = List<Map<String, dynamic>>.from(
      MockDataProvider.potentialConnections,
    );

    // Ordena por compatibilidade com os interesses do usuário
    connections.sort((a, b) {
      final aInterests = a['interesses'] as List<String>;
      final bInterests = b['interesses'] as List<String>;

      final aCommonCount = widget.interessesUsuario
          .where((interest) => aInterests.contains(interest))
          .length;
      final bCommonCount = widget.interessesUsuario
          .where((interest) => bInterests.contains(interest))
          .length;

      return bCommonCount.compareTo(aCommonCount);
    });

    // Adiciona interesses comuns para melhorar o match
    for (var connection in connections.take(3)) {
      final connectionInterests = List<String>.from(connection['interesses']);

      // Adiciona 1-2 interesses do usuário se não tiver
      for (final userInterest in widget.interessesUsuario.take(2)) {
        if (!connectionInterests.contains(userInterest) &&
            connectionInterests.length < 4) {
          connectionInterests.add(userInterest);
        }
      }

      connection['interesses'] = connectionInterests;
      connection['compatibilityScore'] = _calculateCompatibility(connection);
    }

    return connections.take(3).toList();
  }

  double _calculateCompatibility(Map<String, dynamic> connection) {
    final connectionInterests = connection['interesses'] as List<String>;
    final commonInterests = widget.interessesUsuario
        .where((interest) => connectionInterests.contains(interest))
        .length;

    final maxPossible = math.min(
      widget.interessesUsuario.length,
      connectionInterests.length,
    );

    return maxPossible > 0 ? (commonInterests / maxPossible) * 100 : 0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            context.go('/home');
          },
        ),
        title: Text(
          _isSearching ? 'Buscando Conexões...' : 'Conexões Encontradas!',
        ),
        elevation: 0,
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 500),
        child: _isSearching ? _buildSearchingView() : _buildResultsView(),
      ),
    );
  }

  Widget _buildSearchingView() {
    return Container(
      key: const ValueKey('searching'),
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _pulseAnimation.value,
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        Theme.of(context).primaryColor.withOpacity(0.3),
                        Theme.of(context).primaryColor.withOpacity(0.1),
                        Colors.transparent,
                      ],
                    ),
                  ),
                  child: Center(
                    child: CircularProgressIndicator(
                      strokeWidth: 4,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Theme.of(context).primaryColor,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 40),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: Text(
              _searchingText,
              key: ValueKey(_searchStep),
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 16),
          LinearProgressIndicator(
            value: (_searchStep + 1) / _searchSteps.length,
            backgroundColor: Colors.grey[300],
            valueColor: AlwaysStoppedAnimation<Color>(
              Theme.of(context).primaryColor,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            '✨ Estamos preparando as melhores opções para você! ✨',
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildResultsView() {
    return Container(
      key: const ValueKey('results'),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.green.shade200),
            ),
            child: Column(
              children: [
                Icon(Icons.celebration, size: 32, color: Colors.green.shade600),
                const SizedBox(height: 8),
                const Text(
                  '🎉 Encontramos pessoas incríveis! 🎉',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Escolha quem você quer conhecer melhor:',
                  style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: ListView.builder(
              itemCount: _foundConnections.length,
              itemBuilder: (context, index) {
                return FadeTransition(
                  opacity: Tween<double>(begin: 0, end: 1).animate(
                    CurvedAnimation(
                      parent: _resultsController,
                      curve: Interval(
                        index * 0.2,
                        0.6 + (index * 0.2),
                        curve: Curves.easeOut,
                      ),
                    ),
                  ),
                  child: SlideTransition(
                    position:
                        Tween<Offset>(
                          begin: const Offset(1.0, 0.0),
                          end: Offset.zero,
                        ).animate(
                          CurvedAnimation(
                            parent: _resultsController,
                            curve: Interval(
                              index * 0.2,
                              0.6 + (index * 0.2),
                              curve: Curves.easeOut,
                            ),
                          ),
                        ),
                    child: _buildConnectionCard(_foundConnections[index]),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    AppHelpers.showCustomSnackBar(
                      context,
                      'Nenhuma conexão escolhida. Volte quando quiser! 😉',
                      icon: Icons.info,
                    );

                    Duration(seconds: 3);

                    context.go('/home');
                  },
                  icon: const Icon(Icons.arrow_back_ios_new_rounded),
                  label: const Text('Nao tenho interesse'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildConnectionCard(Map<String, dynamic> connection) {
    final compatibilityScore = connection['compatibilityScore'] ?? 0.0;
    final commonInterests = widget.interessesUsuario
        .where(
          (interest) =>
              (connection['interesses'] as List<String>).contains(interest),
        )
        .toList();

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Stack(
                    children: [
                      AppHelpers.buildUserAvatar(
                        avatarId: connection['avatarId'],
                        borderId: connection['borderId'],
                        radius: 32,
                      ),
                      if (connection['verified'] == true)
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: const BoxDecoration(
                              color: Colors.blue,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.verified,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                connection['nome'] as String,
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: _getCompatibilityColor(
                                  compatibilityScore,
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '${compatibilityScore.toInt()}% match',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Text(
                              '${connection['idade']} anos',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Icon(
                              Icons.location_on,
                              size: 16,
                              color: Colors.grey[600],
                            ),
                            Text(
                              connection['distance'] as String,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(
                              AppHelpers.getRelationshipIcon(
                                connection['relationshipInterest'],
                              ),
                              size: 16,
                              color: AppHelpers.getRelationshipColor(
                                connection['relationshipInterest'],
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              connection['relationshipInterest'] as String,
                              style: TextStyle(
                                fontSize: 12,
                                color: AppHelpers.getRelationshipColor(
                                  connection['relationshipInterest'],
                                ),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                connection['bio'] as String,
                style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              if (commonInterests.isNotEmpty) ...[
                Text(
                  'Interesses em comum:',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: commonInterests.map((interest) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green.shade100,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.green.shade300),
                      ),
                      child: Text(
                        interest,
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.green.shade700,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 12),
              ],
              SizedBox(
                width: double.infinity,
                child: AnimatedButton(
                  onPressed: () {
                    // Navigator.pushReplacement(
                    //   context,
                    //   MaterialPageRoute(
                    //     builder: (context) => ConnectionTestScreen(
                    //       chosenConnection: connection,
                    //       userInterests: widget.interessesUsuario,
                    //     ),
                    //   ),
                    // );
                    context.go(
                      '/connection-test',
                      extra: {
                        'userInterests': commonInterests,
                        'chosenConnection': connection,
                      },
                    );
                  },
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.psychology, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Testar Conexão',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getCompatibilityColor(double score) {
    if (score >= 80) return Colors.green;
    if (score >= 60) return Colors.orange;
    return Colors.grey;
  }

  @override
  void dispose() {
    _searchController.dispose();
    _resultsController.dispose();
    super.dispose();
  }
}
