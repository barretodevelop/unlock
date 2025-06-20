import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:unlock/providers/auth_provider.dart'; // ✅ Importar AuthProvider

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen>
    with TickerProviderStateMixin {
  // Removido _isLoading local para depender do AuthProvider
  late AnimationController _logoController;
  late AnimationController _textController;
  late Animation<double> _logoAnimation;
  late Animation<double> _textAnimation;
  late Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();

    // Controlador para animação da logo
    _logoController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    // Controlador para animação do texto
    _textController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    // Animação de escala da logo
    _logoAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.elasticOut),
    );

    // Animação de rotação sutil da logo
    _rotationAnimation = Tween<double>(begin: 0.0, end: 0.1).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.easeInOut),
    );

    // Animação do texto com efeito typewriter
    _textAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _textController, curve: Curves.easeOut));

    // Iniciar animações
    _logoController.forward();
    Future.delayed(const Duration(milliseconds: 500), () {
      _textController.forward();
    });
  }

  @override
  void dispose() {
    _logoController.dispose();
    _textController.dispose();
    super.dispose();
  }

  Future<void> _handleSignIn() async {
    // ✅ Usar o método signInWithGoogle do AuthProvider
    final success = await ref.read(authProvider.notifier).signInWithGoogle();

    // O isLoading agora é gerenciado pelo AuthProvider,
    // então não precisamos mais de _isLoading local para o processo de login em si.
    // Poderíamos manter _isLoading para feedback visual específico do botão, se desejado,
    // mas o estado global de carregamento da autenticação é tratado pelo AuthProvider.
    // Por simplicidade, vamos remover o setState aqui, pois o GoRouter reagirá
    // às mudanças no AuthProvider.

    if (!mounted) return;

    if (!success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Falha ao fazer login com Google. Tente novamente.'),
        ),
      );
    }
    // Não há necessidade de setState para _isLoading = false aqui,
    // pois o AuthProvider cuidará do estado de carregamento.
    // A navegação será tratada pelo GoRouter observando o AuthProvider.
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(
      authProvider,
    ); // Observar o estado do AuthProvider para o botão
    final theme = Theme.of(context);

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              theme.primaryColor.withOpacity(0.8),
              theme.primaryColor.withOpacity(0.6),
              Colors.white.withOpacity(0.9),
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              // Removido SizedBox(height: size.height * 0.1) inicial
              padding: const EdgeInsets.symmetric(horizontal: 32.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // SizedBox(height: size.height * 0.1),

                  // Logo/Ícone principal com animação
                  AnimatedBuilder(
                    animation: _logoController,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _logoAnimation.value,
                        child: Transform.rotate(
                          angle: _rotationAnimation.value,
                          child: Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(60),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 20,
                                  offset: const Offset(0, 10),
                                ),
                                BoxShadow(
                                  color: theme.primaryColor.withOpacity(0.3),
                                  blurRadius: 40,
                                  offset: const Offset(0, 20),
                                ),
                              ],
                            ),
                            child: TweenAnimationBuilder<double>(
                              duration: const Duration(seconds: 2),
                              tween: Tween(begin: 0.0, end: 1.0),
                              builder: (context, value, child) {
                                return Icon(
                                  Icons.lock_open_rounded,
                                  size: 60,
                                  color: Color.lerp(
                                    theme.primaryColor.withOpacity(0.3),
                                    theme.primaryColor,
                                    value,
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 60), // Aumentado espaço
                  // Título com animação typewriter
                  AnimatedBuilder(
                    animation: _textAnimation,
                    builder: (context, child) {
                      const text = 'UNLOCK';
                      final displayText = text.substring(
                        0,
                        (_textAnimation.value * text.length).round(),
                      );

                      return ShaderMask(
                        shaderCallback: (bounds) => LinearGradient(
                          colors: [
                            Colors.white,
                            Colors.white.withOpacity(0.8),
                            theme.primaryColor.withOpacity(0.6),
                          ],
                        ).createShader(bounds),
                        child: Text(
                          displayText,
                          style: const TextStyle(
                            fontSize: 52,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 4.0,
                            color: Colors.white,
                            fontFamily: 'Roboto',
                            shadows: [
                              Shadow(
                                color: Colors.black26,
                                offset: Offset(2, 2),
                                blurRadius: 8,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 8),

                  // Subtítulo com fade in
                  AnimatedBuilder(
                    animation: _textAnimation,
                    builder: (context, child) {
                      return Opacity(
                        opacity: _textAnimation.value,
                        child: Transform.translate(
                          offset: Offset(0, 20 * (1 - _textAnimation.value)),
                          child: Text(
                            'Bem-vindo de volta!',
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: Colors.white.withOpacity(0.9),
                              fontWeight: FontWeight.w300,
                              fontSize: 18,
                            ),
                          ),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 80), // Aumentado espaço
                  // Card do formulário
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 30,
                          offset: const Offset(0, 15),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Text(
                          'Faça seu login',
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[800],
                          ),
                        ),

                        const SizedBox(height: 8),

                        Text(
                          'Use sua conta Google para continuar',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: Colors.grey[600],
                          ),
                          textAlign: TextAlign.center,
                        ),

                        const SizedBox(height: 40),

                        // Botão de login
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child:
                              authState
                                  .isLoading // Usar o isLoading do AuthProvider diretamente
                              ? Container(
                                  // ou observar ref.watch(authProvider.select((s) => s.status == AuthStatus.loading || s.isLoading))
                                  // se quiser ser mais preciso sobre o estado de carregamento do AuthProvider.
                                  // Por ora, vamos manter o _isLoading local para o feedback do botão.
                                  decoration: BoxDecoration(
                                    color: theme.primaryColor.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Center(
                                    child: SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                              theme.primaryColor,
                                            ),
                                      ),
                                    ),
                                  ),
                                )
                              : ElevatedButton.icon(
                                  onPressed: _handleSignIn,
                                  icon: Container(
                                    width: 24,
                                    height: 24,
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Image.network(
                                      'https://developers.google.com/identity/images/g-logo.png',
                                      width: 20,
                                      height: 20,
                                      errorBuilder:
                                          (context, error, stackTrace) {
                                            return const Icon(
                                              Icons.login,
                                              color: Colors.red,
                                              size: 20,
                                            );
                                          },
                                    ),
                                  ),
                                  label: const Text(
                                    'Continuar com Google',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: theme.primaryColor,
                                    foregroundColor: Colors.white,
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                  ),
                                ),
                        ),

                        const SizedBox(height: 24),

                        // Texto adicional
                        RichText(
                          textAlign: TextAlign.center,
                          text: TextSpan(
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.grey[600],
                            ),
                            children: const [
                              TextSpan(
                                text: 'Ao continuar, você concorda com nossos ',
                              ),
                              TextSpan(
                                text: 'Termos de Serviço',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                              TextSpan(text: ' e '),
                              TextSpan(
                                text: 'Política de Privacidade',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 40), // Ajustado espaço
                  // Rodapé
                  Text(
                    '© 2025 Unlock App',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.white.withOpacity(0.7),
                    ),
                  ),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
