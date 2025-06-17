// lib/screens/enhanced_matching_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:unlock/feature/social/providers/discovery_provider.dart';
import 'package:unlock/feature/social/providers/test_invite_provider.dart';
import 'package:unlock/models/user_model.dart';
import 'package:unlock/utils/helpers.dart';
import 'package:unlock/widgtes/animated_button.dart';

class EnhancedMatchingScreen extends ConsumerStatefulWidget {
  final List<String> interessesUsuario;

  const EnhancedMatchingScreen({super.key, required this.interessesUsuario});

  @override
  ConsumerState<EnhancedMatchingScreen> createState() =>
      _EnhancedMatchingScreenState();
}

class _EnhancedMatchingScreenState extends ConsumerState<EnhancedMatchingScreen>
    with TickerProviderStateMixin {
  late AnimationController _searchController;
  late AnimationController _resultsController;
  late Animation<double> _searchAnimation;
  late Animation<double> _pulseAnimation;

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

    // Atualizar atividade do usuário
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(discoveryProvider.notifier).updateUserActivity();
      _startSearch();
    });
  }

  void _startSearch() async {
    _searchController.repeat(reverse: true);

    // Iniciar busca de usuários compatíveis
    await ref.read(discoveryProvider.notifier).findCompatibleUsers();

    _searchController.stop();
    _resultsController.forward();
  }

  @override
  Widget build(BuildContext context) {
    final discoveryState = ref.watch(discoveryProvider);
    final testInviteState = ref.watch(testInviteProvider);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        shadowColor: Colors.black12,
        leading: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(12),
          ),
          child: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, size: 20),
            onPressed: () => context.go('/home'),
          ),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              discoveryState.isSearching
                  ? 'Buscando Conexões...'
                  : 'Conexões Encontradas!',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            if (!discoveryState.isSearching && discoveryState.hasResults)
              Text(
                '${discoveryState.compatibleUsers.length} pessoas encontradas',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.normal,
                ),
              ),
          ],
        ),
        toolbarHeight: 70,
      ),
      body: _buildBody(discoveryState, testInviteState),
    );
  }

  Widget _buildBody(
    DiscoveryState discoveryState,
    TestInviteState testInviteState,
  ) {
    // Mostrar erro se houver
    if (discoveryState.error != null) {
      return _buildErrorView(discoveryState.error!);
    }

    // Mostrar busca se ainda está procurando
    if (discoveryState.isSearching) {
      return _buildSearchingView(discoveryState);
    }

    // Mostrar resultados se encontrou usuários
    if (discoveryState.hasResults) {
      return _buildResultsView(discoveryState, testInviteState);
    }

    // Mostrar vazio se não encontrou ninguém
    return _buildEmptyView();
  }

  Widget _buildSearchingView(DiscoveryState discoveryState) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.blue.shade50, Colors.white, Colors.purple.shade50],
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Animação de busca melhorada
              AnimatedBuilder(
                animation: _pulseAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _pulseAnimation.value,
                    child: Container(
                      width: 140,
                      height: 140,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Theme.of(
                              context,
                            ).primaryColor.withOpacity(0.3),
                            blurRadius: 20,
                            spreadRadius: 5,
                          ),
                        ],
                        gradient: RadialGradient(
                          colors: [
                            Theme.of(context).primaryColor.withOpacity(0.2),
                            Theme.of(context).primaryColor.withOpacity(0.1),
                            Colors.transparent,
                          ],
                        ),
                      ),
                      child: Center(
                        child: Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 10,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: Center(
                            child: CircularProgressIndicator(
                              strokeWidth: 3,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Theme.of(context).primaryColor,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),

              const SizedBox(height: 48),

              // Texto principal
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: Text(
                  ref.read(discoveryProvider.notifier).currentSearchStep,
                  key: ValueKey(discoveryState.searchStep),
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),

              const SizedBox(height: 24),

              // Progress bar melhorada
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Progresso',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          '${((discoveryState.searchStep + 1) / 5 * 100).toInt()}%',
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(context).primaryColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: LinearProgressIndicator(
                        value: (discoveryState.searchStep + 1) / 5,
                        backgroundColor: Colors.grey[200],
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Theme.of(context).primaryColor,
                        ),
                        minHeight: 6,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Cards informativos
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.search,
                            color: Colors.blue.shade600,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Analisando ${discoveryState.availableUsers.length} usuários online',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.purple.shade50,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.auto_awesome,
                            color: Colors.purple.shade600,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            'Preparando as melhores opções para você',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.black54,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResultsView(
    DiscoveryState discoveryState,
    TestInviteState testInviteState,
  ) {
    return Column(
      children: [
        // Header de sucesso compacto
        Container(
          width: double.infinity,
          margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.green.shade400, Colors.green.shade600],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.green.withOpacity(0.3),
                blurRadius: 10,
                spreadRadius: 1,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.celebration,
                  size: 24,
                  color: Colors.green.shade600,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Pessoas incríveis encontradas! 🎉',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '${discoveryState.availableUsers.length} usuários online',
                          style: const TextStyle(
                            fontSize: 13,
                            color: Colors.white,
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
        ),

        // Lista de usuários compatíveis
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: discoveryState.compatibleUsers.length,
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
                  child: _buildConnectionCard(
                    discoveryState.compatibleUsers[index],
                    testInviteState,
                  ),
                ),
              );
            },
          ),
        ),

        // Botão para buscar novamente
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: SafeArea(
            child: AnimatedButton(
              onPressed: () => _startSearch(),
              backgroundColor: Colors.blue.shade600,
              foregroundColor: Colors.white,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.refresh, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Buscar Novamente',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildConnectionCard(UserModel user, TestInviteState testInviteState) {
    final compatibilityScore = _calculateDisplayCompatibility(user);
    final commonInterests = _getCommonInterests(user);
    final isLoading = testInviteState.isLoading;

    // Verificar se já existe convite pendente
    final hasPendingInvite = testInviteState.sentInvites.any(
      (invite) => invite.receiverId == user.uid && invite.canRespond,
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 15,
            spreadRadius: 1,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header do usuário
            Row(
              children: [
                Stack(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: _getCompatibilityColor(
                            compatibilityScore,
                          ).withOpacity(0.3),
                          width: 3,
                        ),
                      ),
                      child: AppHelpers.buildUserAvatar(
                        avatarId: user.avatar,
                        radius: 32,
                      ),
                    ),
                    // Status online melhorado
                    Positioned(
                      right: 2,
                      bottom: 2,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: Colors.green.shade500,
                            shape: BoxShape.circle,
                          ),
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
                              user.preferredDisplayName,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  _getCompatibilityColor(compatibilityScore),
                                  _getCompatibilityColor(
                                    compatibilityScore,
                                  ).withOpacity(0.8),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(15),
                              boxShadow: [
                                BoxShadow(
                                  color: _getCompatibilityColor(
                                    compatibilityScore,
                                  ).withOpacity(0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
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
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade50,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'Nível ${user.level}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.blue.shade700,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            Icons.location_on,
                            size: 14,
                            color: Colors.grey[500],
                          ),
                          const SizedBox(width: 2),
                          Text(
                            'Próximo',
                            style: TextStyle(
                              fontSize: 12,
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
                              user.relationshipInterest,
                            ),
                            size: 16,
                            color: AppHelpers.getRelationshipColor(
                              user.relationshipInterest,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            user.relationshipInterest ?? 'Não informado',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppHelpers.getRelationshipColor(
                                user.relationshipInterest,
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

            // Interesses em comum
            if (commonInterests.isNotEmpty) ...[
              const SizedBox(height: 20),
              Row(
                children: [
                  Icon(Icons.favorite, size: 16, color: Colors.pink.shade400),
                  const SizedBox(width: 6),
                  Text(
                    'Interesses em comum:',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[700],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: commonInterests.map((interest) {
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.green.shade100, Colors.green.shade50],
                      ),
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(
                        color: Colors.green.shade200,
                        width: 1,
                      ),
                    ),
                    child: Text(
                      interest,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.green.shade700,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],

            const SizedBox(height: 20),

            // Botão de ação melhorado
            AnimatedButton(
              onPressed: hasPendingInvite || isLoading
                  ? null
                  : () => _sendTestInvite(user),
              backgroundColor: hasPendingInvite
                  ? Colors.orange.shade500
                  : Theme.of(context).primaryColor,
              foregroundColor: Colors.white,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (isLoading)
                      const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      )
                    else
                      Icon(
                        hasPendingInvite ? Icons.schedule : Icons.psychology,
                        size: 22,
                      ),
                    const SizedBox(width: 12),
                    Text(
                      hasPendingInvite
                          ? 'Convite Enviado'
                          : 'Enviar Convite de Teste',
                      style: const TextStyle(
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
    );
  }

  Widget _buildEmptyView() {
    return Container(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.search_off, size: 60, color: Colors.grey[400]),
          ),
          const SizedBox(height: 32),
          Text(
            'Nenhum usuário compatível encontrado',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            'Tente novamente em alguns minutos ou ajuste seus interesses.',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[500],
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 40),
          AnimatedButton(
            onPressed: () => _startSearch(),
            backgroundColor: Theme.of(context).primaryColor,
            foregroundColor: Colors.white,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.refresh, size: 22),
                  SizedBox(width: 12),
                  Text(
                    'Tentar Novamente',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorView(String error) {
    return Container(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.error_outline, size: 60, color: Colors.red[400]),
          ),
          const SizedBox(height: 32),
          const Text(
            'Ops! Algo deu errado',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.red,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              error,
              style: TextStyle(
                fontSize: 14,
                color: Colors.red.shade700,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 40),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => context.go('/home'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Voltar',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: AnimatedButton(
                  onPressed: () {
                    ref.read(discoveryProvider.notifier).clearResults();
                    _startSearch();
                  },
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: const Text(
                      'Tentar Novamente',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
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

  // ============== MÉTODOS AUXILIARES ==============

  Future<void> _sendTestInvite(UserModel user) async {
    final success = await ref
        .read(testInviteProvider.notifier)
        .sendTestInvite(user);

    if (success && mounted) {
      AppHelpers.showCustomSnackBar(
        context,
        '📨 Convite enviado para ${user.preferredDisplayName}!',
        backgroundColor: Colors.green,
        icon: Icons.send,
      );
    } else if (mounted) {
      final error = ref.read(testInviteProvider).error ?? 'Erro desconhecido';
      AppHelpers.showCustomSnackBar(
        context,
        error,
        backgroundColor: Colors.red,
        icon: Icons.error,
      );
    }
  }

  double _calculateDisplayCompatibility(UserModel user) {
    // Simular cálculo de compatibilidade para exibição
    // Na implementação real, isso viria do algoritmo do DiscoveryProvider
    final commonInterests = _getCommonInterests(user);
    final maxInterests = widget.interessesUsuario.length;

    if (maxInterests == 0) return 50.0;

    final baseScore = (commonInterests.length / maxInterests) * 80;
    final randomBonus = (user.level % 20)
        .toDouble(); // Baseado no nível para consistência

    return (baseScore + randomBonus).clamp(0.0, 100.0);
  }

  List<String> _getCommonInterests(UserModel user) {
    return widget.interessesUsuario
        .where((interest) => user.interesses.contains(interest))
        .toList();
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

// class EnhancedMatchingScreen extends ConsumerStatefulWidget {
//   final List<String> interessesUsuario;

//   const EnhancedMatchingScreen({super.key, required this.interessesUsuario});

//   @override
//   ConsumerState<EnhancedMatchingScreen> createState() =>
//       _EnhancedMatchingScreenState();
// }

// class _EnhancedMatchingScreenState extends ConsumerState<EnhancedMatchingScreen>
//     with TickerProviderStateMixin {
//   late AnimationController _searchController;
//   late AnimationController _resultsController;
//   late Animation<double> _searchAnimation;
//   late Animation<double> _pulseAnimation;

//   @override
//   void initState() {
//     super.initState();

//     _searchController = AnimationController(
//       duration: const Duration(seconds: 2),
//       vsync: this,
//     );

//     _resultsController = AnimationController(
//       duration: const Duration(milliseconds: 1200),
//       vsync: this,
//     );

//     _searchAnimation = Tween<double>(
//       begin: 0.0,
//       end: 1.0,
//     ).animate(_searchController);

//     _pulseAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
//       CurvedAnimation(parent: _searchController, curve: Curves.easeInOut),
//     );

//     // Atualizar atividade do usuário
//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       ref.read(discoveryProvider.notifier).updateUserActivity();
//       _startSearch();
//     });
//   }

//   void _startSearch() async {
//     _searchController.repeat(reverse: true);

//     // Iniciar busca de usuários compatíveis
//     await ref.read(discoveryProvider.notifier).findCompatibleUsers();

//     _searchController.stop();
//     _resultsController.forward();
//   }

//   @override
//   Widget build(BuildContext context) {
//     final discoveryState = ref.watch(discoveryProvider);
//     final testInviteState = ref.watch(testInviteProvider);

//     return Scaffold(
//       appBar: AppBar(
//         leading: IconButton(
//           icon: const Icon(Icons.arrow_back),
//           onPressed: () => context.go('/home'),
//         ),
//         title: Text(
//           discoveryState.isSearching
//               ? 'Buscando Conexões...'
//               : 'Conexões Encontradas!',
//         ),
//         elevation: 0,
//       ),
//       body: _buildBody(discoveryState, testInviteState),
//     );
//   }

//   Widget _buildBody(
//     DiscoveryState discoveryState,
//     TestInviteState testInviteState,
//   ) {
//     // Mostrar erro se houver
//     if (discoveryState.error != null) {
//       return _buildErrorView(discoveryState.error!);
//     }

//     // Mostrar busca se ainda está procurando
//     if (discoveryState.isSearching) {
//       return _buildSearchingView(discoveryState);
//     }

//     // Mostrar resultados se encontrou usuários
//     if (discoveryState.hasResults) {
//       return _buildResultsView(discoveryState, testInviteState);
//     }

//     // Mostrar vazio se não encontrou ninguém
//     return _buildEmptyView();
//   }

//   Widget _buildSearchingView(DiscoveryState discoveryState) {
//     return Container(
//       padding: const EdgeInsets.all(24),
//       child: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           AnimatedBuilder(
//             animation: _pulseAnimation,
//             builder: (context, child) {
//               return Transform.scale(
//                 scale: _pulseAnimation.value,
//                 child: Container(
//                   width: 120,
//                   height: 120,
//                   decoration: BoxDecoration(
//                     shape: BoxShape.circle,
//                     gradient: RadialGradient(
//                       colors: [
//                         Theme.of(context).primaryColor.withOpacity(0.3),
//                         Theme.of(context).primaryColor.withOpacity(0.1),
//                         Colors.transparent,
//                       ],
//                     ),
//                   ),
//                   child: Center(
//                     child: CircularProgressIndicator(
//                       strokeWidth: 4,
//                       valueColor: AlwaysStoppedAnimation<Color>(
//                         Theme.of(context).primaryColor,
//                       ),
//                     ),
//                   ),
//                 ),
//               );
//             },
//           ),
//           const SizedBox(height: 40),
//           AnimatedSwitcher(
//             duration: const Duration(milliseconds: 300),
//             child: Text(
//               ref.read(discoveryProvider.notifier).currentSearchStep,
//               key: ValueKey(discoveryState.searchStep),
//               style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
//               textAlign: TextAlign.center,
//             ),
//           ),
//           const SizedBox(height: 16),
//           LinearProgressIndicator(
//             value: (discoveryState.searchStep + 1) / 5, // 5 steps total
//             backgroundColor: Colors.grey[300],
//             valueColor: AlwaysStoppedAnimation<Color>(
//               Theme.of(context).primaryColor,
//             ),
//           ),
//           const SizedBox(height: 24),
//           Text(
//             '🔍 Analisando ${discoveryState.availableUsers.length} usuários online...',
//             style: TextStyle(fontSize: 16, color: Colors.grey[600]),
//             textAlign: TextAlign.center,
//           ),
//           const SizedBox(height: 16),
//           Text(
//             '✨ Estamos preparando as melhores opções para você! ✨',
//             style: TextStyle(fontSize: 14, color: Colors.grey[500]),
//             textAlign: TextAlign.center,
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildResultsView(
//     DiscoveryState discoveryState,
//     TestInviteState testInviteState,
//   ) {
//     return Container(
//       padding: const EdgeInsets.all(16),
//       child: Column(
//         children: [
//           // Header de sucesso
//           CustomCard(
//             // backgroundColor: Colors.green.shade50,
//             // borderColor: Colors.green.shade200,
//             borderRadius: 0,
//             child: Column(
//               children: [
//                 Icon(Icons.celebration, size: 32, color: Colors.green.shade600),
//                 const SizedBox(height: 8),
//                 const Text(
//                   '🎉 Encontramos pessoas incríveis! 🎉',
//                   style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
//                   textAlign: TextAlign.center,
//                 ),
//                 const SizedBox(height: 8),
//                 Text(
//                   'Escolha quem você quer conhecer melhor:',
//                   style: TextStyle(fontSize: 16, color: Colors.grey[700]),
//                   textAlign: TextAlign.center,
//                 ),
//                 const SizedBox(height: 12),
//                 Container(
//                   padding: const EdgeInsets.symmetric(
//                     horizontal: 12,
//                     vertical: 6,
//                   ),
//                   decoration: BoxDecoration(
//                     color: Colors.blue.shade100,
//                     borderRadius: BorderRadius.circular(16),
//                   ),
//                   child: Text(
//                     '${discoveryState.availableUsers.length} usuários online agora',
//                     style: TextStyle(
//                       fontSize: 14,
//                       color: Colors.blue.shade700,
//                       fontWeight: FontWeight.w500,
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//           const SizedBox(height: 20),

//           // Lista de usuários compatíveis
//           Expanded(
//             child: ListView.builder(
//               itemCount: discoveryState.compatibleUsers.length,
//               itemBuilder: (context, index) {
//                 return FadeTransition(
//                   opacity: Tween<double>(begin: 0, end: 1).animate(
//                     CurvedAnimation(
//                       parent: _resultsController,
//                       curve: Interval(
//                         index * 0.2,
//                         0.6 + (index * 0.2),
//                         curve: Curves.easeOut,
//                       ),
//                     ),
//                   ),
//                   child: SlideTransition(
//                     position:
//                         Tween<Offset>(
//                           begin: const Offset(1.0, 0.0),
//                           end: Offset.zero,
//                         ).animate(
//                           CurvedAnimation(
//                             parent: _resultsController,
//                             curve: Interval(
//                               index * 0.2,
//                               0.6 + (index * 0.2),
//                               curve: Curves.easeOut,
//                             ),
//                           ),
//                         ),
//                     child: _buildConnectionCard(
//                       discoveryState.compatibleUsers[index],
//                       testInviteState,
//                     ),
//                   ),
//                 );
//               },
//             ),
//           ),

//           const SizedBox(height: 16),

//           // Botão para buscar novamente
//           Row(
//             children: [
//               Expanded(
//                 child: AnimatedButton(
//                   onPressed: () => _startSearch(),
//                   backgroundColor: Colors.blue,
//                   foregroundColor: Colors.white,
//                   child: Row(
//                     mainAxisAlignment: MainAxisAlignment.center,
//                     children: [
//                       const Icon(Icons.refresh, size: 18),
//                       const SizedBox(width: 8),
//                       const Flexible(
//                         child: Text(
//                           'Buscar Novamente',
//                           textAlign: TextAlign.center,
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               ),
//             ],
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildConnectionCard(UserModel user, TestInviteState testInviteState) {
//     final compatibilityScore = _calculateDisplayCompatibility(user);
//     final commonInterests = _getCommonInterests(user);
//     final isLoading = testInviteState.isLoading;

//     // Verificar se já existe convite pendente
//     final hasPendingInvite = testInviteState.sentInvites.any(
//       (invite) => invite.receiverId == user.uid && invite.canRespond,
//     );

//     return Container(
//       margin: const EdgeInsets.only(bottom: 16),
//       child: CustomCard(
//         borderRadius: 0,
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Row(
//               children: [
//                 Stack(
//                   children: [
//                     AppHelpers.buildUserAvatar(
//                       avatarId: user.avatar,
//                       // borderId: user.borderId, // Implementar se tiver
//                       radius: 32,
//                     ),
//                     // Status online
//                     Positioned(
//                       right: 0,
//                       bottom: 0,
//                       child: Container(
//                         width: 12,
//                         height: 12,
//                         decoration: BoxDecoration(
//                           color: Colors.green,
//                           shape: BoxShape.circle,
//                           border: Border.all(color: Colors.white, width: 2),
//                         ),
//                       ),
//                     ),
//                   ],
//                 ),
//                 const SizedBox(width: 16),
//                 Expanded(
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Row(
//                         children: [
//                           Expanded(
//                             child: Text(
//                               user.preferredDisplayName,
//                               style: const TextStyle(
//                                 fontSize: 20,
//                                 fontWeight: FontWeight.bold,
//                               ),
//                             ),
//                           ),
//                           Container(
//                             padding: const EdgeInsets.symmetric(
//                               horizontal: 8,
//                               vertical: 4,
//                             ),
//                             decoration: BoxDecoration(
//                               color: _getCompatibilityColor(compatibilityScore),
//                               borderRadius: BorderRadius.circular(12),
//                             ),
//                             child: Text(
//                               '${compatibilityScore.toInt()}% match',
//                               style: const TextStyle(
//                                 color: Colors.white,
//                                 fontSize: 12,
//                                 fontWeight: FontWeight.bold,
//                               ),
//                             ),
//                           ),
//                         ],
//                       ),
//                       const SizedBox(height: 4),
//                       Row(
//                         children: [
//                           Text(
//                             'Nível ${user.level}',
//                             style: TextStyle(
//                               fontSize: 14,
//                               color: Colors.grey[600],
//                             ),
//                           ),
//                           const SizedBox(width: 8),
//                           Icon(
//                             Icons.location_on,
//                             size: 16,
//                             color: Colors.grey[600],
//                           ),
//                           Text(
//                             'Próximo', // TODO: Implementar distância real
//                             style: TextStyle(
//                               fontSize: 14,
//                               color: Colors.grey[600],
//                             ),
//                           ),
//                         ],
//                       ),
//                       const SizedBox(height: 8),
//                       Row(
//                         children: [
//                           Icon(
//                             AppHelpers.getRelationshipIcon(
//                               user.relationshipInterest,
//                             ),
//                             size: 16,
//                             color: AppHelpers.getRelationshipColor(
//                               user.relationshipInterest,
//                             ),
//                           ),
//                           const SizedBox(width: 4),
//                           Text(
//                             user.relationshipInterest ?? 'Não informado',
//                             style: TextStyle(
//                               fontSize: 12,
//                               color: AppHelpers.getRelationshipColor(
//                                 user.relationshipInterest,
//                               ),
//                               fontWeight: FontWeight.w500,
//                             ),
//                           ),
//                         ],
//                       ),
//                     ],
//                   ),
//                 ),
//               ],
//             ),

//             if (commonInterests.isNotEmpty) ...[
//               const SizedBox(height: 16),
//               Text(
//                 'Interesses em comum:',
//                 style: TextStyle(
//                   fontSize: 12,
//                   fontWeight: FontWeight.bold,
//                   color: Colors.grey[700],
//                 ),
//               ),
//               const SizedBox(height: 8),
//               Wrap(
//                 spacing: 6,
//                 runSpacing: 4,
//                 children: commonInterests.map((interest) {
//                   return Container(
//                     padding: const EdgeInsets.symmetric(
//                       horizontal: 8,
//                       vertical: 4,
//                     ),
//                     decoration: BoxDecoration(
//                       color: Colors.green.shade100,
//                       borderRadius: BorderRadius.circular(12),
//                       border: Border.all(color: Colors.green.shade300),
//                     ),
//                     child: Text(
//                       interest,
//                       style: TextStyle(
//                         fontSize: 11,
//                         color: Colors.green.shade700,
//                         fontWeight: FontWeight.w500,
//                       ),
//                     ),
//                   );
//                 }).toList(),
//               ),
//             ],

//             const SizedBox(height: 16),

//             // Botão de ação
//             SizedBox(
//               width: double.infinity,
//               child: AnimatedButton(
//                 onPressed: hasPendingInvite || isLoading
//                     ? null
//                     : () => _sendTestInvite(user),
//                 backgroundColor: hasPendingInvite
//                     ? Colors.orange
//                     : Theme.of(context).primaryColor,
//                 foregroundColor: Colors.white,
//                 child: Row(
//                   mainAxisAlignment: MainAxisAlignment.center,
//                   children: [
//                     if (isLoading)
//                       const SizedBox(
//                         width: 16,
//                         height: 16,
//                         child: CircularProgressIndicator(
//                           strokeWidth: 2,
//                           valueColor: AlwaysStoppedAnimation<Color>(
//                             Colors.white,
//                           ),
//                         ),
//                       )
//                     else
//                       Icon(
//                         hasPendingInvite ? Icons.schedule : Icons.psychology,
//                         size: 20,
//                       ),
//                     const SizedBox(width: 8),
//                     Text(
//                       hasPendingInvite
//                           ? 'Convite Enviado'
//                           : 'Enviar Convite de Teste',
//                       style: const TextStyle(
//                         fontSize: 16,
//                         fontWeight: FontWeight.bold,
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildEmptyView() {
//     return Container(
//       padding: const EdgeInsets.all(24),
//       child: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           Icon(Icons.search_off, size: 80, color: Colors.grey[400]),
//           const SizedBox(height: 24),
//           Text(
//             'Nenhum usuário compatível encontrado',
//             style: TextStyle(
//               fontSize: 20,
//               fontWeight: FontWeight.bold,
//               color: Colors.grey[600],
//             ),
//             textAlign: TextAlign.center,
//           ),
//           const SizedBox(height: 12),
//           Text(
//             'Tente novamente em alguns minutos ou ajuste seus interesses.',
//             style: TextStyle(fontSize: 16, color: Colors.grey[500]),
//             textAlign: TextAlign.center,
//           ),
//           const SizedBox(height: 32),
//           AnimatedButton(
//             onPressed: () => _startSearch(),
//             backgroundColor: Theme.of(context).primaryColor,
//             foregroundColor: Colors.white,
//             child: const Row(
//               mainAxisSize: MainAxisSize.min,
//               children: [
//                 Icon(Icons.refresh, size: 20),
//                 SizedBox(width: 8),
//                 Text('Tentar Novamente'),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildErrorView(String error) {
//     return Container(
//       padding: const EdgeInsets.all(24),
//       child: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           Icon(Icons.error_outline, size: 80, color: Colors.red[400]),
//           const SizedBox(height: 24),
//           const Text(
//             'Ops! Algo deu errado',
//             style: TextStyle(
//               fontSize: 20,
//               fontWeight: FontWeight.bold,
//               color: Colors.red,
//             ),
//             textAlign: TextAlign.center,
//           ),
//           const SizedBox(height: 12),
//           Text(
//             error,
//             style: TextStyle(fontSize: 16, color: Colors.grey[600]),
//             textAlign: TextAlign.center,
//           ),
//           const SizedBox(height: 32),
//           Row(
//             children: [
//               Expanded(
//                 child: OutlinedButton(
//                   onPressed: () => context.go('/home'),
//                   child: const Text('Voltar'),
//                 ),
//               ),
//               const SizedBox(width: 16),
//               Expanded(
//                 child: AnimatedButton(
//                   onPressed: () {
//                     ref.read(discoveryProvider.notifier).clearResults();
//                     _startSearch();
//                   },
//                   backgroundColor: Theme.of(context).primaryColor,
//                   foregroundColor: Colors.white,
//                   child: const Text('Tentar Novamente'),
//                 ),
//               ),
//             ],
//           ),
//         ],
//       ),
//     );
//   }

//   // ============== MÉTODOS AUXILIARES ==============

//   Future<void> _sendTestInvite(UserModel user) async {
//     final success = await ref
//         .read(testInviteProvider.notifier)
//         .sendTestInvite(user);

//     if (success && mounted) {
//       AppHelpers.showCustomSnackBar(
//         context,
//         '📨 Convite enviado para ${user.preferredDisplayName}!',
//         backgroundColor: Colors.green,
//         icon: Icons.send,
//       );
//     } else if (mounted) {
//       final error = ref.read(testInviteProvider).error ?? 'Erro desconhecido';
//       AppHelpers.showCustomSnackBar(
//         context,
//         error,
//         backgroundColor: Colors.red,
//         icon: Icons.error,
//       );
//     }
//   }

//   double _calculateDisplayCompatibility(UserModel user) {
//     // Simular cálculo de compatibilidade para exibição
//     // Na implementação real, isso viria do algoritmo do DiscoveryProvider
//     final commonInterests = _getCommonInterests(user);
//     final maxInterests = widget.interessesUsuario.length;

//     if (maxInterests == 0) return 50.0;

//     final baseScore = (commonInterests.length / maxInterests) * 80;
//     final randomBonus = (user.level % 20)
//         .toDouble(); // Baseado no nível para consistência

//     return (baseScore + randomBonus).clamp(0.0, 100.0);
//   }

//   List<String> _getCommonInterests(UserModel user) {
//     return widget.interessesUsuario
//         .where((interest) => user.interesses.contains(interest))
//         .toList();
//   }

//   Color _getCompatibilityColor(double score) {
//     if (score >= 80) return Colors.green;
//     if (score >= 60) return Colors.orange;
//     return Colors.grey;
//   }

//   @override
//   void dispose() {
//     _searchController.dispose();
//     _resultsController.dispose();
//     super.dispose();
//   }
// }
