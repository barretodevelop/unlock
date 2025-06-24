// lib/shared/widgets/avatar_circle.dart - VERSÃO ATUALIZADA
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

/// Widget de avatar circular reutilizável
/// Suporta imagens de URL, texto de fallback e emojis
class AvatarCircle extends StatelessWidget {
  final String? imageUrl;
  final String? fallbackText; // ✅ NOVO: Para emojis ou texto
  final double radius;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final VoidCallback? onTap;
  final bool showBorder;
  final Color? borderColor;
  final double borderWidth;

  const AvatarCircle({
    super.key,
    this.imageUrl,
    this.fallbackText, // ✅ ADICIONADO
    this.radius = 20,
    this.backgroundColor,
    this.foregroundColor,
    this.onTap,
    this.showBorder = false,
    this.borderColor,
    this.borderWidth = 2,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: radius * 2,
        height: radius * 2,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: showBorder
              ? Border.all(
                  color: borderColor ?? Theme.of(context).colorScheme.outline,
                  width: borderWidth,
                )
              : null,
        ),
        child: CircleAvatar(
          radius: radius,
          backgroundColor: backgroundColor ?? 
            Theme.of(context).colorScheme.surfaceVariant,
          foregroundColor: foregroundColor ?? 
            Theme.of(context).colorScheme.onSurfaceVariant,
          backgroundImage: _buildBackgroundImage(),
          child: _buildChild(context),
        ),
      ),
    );
  }

  /// Construir imagem de fundo se URL fornecida
  ImageProvider? _buildBackgroundImage() {
    if (imageUrl != null && imageUrl!.isNotEmpty) {
      if (imageUrl!.startsWith('http')) {
        return CachedNetworkImageProvider(imageUrl!);
      } else if (imageUrl!.startsWith('assets/')) {
        return AssetImage(imageUrl!);
      }
    }
    return null;
  }

  /// Construir conteúdo do avatar
  Widget? _buildChild(BuildContext context) {
    // Se tem imagem, não mostrar child
    if (imageUrl != null && imageUrl!.isNotEmpty) {
      return null;
    }

    // Se tem fallbackText, mostrar
    if (fallbackText != null && fallbackText!.isNotEmpty) {
      // Verificar se é emoji (caractere único > 1 byte)
      final isEmoji = fallbackText!.length == 1 && 
                     fallbackText!.runes.length == 1 &&
                     fallbackText!.codeUnitAt(0) > 127;
      
      if (isEmoji) {
        // Renderizar emoji
        return Text(
          fallbackText!,
          style: TextStyle(
            fontSize: radius * 0.8, // Emoji proporcional ao tamanho
          ),
        );
      } else {
        // Renderizar texto (iniciais)
        final text = _getInitials(fallbackText!);
        return Text(
          text,
          style: TextStyle(
            fontSize: radius * 0.6, // Texto menor que emoji
            fontWeight: FontWeight.w600,
            color: foregroundColor ?? 
              Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        );
      }
    }

    // Fallback padrão - ícone de pessoa
    return Icon(
      Icons.person,
      size: radius * 0.8,
      color: foregroundColor ?? 
        Theme.of(context).colorScheme.onSurfaceVariant,
    );
  }

  /// Extrair iniciais do texto
  String _getInitials(String text) {
    final words = text.trim().split(' ');
    if (words.isEmpty) return '?';
    
    if (words.length == 1) {
      return words[0].substring(0, 1).toUpperCase();
    } else {
      return (words[0].substring(0, 1) + words[1].substring(0, 1))
        .toUpperCase();
    }
  }
}

/// Widget específico para avatares de usuário
class UserAvatar extends StatelessWidget {
  final String? imageUrl;
  final String? username;
  final String? fallbackText;
  final double radius;
  final bool isOnline;
  final VoidCallback? onTap;

  const UserAvatar({
    super.key,
    this.imageUrl,
    this.username,
    this.fallbackText,
    this.radius = 20,
    this.isOnline = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        AvatarCircle(
          imageUrl: imageUrl,
          fallbackText: fallbackText ?? username,
          radius: radius,
          onTap: onTap,
        ),
        
        // Indicador online
        if (isOnline)
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              width: radius * 0.4,
              height: radius * 0.4,
              decoration: BoxDecoration(
                color: Colors.green,
                shape: BoxShape.circle,
                border: Border.all(
                  color: Theme.of(context).colorScheme.surface,
                  width: 2,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// Widget específico para avatares de grupo
class GroupAvatar extends StatelessWidget {
  final String? imageUrl;
  final String? groupName;
  final String? fallbackText;
  final double radius;
  final Color? backgroundColor;
  final VoidCallback? onTap;

  const GroupAvatar({
    super.key,
    this.imageUrl,
    this.groupName,
    this.fallbackText,
    this.radius = 20,
    this.backgroundColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AvatarCircle(
      imageUrl: imageUrl,
      fallbackText: fallbackText ?? groupName,
      radius: radius,
      backgroundColor: backgroundColor ?? 
        Theme.of(context).colorScheme.primary.withOpacity(0.1),
      foregroundColor: Theme.of(context).colorScheme.primary,
      onTap: onTap,
    );
  }
}

/// Stack de avatares para mostrar múltiplos membros
class AvatarStack extends StatelessWidget {
  final List<String> avatars;
  final double radius;
  final int maxVisible;
  final double overlap;

  const AvatarStack({
    super.key,
    required this.avatars,
    this.radius = 16,
    this.maxVisible = 3,
    this.overlap = 0.6,
  });

  @override
  Widget build(BuildContext context) {
    final visibleAvatars = avatars.take(maxVisible).toList();
    final remainingCount = avatars.length - visibleAvatars.length;

    return SizedBox(
      width: (visibleAvatars.length * radius * overlap * 2) + radius * 2,
      height: radius * 2,
      child: Stack(
        children: [
          // Avatares visíveis
          ...visibleAvatars.asMap().entries.map((entry) {
            final index = entry.key;
            final avatar = entry.value;
            
            return Positioned(
              left: index * radius * overlap * 2,
              child: AvatarCircle(
                imageUrl: avatar.startsWith('http') ? avatar : null,
                fallbackText: avatar.startsWith('http') ? null : avatar,
                radius: radius,
                showBorder: true,
                borderColor: Theme.of(context).colorScheme.surface,
              ),
            );
          }).toList(),
          
          // Contador de avatares restantes
          if (remainingCount > 0)
            Positioned(
              left: visibleAvatars.length * radius * overlap * 2,
              child: AvatarCircle(
                radius: radius,
                backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
                foregroundColor: Theme.of(context).colorScheme.onSurfaceVariant,
                fallbackText: '+$remainingCount',
                showBorder: true,
                borderColor: Theme.of(context).colorScheme.surface,
              ),
            ),
        ],
      ),
    );
  }
}