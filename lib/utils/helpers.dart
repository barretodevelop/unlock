// Helpers
// lib/utils/helpers.dart - Helpers
import 'dart:math';

import 'package:flutter/material.dart';

class Helpers {
  static String formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'Agora';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m atrás';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h atrás';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d atrás';
    } else {
      return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
    }
  }

  static String formatDuration(Duration duration) {
    if (duration.inDays > 0) {
      return '${duration.inDays}d ${duration.inHours % 24}h';
    } else if (duration.inHours > 0) {
      return '${duration.inHours}h ${duration.inMinutes % 60}m';
    } else {
      return '${duration.inMinutes}m';
    }
  }

  static Color getStatColor(int value) {
    if (value >= 80) return const Color(0xFF10B981); // green
    if (value >= 60) return const Color(0xFFFBBF24); // yellow
    if (value >= 40) return const Color(0xFFF97316); // orange
    return const Color(0xFFEF4444); // red
  }

  static Color getRarityColor(String rarity) {
    switch (rarity.toLowerCase()) {
      case 'comum':
        return const Color(0xFF9CA3AF);
      case 'incomum':
        return const Color(0xFF10B981);
      case 'raro':
        return const Color(0xFF3B82F6);
      case 'épico':
        return const Color(0xFF8B5CF6);
      case 'lendário':
        return const Color(0xFFF59E0B);
      case 'único':
        return const Color(0xFFEC4899);
      default:
        return const Color(0xFF6B7280);
    }
  }

  static String generateRandomId() {
    final random = Random();
    const chars =
        'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    return String.fromCharCodes(
      Iterable.generate(
        16,
        (_) => chars.codeUnitAt(random.nextInt(chars.length)),
      ),
    );
  }

  static List<String> getRandomAvatars() {
    return [
      '👨',
      '👩',
      '🧑',
      '👱',
      '👨‍💻',
      '👩‍💻',
      '🧔',
      '👴',
      '👵',
      '👦',
      '👧',
    ];
  }

  // static String getRandomCategoryWithEmoji() {
  //   final random = Random();
  //   final keys = Constants.categoryEmojis.keys.toList();
  //   final key = keys[random.nextInt(keys.length)];
  //   final emoji = Constants.categoryEmojis[key];
  //   return '$emoji';
  // }

  static Color withOpacityNew(Color color, double opacity) {
    return color.withValues(
      alpha: opacity * 255,
      red: color.r.toDouble(),
      green: color.g.toDouble(),
      blue: color.b.toDouble(),
    );
  }

  static String getRandomAvatar() {
    final avatars = getRandomAvatars();
    return avatars[Random().nextInt(avatars.length)];
  }

  static double calculateDistance(double x1, double y1, double x2, double y2) {
    return sqrt(pow(x2 - x1, 2) + pow(y2 - y1, 2));
  }

  static bool isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  static String capitalizeFirst(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1).toLowerCase();
  }

  static String pluralize(String word, int count) {
    if (count == 1) return word;

    // Simple Portuguese pluralization rules
    if (word.endsWith('ão')) {
      return word.replaceAll('ão', 'ões');
    } else if (word.endsWith('m')) {
      return word.replaceAll('m', 'ns');
    } else if (word.endsWith('r') || word.endsWith('s') || word.endsWith('z')) {
      return '${word}es';
    } else {
      return '${word}s';
    }
  }

  static void showSnackBar(
    BuildContext context,
    String message, {
    bool isError = false,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError
            ? const Color(0xFFEF4444)
            : const Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  static Future<bool> showConfirmDialog(
    BuildContext context,
    String title,
    String message, {
    String confirmText = 'Confirmar',
    String cancelText = 'Cancelar',
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(cancelText),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(confirmText),
          ),
        ],
      ),
    );
    return result ?? false;
  }
}
