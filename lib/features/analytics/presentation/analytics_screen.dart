import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/responsive/responsive_layout.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/formatting/currency_formatter.dart';
import '../../budget/data/budget_repository.dart';
import '../../budget/domain/models.dart';

class AnalyticsScreen extends ConsumerWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final budgetState = ref.watch(budgetProvider);
    final currentOverview = budgetState.currentOverview;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (currentOverview == null) {
      return const Scaffold(body: Center(child: Text('Data tidak tersedia')));
    }

    final horizontalPadding = ResponsiveLayout.horizontalPadding(context);
    final allOverviews = budgetState.allOverviews;
    final availableMonths = budgetState.availableMonths;

    // Top spending items
    final sortedItems = List<BudgetItem>.from(currentOverview.budgetItems)
      ..sort((a, b) => b.actual.compareTo(a.actual));
    final topItems = sortedItems.where((i) => i.actual > 0).take(5).toList();

    // Alert items
    final overBudgetItems = currentOverview.budgetItems
        .where((i) => i.status == BudgetStatus.overBudget)
        .toList();
    final nearLimitItems = currentOverview.budgetItems
        .where((i) => i.status == BudgetStatus.nearLimit)
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Analisis & Peringatan',
            style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding:
            EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Month-to-Month Comparison Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Perbandingan Antar Bulan (Month-to-Month)',
                      style: theme.textTheme.titleSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    _buildMonthComparisonBarChart(
                        availableMonths, allOverviews),
                    const SizedBox(height: 16),
                    // Comparison Table
                    _buildComparisonTable(
                        context, availableMonths, allOverviews),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Top Spending Items Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '5 Pengeluaran Terbesar Bulan Ini',
                      style: theme.textTheme.titleSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const Divider(),
                    ...topItems.map((item) {
                      final pct = currentOverview.totalActual > 0
                          ? (item.actual / currentOverview.totalActual * 100)
                          : 0.0;
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6.0),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 3,
                              child: Text(
                                item.name,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600, fontSize: 13),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  CurrencyFormatter.formatRupiah(item.actual),
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold, fontSize: 13),
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.teal.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                '${pct.toStringAsFixed(1)}%',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.primaryGreen,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Alerts Section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.shield_outlined,
                            color: AppTheme.primaryGreen),
                        const SizedBox(width: 8),
                        Text(
                          'Pemeriksaan Kualitas & Anomali Data',
                          style: theme.textTheme.titleSmall
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const Divider(),
                    if (overBudgetItems.isEmpty && nearLimitItems.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8.0),
                        child: Row(
                          children: [
                            Icon(Icons.check_circle,
                                color: AppTheme.statusNormal, size: 20),
                            SizedBox(width: 8),
                            Text('Semua pos anggaran dalam batas aman.'),
                          ],
                        ),
                      )
                    else ...[
                      if (overBudgetItems.isNotEmpty) ...[
                        Text(
                          'Over Budget (${overBudgetItems.length}):',
                          style: const TextStyle(
                              color: Colors.red, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 6),
                        ...overBudgetItems.map((e) => Padding(
                              padding: const EdgeInsets.only(bottom: 4.0),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('• ${e.name}',
                                      style: const TextStyle(fontSize: 13)),
                                  Text(
                                    '${CurrencyFormatter.formatRupiah(e.actual)} (Defisit: ${CurrencyFormatter.formatRupiah(e.remaining.abs())})',
                                    style: const TextStyle(
                                        color: Colors.red,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12),
                                  ),
                                ],
                              ),
                            )),
                        const SizedBox(height: 10),
                      ],
                      if (nearLimitItems.isNotEmpty) ...[
                        Text(
                          'Mendekati Batas (${nearLimitItems.length}):',
                          style: const TextStyle(
                              color: Colors.orange,
                              fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 6),
                        ...nearLimitItems.map((e) => Padding(
                              padding: const EdgeInsets.only(bottom: 4.0),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('• ${e.name}',
                                      style: const TextStyle(fontSize: 13)),
                                  Text(
                                    '${(e.utilizationRate * 100).toStringAsFixed(1)}% terpakai',
                                    style: const TextStyle(
                                        color: Colors.orange,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12),
                                  ),
                                ],
                              ),
                            )),
                      ],
                    ],
                    const SizedBox(height: 12),
                    // Bank Discrepancy Note
                    if (currentOverview.discrepancy != null)
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.grey.shade800
                              : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.info_outline,
                                size: 16, color: Colors.blue),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Rekonsiliasi Bank: Saldo tercatat ${CurrencyFormatter.formatRupiah(currentOverview.bankBalance)} dengan selisih ${CurrencyFormatter.formatRupiah(currentOverview.discrepancy)}.',
                                style: const TextStyle(fontSize: 11),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildMonthComparisonBarChart(
    List<MonthIdentifier> months,
    Map<String, MonthlyOverview> overviews,
  ) {
    if (months.isEmpty) return const SizedBox.shrink();

    final maxVal = months.fold(0.0, (m, mo) {
      final ov = overviews[mo.sheetName];
      if (ov == null) return m;
      final high =
          ov.totalBudget > ov.totalActual ? ov.totalBudget : ov.totalActual;
      return high > m ? high : m;
    });

    return SizedBox(
      height: 220,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: maxVal * 1.15,
          titlesData: FlTitlesData(
            topTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 50,
                getTitlesWidget: (v, _) => Text(
                  CurrencyFormatter.formatRupiah(v, compact: true),
                  style: const TextStyle(fontSize: 9),
                ),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (v, _) {
                  final i = v.toInt();
                  if (i >= 0 && i < months.length) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 4.0),
                      child: Text(
                        months[i].displayName.split(' ').first,
                        style: const TextStyle(
                            fontSize: 10, fontWeight: FontWeight.bold),
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
            getDrawingHorizontalLine: (v) =>
                FlLine(color: Colors.grey.withOpacity(0.15)),
          ),
          borderData: FlBorderData(show: false),
          barGroups: List.generate(months.length, (i) {
            final ov = overviews[months[i].sheetName];
            final budget = ov?.totalBudget ?? 0.0;
            final actual = ov?.totalActual ?? 0.0;

            return BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: budget,
                  color: AppTheme.safeCyan.withValues(alpha: 0.7),
                  width: 14,
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(6)),
                ),
                BarChartRodData(
                  toY: actual,
                  color: AppTheme.dangerNeon,
                  width: 14,
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(6)),
                ),
              ],
            );
          }),
        ),
      ),
    );
  }

  Widget _buildComparisonTable(
    BuildContext context,
    List<MonthIdentifier> months,
    Map<String, MonthlyOverview> overviews,
  ) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columns: const [
          DataColumn(
              label:
                  Text('Bulan', style: TextStyle(fontWeight: FontWeight.bold))),
          DataColumn(
              label: Text('Budget',
                  style: TextStyle(fontWeight: FontWeight.bold))),
          DataColumn(
              label: Text('Realisasi',
                  style: TextStyle(fontWeight: FontWeight.bold))),
          DataColumn(
              label:
                  Text('Sisa', style: TextStyle(fontWeight: FontWeight.bold))),
        ],
        rows: months.map((m) {
          final ov = overviews[m.sheetName];
          return DataRow(
            cells: [
              DataCell(Text(m.displayName)),
              DataCell(Text(CurrencyFormatter.formatRupiah(ov?.totalBudget,
                  compact: true))),
              DataCell(Text(CurrencyFormatter.formatRupiah(ov?.totalActual,
                  compact: true))),
              DataCell(Text(
                CurrencyFormatter.formatRupiah(ov?.totalRemaining,
                    compact: true),
                style: TextStyle(
                  color: (ov?.totalRemaining ?? 0) < 0 ? Colors.red : null,
                  fontWeight: FontWeight.w600,
                ),
              )),
            ],
          );
        }).toList(),
      ),
    );
  }
}
