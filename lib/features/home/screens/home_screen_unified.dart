// // lib/features/home/screens/home_screen_unified.dart - VERSÃO DEFINITIVA
// import 'package:flutter/material.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:go_router/go_router.dart';
// import 'package:unlock/core/constants/app_constants.dart';
// import 'package:unlock/core/utils/logger.dart';
// import 'package:unlock/features/home/widgets/challenge_carousel.dart';
// import 'package:unlock/features/home/widgets/featured_groups_widget.dart';
// import 'package:unlock/features/home/widgets/home_header.dart';
// import 'package:unlock/features/home/widgets/modern_app_bar.dart';
// import 'package:unlock/features/home/widgets/quick_stats_widget.dart';
// import 'package:unlock/features/home/widgets/recent_activity_widget.dart';
// import 'package:unlock/features/mini_games/widgets/home_mini_games_section.dart';
// import 'package:unlock/models/user_model.dart';
// import 'package:unlock/providers/auth_provider.dart';
// import 'package:unlock/providers/challenge_provider.dart';
// import 'package:unlock/providers/group_provider.dart';
// import 'package:unlock/shared/widgets/avatar_circle.dart';
// import 'package:unlock/shared/widgets/empty_state.dart';
// import 'package:unlock/shared/widgets/loading_overlay.dart';
// import 'package:unlock/shared/widgets/stat_card.dart';
// import 'package:unlock/shared/widgets/themed_card.dart';

// /// Home Screen Unificada - Versão Definitiva
// ///
// /// Características principais:
// /// - Dashboard com estatísticas do usuário
// /// - Carrossel de desafios ativos
// /// - Seção de grupos em destaque
// /// - Mini-games integrados
// /// - Atividade recente
// /// - Ações rápidas
// /// - AppBar moderna com notificações
// /// - Navegação otimizada
// /// - Analytics integrado
// class HomeScreenUnified extends ConsumerStatefulWidget {
//   const HomeScreenUnified({super.key});

//   @override
//   ConsumerState<HomeScreenUnified> createState() => _HomeScreenUnifiedState();
// }

// class _HomeScreenUnifiedState extends ConsumerState<HomeScreenUnified>
//     with TickerProviderStateMixin {
//   // Controladores de animação
//   late AnimationController _animationController;
//   late AnimationController _fabController;
//   late Animation<double> _fadeAnimation;
//   late Animation<Offset> _slideAnimation;

//   // Controle de scroll
//   final ScrollController _scrollController = ScrollController();
//   bool _showElevatedAppBar = false;

//   // Estado da tela
//   bool _isRefreshing = false;
//   int _selectedQuickAction = -1;

//   @override
//   void initState() {
//     super.initState();

//     AppLogger.info('🏠 HomeScreenUnified: Iniciada');

//     // Configurar animações
//     _setupAnimations();

//     // Configurar scroll listener
//     _scrollController.addListener(_onScroll);

//     // Carregar dados iniciais
//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       _loadInitialData();
//     });

//     // Analytics
//     // AnalyticsIntegration.trackScreen(
//     //   'home_screen',
//     //   screenClass: 'HomeScreenUnified',
//     //   parameters: {'version': 'unified'},
//     // );
//   }

//   @override
//   void dispose() {
//     _animationController.dispose();
//     _fabController.dispose();
//     _scrollController.dispose();
//     AppLogger.info('🧹 HomeScreenUnified: Disposed');
//     super.dispose();
//   }

//   /// Configurar animações
//   void _setupAnimations() {
//     _animationController = AnimationController(
//       duration: AppConstants.animationDuration,
//       vsync: this,
//     );

//     _fabController = AnimationController(
//       duration: const Duration(milliseconds: 300),
//       vsync: this,
//     );

//     _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
//       CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
//     );

//     _slideAnimation =
//         Tween<Offset>(begin: const Offset(0.0, 0.2), end: Offset.zero).animate(
//           CurvedAnimation(
//             parent: _animationController,
//             curve: Curves.easeOutBack,
//           ),
//         );

//     // Iniciar animações
//     _animationController.forward();
//     _fabController.forward();
//   }

//   /// Listener do scroll
//   void _onScroll() {
//     final shouldShow = _scrollController.offset > 100;
//     if (shouldShow != _showElevatedAppBar) {
//       setState(() {
//         _showElevatedAppBar = shouldShow;
//       });
//     }
//   }

//   /// Carregar dados iniciais
//   Future<void> _loadInitialData() async {
//     final user = ref.read(authProvider.select((state) => state.user));
//     if (user == null) return;

//     try {
//       // Invalidar providers para recarregar dados
//       ref.invalidate(activeChallengesProvider);
//       ref.invalidate(userGroupsProvider);

//       AppLogger.debug('📊 Dados iniciais da home carregados');
//     } catch (e) {
//       AppLogger.error('❌ Erro ao carregar dados iniciais', error: e);
//     }
//   }

//   /// Refresh dos dados
//   Future<void> _refreshData() async {
//     if (_isRefreshing) return;

//     setState(() {
//       _isRefreshing = true;
//     });

//     try {
//       await _loadInitialData();

//       // Analytics
//       // await AnalyticsIntegration.trackEvent('home_refresh');

//       // Feedback visual
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(
//             content: Text('Dados atualizados!'),
//             duration: Duration(seconds: 1),
//           ),
//         );
//       }
//     } catch (e) {
//       AppLogger.error('❌ Erro no refresh', error: e);

//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(
//             content: Text('Erro ao atualizar dados'),
//             backgroundColor: Colors.red,
//           ),
//         );
//       }
//     } finally {
//       if (mounted) {
//         setState(() {
//           _isRefreshing = false;
//         });
//       }
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     final authState = ref.watch(authProvider);

//     // Loading state
//     if (authState.isLoading) {
//       return _buildLoadingScreen();
//     }

//     // Usuário não autenticado
//     if (!authState.isAuthenticated || authState.user == null) {
//       return _buildUnauthenticatedScreen();
//     }

//     return AnimatedBuilder(
//       animation: _animationController,
//       builder: (context, child) {
//         return LoadingOverlay(
//           isLoading: _isRefreshing,
//           message: 'Atualizando...',
//           child: Scaffold(
//             appBar: _buildAppBar(context, authState.user!),
//             body: _buildBody(context, authState.user!),
//             floatingActionButton: _buildFloatingActionButton(context),
//             floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
//           ),
//         );
//       },
//     );
//   }

//   /// Construir AppBar moderna
//   PreferredSizeWidget _buildAppBar(BuildContext context, UserModel user) {
//     return ModernAppBarVariant(
//       title: _showElevatedAppBar ? 'Unlock' : '',
//       // title: AnimatedOpacity(
//       //   opacity: _showElevatedAppBar ? 1.0 : 0.0,
//       //   duration: AppConstants.animationDuration,
//       //   child: const Text('Unlock'),
//       // backgroundColor: _showElevatedAppBar
//       //     ? Theme.of(context).colorScheme.surface
//       //     : Colors.transparent,
//       // elevation: _showElevatedAppBar ? 2 : 0,
//       actions: [
//         // Notificações
//         IconButton(
//           icon: Stack(
//             children: [
//               const Icon(Icons.notifications_outlined),
//               // Badge de notificações não lidas
//               Positioned(
//                 right: 0,
//                 top: 0,
//                 child: Container(
//                   padding: const EdgeInsets.all(2),
//                   decoration: BoxDecoration(
//                     color: Theme.of(context).colorScheme.error,
//                     borderRadius: BorderRadius.circular(6),
//                   ),
//                   constraints: const BoxConstraints(
//                     minWidth: 12,
//                     minHeight: 12,
//                   ),
//                   child: const Text(
//                     '2',
//                     style: TextStyle(color: Colors.white, fontSize: 8),
//                     textAlign: TextAlign.center,
//                   ),
//                 ),
//               ),
//             ],
//           ),
//           onPressed: () => _showNotificationsDialog(context),
//         ),

//         // Avatar do usuário
//         Padding(
//           padding: const EdgeInsets.only(right: 8),
//           child: GestureDetector(
//             onTap: () => context.push('/profile'),
//             child: AvatarCircle.user(
//               imageUrl: user.avatar,
//               displayName: user.displayName,
//               size: 32,
//               showBorder: true,
//             ),
//           ),
//         ),
//       ],
//     );
//   }

//   /// Construir corpo da tela
//   Widget _buildBody(BuildContext context, UserModel user) {
//     return FadeTransition(
//       opacity: _fadeAnimation,
//       child: SlideTransition(
//         position: _slideAnimation,
//         child: RefreshIndicator(
//           onRefresh: _refreshData,
//           child: CustomScrollView(
//             controller: _scrollController,
//             slivers: [
//               // Header com saudação e estatísticas
//               SliverToBoxAdapter(child: HomeHeader(user: user)),

//               // Estatísticas rápidas
//               SliverToBoxAdapter(child: _buildQuickStatsSection(context, user)),

//               // Ações rápidas
//               SliverToBoxAdapter(child: _buildQuickActionsSection(context)),

//               // Desafios em destaque
//               SliverToBoxAdapter(
//                 child: _buildSection(
//                   context,
//                   title: 'Desafios em Destaque',
//                   subtitle: 'Competições acontecendo agora',
//                   icon: Icons.emoji_events,
//                   onSeeAll: () => context.push('/challenges'),
//                   child: const ChallengeCarousel(),
//                 ),
//               ),

//               // Mini-games
//               SliverToBoxAdapter(
//                 child: _buildSection(
//                   context,
//                   title: 'Mini-Games',
//                   subtitle: 'Diversão rápida e pontos',
//                   icon: Icons.games,
//                   onSeeAll: () => context.push('/games'),
//                   child: const HomeMiniGamesSection(),
//                 ),
//               ),

//               // Grupos em destaque
//               SliverToBoxAdapter(
//                 child: _buildSection(
//                   context,
//                   title: 'Seus Grupos',
//                   subtitle: 'Conecte-se e compete',
//                   icon: Icons.group,
//                   onSeeAll: () => context.push('/groups'),
//                   child: const FeaturedGroupsWidget(),
//                 ),
//               ),

//               // Atividade recente
//               SliverToBoxAdapter(
//                 child: _buildSection(
//                   context,
//                   title: 'Atividade Recente',
//                   subtitle: 'O que está rolando',
//                   icon: Icons.timeline,
//                   child: const RecentActivityWidget(),
//                 ),
//               ),

//               // Rankings rápidos
//               SliverToBoxAdapter(child: _buildRankingsPreview(context)),

//               // Espaço final para FAB
//               const SliverToBoxAdapter(child: SizedBox(height: 100)),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   /// Construir seção de estatísticas rápidas
//   Widget _buildQuickStatsSection(BuildContext context, UserModel user) {
//     return Padding(
//       padding: const EdgeInsets.all(16),
//       child: Column(
//         children: [
//           QuickStatsWidget(user: user),
//           const SizedBox(height: 16),

//           // Estatísticas adicionais em cards
//           Row(
//             children: [
//               Expanded(
//                 child: StatCard.compact(
//                   title: 'Streak',
//                   value: '${user.loginStreak ?? 0} dias',
//                   icon: Icons.local_fire_department,
//                   color: Colors.orange,
//                   onTap: () => _showStreakDialog(context),
//                 ),
//               ),
//               const SizedBox(width: 12),
//               Expanded(
//                 child: StatCard.compact(
//                   title: 'Ranking',
//                   value: '#42',
//                   icon: Icons.leaderboard,
//                   color: Colors.purple,
//                   onTap: () => context.push('/rankings'),
//                 ),
//               ),
//             ],
//           ),
//         ],
//       ),
//     );
//   }

//   /// Construir seção de ações rápidas
//   Widget _buildQuickActionsSection(BuildContext context) {
//     final quickActions = [
//       QuickAction(
//         icon: Icons.add_circle,
//         label: 'Criar Desafio',
//         color: Colors.blue,
//         onTap: () => context.push('/challenges/create'),
//       ),
//       QuickAction(
//         icon: Icons.group_add,
//         label: 'Novo Grupo',
//         color: Colors.green,
//         onTap: () => context.push('/groups/create'),
//       ),
//       QuickAction(
//         icon: Icons.qr_code_scanner,
//         label: 'Escanear QR',
//         color: Colors.orange,
//         onTap: () => _showQRScanner(context),
//       ),
//       QuickAction(
//         icon: Icons.sports_esports,
//         label: 'Jogar',
//         color: Colors.purple,
//         onTap: () => context.push('/games'),
//       ),
//     ];

//     return Padding(
//       padding: const EdgeInsets.symmetric(horizontal: 16),
//       child: ThemedCard(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text(
//               'Ações Rápidas',
//               style: Theme.of(
//                 context,
//               ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
//             ),
//             const SizedBox(height: 16),
//             GridView.builder(
//               shrinkWrap: true,
//               physics: const NeverScrollableScrollPhysics(),
//               gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
//                 crossAxisCount: 4,
//                 childAspectRatio: 1,
//                 crossAxisSpacing: 12,
//                 mainAxisSpacing: 12,
//               ),
//               itemCount: quickActions.length,
//               itemBuilder: (context, index) {
//                 final action = quickActions[index];
//                 final isSelected = _selectedQuickAction == index;

//                 return GestureDetector(
//                   onTap: () {
//                     setState(() {
//                       _selectedQuickAction = index;
//                     });

//                     // Analytics
//                     // AnalyticsIntegration.trackEvent(
//                     //   'quick_action_tapped',
//                     //   parameters: {'action': action.label},
//                     // );

//                     // Executar ação após pequeno delay para mostrar feedback
//                     Future.delayed(const Duration(milliseconds: 150), () {
//                       if (mounted) {
//                         setState(() {
//                           _selectedQuickAction = -1;
//                         });
//                         action.onTap();
//                       }
//                     });
//                   },
//                   child: AnimatedContainer(
//                     duration: const Duration(milliseconds: 150),
//                     decoration: BoxDecoration(
//                       color: isSelected
//                           ? action.color.withOpacity(0.2)
//                           : action.color.withOpacity(0.1),
//                       borderRadius: BorderRadius.circular(12),
//                       border: Border.all(
//                         color: isSelected
//                             ? action.color
//                             : action.color.withOpacity(0.3),
//                         width: isSelected ? 2 : 1,
//                       ),
//                     ),
//                     child: Column(
//                       mainAxisAlignment: MainAxisAlignment.center,
//                       children: [
//                         Icon(action.icon, color: action.color, size: 24),
//                         const SizedBox(height: 4),
//                         Text(
//                           action.label,
//                           style: Theme.of(context).textTheme.bodySmall
//                               ?.copyWith(
//                                 color: action.color,
//                                 fontWeight: FontWeight.w500,
//                               ),
//                           textAlign: TextAlign.center,
//                           maxLines: 1,
//                           overflow: TextOverflow.ellipsis,
//                         ),
//                       ],
//                     ),
//                   ),
//                 );
//               },
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   /// Construir preview dos rankings
//   Widget _buildRankingsPreview(BuildContext context) {
//     return Padding(
//       padding: const EdgeInsets.all(16),
//       child: ThemedCard(
//         header: Padding(
//           padding: const EdgeInsets.all(16),
//           child: Row(
//             children: [
//               Icon(
//                 Icons.leaderboard,
//                 color: Theme.of(context).colorScheme.primary,
//               ),
//               const SizedBox(width: 8),
//               Expanded(
//                 child: Text(
//                   'Rankings',
//                   style: Theme.of(context).textTheme.titleMedium?.copyWith(
//                     fontWeight: FontWeight.bold,
//                   ),
//                 ),
//               ),
//               TextButton(
//                 onPressed: () => context.push('/rankings'),
//                 child: const Text('Ver Todos'),
//               ),
//             ],
//           ),
//         ),
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           children: [
//             _buildRankingItem(
//               context,
//               1,
//               'João Silva',
//               2450,
//               'assets/images/avatars/1.png',
//             ),
//             _buildRankingItem(
//               context,
//               2,
//               'Maria Costa',
//               2380,
//               'assets/images/avatars/2.png',
//             ),
//             _buildRankingItem(
//               context,
//               3,
//               'Pedro Santos',
//               2290,
//               'assets/images/avatars/3.png',
//             ),
//             const SizedBox(height: 8),
//             Container(
//               padding: const EdgeInsets.all(12),
//               decoration: BoxDecoration(
//                 color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
//                 borderRadius: BorderRadius.circular(8),
//                 border: Border.all(
//                   color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
//                 ),
//               ),
//               child: Row(
//                 children: [
//                   Container(
//                     width: 24,
//                     height: 24,
//                     decoration: BoxDecoration(
//                       color: Theme.of(context).colorScheme.primary,
//                       borderRadius: BorderRadius.circular(4),
//                     ),
//                     child: Center(
//                       child: Text(
//                         '42',
//                         style: Theme.of(context).textTheme.bodySmall?.copyWith(
//                           color: Colors.white,
//                           fontWeight: FontWeight.bold,
//                         ),
//                       ),
//                     ),
//                   ),
//                   const SizedBox(width: 12),
//                   const Text('Você'),
//                   const Spacer(),
//                   Text(
//                     '1,890 XP',
//                     style: Theme.of(context).textTheme.bodyMedium?.copyWith(
//                       fontWeight: FontWeight.bold,
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   /// Construir item do ranking
//   Widget _buildRankingItem(
//     BuildContext context,
//     int position,
//     String name,
//     int xp,
//     String avatarPath,
//   ) {
//     final positionColors = [Colors.amber, Colors.grey, Colors.orange];
//     final positionColor = position <= 3
//         ? positionColors[position - 1]
//         : Theme.of(context).colorScheme.outline;

//     return Padding(
//       padding: const EdgeInsets.symmetric(vertical: 4),
//       child: Row(
//         children: [
//           Container(
//             width: 24,
//             height: 24,
//             decoration: BoxDecoration(
//               color: positionColor,
//               borderRadius: BorderRadius.circular(4),
//             ),
//             child: Center(
//               child: Text(
//                 '$position',
//                 style: Theme.of(context).textTheme.bodySmall?.copyWith(
//                   color: Colors.white,
//                   fontWeight: FontWeight.bold,
//                 ),
//               ),
//             ),
//           ),
//           const SizedBox(width: 12),
//           AvatarCircle(
//             assetPath: avatarPath,
//             initials: name.split(' ').map((e) => e[0]).join(),
//             size: 32,
//           ),
//           const SizedBox(width: 12),
//           Expanded(
//             child: Text(name, style: Theme.of(context).textTheme.bodyMedium),
//           ),
//           Text(
//             '$xp XP',
//             style: Theme.of(
//               context,
//             ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
//           ),
//         ],
//       ),
//     );
//   }

//   /// Construir seção genérica
//   Widget _buildSection(
//     BuildContext context, {
//     required String title,
//     String? subtitle,
//     required IconData icon,
//     required Widget child,
//     VoidCallback? onSeeAll,
//   }) {
//     return Padding(
//       padding: const EdgeInsets.all(16),
//       child: Column(
//         children: [
//           Row(
//             children: [
//               Container(
//                 padding: const EdgeInsets.all(8),
//                 decoration: BoxDecoration(
//                   color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
//                   borderRadius: BorderRadius.circular(8),
//                 ),
//                 child: Icon(
//                   icon,
//                   color: Theme.of(context).colorScheme.primary,
//                   size: 20,
//                 ),
//               ),
//               const SizedBox(width: 12),
//               Expanded(
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Text(
//                       title,
//                       style: Theme.of(context).textTheme.titleMedium?.copyWith(
//                         fontWeight: FontWeight.bold,
//                       ),
//                     ),
//                     if (subtitle != null)
//                       Text(
//                         subtitle,
//                         style: Theme.of(context).textTheme.bodySmall?.copyWith(
//                           color: Theme.of(
//                             context,
//                           ).colorScheme.onSurface.withOpacity(0.7),
//                         ),
//                       ),
//                   ],
//                 ),
//               ),
//               if (onSeeAll != null)
//                 TextButton(onPressed: onSeeAll, child: const Text('Ver Todos')),
//             ],
//           ),
//           const SizedBox(height: 16),
//           child,
//         ],
//       ),
//     );
//   }

//   /// Construir FAB
//   Widget? _buildFloatingActionButton(BuildContext context) {
//     return AnimatedBuilder(
//       animation: _fabController,
//       builder: (context, child) {
//         return Transform.scale(
//           scale: _fabController.value,
//           child: FloatingActionButton(
//             onPressed: () => _showCreateMenu(context),
//             child: const Icon(Icons.add),
//           ),
//         );
//       },
//     );
//   }

//   /// Construir tela de loading
//   Widget _buildLoadingScreen() {
//     return Scaffold(
//       body: Center(
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             const CircularProgressIndicator(),
//             const SizedBox(height: 16),
//             Text('Carregando...', style: Theme.of(context).textTheme.bodyLarge),
//           ],
//         ),
//       ),
//     );
//   }

//   /// Construir tela não autenticada
//   Widget _buildUnauthenticatedScreen() {
//     return Scaffold(
//       body: EmptyState(
//         icon: Icons.login,
//         title: 'Faça login para continuar',
//         subtitle: 'Acesse sua conta para ver o dashboard',
//         actionLabel: 'Fazer Login',
//         onAction: () => context.go('/login'),
//       ),
//     );
//   }

//   // ========== MÉTODOS DE AÇÕES ==========

//   /// Mostrar diálogo de notificações
//   void _showNotificationsDialog(BuildContext context) {
//     showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: const Text('Notificações'),
//         content: const Text('Você tem 2 notificações não lidas'),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.of(context).pop(),
//             child: const Text('Fechar'),
//           ),
//           TextButton(
//             onPressed: () {
//               Navigator.of(context).pop();
//               context.push('/notifications');
//             },
//             child: const Text('Ver Todas'),
//           ),
//         ],
//       ),
//     );
//   }

//   /// Mostrar diálogo de streak
//   void _showStreakDialog(BuildContext context) {
//     showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: const Text('🔥 Sequência de Login'),
//         content: const Text(
//           'Você está em uma sequência de 5 dias consecutivos! Continue assim para ganhar mais XP.',
//         ),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.of(context).pop(),
//             child: const Text('Legal!'),
//           ),
//         ],
//       ),
//     );
//   }

//   /// Mostrar scanner de QR
//   void _showQRScanner(BuildContext context) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       const SnackBar(content: Text('Scanner QR em desenvolvimento')),
//     );
//   }

//   /// Mostrar menu de criação
//   void _showCreateMenu(BuildContext context) {
//     showModalBottomSheet(
//       context: context,
//       builder: (context) => Container(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             const Text(
//               'O que você quer criar?',
//               style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
//             ),
//             const SizedBox(height: 16),
//             ListTile(
//               leading: const Icon(Icons.emoji_events),
//               title: const Text('Novo Desafio'),
//               onTap: () {
//                 Navigator.of(context).pop();
//                 context.push('/challenges/create');
//               },
//             ),
//             ListTile(
//               leading: const Icon(Icons.group),
//               title: const Text('Novo Grupo'),
//               onTap: () {
//                 Navigator.of(context).pop();
//                 context.push('/groups/create');
//               },
//             ),
//             ListTile(
//               leading: const Icon(Icons.games),
//               title: const Text('Mini-Game'),
//               onTap: () {
//                 Navigator.of(context).pop();
//                 context.push('/games');
//               },
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

// /// Modelo para ações rápidas
// class QuickAction {
//   final IconData icon;
//   final String label;
//   final Color color;
//   final VoidCallback onTap;

//   const QuickAction({
//     required this.icon,
//     required this.label,
//     required this.color,
//     required this.onTap,
//   });
// }
