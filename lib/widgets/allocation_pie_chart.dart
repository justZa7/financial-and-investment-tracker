import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../models/asset_holding_model.dart';
import '../utils/formatters.dart';
import 'asset_class_card.dart';

class AllocationPieChart extends StatefulWidget {
  final Map<AssetClass, double> allocation;
  final double cashValue;

  const AllocationPieChart({
    super.key,
    required this.allocation,
    required this.cashValue,
  });

  @override
  State<AllocationPieChart> createState() => _AllocationPieChartState();
}

class _AllocationPieChartState extends State<AllocationPieChart> {
  int _touchedIndex = -1;

  @override
  Widget build(BuildContext context) {
    final entries = <MapEntry<String, double>>[
      MapEntry('Cash', widget.cashValue),
      ...widget.allocation.entries.map((e) => MapEntry(e.key.label, e.value)),
    ].where((e) => e.value > 0).toList();

    final colors = <String, Color>{
      'Cash': const Color(0xFF6E7B8B),
      for (final cls in AssetClass.values) cls.label: assetClassColor(cls),
    };

    final total = entries.fold(0.0, (sum, e) => sum + e.value);

    if (total <= 0) {
      return const SizedBox(
        height: 180,
        child: Center(child: Text('Belum ada data alokasi')),
      );
    }

    return Row(
      children: [
        SizedBox(
          height: 170,
          width: 170,
          child: PieChart(
            PieChartData(
              sectionsSpace: 2,
              centerSpaceRadius: 46,
              pieTouchData: PieTouchData(
                touchCallback: (event, response) {
                  setState(() {
                    if (!event.isInterestedForInteractions ||
                        response == null ||
                        response.touchedSection == null) {
                      _touchedIndex = -1;
                      return;
                    }
                    _touchedIndex =
                        response.touchedSection!.touchedSectionIndex;
                  });
                },
              ),
              sections: List.generate(entries.length, (i) {
                final e = entries[i];
                final isTouched = i == _touchedIndex;
                final pct = e.value / total * 100;
                return PieChartSectionData(
                  color: colors[e.key],
                  value: e.value,
                  title: '${pct.toStringAsFixed(0)}%',
                  radius: isTouched ? 46 : 40,
                  titleStyle: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                );
              }),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: entries.map((e) {
              final pct = e.value / total * 100;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: colors[e.key],
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(e.key, style: const TextStyle(fontSize: 12)),
                    ),
                    Text(
                      '${pct.toStringAsFixed(1)}%',
                      style: const TextStyle(
                          fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}
