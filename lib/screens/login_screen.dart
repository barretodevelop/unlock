import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:unlock/models/user_model.dart';
import 'package:unlock/providers/user_provider.dart';
import 'package:unlock/screens/home_screen.dart';
import 'package:unlock/services/auth_service.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  // final AuthService _authService = AuthService();
  bool _isLoading = false;

  Future<void> _handleSignIn() async {
    setState(() {
      _isLoading = true;
    });

    // AuthService.signInWithGoogle now calls getOrCreateUserInFirestore
    UserModel? user = await AuthService.signInWithGoogle();

    // Verifica se o widget ainda está montado antes de atualizar o estado ou navegar
    if (!mounted) return;

    // Update isLoading regardless of success or failure before any potential navigation
    // or showing a SnackBar that might depend on the build context.
    setState(() {
      _isLoading = false;
    });

    if (user != null) {
      // Optimistically update the user provider.
      // The UserNotifier's auth state listener will also update it,
      // ensuring consistency. This just makes the UI feel faster.
      ref.read(userProvider.notifier).setUser(user);

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const HomeScreen()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Falha ao fazer login com Google. Tente novamente.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      body: Center(
        child: _isLoading
            ? const CircularProgressIndicator()
            : ElevatedButton.icon(
                icon: const Icon(
                  Icons.login,
                ), // Você pode usar um ícone do Google aqui
                label: const Text('Entrar com Google'),
                onPressed: _handleSignIn,
              ),
      ),
    );
  }
}
