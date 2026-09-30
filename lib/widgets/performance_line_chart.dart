import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../utils/input_currency.dart';
import '../utils/money_formatter.dart';

class PerformanceLineChart extends StatelessWidget {
  final List<String> labels;
  final List<double> portfolioValues; // basis IDR
  final List<double> incomeValues; // basis IDR
  final List<double> expenseValues; // basis IDR
  final InputCurrency currency;
  final double usdRate;

  const PerformanceLineChart({
    super.key,
    required this.labels,
    required this.portfolioValues,
    required this.incomeValues,
    required this.expenseValues,
    required this.currency,
    required this.usdRate,
  });

  @override
  Widget build(BuildContext context) {
    // Konversi semua data ke mata uang tampilan aktif SEBELUM diplot, supaya
    // skala grafik & tooltip ikut berubah saat user toggle IDR/USD.
    final portfolio = portfolioValues.map((v) => MoneyFormatter.convert(v, currency, usdRate)).toList();
    final income = incomeValues.map((v) => MoneyFormatter.convert(v, currency, usdRate)).toList();
    final expense = expenseValues.map((v) => MoneyFormatter.convert(v, currency, usdRate)).toList();

    final allValues = [...portfolio, ...income, ...expense];
    final maxY = allValues.isEmpty ? 100.0 : allValues.reduce((a, b) => a > b ? a : b) * 1.2;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _legendDot('Portofolio', const Color(0xFF2F6FED)),
            const SizedBox(width: 14),
            _legendDot('Pemasukan', const Color(0xFF17A673)),
            const SizedBox(width: 14),
            _legendDot('Pengeluaran', const Color(0xFFE5484D)),
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
                      MoneyFormatter.formatValue(s.y, currency, compact: true),
                      const TextStyle(color: Colors.white, fontSize: 11),
                    );
                  }).toList(),
                ),
              ),
              lineBarsData: [
                _line(portfolio, const Color(0xFF2F6FED)),
                _line(income, const Color(0xFF17A673)),
                _line(expense, const Color(0xFFE5484D)),
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
      belowBarData: BarAreaData(
        show: true,
        gradient: LinearGradient(
          colors: [color.withOpacity(0.16), color.withOpacity(0.0)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
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
