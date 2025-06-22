// lib/features/home/widgets/custom_app_bar.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:unlock/core/constants/app_constants.dart' as constants;
import 'package:unlock/features/home/widgets/settings_bottom_sheet.dart';
import 'package:unlock/models/user_model.dart';
import 'package:unlock/providers/auth_provider.dart';
import 'package:unlock/shared/widgets/avatar_circle.dart';

class CustomAppBar extends ConsumerStatefulWidget {
  const CustomAppBar({super.key});

  @override
  ConsumerState<CustomAppBar> createState() => _CustomAppBarState();
}

class _CustomAppBarState extends ConsumerState<CustomAppBar>
    with TickerProviderStateMixin {
  // Constantes para valores reutilizáveis
  static const double _appBarHeight = kToolbarHeight + 16;
  static const double _avatarRadius = 24.0;
  static const double _horizontalPadding = 20.0;
  static const double _verticalPadding = 12.0;
  static const double _settingsIconSize = 24.0;
  static const double _borderRadius = 28.0;
  static const double _moodEmojiSize = 20.0;

  // Controllers de animação
  late AnimationController _moodAnimationController;
  late AnimationController _floatingEmojiController;
  late Animation<double> _moodScaleAnimation;
  late Animation<Offset> _floatingEmojiAnimation;
  late Animation<double> _floatingEmojiOpacity;

  String? _tempSelectedMood; // Para animação temporária

  @override
  void initState() {
    super.initState();
    _setupAnimations();
  }

  void _setupAnimations() {
    // Animação do mood selector
    _moodAnimationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _moodScaleAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(
        parent: _moodAnimationController,
        curve: Curves.elasticOut,
      ),
    );

    // Animação do emoji flutuante
    _floatingEmojiController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _floatingEmojiAnimation =
        Tween<Offset>(
          begin: const Offset(0, 0),
          end: const Offset(0, -2),
        ).animate(
          CurvedAnimation(
            parent: _floatingEmojiController,
            curve: Curves.easeOutCubic,
          ),
        );

    _floatingEmojiOpacity = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _floatingEmojiController,
        curve: const Interval(0.7, 1.0, curve: Curves.easeOut),
      ),
    );
  }

  @override
  void dispose() {
    _moodAnimationController.dispose();
    _floatingEmojiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider.select((state) => state.user));
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: _buildAppBarDecoration(theme, isDark),
      child: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: theme.colorScheme.onSurface,
        systemOverlayStyle: _buildSystemOverlayStyle(theme),
        automaticallyImplyLeading: false,
        toolbarHeight: _appBarHeight,
        title: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          transitionBuilder: (child, animation) => FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position:
                  Tween<Offset>(
                    begin: const Offset(0, 0.3),
                    end: Offset.zero,
                  ).animate(
                    CurvedAnimation(
                      parent: animation,
                      curve: Curves.easeOutCubic,
                    ),
                  ),
              child: child,
            ),
          ),
          child: user != null
              ? _buildUserProfile(context, user, theme)
              : _buildDefaultTitle(theme),
        ),
        actions: [_buildSettingsButton(context, theme, isDark)],
        bottom: user != null ? _buildMoodSelector(context, user, theme) : null,
      ),
    );
  }

  /// Decoração moderna com gradient e glassmorphism
  BoxDecoration _buildAppBarDecoration(ThemeData theme, bool isDark) {
    return BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: isDark
            ? [
                theme.colorScheme.surface.withOpacity(0.95),
                theme.colorScheme.surface.withOpacity(0.85),
              ]
            : [
                theme.colorScheme.surface.withOpacity(0.98),
                theme.colorScheme.primary.withOpacity(0.02),
              ],
      ),
      border: Border(
        bottom: BorderSide(
          color: theme.dividerColor.withOpacity(0.1),
          width: 0.5,
        ),
      ),
    );
  }

  /// Configuração otimizada do overlay do sistema
  SystemUiOverlayStyle _buildSystemOverlayStyle(ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;
    return SystemUiOverlayStyle(
      statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
      statusBarBrightness: theme.brightness,
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: theme.scaffoldBackgroundColor,
      systemNavigationBarIconBrightness: isDark
          ? Brightness.light
          : Brightness.dark,
    );
  }

  /// Perfil do usuário com animações e micro-interações
  Widget _buildUserProfile(
    BuildContext context,
    UserModel user,
    ThemeData theme,
  ) {
    return Hero(
      tag: 'user_profile_${user.uid}',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _navigateToProfile(context),
          borderRadius: BorderRadius.circular(_borderRadius),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: _horizontalPadding / 2,
              vertical: _verticalPadding / 2,
            ),
            child: Row(
              children: [
                _buildAnimatedAvatar(user),
                const SizedBox(width: 14),
                Expanded(child: _buildUserInfo(user, theme)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Avatar com animação e indicador de status
  Widget _buildAnimatedAvatar(UserModel user) {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 300),
      tween: Tween(begin: 0.8, end: 1.0),
      builder: (context, scale, child) {
        return Transform.scale(
          scale: scale,
          child: Stack(
            children: [
              AvatarCircle(imageUrl: user.avatar, radius: _avatarRadius),
              // Indicador de status online (opcional)
              // if (user.isOnline ?? false)
              //   Positioned(
              //     right: 2,
              //     bottom: 2,
              //     child: Container(
              //       width: 12,
              //       height: 12,
              //       decoration: BoxDecoration(
              //         color: Colors.green,
              //         shape: BoxShape.circle,
              //         border: Border.all(
              //           color: Theme.of(context).scaffoldBackgroundColor,
              //           width: 2,
              //         ),
              //       ),
              //     ),
              //   ),
            ],
          ),
        );
      },
    );
  }

  /// Informações do usuário com tipografia melhorada
  Widget _buildUserInfo(UserModel user, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        TweenAnimationBuilder<double>(
          duration: const Duration(milliseconds: 400),
          tween: Tween(begin: 0.0, end: 1.0),
          builder: (context, opacity, child) {
            return Opacity(
              opacity: opacity,
              child: Text(
                _getGreeting(),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.65),
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.2,
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 2),
        TweenAnimationBuilder<double>(
          duration: const Duration(milliseconds: 500),
          tween: Tween(begin: 0.0, end: 1.0),
          builder: (context, opacity, child) {
            return Opacity(
              opacity: opacity,
              child: Text(
                user.displayName ?? 'Usuário',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  height: 1.2,
                  letterSpacing: -0.2,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            );
          },
        ),
      ],
    );
  }

  /// Título padrão quando não há usuário logado
  Widget _buildDefaultTitle(ThemeData theme) {
    return Text(
      'Home',
      style: theme.textTheme.headlineSmall?.copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: -0.5,
      ),
    );
  }

  /// Botão de configurações modernizado
  Widget _buildSettingsButton(
    BuildContext context,
    ThemeData theme,
    bool isDark,
  ) {
    return Container(
      margin: const EdgeInsets.only(right: _horizontalPadding),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showSettingsBottomSheet(context, theme),
          borderRadius: BorderRadius.circular(_borderRadius),
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
              borderRadius: BorderRadius.circular(_borderRadius),
              border: Border.all(
                color: theme.colorScheme.outline.withOpacity(0.1),
                width: 0.5,
              ),
            ),
            child: Icon(
              Icons.tune_rounded,
              size: _settingsIconSize,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }

  /// Seletor de mood na parte inferior do AppBar
  PreferredSizeWidget _buildMoodSelector(
    BuildContext context,
    UserModel user,
    ThemeData theme,
  ) {
    return PreferredSize(
      preferredSize: const Size.fromHeight(60),
      child: Container(
        height: 60,
        padding: const EdgeInsets.symmetric(horizontal: _horizontalPadding),
        child: Row(
          children: [
            Expanded(
              child: Stack(
                children: [
                  _buildMoodList(context, user, theme),
                  // Emoji flutuante para animação
                  if (_tempSelectedMood != null) _buildFloatingEmoji(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Lista horizontal de moods
  Widget _buildMoodList(BuildContext context, UserModel user, ThemeData theme) {
    return SizedBox(
      height: 48,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(), //
        itemCount: constants.MoodConstants.moodEmojis.length,
        separatorBuilder: (context, index) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final moodEntry = constants.MoodConstants.moodEmojis.entries
              .elementAt(index);
          final moodKey = moodEntry.key;
          final moodData = moodEntry.value;
          final isSelected = user.currentMood == moodKey;

          return _buildMoodItem(
            context: context,
            theme: theme,
            moodKey: moodKey,
            moodData: moodData,
            isSelected: isSelected,
            onTap: () => _onMoodSelected(moodKey, moodData),
          );
        },
      ),
    );
  }

  /// Item individual de mood
  Widget _buildMoodItem({
    required BuildContext context,
    required ThemeData theme,
    required String moodKey,
    required Map<String, dynamic> moodData,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return AnimatedBuilder(
      animation: _moodScaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: isSelected ? _moodScaleAnimation.value : 1.0,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(24),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected
                      ? theme.colorScheme.primary.withOpacity(0.1)
                      : theme.colorScheme.surfaceVariant.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: isSelected
                        ? theme.colorScheme.primary.withOpacity(0.3)
                        : theme.colorScheme.outline.withOpacity(0.1),
                    width: isSelected ? 1.5 : 0.5,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      moodData['emoji'],
                      style: TextStyle(fontSize: _moodEmojiSize),
                    ),
                    if (isSelected) ...[
                      const SizedBox(width: 8),
                      Text(
                        moodData['label'],
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  /// Emoji flutuante para animação de feedback
  Widget _buildFloatingEmoji() {
    final moodData = constants.MoodConstants.moodEmojis[_tempSelectedMood];
    if (moodData == null) return const SizedBox.shrink();

    return AnimatedBuilder(
      animation: _floatingEmojiController,
      builder: (context, child) {
        return SlideTransition(
          position: _floatingEmojiAnimation,
          child: FadeTransition(
            opacity: _floatingEmojiOpacity,
            child: Text(
              moodData['emoji'],
              style: const TextStyle(fontSize: 48),
            ),
          ),
        );
      },
    );
  }

  /// Ação ao selecionar um mood
  void _onMoodSelected(String moodKey, Map<String, dynamic> moodData) async {
    HapticFeedback.lightImpact();

    // Anima o item selecionado
    _moodAnimationController.forward().then((_) {
      _moodAnimationController.reverse();
    });

    // Configura e inicia animação do emoji flutuante
    setState(() {
      _tempSelectedMood = moodKey;
    });

    _floatingEmojiController.forward().then((_) {
      _floatingEmojiController.reset();
      setState(() {
        _tempSelectedMood = null;
      });
    });

    // Atualiza o mood no provider/Firebase
    try {
      await ref.read(authProvider.notifier).updateUserMood(moodKey);

      // Feedback adicional de sucesso
      if (mounted) {
        HapticFeedback.selectionClick();
      }
    } catch (e) {
      // Tratar erro se necessário
      debugPrint('Erro ao atualizar mood: $e');
    }
  }

  /// Saudação dinâmica baseada no horário
  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Bom dia,';
    if (hour < 18) return 'Boa tarde,';
    return 'Boa noite,';
  }

  /// Navegação para perfil com feedback háptico
  void _navigateToProfile(BuildContext context) {
    HapticFeedback.lightImpact();
    // TODO: Implementar navegação para perfil
    // Navigator.of(context).pushNamed('/profile');
  }

  /// Bottom sheet de configurações melhorado
  void _showSettingsBottomSheet(BuildContext context, ThemeData theme) {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(_borderRadius),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: const SettingsBottomSheet(),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(_appBarHeight + 60);
}
