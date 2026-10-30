import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/responsive/responsive_layout.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/formatting/currency_formatter.dart';
import '../../budget/data/budget_repository.dart';
import '../../budget/domain/models.dart';
import 'budget_item_detail_dialog.dart';

class BudgetItemsScreen extends ConsumerStatefulWidget {
  final void Function(BudgetItem item)? onQuickAddForItem;

  const BudgetItemsScreen({super.key, this.onQuickAddForItem});

  @override
  ConsumerState<BudgetItemsScreen> createState() => _BudgetItemsScreenState();
}

class _BudgetItemsScreenState extends ConsumerState<BudgetItemsScreen> {
  String searchQuery = '';
  String selectedCategory = 'Semua';
  BudgetStatus? selectedStatus;
  String sortBy = 'name'; // 'name', 'budget', 'actual', 'remaining', 'utilization'

  @override
  Widget build(BuildContext context) {
    final budgetState = ref.watch(budgetProvider);
    final overview = budgetState.currentOverview;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (overview == null) {
      return const Scaffold(body: Center(child: Text('Data anggaran tidak tersedia')));
    }

    final categories = ['Semua', ...overview.categorySummaries.map((c) => c.category)];

    // Filter and sort items
    var items = overview.budgetItems.where((item) {
      final matchesSearch = item.name.toLowerCase().contains(searchQuery.toLowerCase());
      final matchesCategory = selectedCategory == 'Semua' || item.category == selectedCategory;
      final matchesStatus = selectedStatus == null || item.status == selectedStatus;
      return matchesSearch && matchesCategory && matchesStatus;
    }).toList();

    items.sort((a, b) {
      switch (sortBy) {
        case 'budget':
          return b.budget.compareTo(a.budget);
        case 'actual':
          return b.actual.compareTo(a.actual);
        case 'remaining':
          return a.remaining.compareTo(b.remaining);
        case 'utilization':
          return b.utilizationRate.compareTo(a.utilizationRate);
        case 'name':
        default:
          return a.name.compareTo(b.name);
      }
    });

    final horizontalPadding = ResponsiveLayout.horizontalPadding(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pos Anggaran', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.sort),
            tooltip: 'Urutkan',
            onSelected: (val) => setState(() => sortBy = val),
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'name', child: Text('Urutkan: Nama (A-Z)')),
              const PopupMenuItem(value: 'budget', child: Text('Urutkan: Anggaran Tertinggi')),
              const PopupMenuItem(value: 'actual', child: Text('Urutkan: Realisasi Terbesar')),
              const PopupMenuItem(value: 'remaining', child: Text('Urutkan: Sisa Terendah')),
              const PopupMenuItem(value: 'utilization', child: Text('Urutkan: % Terpakai')),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Search & Filter Header
          Padding(
            padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 8),
            child: Column(
              children: [
                TextField(
                  decoration: InputDecoration(
                    hintText: 'Cari pos anggaran...',
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
                const SizedBox(height: 10),
                // Category Filter Chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: categories.map((cat) {
                      final isSelected = selectedCategory == cat;
                      return Padding(
                        padding: const EdgeInsets.only(right: 6.0),
                        child: FilterChip(
                          label: Text(cat),
                          selected: isSelected,
                          onSelected: (sel) {
                            setState(() => selectedCategory = sel ? cat : 'Semua');
                          },
                          selectedColor: AppTheme.primaryGreen.withOpacity(0.2),
                          labelStyle: TextStyle(
                            fontSize: 12,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            color: isSelected ? AppTheme.primaryGreen : null,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Items List or Grid
          Expanded(
            child: items.isEmpty
                ? const Center(child: Text('Tidak ada pos anggaran yang cocok'))
                : ListView.builder(
                    padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 12),
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final item = items[index];
                      return _buildBudgetItemCard(context, item, overview);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildBudgetItemCard(BuildContext context, BudgetItem item, MonthlyOverview overview) {
    final pct = item.budget > 0 ? (item.actual / item.budget) : 0.0;
    final dangerColor = AppTheme.getDangerColor(pct);
    final dangerLabel = AppTheme.getDangerLabel(pct);
    final isCritical = pct > 0.95;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isCritical
            ? AppTheme.dangerPrimary.withValues(alpha: isDark ? 0.16 : 0.06)
            : (isDark ? const Color(0xFF131B2E) : Colors.white),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isCritical
              ? AppTheme.dangerNeon.withValues(alpha: 0.6)
              : (isDark ? const Color(0xFF1E293B) : Colors.grey.shade200),
          width: isCritical ? 1.5 : 1.0,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          final related = overview.transactions
              .where((t) => t.linkedBudgetItem == item.name)
              .toList();

          showDialog(
            context: context,
            builder: (ctx) => BudgetItemDetailDialog(
              item: item,
              relatedTransactions: related,
              onAddExpense: () {
                if (widget.onQuickAddForItem != null) {
                  widget.onQuickAddForItem!(item);
                }
              },
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      item.name,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                  ),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: dangerColor.withValues(alpha: 0.16),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: dangerColor.withValues(alpha: 0.4)),
                        ),
                        child: Text(
                          dangerLabel,
                          style: TextStyle(
                            fontSize: 10,
                            color: dangerColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppTheme.getCategoryColor(item.category).withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          item.category,
                          style: TextStyle(
                            fontSize: 11,
                            color: AppTheme.getCategoryColor(item.category),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _colText('Anggaran', CurrencyFormatter.formatRupiah(item.budget)),
                  _colText(
                    'Realisasi',
                    CurrencyFormatter.formatRupiah(item.actual),
                    color: isCritical ? AppTheme.dangerNeon : null,
                  ),
                  _colText(
                    item.remaining < 0 ? 'DEFISIT' : 'Sisa',
                    CurrencyFormatter.formatRupiah(item.remaining.abs()),
                    color: item.remaining < 0 ? AppTheme.dangerNeon : AppTheme.safeGreen,
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: pct.clamp(0.0, 1.0),
                        backgroundColor: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
                        valueColor: AlwaysStoppedAnimation<Color>(dangerColor),
                        minHeight: 6,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    '${(pct * 100).toStringAsFixed(0)}%',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: dangerColor,
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

  Widget _colText(String label, String value, {Color? color}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 12,
            color: color,
          ),
        ),
      ],
    );
  }
}
