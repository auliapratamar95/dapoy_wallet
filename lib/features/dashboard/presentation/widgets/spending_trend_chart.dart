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
    if (transactions.isEmpty) {
      return const SizedBox(
        height: 180,
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
    // Take the last 7 dates for readability
    final displayEntries = dateEntries.length > 7
        ? dateEntries.sublist(dateEntries.length - 7)
        : dateEntries;

    final maxY = displayEntries.fold(0.0, (m, e) => e.value > m ? e.value : m);

    return SizedBox(
      height: 200,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: maxY * 1.15,
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                final date = displayEntries[groupIndex].key;
                return BarTooltipItem(
                  '$date\n${CurrencyFormatter.formatRupiah(rod.toY, compact: true)}',
                  const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                );
              },
            ),
          ),
          titlesData: FlTitlesData(
            show: true,
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 48,
                getTitlesWidget: (value, meta) {
                  if (value == 0) return const SizedBox.shrink();
                  return Text(
                    CurrencyFormatter.formatRupiah(value, compact: true),
                    style: const TextStyle(fontSize: 9),
                  );
                },
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 28,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index >= 0 && index < displayEntries.length) {
                    final fullDate = displayEntries[index].key;
                    // Extract first word e.g. "25" or "25 Ags"
                    final parts = fullDate.split(' ');
                    final label = parts.isNotEmpty ? parts.first : fullDate;
                    return Padding(
                      padding: const EdgeInsets.only(top: 4.0),
                      child: Text(
                        label,
                        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w500),
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
          ),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (value) => FlLine(
              color: Colors.grey.withOpacity(0.15),
              strokeWidth: 1,
            ),
          ),
          borderData: FlBorderData(show: false),
          barGroups: List.generate(displayEntries.length, (i) {
            return BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: displayEntries[i].value,
                  color: AppTheme.primaryGreen,
                  width: 14,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                ),
              ],
            );
          }),
        ),
      ),
    );
  }
}
