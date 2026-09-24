import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../utils/formatters.dart';

class PerformanceLineChart extends StatelessWidget {
  final List<String> labels;
  final List<double> portfolioValues;
  final List<double> incomeValues;
  final List<double> expenseValues;

  const PerformanceLineChart({
    super.key,
    required this.labels,
    required this.portfolioValues,
    required this.incomeValues,
    required this.expenseValues,
  });

  @override
  Widget build(BuildContext context) {
    final allValues = [...portfolioValues, ...incomeValues, ...expenseValues];
    final maxY = allValues.isEmpty
        ? 100.0
        : allValues.reduce((a, b) => a > b ? a : b) * 1.2;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _legendDot('Portofolio', Colors.indigo),
            const SizedBox(width: 14),
            _legendDot('Pemasukan', Colors.green),
            const SizedBox(width: 14),
            _legendDot('Pengeluaran', Colors.red),
          ],
        ),
        const SizedBox(height: 14),
        SizedBox(
          height: 200,
          child: LineChart(
            LineChartData(
              minY: 0,
              maxY: maxY == 0 ? 100 : maxY,
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: maxY == 0 ? 20 : maxY / 4,
                getDrawingHorizontalLine: (v) => FlLine(
                  color: Colors.grey.shade200,
                  strokeWidth: 1,
                ),
              ),
              borderData: FlBorderData(show: false),
              titlesData: FlTitlesData(
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 24,
                    getTitlesWidget: (value, meta) {
                      final idx = value.toInt();
                      if (idx < 0 || idx >= labels.length) {
                        return const SizedBox.shrink();
                      }
                      return Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          labels[idx],
                          style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
                        ),
                      );
                    },
                  ),
                ),
              ),
              lineTouchData: LineTouchData(
                touchTooltipData: LineTouchTooltipData(
                  getTooltipItems: (spots) => spots.map((s) {
                    return LineTooltipItem(
                      AppFormatters.rupiahCompact(s.y),
                      const TextStyle(color: Colors.white, fontSize: 11),
                    );
                  }).toList(),
                ),
              ),
              lineBarsData: [
                _line(portfolioValues, Colors.indigo),
                _line(incomeValues, Colors.green),
                _line(expenseValues, Colors.red),
              ],
            ),
          ),
        ),
      ],
    );
  }

  LineChartBarData _line(List<double> values, Color color) {
    return LineChartBarData(
      spots: List.generate(values.length, (i) => FlSpot(i.toDouble(), values[i])),
      isCurved: true,
      color: color,
      barWidth: 2.5,
      dotData: const FlDotData(show: false),
      belowBarData: BarAreaData(show: false),
    );
  }

  Widget _legendDot(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(fontSize: 11, color: Colors.grey.shade700)),
      ],
    );
  }
}
