// lib/screens/test_users_admin_screen.dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:unlock/feature/games/social/providers/test_invite_provider.dart';
import 'package:unlock/models/user_model.dart';
import 'package:unlock/services/support/test_users_service.dart';
import 'package:unlock/utils/helpers.dart';
import 'package:unlock/widgtes/animated_button.dart';
import 'package:unlock/widgtes/custom_card.dart';

// ============== PROVIDER PARA ESTADO DA TELA ==============
final testUsersAdminProvider =
    StateNotifierProvider<TestUsersAdminNotifier, TestUsersAdminState>((ref) {
      return TestUsersAdminNotifier();
    });

class TestUsersAdminState {
  final List<UserModel> testUsers;
  final Map<String, dynamic> stats;
  final bool isLoading;
  final String? error;
  final String? successMessage;

  const TestUsersAdminState({
    this.testUsers = const [],
    this.stats = const {},
    this.isLoading = false,
    this.error,
    this.successMessage,
  });

  TestUsersAdminState copyWith({
    List<UserModel>? testUsers,
    Map<String, dynamic>? stats,
    bool? isLoading,
    String? error,
    String? successMessage,
  }) {
    return TestUsersAdminState(
      testUsers: testUsers ?? this.testUsers,
      stats: stats ?? this.stats,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      successMessage: successMessage,
    );
  }
}

class TestUsersAdminNotifier extends StateNotifier<TestUsersAdminState> {
  Timer? _keepOnlineTimer;

  TestUsersAdminNotifier() : super(const TestUsersAdminState()) {
    loadStats();
    _startKeepOnlineTimer();
  }

  // ============== CARREGAR ESTATÍSTICAS ==============
  Future<void> loadStats() async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      final stats = await TestUsersService.getTestUsersStats();
      state = state.copyWith(stats: stats, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Erro ao carregar estatísticas: $e',
      );
    }
  }

  // ============== CRIAR USUÁRIOS ALEATÓRIOS ==============
  Future<void> createRandomUsers(int count) async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      final users = await TestUsersService.createTestUsers(count: count);

      state = state.copyWith(
        isLoading: false,
        successMessage: '✅ $count usuários aleatórios criados com sucesso!',
      );

      await loadStats();
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Erro ao criar usuários: $e',
      );
    }
  }

  // ============== CRIAR USUÁRIOS ESPECÍFICOS ==============
  Future<void> createSpecificUsers() async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      final users = await TestUsersService.createSpecificTestUsers();

      state = state.copyWith(
        isLoading: false,
        successMessage: '✅ ${users.length} usuários específicos criados!',
      );

      await loadStats();
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Erro ao criar usuários específicos: $e',
      );
    }
  }

  // ============== CRIAR CENÁRIOS DE TESTE ==============
  Future<void> createTestScenarios() async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      await TestUsersService.createTestScenarios();

      state = state.copyWith(
        isLoading: false,
        successMessage: '✅ Cenários de teste criados!',
      );

      await loadStats();
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Erro ao criar cenários: $e',
      );
    }
  }

  // ============== MANTER USUÁRIOS ONLINE ==============
  Future<void> keepUsersOnline() async {
    try {
      await TestUsersService.keepUsersOnline();
      state = state.copyWith(
        successMessage: '🔄 Usuários marcados como online!',
      );
      await loadStats();
    } catch (e) {
      state = state.copyWith(error: 'Erro ao manter usuários online: $e');
    }
  }

  void _startKeepOnlineTimer() {
    _keepOnlineTimer = Timer.periodic(const Duration(minutes: 2), (timer) {
      TestUsersService.keepUsersOnline();
    });
  }

  // ============== DELETAR TODOS USUÁRIOS ==============
  Future<void> deleteAllTestUsers() async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      await TestUsersService.deleteAllTestUsers();

      state = state.copyWith(
        isLoading: false,
        successMessage: '🗑️ Todos os usuários de teste foram removidos!',
      );

      await loadStats();
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Erro ao deletar usuários: $e',
      );
    }
  }

  // ============== LIMPAR MENSAGENS ==============
  void clearMessages() {
    state = state.copyWith(error: null, successMessage: null);
  }

  @override
  void dispose() {
    _keepOnlineTimer?.cancel();
    super.dispose();
  }
}

// ============== TELA ADMINISTRATIVA ==============
class TestUsersAdminScreen extends ConsumerStatefulWidget {
  const TestUsersAdminScreen({super.key});

  @override
  ConsumerState<TestUsersAdminScreen> createState() =>
      _TestUsersAdminScreenState();
}

class _TestUsersAdminScreenState extends ConsumerState<TestUsersAdminScreen> {
  final TextEditingController _countController = TextEditingController(
    text: '10',
  );

  @override
  void initState() {
    super.initState();
    // Carregar stats ao iniciar
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(testUsersAdminProvider.notifier).loadStats();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(testUsersAdminProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('🧪 Admin - Usuários de Teste'),
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () {
              ref.read(testUsersAdminProvider.notifier).loadStats();
            },
            icon: const Icon(Icons.refresh),
            tooltip: 'Atualizar Estatísticas',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Mensagens de feedback
            if (state.error != null) _buildErrorMessage(state.error!),
            if (state.successMessage != null)
              _buildSuccessMessage(state.successMessage!),

            // Estatísticas
            _buildStatsCard(state),
            const SizedBox(height: 20),

            // Ações de criação
            _buildCreationSection(state),
            const SizedBox(height: 20),

            // Ações de manutenção
            _buildMaintenanceSection(state),
            const SizedBox(height: 20),

            // Gerenciamento de convites
            _buildInviteManagementSection(),
            const SizedBox(height: 20),

            // Ações perigosas
            _buildDangerSection(state),

            AnimatedButton(
              onPressed: state.isLoading
                  ? null
                  : () {
                      context.go('/home');
                    },
              backgroundColor: Colors.black,
              foregroundColor: Colors.white,
              child: const Text('Voltar'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorMessage(String error) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: Colors.red.shade600),
          const SizedBox(width: 8),
          Expanded(
            child: Text(error, style: TextStyle(color: Colors.red.shade700)),
          ),
          IconButton(
            onPressed: () {
              ref.read(testUsersAdminProvider.notifier).clearMessages();
            },
            icon: Icon(Icons.close, color: Colors.red.shade600),
            iconSize: 20,
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessMessage(String message) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.green.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.check_circle_outline, color: Colors.green.shade600),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: Colors.green.shade700),
            ),
          ),
          IconButton(
            onPressed: () {
              ref.read(testUsersAdminProvider.notifier).clearMessages();
            },
            icon: Icon(Icons.close, color: Colors.green.shade600),
            iconSize: 20,
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCard(TestUsersAdminState state) {
    return CustomCard(
      borderRadius: 0,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.analytics, color: Colors.blue),
              const SizedBox(width: 8),
              const Text(
                'Estatísticas dos Usuários',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              if (state.isLoading)
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
            ],
          ),
          const SizedBox(height: 16),

          if (state.stats.isNotEmpty) ...[
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    'Total de Teste',
                    state.stats['totalTestUsers']?.toString() ?? '0',
                    Colors.blue,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    'Específicos',
                    state.stats['totalSpecificUsers']?.toString() ?? '0',
                    Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    'Total Geral',
                    state.stats['totalUsers']?.toString() ?? '0',
                    Colors.purple,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    'Online Agora',
                    state.stats['onlineUsers']?.toString() ?? '0',
                    Colors.orange,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Última atualização: ${_formatLastUpdated(state.stats['lastUpdated'])}',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ] else ...[
            const Center(
              child: Text(
                'Carregando estatísticas...',
                style: TextStyle(color: Colors.grey),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildCreationSection(TestUsersAdminState state) {
    return CustomCard(
      borderRadius: 0,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.group_add, color: Colors.green),
              SizedBox(width: 8),
              Text(
                'Criar Usuários de Teste',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Usuários aleatórios
          Row(
            children: [
              Expanded(
                flex: 2,
                child: TextField(
                  controller: _countController,
                  decoration: const InputDecoration(
                    labelText: 'Quantidade',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 3,
                child: AnimatedButton(
                  onPressed: state.isLoading
                      ? null
                      : () {
                          final count =
                              int.tryParse(_countController.text) ?? 10;
                          ref
                              .read(testUsersAdminProvider.notifier)
                              .createRandomUsers(count);
                        },
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  child: const Text('Criar Aleatórios'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Usuários específicos
          SizedBox(
            width: double.infinity,
            child: AnimatedButton(
              onPressed: state.isLoading
                  ? null
                  : () {
                      ref
                          .read(testUsersAdminProvider.notifier)
                          .createSpecificUsers();
                    },
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              child: const Text('Criar Usuários Específicos (5)'),
            ),
          ),
          const SizedBox(height: 12),

          // Cenários de teste
          SizedBox(
            width: double.infinity,
            child: AnimatedButton(
              onPressed: state.isLoading
                  ? null
                  : () {
                      ref
                          .read(testUsersAdminProvider.notifier)
                          .createTestScenarios();
                    },
              backgroundColor: Colors.purple,
              foregroundColor: Colors.white,
              child: const Text('Criar Cenários de Teste'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMaintenanceSection(TestUsersAdminState state) {
    return CustomCard(
      borderRadius: 0,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.build, color: Colors.orange),
              SizedBox(width: 8),
              Text(
                'Manutenção',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 16),

          SizedBox(
            width: double.infinity,
            child: AnimatedButton(
              onPressed: state.isLoading
                  ? null
                  : () {
                      ref
                          .read(testUsersAdminProvider.notifier)
                          .keepUsersOnline();
                    },
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
              child: const Text('Marcar Todos Como Online'),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'ℹ️ Os usuários são automaticamente mantidos online a cada 2 minutos',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDangerSection(TestUsersAdminState state) {
    return CustomCard(
      borderRadius: 0,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.warning, color: Colors.red.shade600),
              const SizedBox(width: 8),
              Text(
                'Zona Perigosa',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.red.shade600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: state.isLoading
                  ? null
                  : () {
                      _showDeleteConfirmation();
                    },
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red.shade600,
                side: BorderSide(color: Colors.red.shade300),
              ),
              child: const Text('🗑️ Deletar TODOS os Usuários de Teste'),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '⚠️ Esta ação é irreversível e remove todos os usuários de teste',
            style: TextStyle(
              fontSize: 12,
              color: Colors.red.shade600,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInviteManagementSection() {
    final testInviteState = ref.watch(testInviteProvider);

    return CustomCard(
      borderRadius: 0,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.mail, color: Colors.purple),
              SizedBox(width: 8),
              Text(
                'Gerenciar Convites de Teste',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Estatísticas de convites
          Row(
            children: [
              Expanded(
                child: _buildInviteStatItem(
                  'Enviados',
                  testInviteState.sentInvites.length.toString(),
                  Colors.blue,
                ),
              ),
              Expanded(
                child: _buildInviteStatItem(
                  'Recebidos',
                  testInviteState.receivedInvites.length.toString(),
                  Colors.green,
                ),
              ),
              Expanded(
                child: _buildInviteStatItem(
                  'Pendentes',
                  testInviteState.pendingReceivedInvites.length.toString(),
                  Colors.orange,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Convites pendentes para aceitar/rejeitar
          if (testInviteState.pendingReceivedInvites.isNotEmpty) ...[
            const Text(
              'Convites Pendentes para Responder:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ...testInviteState.pendingReceivedInvites.map((invite) {
              return _buildInviteCard(invite);
            }).toList(),
          ] else ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Center(
                child: Text(
                  '📭 Nenhum convite pendente\n\nPara testar, use outro usuário para enviar um convite',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            ),
          ],

          // Botão para criar convite de teste
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _showCreateTestInviteDialog(),
              icon: const Icon(Icons.add_circle_outline),
              label: const Text('Simular Convite para Teste'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.purple,
                side: const BorderSide(color: Colors.purple),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInviteStatItem(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildInviteCard(TestInvite invite) {
    final timeRemaining = invite.expiresAt?.difference(DateTime.now());
    final minutesLeft = timeRemaining?.inMinutes ?? 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.purple.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.purple.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AppHelpers.buildUserAvatar(
                avatarId: invite.senderUser.avatar,
                radius: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Convite de ${invite.senderUser.preferredDisplayName}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Nível ${invite.senderUser.level} • ${invite.senderUser.relationshipInterest}',
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: minutesLeft <= 1
                      ? Colors.red.withOpacity(0.2)
                      : Colors.orange.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${minutesLeft}min',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: minutesLeft <= 1 ? Colors.red : Colors.orange,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Interesses em comum
          if (invite.senderUser.interesses.isNotEmpty) ...[
            Text(
              'Interesses: ${invite.senderUser.interesses.take(3).join(", ")}',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
            const SizedBox(height: 12),
          ],

          // Botões de ação
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _respondToInvite(invite.id, false),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                  ),
                  child: const Text('Rejeitar'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => _respondToInvite(invite.id, true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Aceitar'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _respondToInvite(String inviteId, bool accept) async {
    final success = await ref
        .read(testInviteProvider.notifier)
        .respondToInvite(inviteId, accept);

    if (mounted) {
      if (success) {
        final action = accept ? 'aceito' : 'rejeitado';
        AppHelpers.showCustomSnackBar(
          context,
          '✅ Convite $action com sucesso!',
          backgroundColor: accept ? Colors.green : Colors.orange,
          icon: accept ? Icons.check_circle : Icons.cancel,
        );

        if (accept) {
          // Mostrar informações sobre próximos passos
          _showTestInstructions();
        }
      } else {
        final error = ref.read(testInviteProvider).error ?? 'Erro ao responder';
        AppHelpers.showCustomSnackBar(
          context,
          error,
          backgroundColor: Colors.red,
          icon: Icons.error,
        );
      }
    }
  }

  void _showTestInstructions() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('🎉 Convite Aceito!'),
        content: const Text(
          'O convite foi aceito com sucesso!\n\n'
          'Agora o remetente pode iniciar o teste de compatibilidade.\n\n'
          'Em um cenário real, ambos usuários receberiam notificações e seriam direcionados para a tela de teste.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Entendi'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Simular início de teste (opcional)
              _simulateTestStart();
            },
            child: const Text('Simular Teste'),
          ),
        ],
      ),
    );
  }

  void _simulateTestStart() {
    AppHelpers.showCustomSnackBar(
      context,
      '🎮 Teste de compatibilidade iniciado! (Simulação)',
      backgroundColor: Colors.purple,
      icon: Icons.psychology,
    );
  }

  void _showCreateTestInviteDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('💡 Dica para Testar'),
        content: const Text(
          'Para simular um convite de teste:\n\n'
          '1. Use a tela de Matching (Descobrir Conexões)\n'
          '2. Envie um convite para um usuário de teste\n'
          '3. Volte para esta tela admin\n'
          '4. O convite aparecerá aqui para aceitar/rejeitar\n\n'
          'Ou crie usuários específicos que enviem convites automaticamente.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Entendi'),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('⚠️ Confirmar Exclusão'),
        content: const Text(
          'Tem certeza que deseja deletar TODOS os usuários de teste?\n\n'
          'Esta ação não pode ser desfeita!',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(testUsersAdminProvider.notifier).deleteAllTestUsers();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Deletar Tudo'),
          ),
        ],
      ),
    );
  }

  String _formatLastUpdated(String? timestamp) {
    if (timestamp == null) return 'Nunca';
    try {
      final date = DateTime.parse(timestamp);
      final now = DateTime.now();
      final diff = now.difference(date);

      if (diff.inMinutes < 1) return 'Agora';
      if (diff.inMinutes < 60) return '${diff.inMinutes}min atrás';
      if (diff.inHours < 24) return '${diff.inHours}h atrás';
      return '${diff.inDays} dias atrás';
    } catch (e) {
      return 'Inválido';
    }
  }

  @override
  void dispose() {
    _countController.dispose();
    super.dispose();
  }
}

// // ============== PROVIDER PARA ESTADO DA TELA ==============
// final testUsersAdminProvider =
//     StateNotifierProvider<TestUsersAdminNotifier, TestUsersAdminState>((ref) {
//       return TestUsersAdminNotifier();
//     });

// class TestUsersAdminState {
//   final List<UserModel> testUsers;
//   final Map<String, dynamic> stats;
//   final bool isLoading;
//   final String? error;
//   final String? successMessage;

//   const TestUsersAdminState({
//     this.testUsers = const [],
//     this.stats = const {},
//     this.isLoading = false,
//     this.error,
//     this.successMessage,
//   });

//   TestUsersAdminState copyWith({
//     List<UserModel>? testUsers,
//     Map<String, dynamic>? stats,
//     bool? isLoading,
//     String? error,
//     String? successMessage,
//   }) {
//     return TestUsersAdminState(
//       testUsers: testUsers ?? this.testUsers,
//       stats: stats ?? this.stats,
//       isLoading: isLoading ?? this.isLoading,
//       error: error,
//       successMessage: successMessage,
//     );
//   }
// }

// class TestUsersAdminNotifier extends StateNotifier<TestUsersAdminState> {
//   Timer? _keepOnlineTimer;

//   TestUsersAdminNotifier() : super(const TestUsersAdminState()) {
//     loadStats();
//     _startKeepOnlineTimer();
//   }

//   // ============== CARREGAR ESTATÍSTICAS ==============
//   Future<void> loadStats() async {
//     try {
//       state = state.copyWith(isLoading: true, error: null);
//       final stats = await TestUsersService.getTestUsersStats();
//       state = state.copyWith(stats: stats, isLoading: false);
//     } catch (e) {
//       state = state.copyWith(
//         isLoading: false,
//         error: 'Erro ao carregar estatísticas: $e',
//       );
//     }
//   }

//   // ============== CRIAR USUÁRIOS ALEATÓRIOS ==============
//   Future<void> createRandomUsers(int count) async {
//     try {
//       state = state.copyWith(isLoading: true, error: null);

//       final users = await TestUsersService.createTestUsers(count: count);

//       state = state.copyWith(
//         isLoading: false,
//         successMessage: '✅ $count usuários aleatórios criados com sucesso!',
//       );

//       await loadStats();
//     } catch (e) {
//       state = state.copyWith(
//         isLoading: false,
//         error: 'Erro ao criar usuários: $e',
//       );
//     }
//   }

//   // ============== CRIAR USUÁRIOS ESPECÍFICOS ==============
//   Future<void> createSpecificUsers() async {
//     try {
//       state = state.copyWith(isLoading: true, error: null);

//       final users = await TestUsersService.createSpecificTestUsers();

//       state = state.copyWith(
//         isLoading: false,
//         successMessage: '✅ ${users.length} usuários específicos criados!',
//       );

//       await loadStats();
//     } catch (e) {
//       state = state.copyWith(
//         isLoading: false,
//         error: 'Erro ao criar usuários específicos: $e',
//       );
//     }
//   }

//   // ============== CRIAR CENÁRIOS DE TESTE ==============
//   Future<void> createTestScenarios() async {
//     try {
//       state = state.copyWith(isLoading: true, error: null);

//       await TestUsersService.createTestScenarios();

//       state = state.copyWith(
//         isLoading: false,
//         successMessage: '✅ Cenários de teste criados!',
//       );

//       await loadStats();
//     } catch (e) {
//       state = state.copyWith(
//         isLoading: false,
//         error: 'Erro ao criar cenários: $e',
//       );
//     }
//   }

//   // ============== MANTER USUÁRIOS ONLINE ==============
//   Future<void> keepUsersOnline() async {
//     try {
//       await TestUsersService.keepUsersOnline();
//       state = state.copyWith(
//         successMessage: '🔄 Usuários marcados como online!',
//       );
//       await loadStats();
//     } catch (e) {
//       state = state.copyWith(error: 'Erro ao manter usuários online: $e');
//     }
//   }

//   void _startKeepOnlineTimer() {
//     _keepOnlineTimer = Timer.periodic(const Duration(minutes: 2), (timer) {
//       TestUsersService.keepUsersOnline();
//     });
//   }

//   // ============== DELETAR TODOS USUÁRIOS ==============
//   Future<void> deleteAllTestUsers() async {
//     try {
//       state = state.copyWith(isLoading: true, error: null);

//       await TestUsersService.deleteAllTestUsers();

//       state = state.copyWith(
//         isLoading: false,
//         successMessage: '🗑️ Todos os usuários de teste foram removidos!',
//       );

//       await loadStats();
//     } catch (e) {
//       state = state.copyWith(
//         isLoading: false,
//         error: 'Erro ao deletar usuários: $e',
//       );
//     }
//   }

//   // ============== LIMPAR MENSAGENS ==============
//   void clearMessages() {
//     state = state.copyWith(error: null, successMessage: null);
//   }

//   @override
//   void dispose() {
//     _keepOnlineTimer?.cancel();
//     super.dispose();
//   }
// }

// // ============== TELA ADMINISTRATIVA ==============
// class TestUsersAdminScreen extends ConsumerStatefulWidget {
//   const TestUsersAdminScreen({super.key});

//   @override
//   ConsumerState<TestUsersAdminScreen> createState() =>
//       _TestUsersAdminScreenState();
// }

// class _TestUsersAdminScreenState extends ConsumerState<TestUsersAdminScreen> {
//   final TextEditingController _countController = TextEditingController(
//     text: '10',
//   );

//   @override
//   void initState() {
//     super.initState();
//     // Carregar stats ao iniciar
//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       ref.read(testUsersAdminProvider.notifier).loadStats();
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     final state = ref.watch(testUsersAdminProvider);

//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('🧪 Admin - Usuários de Teste'),
//         elevation: 0,
//         actions: [
//           IconButton(
//             onPressed: () {
//               ref.read(testUsersAdminProvider.notifier).loadStats();
//             },
//             icon: const Icon(Icons.refresh),
//             tooltip: 'Atualizar Estatísticas',
//           ),
//         ],
//       ),
//       body: SingleChildScrollView(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.stretch,
//           children: [
//             // Mensagens de feedback
//             if (state.error != null) _buildErrorMessage(state.error!),
//             if (state.successMessage != null)
//               _buildSuccessMessage(state.successMessage!),

//             // Estatísticas
//             _buildStatsCard(state),
//             const SizedBox(height: 20),

//             // Ações de criação
//             _buildCreationSection(state),
//             const SizedBox(height: 20),

//             // Ações de manutenção
//             _buildMaintenanceSection(state),
//             const SizedBox(height: 20),

//             // Ações perigosas
//             _buildDangerSection(state),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildErrorMessage(String error) {
//     return Container(
//       margin: const EdgeInsets.only(bottom: 16),
//       padding: const EdgeInsets.all(12),
//       decoration: BoxDecoration(
//         color: Colors.red.shade50,
//         borderRadius: BorderRadius.circular(8),
//         border: Border.all(color: Colors.red.shade200),
//       ),
//       child: Row(
//         children: [
//           Icon(Icons.error_outline, color: Colors.red.shade600),
//           const SizedBox(width: 8),
//           Expanded(
//             child: Text(error, style: TextStyle(color: Colors.red.shade700)),
//           ),
//           IconButton(
//             onPressed: () {
//               ref.read(testUsersAdminProvider.notifier).clearMessages();
//             },
//             icon: Icon(Icons.close, color: Colors.red.shade600),
//             iconSize: 20,
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildSuccessMessage(String message) {
//     return Container(
//       margin: const EdgeInsets.only(bottom: 16),
//       padding: const EdgeInsets.all(12),
//       decoration: BoxDecoration(
//         color: Colors.green.shade50,
//         borderRadius: BorderRadius.circular(8),
//         border: Border.all(color: Colors.green.shade200),
//       ),
//       child: Row(
//         children: [
//           Icon(Icons.check_circle_outline, color: Colors.green.shade600),
//           const SizedBox(width: 8),
//           Expanded(
//             child: Text(
//               message,
//               style: TextStyle(color: Colors.green.shade700),
//             ),
//           ),
//           IconButton(
//             onPressed: () {
//               ref.read(testUsersAdminProvider.notifier).clearMessages();
//             },
//             icon: Icon(Icons.close, color: Colors.green.shade600),
//             iconSize: 20,
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildStatsCard(TestUsersAdminState state) {
//     return CustomCard(
//       borderRadius: 0,
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Row(
//             children: [
//               const Icon(Icons.analytics, color: Colors.blue),
//               const SizedBox(width: 8),
//               const Text(
//                 'Estatísticas dos Usuários',
//                 style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
//               ),
//               const Spacer(),
//               if (state.isLoading)
//                 const SizedBox(
//                   width: 20,
//                   height: 20,
//                   child: CircularProgressIndicator(strokeWidth: 2),
//                 ),
//             ],
//           ),
//           const SizedBox(height: 16),

//           if (state.stats.isNotEmpty) ...[
//             Row(
//               children: [
//                 Expanded(
//                   child: _buildStatItem(
//                     'Total de Teste',
//                     state.stats['totalTestUsers']?.toString() ?? '0',
//                     Colors.blue,
//                   ),
//                 ),
//                 Expanded(
//                   child: _buildStatItem(
//                     'Específicos',
//                     state.stats['totalSpecificUsers']?.toString() ?? '0',
//                     Colors.green,
//                   ),
//                 ),
//               ],
//             ),
//             const SizedBox(height: 12),
//             Row(
//               children: [
//                 Expanded(
//                   child: _buildStatItem(
//                     'Total Geral',
//                     state.stats['totalUsers']?.toString() ?? '0',
//                     Colors.purple,
//                   ),
//                 ),
//                 Expanded(
//                   child: _buildStatItem(
//                     'Online Agora',
//                     state.stats['onlineUsers']?.toString() ?? '0',
//                     Colors.orange,
//                   ),
//                 ),
//               ],
//             ),
//             const SizedBox(height: 12),
//             Text(
//               'Última atualização: ${_formatLastUpdated(state.stats['lastUpdated'])}',
//               style: TextStyle(fontSize: 12, color: Colors.grey[600]),
//             ),
//           ] else ...[
//             const Center(
//               child: Text(
//                 'Carregando estatísticas...',
//                 style: TextStyle(color: Colors.grey),
//               ),
//             ),
//           ],
//         ],
//       ),
//     );
//   }

//   Widget _buildStatItem(String label, String value, Color color) {
//     return Container(
//       padding: const EdgeInsets.all(12),
//       decoration: BoxDecoration(
//         color: color.withOpacity(0.1),
//         borderRadius: BorderRadius.circular(8),
//         border: Border.all(color: color.withOpacity(0.3)),
//       ),
//       child: Column(
//         children: [
//           Text(
//             value,
//             style: TextStyle(
//               fontSize: 24,
//               fontWeight: FontWeight.bold,
//               color: color,
//             ),
//           ),
//           const SizedBox(height: 4),
//           Text(
//             label,
//             style: TextStyle(
//               fontSize: 12,
//               color: color,
//               fontWeight: FontWeight.w500,
//             ),
//             textAlign: TextAlign.center,
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildCreationSection(TestUsersAdminState state) {
//     return CustomCard(
//       borderRadius: 0,
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           const Row(
//             children: [
//               Icon(Icons.group_add, color: Colors.green),
//               SizedBox(width: 8),
//               Text(
//                 'Criar Usuários de Teste',
//                 style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
//               ),
//             ],
//           ),
//           const SizedBox(height: 16),

//           // Usuários aleatórios
//           Row(
//             children: [
//               Expanded(
//                 flex: 2,
//                 child: TextField(
//                   controller: _countController,
//                   decoration: const InputDecoration(
//                     labelText: 'Quantidade',
//                     border: OutlineInputBorder(),
//                     isDense: true,
//                   ),
//                   keyboardType: TextInputType.number,
//                 ),
//               ),
//               const SizedBox(width: 12),
//               Expanded(
//                 flex: 3,
//                 child: AnimatedButton(
//                   onPressed: state.isLoading
//                       ? null
//                       : () {
//                           final count =
//                               int.tryParse(_countController.text) ?? 10;
//                           ref
//                               .read(testUsersAdminProvider.notifier)
//                               .createRandomUsers(count);
//                         },
//                   backgroundColor: Colors.green,
//                   foregroundColor: Colors.white,
//                   child: const Text('Criar Aleatórios'),
//                 ),
//               ),
//             ],
//           ),
//           const SizedBox(height: 12),

//           // Usuários específicos
//           SizedBox(
//             width: double.infinity,
//             child: AnimatedButton(
//               onPressed: state.isLoading
//                   ? null
//                   : () {
//                       ref
//                           .read(testUsersAdminProvider.notifier)
//                           .createSpecificUsers();
//                     },
//               backgroundColor: Colors.blue,
//               foregroundColor: Colors.white,
//               child: const Text('Criar Usuários Específicos (5)'),
//             ),
//           ),
//           const SizedBox(height: 12),

//           // Cenários de teste
//           SizedBox(
//             width: double.infinity,
//             child: AnimatedButton(
//               onPressed: state.isLoading
//                   ? null
//                   : () {
//                       ref
//                           .read(testUsersAdminProvider.notifier)
//                           .createTestScenarios();
//                     },
//               backgroundColor: Colors.purple,
//               foregroundColor: Colors.white,
//               child: const Text('Criar Cenários de Teste'),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildMaintenanceSection(TestUsersAdminState state) {
//     return CustomCard(
//       borderRadius: 0,
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           const Row(
//             children: [
//               Icon(Icons.build, color: Colors.orange),
//               SizedBox(width: 8),
//               Text(
//                 'Manutenção',
//                 style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
//               ),
//             ],
//           ),
//           const SizedBox(height: 16),

//           SizedBox(
//             width: double.infinity,
//             child: AnimatedButton(
//               onPressed: state.isLoading
//                   ? null
//                   : () {
//                       ref
//                           .read(testUsersAdminProvider.notifier)
//                           .keepUsersOnline();
//                     },
//               backgroundColor: Colors.orange,
//               foregroundColor: Colors.white,
//               child: const Text('Marcar Todos Como Online'),
//             ),
//           ),
//           const SizedBox(height: 8),
//           Text(
//             'ℹ️ Os usuários são automaticamente mantidos online a cada 2 minutos',
//             style: TextStyle(
//               fontSize: 12,
//               color: Colors.grey[600],
//               fontStyle: FontStyle.italic,
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildDangerSection(TestUsersAdminState state) {
//     return CustomCard(
//       borderRadius: 0,
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Row(
//             children: [
//               Icon(Icons.warning, color: Colors.red.shade600),
//               const SizedBox(width: 8),
//               Text(
//                 'Zona Perigosa',
//                 style: TextStyle(
//                   fontSize: 18,
//                   fontWeight: FontWeight.bold,
//                   color: Colors.red.shade600,
//                 ),
//               ),
//             ],
//           ),
//           const SizedBox(height: 16),

//           SizedBox(
//             width: double.infinity,
//             child: OutlinedButton(
//               onPressed: state.isLoading
//                   ? null
//                   : () {
//                       _showDeleteConfirmation();
//                     },
//               style: OutlinedButton.styleFrom(
//                 foregroundColor: Colors.red.shade600,
//                 side: BorderSide(color: Colors.red.shade300),
//               ),
//               child: const Text('🗑️ Deletar TODOS os Usuários de Teste'),
//             ),
//           ),
//           AnimatedButton(
//             onPressed: state.isLoading
//                 ? null
//                 : () {
//                     context.go('/home');
//                   },
//             backgroundColor: Colors.black,
//             foregroundColor: Colors.white,
//             child: const Text('Voltar'),
//           ),

//           const SizedBox(height: 8),
//           Text(
//             '⚠️ Esta ação é irreversível e remove todos os usuários de teste',
//             style: TextStyle(
//               fontSize: 12,
//               color: Colors.red.shade600,
//               fontStyle: FontStyle.italic,
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   void _showDeleteConfirmation() {
//     showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: const Text('⚠️ Confirmar Exclusão'),
//         content: const Text(
//           'Tem certeza que deseja deletar TODOS os usuários de teste?\n\n'
//           'Esta ação não pode ser desfeita!',
//         ),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(context),
//             child: const Text('Cancelar'),
//           ),
//           ElevatedButton(
//             onPressed: () {
//               Navigator.pop(context);
//               ref.read(testUsersAdminProvider.notifier).deleteAllTestUsers();
//             },
//             style: ElevatedButton.styleFrom(
//               backgroundColor: Colors.red,
//               foregroundColor: Colors.white,
//             ),
//             child: const Text('Deletar Tudo'),
//           ),
//         ],
//       ),
//     );
//   }

//   String _formatLastUpdated(String? timestamp) {
//     if (timestamp == null) return 'Nunca';
//     try {
//       final date = DateTime.parse(timestamp);
//       final now = DateTime.now();
//       final diff = now.difference(date);

//       if (diff.inMinutes < 1) return 'Agora';
//       if (diff.inMinutes < 60) return '${diff.inMinutes}min atrás';
//       if (diff.inHours < 24) return '${diff.inHours}h atrás';
//       return '${diff.inDays} dias atrás';
//     } catch (e) {
//       return 'Inválido';
//     }
//   }

//   @override
//   void dispose() {
//     _countController.dispose();
//     super.dispose();
//   }
// }
