import 'package:MatchaFin/utils/input_currency.dart';
import 'package:MatchaFin/utils/input_currency.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/display_currency_provider.dart';

/// Chip toggle kecil di AppBar untuk mengganti mata uang TAMPILAN
/// (IDR/USD) di seluruh aplikasi — mirip toggle mata uang di aplikasi
/// trading. Taruh di `actions` sebuah AppBar/SliverAppBar.
class DisplayCurrencyToggle extends StatelessWidget {
  const DisplayCurrencyToggle({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DisplayCurrencyProvider>();
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(right: 4),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: provider.toggle,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: scheme.primaryContainer,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.currency_exchange_rounded, size: 14, color: scheme.onPrimaryContainer),
              const SizedBox(width: 6),
              Text(
                provider.currency.label,
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: scheme.onPrimaryContainer),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
