import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:unlock/models/user_model.dart';
import 'package:unlock/onboarding/constants/onboarding_data.dart';

class UserAvatar extends StatelessWidget {
  final UserModel user;
  final double size;
  final String? photoUrlOverride;

  const UserAvatar({
    super.key,
    required this.user,
    this.size = 48.0,
    this.photoUrlOverride,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Prioriza a URL de override (revelada no jogo) se ela for fornecida.
    final photoUrl = photoUrlOverride;

    final avatar = OnboardingConstants.freeAvatars.firstWhere(
      (a) => a.id == user.avatarId,
      orElse: () => OnboardingConstants.freeAvatars.first,
    );

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: theme.colorScheme.primary.withOpacity(0.5),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withOpacity(0.2),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipOval(
        child: photoUrl != null && photoUrl.isNotEmpty
            ? CachedNetworkImage(
                imageUrl: photoUrl,
                fit: BoxFit.cover,
                placeholder: (context, url) =>
                    Container(color: theme.colorScheme.surfaceVariant),
                errorWidget: (context, url, error) =>
                    Icon(Icons.error, color: theme.colorScheme.error),
              )
            : Container(
                color: theme.colorScheme.surfaceVariant,
                alignment: Alignment.center,
                child: Text(
                  avatar.emoji,
                  style: TextStyle(fontSize: size * 0.6),
                ),
              ),
      ),
    );
  }
}