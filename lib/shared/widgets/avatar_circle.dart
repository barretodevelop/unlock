// lib/shared/widgets/avatar_circle.dart - WIDGET AVATAR COMPLETO
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

/// Widget de avatar circular com suporte a imagens de rede, assets e iniciais
///
/// Características:
/// - Fallback para iniciais se imagem falhar
/// - Cache automático de imagens de rede
/// - Indicador de status online/offline opcional
/// - Customização completa de tamanho e estilo
class AvatarCircle extends StatelessWidget {
  final String? imageUrl;
  final String? assetPath;
  final String? initials;
  final double size;
  final Color? backgroundColor;
  final Color? textColor;
  final bool showOnlineStatus;
  final bool isOnline;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? margin;
  final bool showBorder;
  final Color? borderColor;
  final double borderWidth;

  const AvatarCircle({
    super.key,
    this.imageUrl,
    this.assetPath,
    this.initials,
    this.size = 40.0,
    this.backgroundColor,
    this.textColor,
    this.showOnlineStatus = false,
    this.isOnline = false,
    this.onTap,
    this.margin,
    this.showBorder = false,
    this.borderColor,
    this.borderWidth = 2.0,
  });

  /// Construtor para avatar de usuário com iniciais automáticas
  factory AvatarCircle.user({
    String? imageUrl,
    required String displayName,
    double size = 40.0,
    Color? backgroundColor,
    bool showOnlineStatus = false,
    bool isOnline = false,
    VoidCallback? onTap,
    EdgeInsetsGeometry? margin,
    bool showBorder = false,
    Color? borderColor,
    double borderWidth = 2.0,
  }) {
    return AvatarCircle(
      imageUrl: imageUrl,
      initials: _generateInitials(displayName),
      size: size,
      backgroundColor: backgroundColor,
      showOnlineStatus: showOnlineStatus,
      isOnline: isOnline,
      onTap: onTap,
      margin: margin,
      showBorder: showBorder,
      borderColor: borderColor,
      borderWidth: borderWidth,
    );
  }

  /// Gerar iniciais a partir do nome
  static String _generateInitials(String name) {
    final words = name.trim().split(' ');
    if (words.isEmpty) return '?';

    if (words.length == 1) {
      return words[0].isNotEmpty ? words[0][0].toUpperCase() : '?';
    }

    return (words[0][0] + words[1][0]).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: margin,
      child: Stack(
        children: [
          // Avatar principal
          GestureDetector(
            onTap: onTap,
            child: Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: showBorder
                    ? Border.all(
                        color: borderColor ?? theme.colorScheme.primary,
                        width: borderWidth,
                      )
                    : null,
              ),
              child: ClipOval(child: _buildAvatarContent(context)),
            ),
          ),

          // Indicador de status online
          if (showOnlineStatus)
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                width: size * 0.25,
                height: size * 0.25,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isOnline ? Colors.green : Colors.grey,
                  border: Border.all(
                    color: theme.colorScheme.surface,
                    width: 2,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// Construir conteúdo do avatar
  Widget _buildAvatarContent(BuildContext context) {
    final theme = Theme.of(context);

    // Prioridade: imageUrl > assetPath > initials
    if (imageUrl != null && imageUrl!.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: imageUrl!,
        fit: BoxFit.cover,
        width: size,
        height: size,
        placeholder: (context, url) => _buildPlaceholder(context),
        errorWidget: (context, url, error) => _buildInitialsAvatar(context),
      );
    }

    if (assetPath != null && assetPath!.isNotEmpty) {
      return Image.asset(
        assetPath!,
        fit: BoxFit.cover,
        width: size,
        height: size,
        errorBuilder: (context, error, stackTrace) =>
            _buildInitialsAvatar(context),
      );
    }

    return _buildInitialsAvatar(context);
  }

  /// Construir placeholder de carregamento
  Widget _buildPlaceholder(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: size,
      height: size,
      color: backgroundColor ?? theme.colorScheme.primary.withOpacity(0.1),
      child: Center(
        child: SizedBox(
          width: size * 0.4,
          height: size * 0.4,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(
              theme.colorScheme.primary,
            ),
          ),
        ),
      ),
    );
  }

  /// Construir avatar com iniciais
  Widget _buildInitialsAvatar(BuildContext context) {
    final theme = Theme.of(context);
    final displayInitials = initials ?? '?';

    return Container(
      width: size,
      height: size,
      color: backgroundColor ?? theme.colorScheme.primary,
      child: Center(
        child: Text(
          displayInitials,
          style: TextStyle(
            color: textColor ?? theme.colorScheme.onPrimary,
            fontSize: size * 0.4,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
