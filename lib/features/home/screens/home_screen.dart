import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:unlock/features/auth/screens/login_screen.dart';
import 'package:unlock/providers/user_provider.dart';
import 'package:unlock/services/auth_service.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(userProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Página Inicial'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await AuthService.signOut();
              if (context.mounted) {
                // Navega para LoginScreen e remove todas as rotas anteriores
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                  (Route<dynamic> route) => false,
                );
              }
            },
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              'Bem-vindo(a)!',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            if (user?.avatar != null)
              CircleAvatar(
                backgroundImage: NetworkImage(user!.avatar!),
                radius: 40,
              ),
            if (user?.displayName != null) Text('Nome: ${user!.displayName}'),
            if (user?.email != null) Text('Email: ${user!.email}'),
          ],
        ),
      ),
    );
  }
}
