import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/responsive/responsive_layout.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/formatting/currency_formatter.dart';
import '../../budget/data/budget_repository.dart';
import '../../budget/domain/models.dart';
import 'widgets/category_pie_chart.dart';
import 'widgets/kpi_card.dart';
import 'widgets/spending_trend_chart.dart';

class DashboardScreen extends ConsumerWidget {
  final VoidCallback? onNavigateToBudget;
  final VoidCallback? onNavigateToTransactions;

  const DashboardScreen({
    super.key,
    this.onNavigateToBudget,
    this.onNavigateToTransactions,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final budgetState = ref.watch(budgetProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (budgetState.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (budgetState.errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 12),
              Text(budgetState.errorMessage!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () => ref.read(budgetProvider.notifier).loadInitialData(),
                icon: const Icon(Icons.refresh),
                label: const Text('Coba Lagi'),
              ),
            ],
          ),
        ),
      );
    }

    final overview = budgetState.currentOverview;
    if (overview == null) {
      return const Center(child: Text('Tidak ada data bulan yang ditemukan'));
    }

    final screenType = ResponsiveLayout.getDeviceType(context);
    final horizontalPadding = ResponsiveLayout.horizontalPadding(context);

    // Over-budget or near limit items
    final alertItems = overview.budgetItems.where((i) =>
        i.status == BudgetStatus.overBudget || i.status == BudgetStatus.nearLimit).toList();

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Dapoy Wallet',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            Text(
              overview.title,
              style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey.shade600),
            ),
          ],
        ),
        actions: [
          // Month Selector
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: isDark ? Colors.grey.shade800 : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<MonthIdentifier>(
                value: budgetState.selectedMonth,
                icon: const Icon(Icons.keyboard_arrow_down, size: 20),
                items: budgetState.availableMonths.map((m) {
                  return DropdownMenuItem(
                    value: m,
                    child: Text(
                      m.displayName,
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                    ),
                  );
                }).toList(),
                onChanged: (selected) {
                  if (selected != null) {
                    ref.read(budgetProvider.notifier).selectMonth(selected);
                  }
                },
              ),
            ),
          ),
          IconButton(
            tooltip: isDark ? 'Mode Terang' : 'Mode Gelap',
            icon: Icon(isDark ? Icons.light_mode : Icons.dark_mode),
            onPressed: () {
              ref.read(themeModeProvider.notifier).state =
                  isDark ? ThemeMode.light : ThemeMode.dark;
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(budgetProvider.notifier).loadInitialData(),
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Secondary Status Banner (Bank & Reconciliation)
              _buildStatusBanner(context, overview, isDark),
              const SizedBox(height: 16),

              // KPI Cards Grid
              _buildKpiGrid(context, overview, screenType),
              const SizedBox(height: 20),

              // Alerts if any items are over-budget
              if (alertItems.isNotEmpty) ...[
                _buildAlertBanner(context, alertItems),
                const SizedBox(height: 20),
              ],

              // Charts & Category Breakdown (responsive 1-col or 2-col)
              if (screenType == DeviceScreenType.compact) ...[
                _buildCategoryDonutCard(context, overview),
                const SizedBox(height: 16),
                _buildSpendingTrendCard(context, overview),
                const SizedBox(height: 16),
                _buildCategoryProgressList(context, overview),
              ] else ...[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 5,
                      child: Column(
                        children: [
                          _buildCategoryDonutCard(context, overview),
                          const SizedBox(height: 16),
                          _buildSpendingTrendCard(context, overview),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      flex: 6,
                      child: _buildCategoryProgressList(context, overview),
                    ),
                  ],
                ),
              ],

              const SizedBox(height: 20),

              // Recent Transactions preview
              _buildRecentTransactionsCard(context, overview),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBanner(BuildContext context, MonthlyOverview overview, bool isDark) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: AppTheme.statusNormal,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Tersinkronisasi',
                style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          if (overview.bankBalance != null)
            Row(
              children: [
                Icon(Icons.account_balance, size: 16, color: Colors.grey.shade600),
                const SizedBox(width: 6),
                Text(
                  'Saldo: ${CurrencyFormatter.formatRupiah(overview.bankBalance, compact: true)}',
                  style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
                ),
                if (overview.discrepancy != null && overview.discrepancy!.abs() > 1.0) ...[
                  const SizedBox(width: 12),
                  Text(
                    'Selisih: ${CurrencyFormatter.formatRupiah(overview.discrepancy, compact: true)}',
                    style: TextStyle(
                      color: Colors.red.shade600,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ],
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildKpiGrid(
    BuildContext context,
    MonthlyOverview overview,
    DeviceScreenType screenType,
  ) {
    final cards = [
      KpiCard(
        title: 'Total Pemasukan',
        amount: overview.totalIncome,
        icon: Icons.arrow_downward,
        iconColor: AppTheme.statusNormal,
        subtitle: '${overview.incomes.length} Sumber Pendapatan',
      ),
      KpiCard(
        title: 'Total Budget',
        amount: overview.totalBudget,
        icon: Icons.account_balance_wallet,
        iconColor: AppTheme.accentIndigo,
        subtitle: '${overview.budgetItems.length} Alokasi Pos Anggaran',
      ),
      KpiCard(
        title: 'Total Pengeluaran',
        amount: overview.totalActual,
        icon: Icons.arrow_upward,
        iconColor: AppTheme.statusApproaching,
        subtitle: '${(overview.totalActual / (overview.totalBudget > 0 ? overview.totalBudget : 1) * 100).toStringAsFixed(1)}% dari Anggaran',
      ),
      KpiCard(
        title: 'Sisa Anggaran',
        amount: overview.totalRemaining,
        icon: Icons.savings,
        iconColor: overview.totalRemaining < 0 ? Colors.red : AppTheme.primaryLight,
        isNegativeAlert: true,
        subtitle: overview.totalRemaining >= 0 ? 'Tersedia' : 'Over Budget!',
      ),
    ];

    if (screenType == DeviceScreenType.compact) {
      return GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 2,
        childAspectRatio: 1.35,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        children: cards,
      );
    } else {
      return GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 4,
        childAspectRatio: 1.5,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        children: cards,
      );
    }
  }

  Widget _buildAlertBanner(BuildContext context, List<BudgetItem> alertItems) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.warning_amber_rounded, color: Colors.red, size: 24),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Perhatian: ${alertItems.length} Pos Anggaran Melebihi / Menjelang Batas',
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
                ),
                const SizedBox(height: 4),
                Text(
                  alertItems.map((e) => '${e.name} (${(e.utilizationRate * 100).toStringAsFixed(0)}%)').join(', '),
                  style: TextStyle(color: Colors.red.shade900, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryDonutCard(BuildContext context, MonthlyOverview overview) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Proporsi Pengeluaran Kategori',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
                const Icon(Icons.pie_chart_outline, size: 20, color: Colors.grey),
              ],
            ),
            const SizedBox(height: 16),
            CategoryPieChart(summaries: overview.categorySummaries),
          ],
        ),
      ),
    );
  }

  Widget _buildSpendingTrendCard(BuildContext context, MonthlyOverview overview) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Tren Pengeluaran Harian',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
                const Icon(Icons.bar_chart, size: 20, color: Colors.grey),
              ],
            ),
            const SizedBox(height: 16),
            SpendingTrendChart(transactions: overview.transactions),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryProgressList(BuildContext context, MonthlyOverview overview) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Realisasi per Kategori',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
                if (onNavigateToBudget != null)
                  TextButton(
                    onPressed: onNavigateToBudget,
                    child: const Text('Lihat Detail', style: TextStyle(fontSize: 12)),
                  ),
              ],
            ),
            const Divider(),
            ...overview.categorySummaries.map((cat) {
              final pct = cat.budget > 0 ? (cat.actual / cat.budget) : 0.0;
              Color progressColor = AppTheme.statusNormal;
              if (pct > 1.0) {
                progressColor = AppTheme.statusOverBudget;
              } else if (pct >= 0.95) {
                progressColor = AppTheme.statusNearLimit;
              } else if (pct >= 0.75) {
                progressColor = AppTheme.statusApproaching;
              }

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          cat.category,
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                        ),
                        Text(
                          '${CurrencyFormatter.formatRupiah(cat.actual)} / ${CurrencyFormatter.formatRupiah(cat.budget, compact: true)}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: progressColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: pct.clamp(0.0, 1.0),
                        backgroundColor: Colors.grey.withOpacity(0.15),
                        valueColor: AlwaysStoppedAnimation<Color>(progressColor),
                        minHeight: 8,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentTransactionsCard(BuildContext context, MonthlyOverview overview) {
    final recent = overview.transactions.reversed.take(5).toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Transaksi Terakhir',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
                if (onNavigateToTransactions != null)
                  TextButton(
                    onPressed: onNavigateToTransactions,
                    child: const Text('Semua Transaksi', style: TextStyle(fontSize: 12)),
                  ),
              ],
            ),
            const Divider(),
            if (recent.isEmpty)
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Center(child: Text('Belum ada transaksi')),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: recent.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final tx = recent[index];
                  return ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.teal.shade50,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.receipt_long, size: 18, color: Colors.teal.shade700),
                    ),
                    title: Text(tx.description, style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text(
                      '${tx.date}${tx.linkedBudgetItem != null ? " • ${tx.linkedBudgetItem}" : ""}',
                      style: const TextStyle(fontSize: 11),
                    ),
                    trailing: Text(
                      CurrencyFormatter.formatRupiah(tx.amount),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}
