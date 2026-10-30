import 'package:flutter/material.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/formatting/currency_formatter.dart';
import '../../budget/domain/models.dart';

class BudgetItemDetailDialog extends StatelessWidget {
  final BudgetItem item;
  final List<DailyExpense> relatedTransactions;
  final VoidCallback onAddExpense;

  const BudgetItemDetailDialog({
    super.key,
    required this.item,
    required this.relatedTransactions,
    required this.onAddExpense,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final pct = item.budget > 0 ? (item.actual / item.budget) : 0.0;
    Color statusColor = AppTheme.statusNormal;
    String statusLabel = 'On Track';

    if (item.status == BudgetStatus.overBudget) {
      statusColor = AppTheme.statusOverBudget;
      statusLabel = 'Melebihi Budget';
    } else if (item.status == BudgetStatus.nearLimit) {
      statusColor = AppTheme.statusNearLimit;
      statusLabel = 'Hampir Habis';
    } else if (item.status == BudgetStatus.approachingLimit) {
      statusColor = AppTheme.statusApproaching;
      statusLabel = 'Mendekati Limit';
    }

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 550, maxHeight: 650),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
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
                          item.name,
                          style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppTheme.getCategoryColor(item.category).withOpacity(0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            item.category,
                            style: TextStyle(
                              color: AppTheme.getCategoryColor(item.category),
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Metrics Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildMetricCol('Anggaran', CurrencyFormatter.formatRupiah(item.budget)),
                        _buildMetricCol('Realisasi', CurrencyFormatter.formatRupiah(item.actual)),
                        _buildMetricCol(
                          'Sisa',
                          CurrencyFormatter.formatRupiah(item.remaining),
                          isAlert: item.remaining < 0,
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: pct.clamp(0.0, 1.0),
                        backgroundColor: Colors.grey.withOpacity(0.2),
                        valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                        minHeight: 10,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Status: $statusLabel',
                          style: TextStyle(
                            color: statusColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          '${(pct * 100).toStringAsFixed(1)}% terpakai',
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),
              Text(
                'Riwayat Transaksi Terkait (${relatedTransactions.length})',
                style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              const Divider(),

              // Transactions list
              Expanded(
                child: relatedTransactions.isEmpty
                    ? Center(
                        child: Text(
                          'Belum ada transaksi tercatat untuk pos ini.',
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                      )
                    : ListView.separated(
                        itemCount: relatedTransactions.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, i) {
                          final tx = relatedTransactions[i];
                          return ListTile(
                            dense: true,
                            contentPadding: EdgeInsets.zero,
                            title: Text(tx.description, style: const TextStyle(fontWeight: FontWeight.w600)),
                            subtitle: Text(tx.date, style: const TextStyle(fontSize: 12)),
                            trailing: Text(
                              CurrencyFormatter.formatRupiah(tx.amount),
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          );
                        },
                      ),
              ),

              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Tutup'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () {
                        Navigator.of(context).pop();
                        onAddExpense();
                      },
                      icon: const Icon(Icons.add),
                      label: const Text('Tambah Pengeluaran'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetricCol(String label, String value, {bool isAlert = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 13,
            color: isAlert ? Colors.red : null,
          ),
        ),
      ],
    );
  }
}

