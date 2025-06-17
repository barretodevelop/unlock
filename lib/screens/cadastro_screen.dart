// lib/screens/cadastro_screen.dart
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:unlock/data/mock_data_provider.dart';
import 'package:unlock/providers/auth_provider.dart';
import 'package:unlock/providers/user_provider.dart';
import 'package:unlock/widgtes/animated_button.dart';

class CadastroScreen extends ConsumerStatefulWidget {
  const CadastroScreen({super.key});

  @override
  ConsumerState<CadastroScreen> createState() => _CadastroScreenState();
}

class _CadastroScreenState extends ConsumerState<CadastroScreen>
    with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  int _currentPage = 0;
  final int _totalPages = 3;
  bool _isLoading = false;

  // Dados do formulário
  final TextEditingController _codinomeController = TextEditingController();
  final List<String> _interessesSelecionados = [];
  String? _selectedRelationshipInterest;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(_animationController);

    _animationController.forward();
  }

  void _nextPage() {
    if (_currentPage < _totalPages - 1) {
      setState(() {
        _currentPage++;
        _errorMessage = null;
      });
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      _animationController.reset();
      _animationController.forward();
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      setState(() {
        _currentPage--;
        _errorMessage = null;
      });
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      _animationController.reset();
      _animationController.forward();
    }
  }

  bool _validateCurrentPage() {
    setState(() {
      _errorMessage = null;
    });

    switch (_currentPage) {
      case 0:
        if (_codinomeController.text.trim().isEmpty) {
          setState(() {
            _errorMessage = 'Por favor, digite um codinome único.';
          });
          return false;
        }
        if (_codinomeController.text.trim().length < 3) {
          setState(() {
            _errorMessage = 'Codinome deve ter pelo menos 3 caracteres.';
          });
          return false;
        }
        break;
      case 1:
        if (_interessesSelecionados.isEmpty) {
          setState(() {
            _errorMessage = 'Escolha pelo menos um interesse.';
          });
          return false;
        }
        if (_interessesSelecionados.length < 3) {
          setState(() {
            _errorMessage =
                'Escolha pelo menos 3 interesses para melhores matches.';
          });
          return false;
        }
        break;
      case 2:
        if (_selectedRelationshipInterest == null) {
          setState(() {
            _errorMessage = 'Escolha seu interesse no app.';
          });
          return false;
        }
        break;
    }
    return true;
  }

  void _finalizarCadastro() async {
    if (!_validateCurrentPage()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Atualiza o perfil do usuário usando o provider

      // ✅ FALLBACK PARA PROVIDERS DESINCRONIZADOS
      final userState = ref.read(userProvider);
      final authState = ref.read(authProvider);

      if (userState == null && authState.user != null) {
        if (kDebugMode) {
          print('🔄 Sincronizando UserProvider...');
        }
        ref.read(userProvider.notifier).setUser(authState.user!);
      }

      await ref
          .read(userProvider.notifier)
          .updateProfile(
            codinome: _codinomeController.text.trim(),
            interesses: _interessesSelecionados,
            relationshipInterest: _selectedRelationshipInterest!,
          );

      // Marca o onboarding como completo no auth provider
      await ref.read(authProvider.notifier).completeOnboarding();

      if (mounted) {
        // Navegação com animação personalizada
        // Navigator.pushReplacement(
        //   context,
        //   PageRouteBuilder(
        //     pageBuilder: (context, animation, secondaryAnimation) =>
        //         const EnhancedHomeScreen(),
        //     transitionsBuilder:
        //         (context, animation, secondaryAnimation, child) {
        //           return SlideTransition(
        //             position: Tween<Offset>(
        //               begin: const Offset(1.0, 0.0),
        //               end: Offset.zero,
        //             ).animate(animation),
        //             child: child,
        //           );
        //         },
        //     transitionDuration: const Duration(milliseconds: 500),
        //   ),
        // );
        context.go('/home');
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Erro ao salvar perfil: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Header com progresso
            Container(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Row(
                    children: [
                      if (_currentPage > 0)
                        IconButton(
                          onPressed: _isLoading ? null : _previousPage,
                          icon: const Icon(Icons.arrow_back),
                        ),
                      const Spacer(),
                      Text(
                        'Passo ${_currentPage + 1} de $_totalPages',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const Spacer(),
                      SizedBox(width: _currentPage > 0 ? 48 : 0),
                    ],
                  ),
                  const SizedBox(height: 16),
                  LinearProgressIndicator(
                    value: (_currentPage + 1) / _totalPages,
                    backgroundColor: Colors.grey[300],
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Theme.of(context).primaryColor,
                    ),
                  ),
                ],
              ),
            ),

            // Conteúdo das páginas
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _buildCodinomePage(),
                  _buildInteressesPage(),
                  _buildRelationshipPage(),
                ],
              ),
            ),

            // Footer com botões
            Container(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  if (_errorMessage != null)
                    Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.error_outline,
                            color: Colors.red.shade600,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _errorMessage!,
                              style: TextStyle(
                                color: Colors.red.shade700,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  SizedBox(
                    width: double.infinity,
                    child: AnimatedButton(
                      onPressed: _isLoading
                          ? null
                          : () {
                              if (_currentPage == _totalPages - 1) {
                                _finalizarCadastro();
                              } else if (_validateCurrentPage()) {
                                _nextPage();
                              }
                            },
                      backgroundColor: Theme.of(context).primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                          : Text(
                              _currentPage == _totalPages - 1
                                  ? 'Entrar no App'
                                  : 'Continuar',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCodinomePage() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            Text(
              '👋 Olá!',
              style: Theme.of(
                context,
              ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Como você gostaria de ser chamado?',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(color: Colors.grey[600]),
            ),
            const SizedBox(height: 40),
            TextField(
              controller: _codinomeController,
              enabled: !_isLoading,
              decoration: InputDecoration(
                labelText: 'Seu codinome único',
                hintText: 'Ex: Aventureiro_07, MusicLover, etc.',
                prefixIcon: const Icon(Icons.person),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: Theme.of(context).primaryColor,
                    width: 2,
                  ),
                ),
              ),
              textCapitalization: TextCapitalization.none,
              maxLength: 20,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: Colors.blue.shade600,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Seu codinome é como outros usuários te encontrarão. Seja criativo!',
                      style: TextStyle(
                        color: Colors.blue.shade700,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInteressesPage() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            Text(
              '🎯 Seus Interesses',
              style: Theme.of(
                context,
              ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Escolha pelo menos 3 coisas que você ama:',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(color: Colors.grey[600]),
            ),
            const SizedBox(height: 20),
            Text(
              'Selecionados: ${_interessesSelecionados.length}',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: _interessesSelecionados.length >= 3
                    ? Colors.green
                    : Colors.orange,
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: SingleChildScrollView(
                child: Wrap(
                  spacing: 8.0,
                  runSpacing: 8.0,
                  children: MockDataProvider.availableInterests.map((
                    interesse,
                  ) {
                    final isSelected = _interessesSelecionados.contains(
                      interesse,
                    );
                    return FilterChip(
                      label: Text(interesse),
                      selected: isSelected,
                      onSelected: _isLoading
                          ? null
                          : (selected) {
                              setState(() {
                                if (selected) {
                                  _interessesSelecionados.add(interesse);
                                } else {
                                  _interessesSelecionados.remove(interesse);
                                }
                              });
                            },
                      selectedColor: Theme.of(
                        context,
                      ).primaryColor.withOpacity(0.2),
                      checkmarkColor: Theme.of(context).primaryColor,
                      backgroundColor: Colors.grey.shade100,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRelationshipPage() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            Text(
              '❤️ Seu Objetivo',
              style: Theme.of(
                context,
              ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'O que você está buscando no app?',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(color: Colors.grey[600]),
            ),
            const SizedBox(height: 30),
            Expanded(
              child: ListView.builder(
                itemCount: MockDataProvider.relationshipTypes.length,
                itemBuilder: (context, index) {
                  final type = MockDataProvider.relationshipTypes[index];
                  final isSelected =
                      _selectedRelationshipInterest == type['id'];

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: Card(
                      elevation: isSelected ? 4 : 1,
                      color: isSelected ? type['color'].withOpacity(0.1) : null,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          color: isSelected
                              ? type['color']
                              : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      child: InkWell(
                        onTap: _isLoading
                            ? null
                            : () {
                                setState(() {
                                  _selectedRelationshipInterest = type['id'];
                                });
                              },
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: type['color'].withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  type['icon'],
                                  color: type['color'],
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      type['name'],
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      type['description'],
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (isSelected)
                                Icon(
                                  Icons.check_circle,
                                  color: type['color'],
                                  size: 24,
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    _codinomeController.dispose();
    _animationController.dispose();
    super.dispose();
  }
}
