import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/formatting/currency_formatter.dart';
import '../../budget/data/budget_repository.dart';
import '../../budget/domain/models.dart';

class EditBudgetItemDialog extends ConsumerStatefulWidget {
  final BudgetItem? item; // null if adding new item

  const EditBudgetItemDialog({
    super.key,
    this.item,
  });

  @override
  ConsumerState<EditBudgetItemDialog> createState() => _EditBudgetItemDialogState();
}

class _EditBudgetItemDialogState extends ConsumerState<EditBudgetItemDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _budgetController;
  late String _selectedCategory;
  bool _isLoading = false;

  final List<String> _categories = List<String>.from(AppTheme.categoryOrder);

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.item?.name ?? '');
    _budgetController = TextEditingController(
      text: widget.item != null
          ? RupiahInputFormatter().formatEditUpdate(
              TextEditingValue.empty,
              TextEditingValue(text: widget.item!.budget.toInt().toString()),
            ).text
          : '',
    );
    _selectedCategory = widget.item?.category ?? 'Wajib';
    if (!_categories.contains(_selectedCategory)) {
      _categories.insert(0, _selectedCategory);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _budgetController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final name = _nameController.text.trim();
    final rawBudget = _budgetController.text.replaceAll(RegExp(r'[^0-9]'), '');
    final budget = double.tryParse(rawBudget) ?? 0.0;
    final notifier = ref.read(budgetProvider.notifier);

    String? createdId;
    if (widget.item != null) {
      await notifier.updateBudgetItem(
        id: widget.item!.id,
        name: name,
        category: _selectedCategory,
        budget: budget,
        oldName: widget.item!.name,
      );
      createdId = widget.item!.id;
    } else {
      createdId = await notifier.addBudgetItem(
        name: name,
        category: _selectedCategory,
        budget: budget,
      );
    }

    if (mounted) {
      Navigator.of(context).pop(createdId ?? true);
    }
  }

  Future<void> _confirmDelete() async {
    if (widget.item == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Pos Anggaran?'),
        content: Text('Yakin ingin menghapus pos anggaran "${widget.item!.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppTheme.dangerPrimary),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      setState(() => _isLoading = true);
      await ref.read(budgetProvider.notifier).deleteBudgetItem(widget.item!.id);
      if (mounted) {
        Navigator.of(context).pop(true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isEditing = widget.item != null;

    final currentActual = widget.item?.actual ?? 0.0;
    final inputBudget = double.tryParse(_budgetController.text.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0.0;
    final projectedRemaining = inputBudget - currentActual;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        isEditing ? 'Edit Pos Anggaran' : 'Tambah Pos Anggaran',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Name field
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: 'Nama Pos Anggaran',
                    hintText: 'misal: Belanja Bulanan, PDAM, Bensin',
                    prefixIcon: const Icon(Icons.label_outline),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Nama pos anggaran wajib diisi' : null,
                ),
                const SizedBox(height: 16),

                // Category selector
                Text(
                  'Kategori',
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.grey.shade300 : Colors.grey.shade700,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: _categories.map((cat) {
                    final isSelected = _selectedCategory == cat;
                    final catColor = AppTheme.getCategoryColor(cat);
                    final catIcon = AppTheme.getCategoryIcon(cat);
                    return ChoiceChip(
                      avatar: Icon(
                        catIcon,
                        size: 14,
                        color: isSelected ? Colors.white : catColor,
                      ),
                      label: Text(cat),
                      selected: isSelected,
                      onSelected: (val) {
                        if (val) setState(() => _selectedCategory = cat);
                      },
                      selectedColor: catColor,
                      backgroundColor: catColor.withValues(alpha: 0.1),
                      side: BorderSide(
                        color: isSelected ? catColor : catColor.withValues(alpha: 0.3),
                        width: 1,
                      ),
                      labelStyle: TextStyle(
                        fontSize: 12,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                        color: isSelected ? Colors.white : (isDark ? Colors.grey.shade300 : catColor),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),

                // Budget amount
                TextFormField(
                  controller: _budgetController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    RupiahInputFormatter(),
                  ],
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    labelText: 'Alokasi Anggaran (Rp)',
                    prefixText: 'Rp ',
                    prefixIcon: const Icon(Icons.account_balance_wallet_outlined),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Nominal anggaran wajib diisi';
                    final val = double.tryParse(v.replaceAll(RegExp(r'[^0-9]'), ''));
                    if (val == null || val < 0) return 'Nominal anggaran tidak valid';
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Real-time calculation if editing
                if (isEditing) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Realisasi Saat Ini:', style: TextStyle(fontSize: 12)),
                            Text(
                              CurrencyFormatter.formatRupiah(currentActual),
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Proyeksi Sisa Budget:', style: TextStyle(fontSize: 12)),
                            Text(
                              CurrencyFormatter.formatRupiah(projectedRemaining),
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: projectedRemaining < 0
                                    ? AppTheme.dangerNeon
                                    : AppTheme.safeGreen,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Action buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (isEditing)
                      TextButton.icon(
                        style: TextButton.styleFrom(foregroundColor: AppTheme.dangerPrimary),
                        onPressed: _isLoading ? null : _confirmDelete,
                        icon: const Icon(Icons.delete_outline, size: 18),
                        label: const Text('Hapus'),
                      )
                    else
                      const SizedBox.shrink(),
                    Row(
                      children: [
                        TextButton(
                          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
                          child: const Text('Batal'),
                        ),
                        const SizedBox(width: 8),
                        FilledButton.icon(
                          onPressed: _isLoading ? null : _save,
                          icon: _isLoading
                              ? const SizedBox(
                                  width: 14,
                                  height: 14,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                )
                              : const Icon(Icons.check, size: 18),
                          label: Text(isEditing ? 'Simpan' : 'Tambah'),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

