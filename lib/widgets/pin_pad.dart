import 'package:flutter/material.dart';

import '../utils/app_theme.dart';

/// Indikator titik PIN (6 digit) + numpad angka — dipakai bareng oleh
/// LockScreen dan PinSetupPage supaya tidak duplikasi kode.
class PinDots extends StatelessWidget {
  final int filled;
  final int total;
  const PinDots({super.key, required this.filled, this.total = 6});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(total, (i) {
        final isFilled = i < filled;
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 6),
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isFilled ? AppColors.matchaDarkest : Colors.transparent,
            border: Border.all(color: AppColors.matchaDarkest, width: 1.5),
          ),
        );
      }),
    );
  }
}

class PinNumPad extends StatelessWidget {
  final ValueChanged<String> onDigit;
  final VoidCallback onBackspace;

  const PinNumPad({super.key, required this.onDigit, required this.onBackspace});

  @override
  Widget build(BuildContext context) {
    const rows = [
      ['1', '2', '3'],
      ['4', '5', '6'],
      ['7', '8', '9'],
      ['', '0', 'back'],
    ];

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: rows.map((row) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: row.map((key) {
              if (key.isEmpty) return const SizedBox(width: 122, height: 64);
              if (key == 'back') {
                return SizedBox(
                  width: 122,
                  height: 64,
                  child: IconButton(
                    onPressed: onBackspace,
                    icon: const Icon(Icons.backspace_outlined, color: AppColors.matchaDarkest),
                  ),
                );
              }
              return SizedBox(
                width: 122,
                height: 64,
                child: InkWell(
                  borderRadius: BorderRadius.circular(36),
                  onTap: () => onDigit(key),
                  child: Center(
                    child: Text(key, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w600, color: AppColors.matchaDarkest)),
                  ),
                ),
              );
            }).toList(),
          ),
        );
      }).toList(),
    );
  }
}
