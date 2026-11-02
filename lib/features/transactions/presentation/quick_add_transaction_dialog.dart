import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/formatting/currency_formatter.dart';
import '../../../../core/formatting/date_formatter.dart';
import '../../budget/data/budget_repository.dart';
import '../../budget/domain/models.dart';

class QuickAddTransactionDialog extends ConsumerStatefulWidget {
  final BudgetItem? preselectedItem;
  final DailyExpense? expenseToEdit;

  const QuickAddTransactionDialog({
    super.key,
    this.preselectedItem,
    this.expenseToEdit,
  });

  @override
  ConsumerState<QuickAddTransactionDialog> createState() => _QuickAddTransactionDialogState();
}

class _QuickAddTransactionDialogState extends ConsumerState<QuickAddTransactionDialog> {
  final _formKey = GlobalKey<FormState>();
  late DateTime _selectedDate;
  late TextEditingController _descController;
  late TextEditingController _amountController;
  BudgetItem? _selectedBudgetItem;
  bool _isSaving = false;
  String _selectedFilterCategory = 'Semua';

  @override
  void initState() {
    super.initState();
    final expense = widget.expenseToEdit;
    if (expense != null) {
      _selectedDate = DateTime.now();
      _descController = TextEditingController(text: expense.description);
      _amountController = TextEditingController(
        text: RupiahInputFormatter().formatEditUpdate(
          TextEditingValue.empty,
          TextEditingValue(text: expense.amount.toInt().toString()),
        ).text,
      );
    } else {
      _selectedDate = DateTime.now();
      _descController = TextEditingController();
      _amountController = TextEditingController();
      _selectedBudgetItem = widget.preselectedItem;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (widget.expenseToEdit != null && _selectedBudgetItem == null) {
      final overview = ref.read(budgetProvider).currentOverview;
      if (overview != null && widget.expenseToEdit!.linkedBudgetItem != null) {
        final matches = overview.budgetItems.where((b) => b.name == widget.expenseToEdit!.linkedBudgetItem);
        if (matches.isNotEmpty) {
          _selectedBudgetItem = matches.first;
        }
      }
    }
  }

  @override
  void dispose() {
    _descController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2024),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final amount = CurrencyFormatter.parseRupiah(_amountController.text);
    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nominal harus lebih dari 0')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final dateFormatted = '${_selectedDate.day} ${DateFormatter.indonesianMonths[_selectedDate.month - 1]}';
      final isEditing = widget.expenseToEdit != null;

      if (isEditing) {
        await ref.read(budgetProvider.notifier).updateTransaction(
          id: widget.expenseToEdit!.id,
          date: dateFormatted,
          description: _descController.text.trim(),
          amount: amount,
          linkedBudgetItem: _selectedBudgetItem?.name,
        );
      } else {
        await ref.read(budgetProvider.notifier).addTransaction(
          date: dateFormatted,
          description: _descController.text.trim(),
          amount: amount,
          linkedBudgetItem: _selectedBudgetItem?.name,
        );
      }

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppTheme.primaryGreen,
            content: Text(
              isEditing
                  ? 'Perubahan transaksi berhasil disimpan!'
                  : 'Transaksi ${CurrencyFormatter.formatRupiah(amount)} berhasil disimpan!',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menyimpan transaksi: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final budgetState = ref.watch(budgetProvider);
    final overview = budgetState.currentOverview;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isEditing = widget.expenseToEdit != null;

    if (overview == null) {
      return const SizedBox.shrink();
    }

    final sortedItems = List<BudgetItem>.from(overview.budgetItems)
      ..sort((a, b) {
        final catA = AppTheme.getCategorySortIndex(a.category);
        final catB = AppTheme.getCategorySortIndex(b.category);
        if (catA != catB) return catA.compareTo(catB);
        return a.name.toLowerCase().compareTo(b.name.toLowerCase());
      });

    final availableCategories = ['Semua'];
    for (final cat in AppTheme.categoryOrder) {
      if (sortedItems.any((i) => i.category == cat)) {
        availableCategories.add(cat);
      }
    }
    for (final item in sortedItems) {
      if (!availableCategories.contains(item.category)) {
        availableCategories.add(item.category);
      }
    }

    final List<BudgetItem> dropdownItems;
    if (_selectedFilterCategory == 'Semua') {
      dropdownItems = sortedItems;
    } else {
      final filtered = sortedItems.where((i) => i.category == _selectedFilterCategory).toList();
      if (_selectedBudgetItem != null && !filtered.any((i) => i.id == _selectedBudgetItem!.id)) {
        filtered.insert(0, _selectedBudgetItem!);
      }
      dropdownItems = filtered;
    }

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        isEditing ? 'Edit Transaksi' : 'Tambah Pengeluaran',
                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                  const Divider(),
                  const SizedBox(height: 12),

                  // Date Picker Field
                  InkWell(
                    onTap: _pickDate,
                    borderRadius: BorderRadius.circular(10),
                    child: InputDecorator(
                      decoration: InputDecoration(
                        labelText: 'Tanggal Pengeluaran',
                        prefixIcon: const Icon(Icons.calendar_today, size: 20),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text(
                        '${_selectedDate.day} ${DateFormatter.indonesianMonths[_selectedDate.month - 1]} ${_selectedDate.year}',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Description
                  TextFormField(
                    controller: _descController,
                    decoration: InputDecoration(
                      labelText: 'Keterangan Transaksi *',
                      hintText: 'Contoh: BBM motor, Belanja sayur, dll',
                      prefixIcon: const Icon(Icons.description_outlined, size: 20),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return 'Keterangan tidak boleh kosong';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),

                  // Amount with RupiahInputFormatter
                  TextFormField(
                    controller: _amountController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      RupiahInputFormatter(),
                    ],
                    decoration: InputDecoration(
                      labelText: 'Jumlah Nominal (Rp) *',
                      prefixText: 'Rp ',
                      hintText: 'Contoh: 50.000',
                      prefixIcon: const Icon(Icons.payments_outlined, size: 20),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return 'Nominal wajib diisi';
                      }
                      final parsed = CurrencyFormatter.parseRupiah(val);
                      if (parsed <= 0) return 'Nominal harus lebih dari 0';
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),

                  // Category Filter Chips
                  Row(
                    children: [
                      const Icon(Icons.tune_rounded, size: 15, color: Colors.grey),
                      const SizedBox(width: 6),
                      Text(
                        'Pilih Kategori:',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.grey.shade400 : Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: availableCategories.map((cat) {
                        final isSelected = _selectedFilterCategory == cat;
                        final isSemua = cat == 'Semua';
                        final catColor = isSemua ? AppTheme.safeGreen : AppTheme.getCategoryColor(cat);
                        final catIcon = isSemua ? Icons.grid_view_rounded : AppTheme.getCategoryIcon(cat);

                        return Padding(
                          padding: const EdgeInsets.only(right: 6.0),
                          child: FilterChip(
                            avatar: Icon(
                              catIcon,
                              size: 13,
                              color: isSelected ? Colors.white : catColor,
                            ),
                            label: Text(cat),
                            selected: isSelected,
                            onSelected: (selected) {
                              setState(() {
                                _selectedFilterCategory = selected ? cat : 'Semua';
                              });
                            },
                            selectedColor: catColor,
                            backgroundColor: catColor.withValues(alpha: 0.1),
                            checkmarkColor: Colors.white,
                            side: BorderSide(
                              color: isSelected ? catColor : catColor.withValues(alpha: 0.3),
                              width: 1,
                            ),
                            labelStyle: TextStyle(
                              fontSize: 11,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                              color: isSelected ? Colors.white : (isDark ? Colors.grey.shade200 : catColor),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
                            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Budget Item Dropdown
                  DropdownButtonFormField<BudgetItem>(
                    value: _selectedBudgetItem,
                    isExpanded: true,
                    menuMaxHeight: 380,
                    borderRadius: BorderRadius.circular(16),
                    dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                    decoration: InputDecoration(
                      labelText: 'Pilih Pos Anggaran *',
                      prefixIcon: Icon(
                        _selectedBudgetItem != null
                            ? AppTheme.getCategoryIcon(_selectedBudgetItem!.category)
                            : Icons.category_outlined,
                        size: 20,
                        color: _selectedBudgetItem != null
                            ? AppTheme.getCategoryColor(_selectedBudgetItem!.category)
                            : null,
                      ),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    ),
                    items: dropdownItems.map((item) {
                      final catColor = AppTheme.getCategoryColor(item.category);
                      final catIcon = AppTheme.getCategoryIcon(item.category);
                      final isOver = item.remaining < 0;

                      return DropdownMenuItem<BudgetItem>(
                        value: item,
                        child: Row(
                          children: [
                            Container(
                              width: 30,
                              height: 30,
                              decoration: BoxDecoration(
                                color: catColor.withValues(alpha: 0.16),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: catColor.withValues(alpha: 0.35)),
                              ),
                              child: Icon(catIcon, size: 16, color: catColor),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    item.name,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 1),
                                  Row(
                                    children: [
                                      Text(
                                        'Sisa: ',
                                        style: TextStyle(
                                          fontSize: 10.5,
                                          color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                                        ),
                                      ),
                                      Text(
                                        CurrencyFormatter.formatRupiah(item.remaining, compact: true),
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: isOver ? AppTheme.dangerNeon : AppTheme.safeGreen,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                              decoration: BoxDecoration(
                                color: catColor.withValues(alpha: 0.14),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: catColor.withValues(alpha: 0.3)),
                              ),
                              child: Text(
                                item.category,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: catColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                    selectedItemBuilder: (context) {
                      return dropdownItems.map((item) {
                        final catColor = AppTheme.getCategoryColor(item.category);
                        final catIcon = AppTheme.getCategoryIcon(item.category);
                        return Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(3),
                              decoration: BoxDecoration(
                                color: catColor.withValues(alpha: 0.16),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Icon(catIcon, size: 14, color: catColor),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                item.name,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: catColor.withValues(alpha: 0.14),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                item.category,
                                style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: catColor),
                              ),
                            ),
                          ],
                        );
                      }).toList();
                    },
                    onChanged: (val) {
                      setState(() {
                        _selectedBudgetItem = val;
                      });
                    },
                  ),

                  if (_selectedBudgetItem != null) ...[
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.getCategoryColor(_selectedBudgetItem!.category).withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppTheme.getCategoryColor(_selectedBudgetItem!.category).withValues(alpha: 0.35),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppTheme.getCategoryColor(_selectedBudgetItem!.category).withValues(alpha: 0.2),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              AppTheme.getCategoryIcon(_selectedBudgetItem!.category),
                              size: 20,
                              color: AppTheme.getCategoryColor(_selectedBudgetItem!.category),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      _selectedBudgetItem!.name,
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: AppTheme.getCategoryColor(_selectedBudgetItem!.category).withValues(alpha: 0.2),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        _selectedBudgetItem!.category,
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: AppTheme.getCategoryColor(_selectedBudgetItem!.category),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Text(
                                      'Sisa Anggaran: ',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                                      ),
                                    ),
                                    Text(
                                      CurrencyFormatter.formatRupiah(_selectedBudgetItem!.remaining),
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: _selectedBudgetItem!.remaining < 0
                                            ? AppTheme.dangerNeon
                                            : AppTheme.safeGreen,
                                      ),
                                    ),
                                    const Spacer(),
                                    Text(
                                      'Budget: ${CurrencyFormatter.formatRupiah(_selectedBudgetItem!.budget, compact: true)}',
                                      style: TextStyle(
                                        fontSize: 10.5,
                                        color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 20),

                  // Safe Mapping Notice
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.teal.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.teal.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.shield_outlined, size: 18, color: Colors.teal.shade800),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Transaksi dicatat aman secara offline-first dan diperhitungkan ke alokasi pos anggaran.',
                            style: TextStyle(fontSize: 11, color: Colors.teal.shade900),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Actions
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
                          child: const Text('Batal'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton(
                          onPressed: _isSaving ? null : _submit,
                          child: _isSaving
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                )
                              : Text(isEditing ? 'Simpan Perubahan' : 'Simpan'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
