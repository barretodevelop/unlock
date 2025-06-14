// lib/screens/profile_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:unlock/providers/auth_provider.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final user = authState.user;

    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        title: const Text('Perfil'),
        backgroundColor: const Color(0xFF1E293B),
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Profile header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF9333EA), Color(0xFF2563EB)],
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.white.withOpacity(0.2),
                    child: Text(
                      user.avatar,
                      style: const TextStyle(fontSize: 50),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    user.displayName,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    user.email,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withOpacity(0.8),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // User stats
            _buildStatsGrid(user),

            const SizedBox(height: 30),

            // User info
            _buildInfoSection(user),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsGrid(user) {
    final stats = [
      {'label': 'Nível', 'value': '${user.level}', 'icon': Icons.stars},
      {'label': 'XP', 'value': '${user.xp}', 'icon': Icons.flash_on},
      {
        'label': 'Moedas',
        'value': '${user.coins}',
        'icon': Icons.monetization_on,
      },
      {'label': 'Gemas', 'value': '${user.gems}', 'icon': Icons.diamond},
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.5,
      ),
      itemCount: stats.length,
      itemBuilder: (context, index) {
        final stat = stats[index];
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                stat['icon'] as IconData,
                color: const Color(0xFF9333EA),
                size: 32,
              ),
              const SizedBox(height: 8),
              Text(
                stat['value'] as String,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              Text(
                stat['label'] as String,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white.withOpacity(0.7),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInfoSection(user) {
    final info = [
      {'label': 'Nome de usuário', 'value': user.username},
      {'label': 'Email', 'value': user.email},
      {'label': 'Membro desde', 'value': _formatDate(user.createdAt)},
      {
        'label': 'Último login',
        'value': _formatDate(user.lastLoginAt ?? user.createdAt),
      },
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Informações da Conta',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          ...info
              .map(
                (item) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 120,
                        child: Text(
                          item['label'] as String,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.7),
                            fontSize: 14,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          item['value'] as String,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              )
              .toList(),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
