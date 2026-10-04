import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../services/market_data_service.dart';
import '../utils/app_theme.dart';
import '../utils/formatters.dart';

/// Kartu preview harga pasar LIVE untuk ticker yang sedang diketik user di
/// form Input — menampilkan angka harga terkini + sparkline chart (kalau
/// tersedia) mirip tampilan widget harga di aplikasi exchange, plus tombol
/// cepat untuk langsung memakai harga itu sebagai "Harga per Unit".
class PriceQuoteCard extends StatelessWidget {
  final bool isLoading;
  final AssetQuote? quote;
  final String? errorMessage;
  final VoidCallback onUsePrice;

  const PriceQuoteCard({
    super.key,
    required this.isLoading,
    required this.quote,
    required this.errorMessage,
    required this.onUsePrice,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    if (isLoading) {
      return _frame(
        scheme,
        child: Row(
          children: [
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(width: 10),
            Text('Mengambil harga terkini...', style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant)),
          ],
        ),
      );
    }

    if (quote == null) {
      if (errorMessage == null) return const SizedBox.shrink();
      return _frame(
        scheme,
        child: Row(
          children: [
            Icon(Icons.info_outline_rounded, size: 15, color: scheme.onSurfaceVariant),
            const SizedBox(width: 8),
            Expanded(
              child: Text(errorMessage!, style: TextStyle(fontSize: 11.5, color: scheme.onSurfaceVariant)),
            ),
          ],
        ),
      );
    }

    final change = quote!.changePercent;
    final isUp = (change ?? 0) >= 0;
    final changeColor = isUp ? AppColors.gain : AppColors.loss;

    return _frame(
      scheme,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.show_chart_rounded, size: 13, color: AppColors.matchaDarkest),
                        const SizedBox(width: 4),
                        Text('Harga Pasar Saat Ini', style: TextStyle(fontSize: 10.5, color: scheme.onSurfaceVariant)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      AppFormatters.rupiah(quote!.price),
                      style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: scheme.onSurface),
                    ),
                    if (change != null) ...[
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(isUp ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
                              size: 12, color: changeColor),
                          Text(
                            '${AppFormatters.percent(change)} (7 hari)',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: changeColor),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              if (quote!.history.length >= 2)
                SizedBox(
                  width: 90,
                  height: 42,
                  child: _Sparkline(points: quote!.history, color: changeColor),
                ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: onUsePrice,
              icon: const Icon(Icons.bolt_rounded, size: 15),
              label: const Text('Gunakan Harga Ini', style: TextStyle(fontSize: 12)),
              style: OutlinedButton.styleFrom(
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.symmetric(vertical: 8),
              ),
            ),
          ),
          if (quote!.history.isEmpty) ...[
            const SizedBox(height: 6),
            Text(
              'Grafik historis belum tersedia untuk kelas aset ini.',
              style: TextStyle(fontSize: 10, color: scheme.onSurfaceVariant),
            ),
          ],
        ],
      ),
    );
  }

  Widget _frame(ColorScheme scheme, {required Widget child}) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.matchaDarkest.withOpacity(0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.matchaDarkest.withOpacity(0.15)),
      ),
      child: child,
    );
  }
}

class _Sparkline extends StatelessWidget {
  final List<double> points;
  final Color color;

  const _Sparkline({required this.points, required this.color});

  @override
  Widget build(BuildContext context) {
    final minY = points.reduce((a, b) => a < b ? a : b);
    final maxY = points.reduce((a, b) => a > b ? a : b);
    final pad = (maxY - minY) * 0.1;

    return LineChart(
      LineChartData(
        minY: minY - pad,
        maxY: maxY + pad,
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        titlesData: const FlTitlesData(show: false),
        lineTouchData: const LineTouchData(enabled: false),
        lineBarsData: [
          LineChartBarData(
            spots: List.generate(points.length, (i) => FlSpot(i.toDouble(), points[i])),
            isCurved: true,
            color: color,
            barWidth: 2,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [color.withOpacity(0.2), color.withOpacity(0.0)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
