// lib/features/home/screens/home_screen.dart - VERSÃO COMPLETA E CORRIGIDA
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Importe para HapticFeedback
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:unlock/core/constants/app_constants.dart'; // Importe as constantes
import 'package:unlock/core/router/app_router.dart';
import 'package:unlock/core/utils/logger.dart';
import 'package:unlock/features/missions/providers/missions_provider.dart';
import 'package:unlock/features/missions/widgets/mission_card.dart';
import 'package:unlock/models/user_model.dart'; // Importar UserModel
import 'package:unlock/providers/auth_provider.dart';
import 'package:unlock/providers/theme_provider.dart';

/// ✅ Tela principal completa com logout e missões reais
class HomeScreen extends ConsumerStatefulWidget {
  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with SingleTickerProviderStateMixin {
  // Animação para o emoji do humor
  late final AnimationController _moodAnimationController;
  late final Animation<Offset> _moodOffsetAnimation;
  late final Animation<double> _moodFadeAnimation;
  String _animatingMoodEmoji = '';

  @override
  void initState() {
    super.initState();
    _moodAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _moodOffsetAnimation =
        Tween<Offset>(
          begin: Offset.zero,
          end: const Offset(0.0, -4.0), // Sobe 4x a sua altura
        ).animate(
          CurvedAnimation(
            parent: _moodAnimationController,
            curve: Curves.easeOut,
          ),
        );

    _moodFadeAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _moodAnimationController, curve: Curves.easeIn),
    );
    AppLogger.info('🏠 HomeScreen inicializada');
  }

  @override
  void dispose() {
    _moodAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final missionsState = ref.watch(missionsProvider);
    final isDark = ref.watch(themeProvider);
    final theme = Theme.of(context);

    // ✅ VERIFICAÇÃO SIMPLES - sem redirecionamento automático
    // ✅ VERIFICAÇÃO DE NULIDADE E REDIRECIONAMENTO SE NECESSÁRIO
    // Se o usuário não estiver autenticado ou o objeto user for nulo,
    // mostre uma tela de carregamento e dispare o redirecionamento.
    if (!authState.isAuthenticated || authState.user == null) {
      AppLogger.warning(
        '🏠 HomeScreen: Auth state inconsistent. User is null or not authenticated. Triggering redirect.',
      );
      // Dispara o redirecionamento para o login no próximo frame
      WidgetsBinding.instance.addPostFrameCallback((_) {
        // Verifica se o widget ainda está montado antes de navegar
        if (mounted) {
          // Verifica a rota atual para evitar loops se já estiver no login
          // Correção: Usar GoRouterState.of(context).uri.toString() para obter a rota atual
          if (GoRouterState.of(context).uri.toString() != AppRoutes.login) {
            context.go(AppRoutes.login);
          }
        }
      });
      // Retorna uma tela de carregamento para evitar o erro de null safety
      // enquanto o redirecionamento acontece.
      return _buildLoadingScreen(theme);
    }

    final user = authState.user!;

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: _buildAppBar(context, theme, user, isDark),
      body: _buildBody(context, theme, user, missionsState), // Corpo principal
      bottomNavigationBar: _buildBottomNav(
        context,
        theme,
      ), // Barra de navegação inferior
      floatingActionButton: _buildFloatingActionButton(
        context,
        theme,
      ), // Botão de ação flutuante
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }

  /// ✅ Tela de loading
  Widget _buildLoadingScreen(ThemeData theme) {
    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: const Center(child: CircularProgressIndicator()),
    );
  }

  // Funções auxiliares para nome e inicial do avatar
  String _getDisplayFirstName(UserModel user) {
    if (user.displayName.isNotEmpty) {
      final parts = user.displayName.trim().split(' ');
      if (parts.isNotEmpty && parts.first.isNotEmpty) {
        return parts.first;
      }
    }
    if (user.codinome != null && user.codinome!.trim().isNotEmpty) {
      return user.codinome!;
    }
    return 'Usuário'; // Fallback genérico
  }

  String _getAvatarInitial(UserModel user) {
    if (user.displayName.isNotEmpty) {
      return user.displayName.trim().substring(0, 1).toUpperCase();
    }
    if (user.codinome != null && user.codinome!.trim().isNotEmpty) {
      return user.codinome!.trim().substring(0, 1).toUpperCase();
    }
    return 'U';
  }

  /// ✅ AppBar completa com logout
  PreferredSizeWidget _buildAppBar(
    BuildContext context,
    ThemeData theme,
    UserModel user, // Tipar o usuário
    bool isDark, // Manter isDark
  ) {
    return AppBar(
      backgroundColor: theme.colorScheme.surface,
      elevation: 0,
      scrolledUnderElevation: 1,
      title: Row(
        children: [
          // Avatar do usuário - melhorado
          GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact(); // Feedback tátil
              NavigationUtils.navigateTo(context, AppRoutes.profile);
            },
            child: ClipRRect(
              // Para aplicar cantos arredondados
              borderRadius: BorderRadius.circular(
                AppConstants.cardBorderRadius,
              ),
              child: Container(
                width: AppConstants.avatarSize, // Tamanho do avatar
                height: AppConstants.avatarSize, // Tamanho do avatar
                decoration: BoxDecoration(
                  color: theme
                      .colorScheme
                      .surface, // Cor de fundo para o placeholder/erro
                  border: Border.all(
                    color: theme.colorScheme.primary, // Cor da borda
                    width: AppConstants.avatarBorderWidth, // Espessura da borda
                  ),
                  borderRadius: BorderRadius.circular(
                    12.0,
                  ), // Deve corresponder ao ClipRRect
                  boxShadow: [
                    BoxShadow(
                      color: theme.colorScheme.primary.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child:
                    user.avatar != null &&
                        user
                            .avatar!
                            .isNotEmpty // Assuming the field is photoURL
                    ? CachedNetworkImage(
                        imageUrl:
                            user.avatar!, // Assuming the field is photoURL
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Center(
                          child: CircularProgressIndicator(
                            strokeWidth: 2.0,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              theme.colorScheme.primary,
                            ),
                          ),
                        ),
                        errorWidget: (context, url, error) => Center(
                          child: Icon(
                            Icons.person,
                            color: theme.colorScheme.primary,
                            size: 28,
                          ),
                        ),
                      )
                    : Center(
                        // Fallback se não houver avatarUrl
                        child: Text(
                          // Exibe a inicial do nome ou codinome
                          _getAvatarInitial(user),
                          style: TextStyle(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.bold,
                            fontSize: AppConstants.fontSizeAvatarInitial,
                          ),
                        ),
                      ),
              ),
            ),
          ),

          const SizedBox(width: AppConstants.spacingLarge),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Olá, ${_getDisplayFirstName(user)}!',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Nível ${user.level} • ${user.xp} XP',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        // Botão de tema
        IconButton(
          onPressed: () {
            HapticFeedback.lightImpact(); // Feedback tátil
            ref.read(themeProvider.notifier).toggleTheme();
          },
          icon: Icon(isDark ? Icons.light_mode : Icons.dark_mode),
          tooltip: 'Alternar tema',
        ),
        // ✅ LOGOUT BUTTON - Adicionar botão direto na AppBar
        IconButton(
          onPressed: () => _showLogoutDialog(context),
          icon: const Icon(Icons.logout),
          tooltip: 'Sair',
          color: theme.colorScheme.error,
        ),
        // Menu de opções adicional
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert),
          onSelected: (value) => _handleMenuAction(context, value),
          itemBuilder: (context) => [
            const PopupMenuItem<String>(
              value: 'profile',
              child: ListTile(
                leading: Icon(Icons.person),
                title: Text('Perfil'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            const PopupMenuItem<String>(
              value: 'settings',
              child: ListTile(
                leading: Icon(Icons.settings),
                title: Text('Configurações'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Seletor de humor do usuário
  Widget _buildMoodSelector(
    BuildContext context,
    ThemeData theme,
    UserModel user,
  ) {
    final moods = [
      {'id': 'social', 'icon': Icons.people, 'label': 'Social', 'emoji': '🥳'},
      {
        'id': 'creative',
        'icon': Icons.palette,
        'label': 'Criativo',
        'emoji': '🎨',
      },
      {
        'id': 'chill',
        'icon': Icons.self_improvement,
        'label': 'Relaxar',
        'emoji': '🧘',
      },
      {
        'id': 'adventure',
        'icon': Icons.explore,
        'label': 'Aventura',
        'emoji': '🚀',
      },
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppConstants.paddingMedium),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppConstants.paddingMedium,
            ),
            child: Text(
              'Como você está se sentindo?',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: AppConstants.spacingLarge),
          // Stack para permitir a animação do emoji sobre os botões
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                height: 48, // Altura fixa para os botões
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: moods.length,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppConstants.paddingMedium,
                  ),
                  itemBuilder: (context, index) {
                    final mood = moods[index];
                    final isSelected =
                        user.currentMood ==
                        mood['id']; // Usa o humor do UserModel

                    return GestureDetector(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        final moodId = mood['id'] as String;
                        final emoji = mood['emoji'] as String;

                        // Dispara a animação
                        setState(() {
                          _animatingMoodEmoji = emoji;
                        });
                        _moodAnimationController.forward(from: 0.0);

                        // Atualiza o estado no Firebase
                        ref.read(authProvider.notifier).updateUserMood(moodId);
                      },
                      child: Container(
                        margin: const EdgeInsets.only(
                          right: AppConstants.spacingLarge,
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? theme.colorScheme.primaryContainer
                              : theme.colorScheme.surfaceVariant,
                          borderRadius: BorderRadius.circular(
                            AppConstants.cardBorderRadius,
                          ),
                          border: isSelected
                              ? Border.all(
                                  color: theme.colorScheme.primary,
                                  width: 2,
                                )
                              : Border.all(
                                  color: theme.colorScheme.outline.withOpacity(
                                    0.2,
                                  ),
                                ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              mood['icon'] as IconData,
                              size: 20,
                              color: isSelected
                                  ? theme.colorScheme.primary
                                  : theme.colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(width: AppConstants.spacingMedium),
                            Text(
                              mood['label'] as String,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: isSelected
                                    ? theme.colorScheme.primary
                                    : theme.colorScheme.onSurfaceVariant,
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              // Emoji animado
              FadeTransition(
                opacity: _moodFadeAnimation,
                child: SlideTransition(
                  position: _moodOffsetAnimation,
                  child: Text(
                    _animatingMoodEmoji,
                    style: const TextStyle(fontSize: 40),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Seção de Sugestões de Conexão
  Widget _buildConnectionsSuggestions(BuildContext context, ThemeData theme) {
    return Padding(
      // Adiciona padding para alinhar com outras seções
      padding: const EdgeInsets.symmetric(vertical: AppConstants.paddingMedium),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppConstants.paddingMedium,
            ),
            child: Text(
              'Sugestões de Conexão',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: AppConstants.spacingLarge),
          SizedBox(
            height: 120,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: 5, // Mocked count
              padding: const EdgeInsets.symmetric(
                horizontal: AppConstants.paddingMedium,
              ),
              itemBuilder: (context, index) {
                // Passa o tema para o card
                return _buildSuggestionCard(context, theme, index);
              },
            ),
          ),
        ],
      ),
    );
  }

  /// Card individual de sugestão de conexão
  Widget _buildSuggestionCard(
    BuildContext context,
    ThemeData theme,
    int index,
  ) {
    // Cores para os avatares, podem ser mantidas para variedade visual
    final colors = [
      Colors.red.shade300,
      Colors.blue.shade300,
      Colors.green.shade300,
      Colors.purple.shade300,
      Colors.orange.shade300,
    ];

    return Container(
      width: 100,
      margin: const EdgeInsets.only(right: AppConstants.spacingLarge),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant, // Cor adaptável ao tema
        borderRadius: BorderRadius.circular(AppConstants.cardBorderRadius),
        border: Border.all(color: theme.colorScheme.outline.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withOpacity(
              theme.brightness == Brightness.dark ? 0.4 : 0.1,
            ),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: AppConstants.avatarSize,
            height: AppConstants.avatarSize,
            decoration: BoxDecoration(
              color: colors[index % colors.length],
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.person, color: Colors.white, size: 24),
          ),
          const SizedBox(height: AppConstants.spacingMedium),
          Text(
            'Anônimo ${index + 1}',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: AppConstants.spacingSmall),
          Text(
            '95% match',
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  /// ✅ Corpo principal da tela com missões reais
  Widget _buildBody(
    BuildContext context,
    ThemeData theme,
    user,
    missionsState,
  ) {
    return RefreshIndicator(
      // ✅ REFRESH CORRIGIDO - inclui missões
      onRefresh: () => _handleRefreshData(context),
      color: theme.colorScheme.primary,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          // Header com estatísticas
          SliverToBoxAdapter(child: _buildStatsCard(context, theme, user)),

          // Ações rápidas
          SliverToBoxAdapter(child: _buildQuickActions(context, theme)),

          SliverToBoxAdapter(
            child: _buildMoodSelector(
              context,
              theme,
              user,
            ), // Passa o user para o seletor de humor
          ),

          SliverToBoxAdapter(
            child: _buildConnectionsSuggestions(context, theme),
          ),

          // ✅ MISSÕES REAIS - usando o provider
          SliverToBoxAdapter(
            child: _buildMissionsSection(context, theme, missionsState),
          ),

          // Espaço para floating button
          const SliverToBoxAdapter(
            child: SizedBox(height: AppConstants.bottomNavHeight),
          ),
        ],
      ),
    );
  }

  /// ✅ Card de estatísticas melhorado
  Widget _buildStatsCard(BuildContext context, ThemeData theme, user) {
    return Container(
      margin: const EdgeInsets.all(AppConstants.paddingMedium),
      padding: const EdgeInsets.all(AppConstants.statsCardPadding),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primary,
            theme.colorScheme.primary.withOpacity(0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Suas Conquistas',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: AppConstants.fontSizeExtraLarge,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Icon(
                Icons.emoji_events,
                color: Colors.white.withOpacity(0.8),
                size: 24,
              ),
            ],
          ),
          const SizedBox(height: AppConstants.spacingExtraLarge),
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  context,
                  'XP',
                  user.xp?.toString() ?? '0',
                  Icons.trending_up,
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  context,
                  'Moedas',
                  user.coins?.toString() ?? '0',
                  Icons.monetization_on,
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  context,
                  'Gemas',
                  user.gems?.toString() ?? '0',
                  Icons.diamond,
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  context,
                  'Nível',
                  user.level?.toString() ?? '1',
                  Icons.star,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// ✅ Item de estatística
  Widget _buildStatItem(
    BuildContext context,
    String label,
    String value,
    IconData icon,
  ) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: Colors.white, size: 20),
        ),
        const SizedBox(height: 8),
        Text(
          // Valor da estatística
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          // Rótulo da estatística
          label,
          style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 10),
        ),
      ],
    );
  }

  /// ✅ Ações rápidas
  Widget _buildQuickActions(BuildContext context, ThemeData theme) {
    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: AppConstants.paddingMedium,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Ações Rápidas',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold, // Manter peso da fonte do TextTheme
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildActionCard(
                  context, // Passar context
                  theme,
                  'Perfil',
                  Icons.visibility, // Ícone para "Ver meu perfil público"
                  // Leva para o Perfil Público
                  () => NavigationUtils.navigateTo(context, AppRoutes.profile),
                ),
              ),
              const SizedBox(width: AppConstants.spacingLarge),
              Expanded(
                child: _buildActionCard(
                  context, // Passar context
                  theme,
                  'Conexões',
                  Icons.people,
                  () => NavigationUtils.navigateTo(
                    context,
                    AppRoutes.connections,
                  ),
                ),
              ),
              const SizedBox(width: AppConstants.spacingLarge),
              Expanded(
                child: _buildActionCard(
                  context, // Passar context
                  theme,
                  'Jogos', // Alterado para Jogos
                  Icons.gamepad, // Ícone para Jogos
                  () => NavigationUtils.navigateTo(
                    context,
                    AppRoutes.games,
                  ), // Navegar para GamesScreen
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// ✅ Card de ação
  Widget _buildActionCard(
    BuildContext context,
    ThemeData theme,
    String title,
    IconData icon,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: () {
        HapticFeedback.lightImpact(); // Feedback tátil
        onTap();
      },
      borderRadius: BorderRadius.circular(AppConstants.cardBorderRadius),
      child: Container(
        padding: const EdgeInsets.all(AppConstants.cardPadding),
        decoration: BoxDecoration(
          color: theme.colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(AppConstants.cardBorderRadius),
          border: Border.all(
            color: theme.colorScheme.primary.withOpacity(0.1),
            width: 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: theme.colorScheme.onPrimaryContainer,
              size: 28,
            ), // Tamanho do ícone fixo
            const SizedBox(height: AppConstants.spacingMedium),
            Text(
              title,
              style: TextStyle(
                color: theme.colorScheme.onPrimaryContainer,
                fontWeight: FontWeight.w500, // Manter peso da fonte
                fontSize: AppConstants.fontSizeMedium, // Usar constante
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// ✅ Seção de missões REAL usando o provider
  Widget _buildMissionsSection(
    BuildContext context,
    ThemeData theme,
    missionsState,
  ) {
    return Container(
      margin: const EdgeInsets.all(AppConstants.paddingMedium),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Missões Ativas',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ), // Manter peso da fonte
              ),
              TextButton.icon(
                onPressed: () => NavigationUtils.navigateTo(
                  context,
                  AppRoutes.missions,
                ), // Navegar para MissionsCategorizedScreen
                icon: const Icon(
                  Icons.arrow_forward,
                  size: 16,
                ), // Tamanho do ícone fixo
                label: const Text('Ver todas'),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // ✅ LISTA REAL DE MISSÕES
          _buildMissionsList(context, theme, missionsState),
        ],
      ),
    );
  }

  /// ✅ Lista real de missões usando o provider
  Widget _buildMissionsList(
    BuildContext context,
    ThemeData theme,
    missionsState,
  ) {
    // Loading state
    if (missionsState.isLoading) {
      return Container(
        padding: const EdgeInsets.all(AppConstants.cardPadding),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceVariant,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 12),
            Text('Carregando missões...'),
          ],
        ),
      );
    }

    // Error state
    if (missionsState.error != null) {
      return Container(
        padding: const EdgeInsets.all(AppConstants.cardPadding),
        decoration: BoxDecoration(
          color: theme.colorScheme.errorContainer,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(Icons.error, color: theme.colorScheme.onErrorContainer),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Erro ao carregar missões',
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: theme.colorScheme.onErrorContainer,
                    ),
                  ),
                  Text(
                    'Toque em "Ver todas" para tentar novamente',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onErrorContainer,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    // Empty state
    if (missionsState.availableMissions.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(AppConstants.cardPadding),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceVariant,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(Icons.assignment, color: theme.colorScheme.onSurfaceVariant),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Nenhuma missão disponível',
                    style: theme.textTheme.titleSmall,
                  ),
                  Text(
                    'Volte em breve para novas aventuras!',
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    // ✅ MISSÕES DISPONÍVEIS - mostrar até 3 na home
    final missionsToShow = missionsState.availableMissions.take(3).toList();

    return Column(
      children: List<Widget>.from(
        missionsToShow.map((mission) {
          final progress = missionsState.userProgress[mission.id];
          return Padding(
            padding: const EdgeInsets.only(bottom: AppConstants.spacingMedium),
            child: MissionCard(mission: mission, progress: progress),
          );
        }),
      ),
    );
  }

  /// ✅ Bottom Navigation
  // Mantido o BottomNavigationBar, mas a navegação principal é via GoRouter
  // O currentIndex agora é derivado do GoRouterState para consistência.
  Widget _buildBottomNav(BuildContext context, ThemeData theme) {
    final String currentLocation = GoRouterState.of(context).uri.toString();
    int currentBottomNavIndex = 0;

    if (currentLocation.startsWith(AppRoutes.missions)) {
      currentBottomNavIndex = 1;
    } else if (currentLocation.startsWith(AppRoutes.connections)) {
      currentBottomNavIndex = 2;
    } else if (currentLocation.startsWith(AppRoutes.profile)) {
      currentBottomNavIndex = 3;
    } else if (currentLocation.startsWith(AppRoutes.home)) {
      currentBottomNavIndex = 0;
    }

    return BottomNavigationBar(
      currentIndex: currentBottomNavIndex,
      onTap: (index) {
        HapticFeedback.lightImpact(); // Feedback tátil no tap
        // A navegação via GoRouter no _handleBottomNavTap fará com que
        // o widget seja reconstruído e o currentIndex seja atualizado.
        _handleBottomNavTap(context, index);
      },
      type: BottomNavigationBarType.fixed,
      selectedItemColor: theme.colorScheme.primary,
      unselectedItemColor: theme.colorScheme.onSurface.withOpacity(
        0.6,
      ), // Ajustado cor
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
        BottomNavigationBarItem(
          icon: Icon(Icons.flag),
          label: 'Missões', // Mantido Missões no BottomNav
        ),
        BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Conexões'),
        BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Perfil'),
      ],
    );
  }

  Widget _buildFloatingActionButton(BuildContext context, ThemeData theme) {
    return FloatingActionButton(
      onPressed: () {
        HapticFeedback.lightImpact(); // Feedback tátil
        // Navegar para a tela de conexões em vez de mostrar um diálogo
        NavigationUtils.navigateTo(context, AppRoutes.connections);
      },
      backgroundColor: theme.colorScheme.primary,
      child: const Icon(Icons.connect_without_contact),
    );
  }

  // ========== EVENT HANDLERS ==========

  /// ✅ REFRESH DE DADOS - inclui missões sem afetar navegação
  Future<void> _handleRefreshData(BuildContext context) async {
    try {
      AppLogger.info('🔄 HomeScreen: Refreshing data including missions');

      // ✅ REFRESH MISSÕES E OUTROS DADOS - não auth
      await Future.wait([
        ref.read(missionsProvider.notifier).refresh(),
        // Adicionar outros providers aqui se necessário
        // ref.read(rewardsProvider.notifier).refresh(),
      ]);

      AppLogger.info('✅ HomeScreen: Data refreshed successfully');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.refresh, color: Colors.white),
                SizedBox(width: 8),
                Text('Dados atualizados!'),
              ],
            ),
            backgroundColor: Theme.of(context).colorScheme.primary,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      AppLogger.error('❌ HomeScreen: Error refreshing data', error: e);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erro ao atualizar dados'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// ✅ Ações do menu
  void _handleMenuAction(BuildContext context, String action) {
    switch (action) {
      case 'profile':
        // Leva para o Perfil Público
        NavigationUtils.navigateTo(context, AppRoutes.profile);
        break;
      case 'settings':
        NavigationUtils.navigateTo(
          context,
          AppRoutes.settings,
        ); // Navegar para SettingsScreen
        break;
    }
  }

  /// ✅ Navegação do bottom nav
  void _handleBottomNavTap(BuildContext context, int index) {
    switch (index) {
      case 0:
        // Já estamos na home
        // Usar context.go para garantir que a pilha de navegação seja limpa até a home
        context.go(AppRoutes.home);
        break;
      case 1:
        // Navegar para Missões
        context.go(AppRoutes.missions); // Usar context.go
        break;
      case 2:
        // Navegar para Conexões
        context.go(AppRoutes.connections); // Usar context.go
        break;
      case 3:
        // Navegar para Perfil Público
        context.go(AppRoutes.profile);

        break;
    }
  }

  /// ✅ Diálogo de logout MELHORADO
  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.logout, color: Theme.of(context).colorScheme.error),
            const SizedBox(width: 8),
            const Text('Sair do App'),
          ],
        ),
        content: const Text('Tem certeza que deseja sair da sua conta?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _performLogout(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            child: const Text('Sair'),
          ),
        ],
      ),
    );
  }

  /// ✅ Realizar logout COM FEEDBACK
  void _performLogout(BuildContext context) async {
    try {
      AppLogger.info('🚪 HomeScreen: Performing logout');

      // Mostrar loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('Saindo...'),
            ],
          ),
        ),
      );

      // ✅ LOGOUT USANDO O PROVIDER CORRETO
      await ref.read(authProvider.notifier).signOut();

      AppLogger.info('✅ HomeScreen: Logout successful');
    } catch (e) {
      AppLogger.error('❌ HomeScreen: Logout error', error: e);

      // Fechar dialog de loading
      if (mounted) {
        Navigator.of(context).pop();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.error, color: Colors.white),
                SizedBox(width: 8),
                Text('Erro ao fazer logout. Tente novamente.'),
              ],
            ),
            backgroundColor: Colors.red,
            action: SnackBarAction(
              label: 'TENTAR NOVAMENTE',
              textColor: Colors.white,
              onPressed: () => _performLogout(context),
            ),
          ),
        );
      }
    } finally {
      // Fechar dialog de loading se ainda estiver montado
      if (mounted && Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
    }
  }
}
