import 'package:flutter/material.dart';

/// Header seksi konsisten (ikon dalam badge warna + judul + trailing
/// opsional) dipakai di seluruh halaman supaya hierarki visual lebih jelas
/// dibanding cuma Text biasa.
class SectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final Widget? trailing;

  const SectionHeader({
    super.key,
    required this.title,
    required this.icon,
    this.color = const Color(0xFF2F6FED),
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 15, color: color),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
          ),
        ),
        if (trailing != null) trailing!,
      ],
    );
  }
}
