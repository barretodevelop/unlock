import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:unlock/features/connections/providers/connections_provider.dart';
import 'package:unlock/features/connections/widgets/connection_list_tile.dart';

class ConnectionsScreen extends ConsumerWidget {
  const ConnectionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final connectionsAsync = ref.watch(connectionsProvider);

    return Scaffold(
      body: connectionsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Erro ao carregar conexões: $err',
              textAlign: TextAlign.center,
            ),
          ),
        ),
        data: (connections) {
          if (connections.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.people_outline,
                      size: 80,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Nenhuma conexão formada',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Jogue para desbloquear novas conexões e começar a conversar!',
                      style: TextStyle(color: Colors.grey[600]),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.separated(
            itemCount: connections
                .length, // ✅ CORREÇÃO: Removido o padding desnecessário aqui
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final connection = connections[index];
              return ConnectionListTile(connection: connection)
                  .animate()
                  .fadeIn(delay: (100 * index).ms, duration: 300.ms)
                  .slideX(begin: -0.1, curve: Curves.easeOutCubic);
            },
          );
        },
      ),
    );
  }
}
