import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/formatting/currency_formatter.dart';
import '../../../budget/domain/models.dart';

class CategoryPieChart extends StatefulWidget {
  final List<CategorySummary> summaries;

  const CategoryPieChart({super.key, required this.summaries});

  @override
  State<CategoryPieChart> createState() => _CategoryPieChartState();
}

class _CategoryPieChartState extends State<CategoryPieChart> {
  int touchedIndex = -1;

  @override
  Widget build(BuildContext context) {
    final validSummaries = widget.summaries.where((s) => s.actual > 0).toList();
    final totalSpent = validSummaries.fold(0.0, (sum, s) => sum + s.actual);

    if (validSummaries.isEmpty || totalSpent <= 0) {
      return const SizedBox(
        height: 180,
        child: Center(
          child: Text('Belum ada data pengeluaran'),
        ),
      );
    }

    return Column(
      children: [
        SizedBox(
          height: 190,
          child: PieChart(
            PieChartData(
              pieTouchData: PieTouchData(
                touchCallback: (FlTouchEvent event, pieTouchResponse) {
                  setState(() {
                    if (!event.isInterestedForInteractions ||
                        pieTouchResponse == null ||
                        pieTouchResponse.touchedSection == null) {
                      touchedIndex = -1;
                      return;
                    }
                    touchedIndex = pieTouchResponse.touchedSection!.touchedSectionIndex;
                  });
                },
              ),
              borderData: FlBorderData(show: false),
              sectionsSpace: 2,
              centerSpaceRadius: 40,
              sections: List.generate(validSummaries.length, (i) {
                final isTouched = i == touchedIndex;
                final radius = isTouched ? 48.0 : 40.0;
                final item = validSummaries[i];
                final percentage = (item.actual / totalSpent) * 100;
                final color = AppTheme.getCategoryColor(item.category);

                return PieChartSectionData(
                  color: color,
                  value: item.actual,
                  title: '${percentage.toStringAsFixed(0)}%',
                  radius: radius,
                  titleStyle: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                );
              }),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 8,
          children: validSummaries.map((s) {
            final color = AppTheme.getCategoryColor(s.category);
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                ),
                const SizedBox(width: 6),
                Text(
                  '${s.category}: ${CurrencyFormatter.formatRupiah(s.actual, compact: true)}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            );
          }).toList(),
        ),
      ],
    );
  }
}
