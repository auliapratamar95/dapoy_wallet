import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/responsive/responsive_layout.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/formatting/currency_formatter.dart';
import '../../../../core/formatting/date_formatter.dart';
import '../../budget/data/budget_repository.dart';
import '../../budget/domain/models.dart';
import 'widgets/category_pie_chart.dart';
import 'widgets/infographic_pie_chart.dart';
import 'widgets/kpi_card.dart';
import 'widgets/spending_trend_chart.dart';
import '../../budget/presentation/manage_incomes_dialog.dart';

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
    final isCompact = screenType == DeviceScreenType.compact;
    final horizontalPadding = isCompact ? 12.0 : ResponsiveLayout.horizontalPadding(context);

    // Over-budget or near limit items
    final alertItems = overview.budgetItems.where((i) =>
        i.status == BudgetStatus.overBudget || i.status == BudgetStatus.nearLimit).toList();

    return Scaffold(
      appBar: AppBar(
        titleSpacing: isCompact ? 12 : 16,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.account_balance_wallet_rounded, size: 18, color: AppTheme.dangerNeon),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                'Dapoy Wallet',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                  fontSize: isCompact ? 15 : 18,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        actions: [
          // Month Selector (Responsive)
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isDark ? const Color(0xFF334155) : Colors.grey.shade300,
              ),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<MonthIdentifier>(
                value: budgetState.selectedMonth,
                icon: const Icon(Icons.keyboard_arrow_down, size: 16),
                items: budgetState.availableMonths.map((m) {
                  return DropdownMenuItem(
                    value: m,
                    child: Text(
                      isCompact
                          ? '${m.month != null ? DateFormatter.indonesianMonths[m.month! - 1].substring(0, 3) : m.displayName} ${m.year ?? ""}'
                          : m.displayName,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
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

          // Theme Switcher (Icon button on compact to prevent overflow; Pill on large)
          if (isCompact)
            IconButton(
              tooltip: isDark ? 'Mode Terang' : 'Mode Gelap',
              icon: Icon(
                isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                color: isDark ? Colors.amber : Colors.grey.shade800,
                size: 20,
              ),
              onPressed: () {
                ref.read(themeModeProvider.notifier).state =
                    isDark ? ThemeMode.light : ThemeMode.dark;
              },
            )
          else
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
                          Icon(Icons.light_mode_rounded, size: 13, color: !isDark ? Colors.amber.shade700 : Colors.grey),
                          const SizedBox(width: 4),
                          Text(
                            'LIGHT',
                            style: TextStyle(fontSize: 10, fontWeight: !isDark ? FontWeight.bold : FontWeight.w500),
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
                            ? [BoxShadow(color: AppTheme.dangerPrimary.withValues(alpha: 0.4), blurRadius: 6)]
                            : null,
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.dark_mode_rounded, size: 13, color: isDark ? Colors.white : Colors.grey),
                          const SizedBox(width: 4),
                          Text(
                            'DARK',
                            style: TextStyle(fontSize: 10, fontWeight: isDark ? FontWeight.bold : FontWeight.w500, color: isDark ? Colors.white : null),
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
          padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Secondary Status Banner (Non-overlapping)
              _buildStatusBanner(context, overview, isDark, isCompact),
              const SizedBox(height: 12),

              // KPI Cards with 1.12 aspect ratio to avoid card overflow
              _buildKpiGrid(context, overview, screenType),
              const SizedBox(height: 16),

              // Critical Alerts Banner
              if (alertItems.isNotEmpty) ...[
                _buildAlertBanner(context, alertItems, isDark),
                const SizedBox(height: 16),
              ],

              // Charts & Category Breakdown (responsive 1-col or 2-col)
              if (isCompact) ...[
                _buildCategoryDonutCard(context, overview),
                const SizedBox(height: 14),
                _buildSpendingTrendCard(context, overview),
                const SizedBox(height: 14),
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

              const SizedBox(height: 16),

              // Recent Transactions preview
              _buildRecentTransactionsCard(context, overview),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBanner(
    BuildContext context,
    MonthlyOverview overview,
    bool isDark,
    bool isCompact,
  ) {
    final theme = Theme.of(context);

    if (isCompact) {
      // Clean 2-tier layout on small phones so it NEVER overflows
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF131B2E) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: isDark ? const Color(0xFF1E293B) : Colors.grey.shade200),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(width: 7, height: 7, decoration: const BoxDecoration(color: AppTheme.safeGreen, shape: BoxShape.circle)),
                    const SizedBox(width: 6),
                    Text('Supabase Synced', style: theme.textTheme.labelSmall?.copyWith(fontWeight: FontWeight.bold, fontSize: 11)),
                  ],
                ),
                if (overview.bankBalance != null)
                  Text(
                    'Saldo: ${CurrencyFormatter.formatRupiah(overview.bankBalance, compact: true)}',
                    style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w700, fontSize: 11),
                  ),
              ],
            ),
            if (overview.discrepancy != null && overview.discrepancy!.abs() > 1.0) ...[
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                    decoration: BoxDecoration(
                      color: AppTheme.dangerPrimary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'Selisih: ${CurrencyFormatter.formatRupiah(overview.discrepancy, compact: true)}',
                      style: const TextStyle(color: AppTheme.dangerNeon, fontWeight: FontWeight.bold, fontSize: 10),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF131B2E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? const Color(0xFF1E293B) : Colors.grey.shade200),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(width: 8, height: 8, decoration: const BoxDecoration(color: AppTheme.safeGreen, shape: BoxShape.circle)),
              const SizedBox(width: 8),
              Text('Supabase Cloud Synced', style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.bold)),
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
                      style: const TextStyle(color: AppTheme.dangerNeon, fontWeight: FontWeight.bold, fontSize: 11),
                    ),
                  ),
                ],
              ],
            ),
        ],
      ),
    );
  }

  void _openManageIncomes(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => const ManageIncomesDialog(),
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
        subtitle: '${overview.incomes.length} Sumber • Ketuk edit',
        onTap: () => _openManageIncomes(context),
        showEditIndicator: true,
      ),
      KpiCard(
        title: 'Batas Anggaran',
        amount: overview.totalBudget,
        icon: Icons.security_rounded,
        iconColor: AppTheme.safeCyan,
        subtitle: '${overview.budgetItems.length} Pos • Kelola',
        onTap: widget.onNavigateToBudget,
        showEditIndicator: true,
      ),
      KpiCard(
        title: 'TOTAL PENGELUARAN',
        amount: overview.totalActual,
        icon: Icons.local_fire_department,
        iconColor: AppTheme.dangerNeon,
        isExpense: true,
        subtitle: '${(overview.totalActual / (overview.totalBudget > 0 ? overview.totalBudget : 1) * 100).toStringAsFixed(1)}% Terpakai',
      ),
      KpiCard(
        title: 'Sisa Bertahan',
        amount: overview.totalRemaining,
        icon: Icons.savings_rounded,
        iconColor: overview.totalRemaining < 0 ? AppTheme.dangerNeon : AppTheme.safeGreen,
        isNegativeAlert: true,
        subtitle: overview.totalRemaining >= 0 ? '🛡️ Terkendali' : '🚨 OVER BUDGET!',
      ),
    ];

    if (screenType == DeviceScreenType.compact) {
      // Aspect ratio 1.10 provides ample vertical height so contents never overflow on Samsung S7 / iPhone 11
      return GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 2,
        childAspectRatio: 1.12,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
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
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF260D15) : const Color(0xFFFFF1F2),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.dangerNeon.withValues(alpha: 0.6), width: 1.2),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.crisis_alert_rounded, color: AppTheme.dangerNeon, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '🚨 PERINGATAN: POS ANGGARAN KRITIS!',
                  style: TextStyle(fontWeight: FontWeight.w900, color: AppTheme.dangerNeon, fontSize: 11),
                ),
                const SizedBox(height: 3),
                Text(
                  '${alertItems.length} pos anggaran telah menembus batas:',
                  style: TextStyle(color: isDark ? Colors.grey.shade300 : const Color(0xFF881337), fontSize: 11),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 4,
                  runSpacing: 4,
                  children: alertItems.map((e) {
                    final isOver = e.status == BudgetStatus.overBudget;
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: isOver ? AppTheme.dangerNeon.withValues(alpha: 0.2) : AppTheme.warningAmber.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: isOver ? AppTheme.dangerNeon : AppTheme.warningAmber, width: 1),
                      ),
                      child: Text(
                        '${e.name}: ${(e.utilizationRate * 100).toStringAsFixed(0)}%',
                        style: TextStyle(
                          color: isOver ? AppTheme.dangerNeon : AppTheme.warningAmber,
                          fontWeight: FontWeight.bold,
                          fontSize: 10,
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
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'Proporsi Pengeluaran Kategori',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  icon: Icon(
                    _useInfographic ? Icons.pie_chart_rounded : Icons.donut_large_rounded,
                    color: AppTheme.dangerNeon,
                    size: 20,
                  ),
                  tooltip: _useInfographic ? 'Ganti ke Donut Standar' : 'Ganti ke Infografis Modern',
                  onPressed: () => setState(() => _useInfographic = !_useInfographic),
                ),
              ],
            ),
            const SizedBox(height: 8),
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
        padding: const EdgeInsets.all(12.0),
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
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.speed_rounded, size: 16, color: AppTheme.dangerFlame),
                    SizedBox(width: 6),
                    Text(
                      'Radar Realisasi Kategori',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ],
                ),
                if (widget.onNavigateToBudget != null)
                  TextButton(
                    onPressed: widget.onNavigateToBudget,
                    child: const Text('Detail', style: TextStyle(fontSize: 11)),
                  ),
              ],
            ),
            const Divider(height: 8),
            ...overview.categorySummaries.map((cat) {
              final pct = cat.budget > 0 ? (cat.actual / cat.budget) : 0.0;
              final dangerColor = AppTheme.getDangerColor(pct);
              final dangerLabel = AppTheme.getDangerLabel(pct);
              final isHighDanger = pct > 0.95;

              return Container(
                margin: const EdgeInsets.symmetric(vertical: 4.0),
                padding: const EdgeInsets.all(8.0),
                decoration: BoxDecoration(
                  color: isHighDanger
                      ? AppTheme.dangerPrimary.withValues(alpha: isDark ? 0.16 : 0.08)
                      : (isDark ? Colors.white.withValues(alpha: 0.02) : Colors.grey.shade50),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isHighDanger
                        ? AppTheme.dangerNeon.withValues(alpha: 0.5)
                        : (isDark ? Colors.grey.shade800 : Colors.grey.shade200),
                    width: isHighDanger ? 1.2 : 1.0,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              Container(width: 7, height: 7, decoration: BoxDecoration(color: dangerColor, shape: BoxShape.circle)),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  cat.category,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                          decoration: BoxDecoration(
                            color: dangerColor.withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(5),
                            border: Border.all(color: dangerColor.withValues(alpha: 0.4)),
                          ),
                          child: Text(
                            dangerLabel,
                            style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: dangerColor),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),

                    // Dangerous Capsule Progress Gauge
                    ClipRRect(
                      borderRadius: BorderRadius.circular(5),
                      child: Stack(
                        children: [
                          Container(height: 8, color: isDark ? Colors.grey.shade800 : Colors.grey.shade200),
                          FractionallySizedBox(
                            widthFactor: pct.clamp(0.0, 1.0),
                            child: Container(
                              height: 8,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    pct > 0.95 ? AppTheme.dangerFlame : AppTheme.safeGreen,
                                    dangerColor,
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 5),

                    // Safe non-colliding row with Expanded
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            CurrencyFormatter.formatRupiah(cat.actual, compact: true),
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: isHighDanger ? AppTheme.dangerNeon : null,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Flexible(
                          child: Text(
                            cat.remaining >= 0
                                ? 'Sisa: ${CurrencyFormatter.formatRupiah(cat.remaining, compact: true)} (${(pct * 100).toStringAsFixed(0)}%)'
                                : 'DEFISIT: ${CurrencyFormatter.formatRupiah(cat.remaining.abs(), compact: true)} (${(pct * 100).toStringAsFixed(0)}%)',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: cat.remaining < 0 ? AppTheme.dangerNeon : Colors.grey.shade500,
                            ),
                            textAlign: TextAlign.end,
                            overflow: TextOverflow.ellipsis,
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
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.history, size: 16, color: Colors.grey),
                    SizedBox(width: 6),
                    Text(
                      'Log Pengeluaran Terbaru',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ],
                ),
                if (widget.onNavigateToTransactions != null)
                  TextButton(
                    onPressed: widget.onNavigateToTransactions,
                    child: const Text('Semua Log', style: TextStyle(fontSize: 11)),
                  ),
              ],
            ),
            const Divider(height: 8),
            if (recent.isEmpty)
              const Padding(
                padding: EdgeInsets.all(12.0),
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
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppTheme.dangerPrimary.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.outbox_rounded, size: 16, color: AppTheme.dangerNeon),
                    ),
                    title: Text(tx.description, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis),
                    subtitle: Text(
                      '${tx.date}${tx.linkedBudgetItem != null ? " • ${tx.linkedBudgetItem}" : ""}',
                      style: const TextStyle(fontSize: 10),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: Text(
                      CurrencyFormatter.formatRupiah(tx.amount),
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 12,
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
