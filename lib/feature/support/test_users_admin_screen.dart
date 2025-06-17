// lib/services/support/test_users_admin_screen.dart
import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:unlock/feature/support/test_users_service.dart';
import 'package:unlock/models/user_model.dart';
import 'package:unlock/providers/auth_provider.dart';
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

  @override
  void dispose() {
    _keepOnlineTimer?.cancel();
    super.dispose();
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

  // ============== GERAR CONVITE ALEATÓRIO - NOVA FUNCIONALIDADE ==============
  Future<void> generateRandomInvite(String currentUserId) async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      final result = await TestUsersService.createRandomInviteForCurrentUser(
        currentUserId,
      );

      if (result == null) {
        state = state.copyWith(
          isLoading: false,
          error: 'Nenhum usuário disponível para criar convite',
        );
        return;
      }

      final status = result['status'] as String;
      final message = result['message'] as String;

      switch (status) {
        case 'created':
          final senderName = result['senderName'] as String;
          final senderInterests = result['senderInterests'] as List;

          state = state.copyWith(
            isLoading: false,
            successMessage:
                '🎯 $message\n'
                '👤 De: $senderName\n'
                '🎯 Interesses: ${senderInterests.take(3).join(", ")}',
          );
          break;

        case 'existing':
          final senderUser = result['senderUser'] as Map<String, dynamic>;
          final senderName = senderUser['displayName'] as String;

          state = state.copyWith(
            isLoading: false,
            successMessage:
                '⚠️ $message\n'
                '👤 Usuário: $senderName',
          );
          break;

        case 'error':
          state = state.copyWith(isLoading: false, error: message);
          break;
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Erro ao gerar convite: $e',
      );
    }
  }

  // ============== LISTAR CONVITES ATIVOS ==============
  Future<void> loadActiveInvites(String currentUserId) async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      final invites = await TestUsersService.getActiveInvitesForUser(
        currentUserId,
      );

      if (invites.isEmpty) {
        state = state.copyWith(
          isLoading: false,
          successMessage: 'ℹ️ Nenhum convite ativo encontrado',
        );
      } else {
        final receivedCount = invites
            .where((i) => i['type'] == 'received')
            .length;
        final sentCount = invites.where((i) => i['type'] == 'sent').length;

        state = state.copyWith(
          isLoading: false,
          successMessage:
              '📋 Convites ativos:\n'
              '📥 Recebidos: $receivedCount\n'
              '📤 Enviados: $sentCount\n'
              '📊 Total: ${invites.length}',
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Erro ao carregar convites: $e',
      );
    }
  }

  // ============== LIMPAR CONVITES EXPIRADOS ==============
  Future<void> cleanupExpiredInvites() async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      // Buscar convites expirados
      final now = DateTime.now();
      final expiredInvites = await FirebaseFirestore.instance
          .collection('test_invites')
          .where('expiresAt', isLessThan: now.toIso8601String())
          .where('status', isEqualTo: 'pending')
          .get();

      if (expiredInvites.docs.isEmpty) {
        state = state.copyWith(
          isLoading: false,
          successMessage: 'ℹ️ Nenhum convite expirado encontrado',
        );
        return;
      }

      // Atualizar status para expirado
      final batch = FirebaseFirestore.instance.batch();
      for (final doc in expiredInvites.docs) {
        batch.update(doc.reference, {
          'status': 'expired',
          'updatedAt': now.toIso8601String(),
        });
      }
      await batch.commit();

      state = state.copyWith(
        isLoading: false,
        successMessage:
            '🧹 ${expiredInvites.docs.length} convites expirados limpos',
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Erro ao limpar convites: $e',
      );
    }
  }
}

// ============== TELA DE ADMINISTRAÇÃO ==============
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
  void dispose() {
    _countController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(testUsersAdminProvider);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Admin - Usuários de Teste'),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/home'),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.read(testUsersAdminProvider.notifier).loadStats();
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildStatsSection(state),
              const SizedBox(height: 20),
              _buildUserCreationSection(state),
              const SizedBox(height: 20),
              _buildMaintenanceSection(state),
              const SizedBox(height: 20),

              // ✅ NOVA SEÇÃO DE CONVITES
              _buildInviteTestSection(state, ref),

              const SizedBox(height: 20),
              _buildMessageDisplay(state),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatsSection(TestUsersAdminState state) {
    final stats = state.stats;

    return CustomCard(
      borderRadius: 0,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.analytics, color: Colors.blue),
              SizedBox(width: 8),
              Text(
                'Estatísticas',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (stats.isNotEmpty) ...[
            _buildStatItem(
              'Total de Usuários de Teste',
              stats['totalTestUsers'],
            ),
            _buildStatItem('Usuários Específicos', stats['totalSpecificUsers']),
            _buildStatItem('Total Geral', stats['totalUsers']),
            _buildStatItem('Usuários Online', stats['onlineUsers']),
          ] else ...[
            const Text('Carregando estatísticas...'),
          ],
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, dynamic value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            value?.toString() ?? '0',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildUserCreationSection(TestUsersAdminState state) {
    return CustomCard(
      borderRadius: 0,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.person_add, color: Colors.green),
              SizedBox(width: 8),
              Text(
                'Criar Usuários',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Usuários aleatórios
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _countController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Quantidade',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
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
              child: const Text('Manter Usuários Online'),
            ),
          ),
          const SizedBox(height: 12),

          SizedBox(
            width: double.infinity,
            child: AnimatedButton(
              onPressed: state.isLoading
                  ? null
                  : () {
                      _showDeleteConfirmation();
                    },
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              child: const Text('Deletar Todos os Usuários'),
            ),
          ),
        ],
      ),
    );
  }

  // ============== NOVA SEÇÃO DE CONVITES ==============
  Widget _buildInviteTestSection(TestUsersAdminState state, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final currentUser = authState.user;

    return CustomCard(
      borderRadius: 0,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.mail_outline, color: Colors.indigo),
              SizedBox(width: 8),
              Text(
                'Testes de Convites',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Informações do usuário atual
          if (currentUser != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: Colors.indigo[100],
                    child: Text(
                      currentUser.displayName.isNotEmpty
                          ? currentUser.displayName[0].toUpperCase()
                          : 'U',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.indigo[700],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Usuário Logado: ${currentUser.displayName}',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          'UID: ${currentUser.uid.substring(0, 8)}...',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Botão principal - Gerar convite aleatório
          SizedBox(
            width: double.infinity,
            child: AnimatedButton(
              onPressed: state.isLoading || currentUser == null
                  ? null
                  : () {
                      ref
                          .read(testUsersAdminProvider.notifier)
                          .generateRandomInvite(currentUser!.uid);
                    },
              backgroundColor: Colors.indigo,
              foregroundColor: Colors.white,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.casino, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    state.isLoading ? 'Gerando...' : 'Gerar Convite Aleatório',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Botões secundários em linha
          Row(
            children: [
              // Botão ver convites ativos
              Expanded(
                child: AnimatedButton(
                  onPressed: state.isLoading || currentUser == null
                      ? null
                      : () {
                          ref
                              .read(testUsersAdminProvider.notifier)
                              .loadActiveInvites(currentUser!.uid);
                        },
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  child: const Column(
                    children: [
                      Icon(Icons.list_alt, size: 18),
                      SizedBox(height: 4),
                      Text('Ver Convites', style: TextStyle(fontSize: 12)),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // Botão limpar expirados
              Expanded(
                child: AnimatedButton(
                  onPressed: state.isLoading
                      ? null
                      : () {
                          ref
                              .read(testUsersAdminProvider.notifier)
                              .cleanupExpiredInvites();
                        },
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  child: const Column(
                    children: [
                      Icon(Icons.cleaning_services, size: 18),
                      SizedBox(height: 4),
                      Text('Limpar Expirados', style: TextStyle(fontSize: 12)),
                    ],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Informações sobre o teste
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.indigo[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.indigo[200]!),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 16,
                      color: Colors.indigo[700],
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Como Funciona',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.indigo[700],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '• O convite será criado de um usuário de teste aleatório\n'
                  '• Você receberá uma notificação do convite\n'
                  '• O convite expira em 24 horas\n'
                  '• Use para testar o fluxo completo de unlock',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.indigo[600],
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageDisplay(TestUsersAdminState state) {
    if (state.successMessage == null && state.error == null) {
      return const SizedBox.shrink();
    }

    return CustomCard(
      borderRadius: 0,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (state.successMessage != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.green[600]),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      state.successMessage!,
                      style: TextStyle(color: Colors.green[700]),
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (state.error != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.error, color: Colors.red[600]),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      state.error!,
                      style: TextStyle(color: Colors.red[700]),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showDeleteConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Exclusão'),
        content: const Text(
          'Tem certeza que deseja deletar TODOS os usuários de teste? '
          'Esta ação não pode ser desfeita.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              ref.read(testUsersAdminProvider.notifier).deleteAllTestUsers();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Deletar Todos'),
          ),
        ],
      ),
    );
  }
}
