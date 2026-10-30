import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/responsive/responsive_layout.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/formatting/currency_formatter.dart';
import '../../budget/data/budget_repository.dart';
import '../../budget/domain/models.dart';
import 'quick_add_transaction_dialog.dart';

class TransactionsScreen extends ConsumerStatefulWidget {
  const TransactionsScreen({super.key});

  @override
  ConsumerState<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends ConsumerState<TransactionsScreen> {
  String searchQuery = '';
  String selectedFilterCategory = 'Semua';

  void _showAddDialog() {
    showDialog(
      context: context,
      builder: (_) => const QuickAddTransactionDialog(),
    );
  }

  void _confirmDelete(DailyExpense expense) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Transaksi?'),
        content: Text(
          'Apakah Anda yakin ingin menghapus transaksi "${expense.description}" sebesar ${CurrencyFormatter.formatRupiah(expense.amount)}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Batal'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Navigator.of(ctx).pop();
              ref.read(budgetProvider.notifier).deleteTransaction(expense);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Transaksi berhasil dihapus')),
              );
            },
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final budgetState = ref.watch(budgetProvider);
    final overview = budgetState.currentOverview;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (overview == null) {
      return const Scaffold(body: Center(child: Text('Data transaksi tidak tersedia')));
    }

    final horizontalPadding = ResponsiveLayout.horizontalPadding(context);

    // Filter transactions
    final filtered = overview.transactions.where((t) {
      final matchesSearch = t.description.toLowerCase().contains(searchQuery.toLowerCase()) ||
          (t.linkedBudgetItem?.toLowerCase().contains(searchQuery.toLowerCase()) ?? false);
      return matchesSearch;
    }).toList();

    // Group by Date
    final Map<String, List<DailyExpense>> groupedByDate = {};
    for (final tx in filtered.reversed) {
      final dateKey = tx.date.isNotEmpty ? tx.date : 'Tanpa Tanggal';
      groupedByDate.putIfAbsent(dateKey, () => []).add(tx);
    }

    final totalFilteredSpending = filtered.fold(0.0, (s, t) => s + t.amount);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Catatan Pengeluaran', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            tooltip: 'Tambah Transaksi',
            icon: const Icon(Icons.add_circle_outline),
            onPressed: _showAddDialog,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddDialog,
        backgroundColor: AppTheme.primaryGreen,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Catat Pengeluaran'),
      ),
      body: Column(
        children: [
          // Total spending & Search Bar
          Padding(
            padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 8),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E293B) : Colors.teal.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.teal.shade200),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Total Pengeluaran Tercatat',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            CurrencyFormatter.formatRupiah(totalFilteredSpending),
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : Colors.teal.shade900,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        '${filtered.length} Transaksi',
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  decoration: InputDecoration(
                    hintText: 'Cari keterangan atau pos anggaran...',
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                    fillColor: isDark ? Colors.grey.shade800 : Colors.white,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.withOpacity(0.2)),
                    ),
                  ),
                  onChanged: (val) => setState(() => searchQuery = val),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Grouped List
          Expanded(
            child: groupedByDate.isEmpty
                ? const Center(child: Text('Tidak ada transaksi yang cocok'))
                : ListView.builder(
                    padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 8),
                    itemCount: groupedByDate.keys.length,
                    itemBuilder: (context, dateIndex) {
                      final date = groupedByDate.keys.elementAt(dateIndex);
                      final txsForDate = groupedByDate[date]!;
                      final subtotal = txsForDate.fold(0.0, (s, t) => s + t.amount);

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Date Header
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.calendar_today_outlined, size: 14, color: AppTheme.primaryGreen),
                                    const SizedBox(width: 6),
                                    Text(
                                      date,
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                    ),
                                  ],
                                ),
                                Text(
                                  CurrencyFormatter.formatRupiah(subtotal),
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Card with items
                          Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: txsForDate.length,
                              separatorBuilder: (_, __) => const Divider(height: 1),
                              itemBuilder: (context, i) {
                                final tx = txsForDate[i];
                                return ListTile(
                                  leading: CircleAvatar(
                                    radius: 16,
                                    backgroundColor: Colors.teal.withOpacity(0.12),
                                    child: Text(
                                      '${tx.entryNumber}',
                                      style: const TextStyle(
                                        color: AppTheme.primaryGreen,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                  title: Text(
                                    tx.description,
                                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                                  ),
                                  subtitle: tx.linkedBudgetItem != null
                                      ? Text(
                                          tx.linkedBudgetItem!,
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: Colors.grey.shade600,
                                          ),
                                        )
                                      : null,
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        CurrencyFormatter.formatRupiah(tx.amount),
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete_outline, size: 18, color: Colors.grey),
                                        onPressed: () => _confirmDelete(tx),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

