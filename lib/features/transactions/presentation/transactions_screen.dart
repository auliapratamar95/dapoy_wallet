import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/responsive/responsive_layout.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/formatting/currency_formatter.dart';
import '../../../../core/formatting/date_formatter.dart';
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
  bool _sortNewestFirst = true; // true: terbaru ke terlama, false: terlama ke terbaru

  void _showAddDialog() {
    showDialog(
      context: context,
      builder: (_) => const QuickAddTransactionDialog(),
    );
  }

  void _showEditDialog(DailyExpense expense) {
    showDialog(
      context: context,
      builder: (_) => QuickAddTransactionDialog(expenseToEdit: expense),
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

    final refYear = overview.month.year ?? 2026;
    final refMonth = overview.month.month ?? 10;

    // Group transactions by parsed date (chronological sorting)
    final Map<DateTime, String> dateLabels = {};
    final Map<DateTime, List<DailyExpense>> groupedByDate = {};

    for (final tx in filtered) {
      final cleanDate = DateFormatter.cleanDateString(tx.date);
      final parsedDate = DateFormatter.parseIndonesianDate(
        cleanDate,
        referenceYear: refYear,
        referenceMonth: refMonth,
      );

      dateLabels.putIfAbsent(parsedDate, () => cleanDate.isNotEmpty ? cleanDate : 'Tanpa Tanggal');
      groupedByDate.putIfAbsent(parsedDate, () => []).add(tx);
    }

    // Sort the dates strictly chronologically
    final sortedDates = groupedByDate.keys.toList()
      ..sort((a, b) => _sortNewestFirst ? b.compareTo(a) : a.compareTo(b));

    // Inside each date group, sort transactions by entryNumber
    for (final date in sortedDates) {
      groupedByDate[date]!.sort((a, b) {
        if (_sortNewestFirst) {
          return b.entryNumber.compareTo(a.entryNumber);
        } else {
          return a.entryNumber.compareTo(b.entryNumber);
        }
      });
    }

    final totalFilteredSpending = filtered.fold(0.0, (s, t) => s + t.amount);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Catatan Pengeluaran', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            tooltip: _sortNewestFirst ? 'Urutan: Tanggal Terbaru' : 'Urutan: Tanggal Terlama',
            icon: Icon(_sortNewestFirst ? Icons.arrow_downward : Icons.arrow_upward),
            onPressed: () {
              setState(() => _sortNewestFirst = !_sortNewestFirst);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  duration: const Duration(milliseconds: 1000),
                  content: Text(_sortNewestFirst ? 'Urutan: Tanggal Terbaru ke Terlama' : 'Urutan: Tanggal Terlama ke Terbaru'),
                ),
              );
            },
          ),
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
                    color: isDark ? const Color(0xFF260D15) : const Color(0xFFFFF1F2),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppTheme.dangerNeon.withValues(alpha: isDark ? 0.45 : 0.35),
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.local_fire_department, size: 14, color: AppTheme.dangerNeon),
                              const SizedBox(width: 4),
                              Text(
                                'TOTAL DANA TERBAKAR / KELUAR',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.5,
                                  color: AppTheme.dangerNeon,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            CurrencyFormatter.formatRupiah(totalFilteredSpending),
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                              color: AppTheme.dangerNeon,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.dangerNeon.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppTheme.dangerNeon.withValues(alpha: 0.3)),
                        ),
                        child: Text(
                          '${filtered.length} Transaksi',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            color: AppTheme.dangerNeon,
                          ),
                        ),
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
            child: sortedDates.isEmpty
                ? const Center(child: Text('Tidak ada transaksi yang cocok'))
                : ListView.builder(
                    padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 8),
                    itemCount: sortedDates.length,
                    itemBuilder: (context, dateIndex) {
                      final date = sortedDates[dateIndex];
                      final dateLabel = dateLabels[date] ?? 'Tanpa Tanggal';
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
                                      dateLabel,
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
                                  onTap: () => _showEditDialog(tx),
                                  leading: CircleAvatar(
                                    radius: 16,
                                    backgroundColor: AppTheme.dangerPrimary.withValues(alpha: 0.15),
                                    child: const Icon(Icons.outbox_rounded, size: 16, color: AppTheme.dangerNeon),
                                  ),
                                  title: Text(
                                    tx.description,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  subtitle: tx.linkedBudgetItem != null
                                      ? Text(
                                          tx.linkedBudgetItem!,
                                          style: TextStyle(
                                            fontSize: 10,
                                            color: Colors.grey.shade500,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        )
                                      : null,
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      ConstrainedBox(
                                        constraints: const BoxConstraints(maxWidth: 105),
                                        child: FittedBox(
                                          fit: BoxFit.scaleDown,
                                          alignment: Alignment.centerRight,
                                          child: Text(
                                            '- ${CurrencyFormatter.formatRupiah(tx.amount)}',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w900,
                                              fontSize: 13,
                                              color: AppTheme.dangerNeon,
                                            ),
                                          ),
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.edit_outlined, size: 18, color: Colors.blueGrey),
                                        tooltip: 'Edit Transaksi',
                                        onPressed: () => _showEditDialog(tx),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete_outline, size: 18, color: Colors.grey),
                                        tooltip: 'Hapus Transaksi',
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

