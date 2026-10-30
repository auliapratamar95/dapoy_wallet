import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/formatting/currency_formatter.dart';
import '../../../budget/domain/models.dart';

class SpendingTrendChart extends StatelessWidget {
  final List<DailyExpense> transactions;

  const SpendingTrendChart({super.key, required this.transactions});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (transactions.isEmpty) {
      return const SizedBox(
        height: 200,
        child: Center(child: Text('Belum ada transaksi')),
      );
    }

    // Group transactions by date
    final Map<String, double> byDate = {};
    for (final tx in transactions) {
      if (tx.date.isNotEmpty) {
        byDate[tx.date] = (byDate[tx.date] ?? 0.0) + tx.amount;
      }
    }

    final dateEntries = byDate.entries.toList();
    // Take the last 8 entries for smooth curve presentation
    final displayEntries = dateEntries.length > 8
        ? dateEntries.sublist(dateEntries.length - 8)
        : dateEntries;

    final maxY = displayEntries.fold<double>(0.0, (m, e) => e.value > m ? e.value : m);

    final spots = <FlSpot>[];
    for (int i = 0; i < displayEntries.length; i++) {
      spots.add(FlSpot(i.toDouble(), displayEntries[i].value));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: AppTheme.dangerNeon,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Gelombang Pengeluaran Harian',
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.grey.shade300 : Colors.grey.shade700,
                  ),
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppTheme.dangerPrimary.withValues(alpha: isDark ? 0.25 : 0.12),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: AppTheme.dangerPrimary.withValues(alpha: 0.3)),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.local_fire_department, size: 12, color: AppTheme.dangerNeon),
                  SizedBox(width: 4),
                  Text(
                    'FLUKTUASI PENGELUARAN',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.dangerNeon,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 220,
          child: LineChart(
            LineChartData(
              minX: 0,
              maxX: (displayEntries.length - 1).toDouble().clamp(1.0, 100.0),
              minY: 0,
              maxY: maxY * 1.25,
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: maxY > 0 ? (maxY / 3) : 100000,
                getDrawingHorizontalLine: (value) => FlLine(
                  color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.06),
                  strokeWidth: 1,
                  dashArray: [4, 4],
                ),
              ),
              titlesData: FlTitlesData(
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 52,
                    getTitlesWidget: (value, meta) {
                      if (value == 0) return const SizedBox.shrink();
                      return Text(
                        CurrencyFormatter.formatRupiah(value, compact: true),
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                        ),
                      );
                    },
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 28,
                    getTitlesWidget: (value, meta) {
                      final i = value.toInt();
                      if (i >= 0 && i < displayEntries.length) {
                        final raw = displayEntries[i].key;
                        final parts = raw.split(' ');
                        final label = parts.isNotEmpty ? parts.first : raw;
                        return Padding(
                          padding: const EdgeInsets.only(top: 6.0),
                          child: Text(
                            label,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.grey.shade300 : Colors.grey.shade700,
                            ),
                          ),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                ),
              ),
              borderData: FlBorderData(show: false),
              lineTouchData: LineTouchData(
                touchTooltipData: LineTouchTooltipData(
                  getTooltipItems: (touchedSpots) {
                    return touchedSpots.map((spot) {
                      final i = spot.x.toInt();
                      final date = (i >= 0 && i < displayEntries.length)
                          ? displayEntries[i].key
                          : '';
                      return LineTooltipItem(
                        '🔥 $date\n${CurrencyFormatter.formatRupiah(spot.y)}',
                        const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      );
                    }).toList();
                  },
                ),
              ),
              lineBarsData: [
                LineChartBarData(
                  spots: spots,
                  isCurved: true,
                  curveSmoothness: 0.35,
                  preventCurveOverShooting: true,
                  color: AppTheme.dangerNeon,
                  barWidth: 3.5,
                  isStrokeCapRound: true,
                  dotData: FlDotData(
                    show: true,
                    getDotPainter: (spot, percent, barData, index) {
                      return FlDotCirclePainter(
                        radius: 5,
                        color: Colors.white,
                        strokeWidth: 3,
                        strokeColor: AppTheme.dangerNeon,
                      );
                    },
                  ),
                  belowBarData: BarAreaData(
                    show: true,
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        AppTheme.dangerNeon.withValues(alpha: isDark ? 0.40 : 0.28),
                        AppTheme.dangerFlame.withValues(alpha: isDark ? 0.15 : 0.08),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
