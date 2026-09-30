import 'package:flutter/material.dart';

class SummaryCard extends StatelessWidget {
  final String title;
  final String? value;
  final Widget? valueWidget;
  final String? subtitle;
  final IconData icon;
  final Color color;
  final bool valuePositive;

  const SummaryCard({
    super.key,
    required this.title,
    this.value,
    this.valueWidget,
    this.subtitle,
    required this.icon,
    required this.color,
    this.valuePositive = true,
  }) : assert(value != null || valueWidget != null, 'Isi salah satu: value atau valueWidget');

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 12, offset: const Offset(0, 4)),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [color.withOpacity(0.18), color.withOpacity(0.06)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 12.5,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            DefaultTextStyle(
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: valuePositive ? Colors.black87 : const Color(0xFFE5484D),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              child: valueWidget ?? Text(value!),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 4),
              Text(
                subtitle!,
                style: TextStyle(fontSize: 11.5, color: Colors.grey.shade500),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
