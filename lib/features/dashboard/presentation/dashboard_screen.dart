import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/responsive/responsive_layout.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/formatting/currency_formatter.dart';
import '../../budget/data/budget_repository.dart';
import '../../budget/domain/models.dart';
import 'widgets/category_pie_chart.dart';
import 'widgets/infographic_pie_chart.dart';
import 'widgets/kpi_card.dart';
import 'widgets/spending_trend_chart.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  final VoidCallback? onNavigateToBudget;
  final VoidCallback? onNavigateToTransactions;

  const DashboardScreen({
    super.key,
    this.onNavigateToBudget,
    this.onNavigateToTransactions,
  });

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  bool _useInfographic = true;

  @override
  Widget build(BuildContext context) {
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

    // Over-budget or near limit items (Danger items)
    final alertItems = overview.budgetItems.where((i) =>
        i.status == BudgetStatus.overBudget || i.status == BudgetStatus.nearLimit).toList();

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.account_balance_wallet_rounded, size: 20, color: AppTheme.dangerNeon),
                const SizedBox(width: 8),
                Text(
                  'Dapoy Wallet',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
                ),
              ],
            ),
            Text(
              overview.title,
              style: theme.textTheme.bodySmall?.copyWith(
                color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                fontSize: 11,
              ),
            ),
          ],
        ),
        actions: [
          // Month Selector
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark ? const Color(0xFF334155) : Colors.grey.shade300,
              ),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<MonthIdentifier>(
                value: budgetState.selectedMonth,
                icon: const Icon(Icons.keyboard_arrow_down, size: 18),
                items: budgetState.availableMonths.map((m) {
                  return DropdownMenuItem(
                    value: m,
                    child: Text(
                      m.displayName,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
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

          // Prominent LIGHT / DARK Mode Switcher Pill
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.grey.shade200,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isDark ? const Color(0xFF334155) : Colors.grey.shade300,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                InkWell(
                  onTap: () => ref.read(themeModeProvider.notifier).state = ThemeMode.light,
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                    decoration: BoxDecoration(
                      color: !isDark ? Colors.white : Colors.transparent,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: !isDark
                          ? [const BoxShadow(color: Colors.black12, blurRadius: 4)]
                          : null,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.light_mode_rounded,
                          size: 13,
                          color: !isDark ? Colors.amber.shade700 : Colors.grey,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'LIGHT',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: !isDark ? FontWeight.bold : FontWeight.w500,
                            color: !isDark ? Colors.black87 : Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                InkWell(
                  onTap: () => ref.read(themeModeProvider.notifier).state = ThemeMode.dark,
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                    decoration: BoxDecoration(
                      color: isDark ? AppTheme.dangerPrimary : Colors.transparent,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: isDark
                          ? [
                              BoxShadow(
                                color: AppTheme.dangerPrimary.withValues(alpha: 0.4),
                                blurRadius: 6,
                              ),
                            ]
                          : null,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.dark_mode_rounded,
                          size: 13,
                          color: isDark ? Colors.white : Colors.grey,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'DARK',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: isDark ? FontWeight.bold : FontWeight.w500,
                            color: isDark ? Colors.white : Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
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
              // Secondary Status Banner (Bank & Discrepancy)
              _buildStatusBanner(context, overview, isDark),
              const SizedBox(height: 16),

              // KPI Cards with Dangerous Alert Hierarchy
              _buildKpiGrid(context, overview, screenType),
              const SizedBox(height: 20),

              // Critical Alerts Banner (Psychological Emergency Notice)
              if (alertItems.isNotEmpty) ...[
                _buildAlertBanner(context, alertItems, isDark),
                const SizedBox(height: 20),
              ],

              // Charts & Category Breakdown (responsive 1-col or 2-col)
              if (screenType == DeviceScreenType.compact) ...[
                _buildCategoryDonutCard(context, overview),
                const SizedBox(height: 16),
                _buildSpendingTrendCard(context, overview),
                const SizedBox(height: 16),
                _buildCategoryProgressList(context, overview, isDark),
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
                      child: _buildCategoryProgressList(context, overview, isDark),
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
        color: isDark ? const Color(0xFF131B2E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF1E293B) : Colors.grey.shade200,
        ),
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
                  color: AppTheme.safeGreen,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Supabase Cloud Synced',
                style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          if (overview.bankBalance != null)
            Row(
              children: [
                Icon(Icons.account_balance, size: 15, color: Colors.grey.shade500),
                const SizedBox(width: 6),
                Text(
                  'Saldo: ${CurrencyFormatter.formatRupiah(overview.bankBalance, compact: true)}',
                  style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w700),
                ),
                if (overview.discrepancy != null && overview.discrepancy!.abs() > 1.0) ...[
                  const SizedBox(width: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppTheme.dangerPrimary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'Selisih: ${CurrencyFormatter.formatRupiah(overview.discrepancy, compact: true)}',
                      style: const TextStyle(
                        color: AppTheme.dangerNeon,
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
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
        icon: Icons.south_west_rounded,
        iconColor: AppTheme.safeGreen,
        subtitle: '${overview.incomes.length} Sumber Pendapatan',
      ),
      KpiCard(
        title: 'Batas Anggaran',
        amount: overview.totalBudget,
        icon: Icons.security_rounded,
        iconColor: AppTheme.safeCyan,
        subtitle: '${overview.budgetItems.length} Alokasi Pos Anggaran',
      ),
      KpiCard(
        title: 'TOTAL PENGELUARAN',
        amount: overview.totalActual,
        icon: Icons.local_fire_department,
        iconColor: AppTheme.dangerNeon,
        isExpense: true, // TRIGGERS DANGER PSYCHOLOGICAL ALERT
        subtitle: '${(overview.totalActual / (overview.totalBudget > 0 ? overview.totalBudget : 1) * 100).toStringAsFixed(1)}% Terbakar / Terpakai',
      ),
      KpiCard(
        title: 'Sisa Dana Bertahan',
        amount: overview.totalRemaining,
        icon: Icons.savings_rounded,
        iconColor: overview.totalRemaining < 0 ? AppTheme.dangerNeon : AppTheme.safeGreen,
        isNegativeAlert: true,
        subtitle: overview.totalRemaining >= 0 ? '🛡️ Aman Terkendali' : '🚨 OVER BUDGET!',
      ),
    ];

    if (screenType == DeviceScreenType.compact) {
      return GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 2,
        childAspectRatio: 1.30,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        children: cards,
      );
    } else {
      return GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 4,
        childAspectRatio: 1.45,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        children: cards,
      );
    }
  }

  Widget _buildAlertBanner(BuildContext context, List<BudgetItem> alertItems, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF260D15) : const Color(0xFFFFF1F2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.dangerNeon.withValues(alpha: 0.6), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: AppTheme.dangerNeon.withValues(alpha: isDark ? 0.2 : 0.08),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppTheme.dangerNeon.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.crisis_alert_rounded, color: AppTheme.dangerNeon, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '🚨 PERINGATAN DISIPLIN: POS ANGGARAN KRITIS!',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    color: AppTheme.dangerNeon,
                    letterSpacing: 0.5,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Rem pengeluaran Anda segera! ${alertItems.length} pos anggaran telah menembus batas kewajaran:',
                  style: TextStyle(
                    color: isDark ? Colors.grey.shade300 : const Color(0xFF881337),
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: alertItems.map((e) {
                    final isOver = e.status == BudgetStatus.overBudget;
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: isOver
                            ? AppTheme.dangerNeon.withValues(alpha: 0.2)
                            : AppTheme.warningAmber.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: isOver ? AppTheme.dangerNeon : AppTheme.warningAmber,
                          width: 1,
                        ),
                      ),
                      child: Text(
                        '${e.name}: ${(e.utilizationRate * 100).toStringAsFixed(0)}%',
                        style: TextStyle(
                          color: isOver ? AppTheme.dangerNeon : AppTheme.warningAmber,
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                    );
                  }).toList(),
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
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Proporsi Pengeluaran Kategori',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        _useInfographic ? 'Gaya Infografis (Tap sektor untuk detail)' : 'Gaya Donut Standar',
                        style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(
                    _useInfographic ? Icons.pie_chart_rounded : Icons.donut_large_rounded,
                    color: AppTheme.dangerNeon,
                  ),
                  tooltip: _useInfographic ? 'Ganti ke Donut Standar' : 'Ganti ke Infografis Modern',
                  onPressed: () => setState(() => _useInfographic = !_useInfographic),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_useInfographic)
              Center(child: InfographicPieChart(summaries: overview.categorySummaries))
            else
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
            SpendingTrendChart(transactions: overview.transactions),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryProgressList(
    BuildContext context,
    MonthlyOverview overview,
    bool isDark,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.speed_rounded, size: 18, color: AppTheme.dangerFlame),
                    const SizedBox(width: 6),
                    Text(
                      'Radar Realisasi Kategori',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                if (widget.onNavigateToBudget != null)
                  TextButton(
                    onPressed: widget.onNavigateToBudget,
                    child: const Text('Semua Pos Anggaran', style: TextStyle(fontSize: 12)),
                  ),
              ],
            ),
            const Divider(),
            ...overview.categorySummaries.map((cat) {
              final pct = cat.budget > 0 ? (cat.actual / cat.budget) : 0.0;
              final dangerColor = AppTheme.getDangerColor(pct);
              final dangerLabel = AppTheme.getDangerLabel(pct);
              final isHighDanger = pct > 0.95;

              return Container(
                margin: const EdgeInsets.symmetric(vertical: 6.0),
                padding: const EdgeInsets.all(10.0),
                decoration: BoxDecoration(
                  color: isHighDanger
                      ? AppTheme.dangerPrimary.withValues(alpha: isDark ? 0.16 : 0.08)
                      : (isDark ? Colors.white.withValues(alpha: 0.02) : Colors.grey.shade50),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isHighDanger
                        ? AppTheme.dangerNeon.withValues(alpha: 0.5)
                        : (isDark ? Colors.grey.shade800 : Colors.grey.shade200),
                    width: isHighDanger ? 1.4 : 1.0,
                  ),
                ),
                child: Column(
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
                              decoration: BoxDecoration(
                                color: dangerColor,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              cat.category,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: dangerColor.withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: dangerColor.withValues(alpha: 0.4)),
                          ),
                          child: Text(
                            dangerLabel,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: dangerColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Dangerous Capsule Progress Gauge
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: Stack(
                        children: [
                          Container(
                            height: 10,
                            color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
                          ),
                          FractionallySizedBox(
                            widthFactor: pct.clamp(0.0, 1.0),
                            child: Container(
                              height: 10,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    pct > 0.95
                                        ? AppTheme.dangerFlame
                                        : AppTheme.safeGreen,
                                    dangerColor,
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 6),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Terpakai: ${CurrencyFormatter.formatRupiah(cat.actual)}',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: isHighDanger ? AppTheme.dangerNeon : null,
                          ),
                        ),
                        Text(
                          cat.remaining >= 0
                              ? 'Sisa: ${CurrencyFormatter.formatRupiah(cat.remaining)} (${(pct * 100).toStringAsFixed(0)}%)'
                              : 'DEFISIT: ${CurrencyFormatter.formatRupiah(cat.remaining.abs())} (${(pct * 100).toStringAsFixed(0)}%)',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: cat.remaining < 0 ? AppTheme.dangerNeon : Colors.grey.shade500,
                          ),
                        ),
                      ],
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
                const Row(
                  children: [
                    Icon(Icons.history, size: 18, color: Colors.grey),
                    SizedBox(width: 6),
                    Text(
                      'Log Pengeluaran Terbaru',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                  ],
                ),
                if (widget.onNavigateToTransactions != null)
                  TextButton(
                    onPressed: widget.onNavigateToTransactions,
                    child: const Text('Semua Log Transaksi', style: TextStyle(fontSize: 12)),
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
                        color: AppTheme.dangerPrimary.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.outbox_rounded, size: 18, color: AppTheme.dangerNeon),
                    ),
                    title: Text(tx.description, style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text(
                      '${tx.date}${tx.linkedBudgetItem != null ? " • ${tx.linkedBudgetItem}" : ""}',
                      style: const TextStyle(fontSize: 11),
                    ),
                    trailing: Text(
                      CurrencyFormatter.formatRupiah(tx.amount),
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        color: AppTheme.dangerNeon,
                      ),
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
