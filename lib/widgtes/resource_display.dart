import 'package:flutter/material.dart';

class ResourceDisplay extends StatelessWidget {
  final IconData icon;
  final String label;
  final int value;
  final Color? iconColor;

  const ResourceDisplay({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 30, color: iconColor ?? Colors.amber),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        Text(
          value.toString(),
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}
