// lib/shared/widgets/avatar_circle.dart
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class AvatarCircle extends StatelessWidget {
  final String? imageUrl;
  final double radius;

  const AvatarCircle({super.key, required this.imageUrl, this.radius = 24.0});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasImage =
        imageUrl != null &&
        imageUrl!.isNotEmpty &&
        imageUrl!.startsWith('http');

    return CircleAvatar(
      radius: radius,
      backgroundColor: theme.colorScheme.surfaceContainerHighest,
      child: hasImage
          ? ClipOval(
              child: CachedNetworkImage(
                imageUrl: imageUrl!,
                fit: BoxFit.cover,
                width: radius * 2,
                height: radius * 2,
                placeholder: (context, url) => Shimmer.fromColors(
                  baseColor: Colors.grey[300]!,
                  highlightColor: Colors.grey[100]!,
                  child: Container(color: Colors.white),
                ),
                errorWidget: (context, url, error) => Icon(
                  Icons.person,
                  size: radius,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            )
          : Icon(
              Icons.person,
              size: radius,
              color: theme.colorScheme.onSurfaceVariant,
            ),
    );
  }
}
