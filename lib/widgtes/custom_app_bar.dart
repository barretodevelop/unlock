// Widget AppBar Customizado
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String userName;
  final String userCode;
  final String avatarId;
  final bool hasNotifications;
  final VoidCallback? onNotificationTap;
  final VoidCallback? onAvatarTap;

  const CustomAppBar({
    super.key,
    required this.userName,
    required this.userCode,
    required this.avatarId,
    this.hasNotifications = false,
    this.onNotificationTap,
    this.onAvatarTap,
    required int notificationCount,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return AppBar(
      elevation: 0,
      backgroundColor: isDark
          ? const Color(0xFF0A0A0A)
          : const Color(0xFFF8F9FA),
      automaticallyImplyLeading: false,
      toolbarHeight: 80,
      flexibleSpace: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Row(
            children: [
              _buildUserInfo(isDark),
              const Spacer(),
              _buildNotificationButton(isDark),
              IconButton(
                onPressed: () => context.go('/settings'),
                icon: Icon(Icons.settings),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Widget _buildConfig(bool isDark) {
  //   return IconButton(
  //     // onPressed: () {
  //     //   context.go('/setting');
  //     // },
  //      onPressed: () => context.go('/home'),
  //     icon: Icon(Icons.settings),
  //   );
  // }

  Widget _buildUserInfo(bool isDark) {
    return Row(
      children: [
        GestureDetector(
          onTap: onAvatarTap,
          child: _buildAvatarWithStatus(isDark),
        ),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              userName,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              userCode,
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAvatarWithStatus(bool isDark) {
    return Stack(
      children: [
        // Container(
        //   width: 48,
        //   height: 48,
        //   decoration: BoxDecoration(
        //     shape: BoxShape.circle,
        //     gradient: LinearGradient(
        //       begin: Alignment.topLeft,
        //       end: Alignment.bottomRight,
        //       colors: [Colors.purple.shade400, Colors.blue.shade400],
        //     ),
        //     boxShadow: [
        //       BoxShadow(
        //         color: Colors.purple.withOpacity(0.3),
        //         blurRadius: 8,
        //         offset: const Offset(0, 2),
        //       ),
        //     ],
        //   ),
        //   child: CachedNetworkImage(
        //     imageUrl: avatarId,
        //     placeholder: (context, url) => const CircularProgressIndicator(
        //       valueColor: AlwaysStoppedAnimation<Color>(Colors.white70),
        //     ),
        //     errorWidget: (context, url, error) =>
        //         const Icon(Icons.person, size: 30, color: Colors.white70),
        //     fit: BoxFit.cover,
        //     width: 60,
        //     height: 60,
        //   ),
        // ),
        CircleAvatar(
          radius: 25,
          backgroundColor: Colors.white.withOpacity(0.2),
          child: avatarId.startsWith('http')
              ? ClipOval(
                  child: CachedNetworkImage(
                    imageUrl: avatarId,
                    placeholder: (context, url) =>
                        const CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white70,
                          ),
                        ),
                    errorWidget: (context, url, error) => const Icon(
                      Icons.person,
                      size: 30,
                      color: Colors.white70,
                    ),
                    fit: BoxFit.cover,
                    width: 60,
                    height: 60,
                  ),
                )
              : Text(
                  avatarId,
                  style: const TextStyle(fontSize: 30),
                ), // Fallback para emoji/texto se não for URL
        ),
        Positioned(
          right: 0,
          bottom: 0,
          child: Container(
            width: 14,
            height: 14,
            decoration: BoxDecoration(
              color: Colors.green,
              shape: BoxShape.circle,
              border: Border.all(
                color: isDark
                    ? const Color(0xFF0A0A0A)
                    : const Color(0xFFF8F9FA),
                width: 2,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNotificationButton(bool isDark) {
    return GestureDetector(
      onTap: onNotificationTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: isDark
              ? Colors.grey.shade800.withOpacity(0.5)
              : Colors.white.withOpacity(0.8),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: const Color.fromARGB(255, 22, 42, 172).withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Stack(
          children: [
            Center(
              child: Icon(
                hasNotifications
                    ? Icons.notifications
                    : Icons.notifications_outlined,
                color: hasNotifications
                    ? Colors.amber.shade300
                    : (isDark ? Colors.white70 : Colors.black54),
                size: 22,
              ),
            ),
            if (hasNotifications)
              Positioned(
                right: 10,
                top: 10,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: Colors.red.shade400,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.white.withOpacity(0.5),
                        blurRadius: 4,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(80);
}
