import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:unlock/screens/home_screen.dart';
import 'package:unlock/screens/login_screen.dart';
// Se você mover AuthService para services/auth_service.dart, o import seria:
// import 'package:unlock/services/auth_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuthStateAndNavigate();
  }

  Future<void> _checkAuthStateAndNavigate() async {
    // Aguarda um pouco para simular carregamento e dar tempo para o Firebase inicializar
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return; // Garante que o widget ainda está na árvore

    User? user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const HomeScreen()),
      );
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 20),
            Text("Carregando..."),
          ],
        ),
      ),
    );
  }
}