import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/theme_mode_provider.dart';

/// Chip toggle kecil di AppBar untuk mengganti tema Light/Dark, taruh
/// bersebelahan dengan DisplayCurrencyToggle.
class ThemeModeToggle extends StatelessWidget {
  const ThemeModeToggle({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ThemeModeProvider>();
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: provider.toggle,
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: scheme.surfaceContainerHighest,
            shape: BoxShape.circle,
          ),
          child: Icon(
            provider.isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
            size: 16,
            color: scheme.onSurface,
          ),
        ),
      ),
    );
  }
}
