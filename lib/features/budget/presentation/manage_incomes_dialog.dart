import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/formatting/currency_formatter.dart';
import '../data/budget_repository.dart';
import '../domain/models.dart';

class ManageIncomesDialog extends ConsumerStatefulWidget {
  const ManageIncomesDialog({super.key});

  @override
  ConsumerState<ManageIncomesDialog> createState() => _ManageIncomesDialogState();
}

class _ManageIncomesDialogState extends ConsumerState<ManageIncomesDialog> {
  bool _isAddingNew = false;
  IncomeSource? _editingItem;

  final _sourceController = TextEditingController();
  final _amountController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _sourceController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  void _startAdd() {
    setState(() {
      _isAddingNew = true;
      _editingItem = null;
      _sourceController.clear();
      _amountController.clear();
    });
  }

  void _startEdit(IncomeSource item) {
    setState(() {
      _isAddingNew = false;
      _editingItem = item;
      _sourceController.text = item.source;
      _amountController.text = RupiahInputFormatter().formatEditUpdate(
        TextEditingValue.empty,
        TextEditingValue(text: item.amount.toInt().toString()),
      ).text;
    });
  }

  void _cancelForm() {
    setState(() {
      _isAddingNew = false;
      _editingItem = null;
      _sourceController.clear();
      _amountController.clear();
    });
  }

  Future<void> _saveIncome() async {
    if (!_formKey.currentState!.validate()) return;

    final source = _sourceController.text.trim();
    final rawAmount = _amountController.text.replaceAll(RegExp(r'[^0-9]'), '');
    final amount = double.tryParse(rawAmount) ?? 0.0;

    final notifier = ref.read(budgetProvider.notifier);

    if (_editingItem != null) {
      await notifier.updateIncomeSource(
        id: _editingItem!.id,
        source: source,
        amount: amount,
        oldSource: _editingItem!.source,
      );
    } else {
      await notifier.addIncomeSource(
        source: source,
        amount: amount,
      );
    }

    _cancelForm();
  }

  Future<void> _confirmDelete(IncomeSource item) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Pemasukan?'),
        content: Text('Yakin ingin menghapus sumber pemasukan "${item.source}"?'),
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

    if (confirm == true) {
      await ref.read(budgetProvider.notifier).deleteIncomeSource(
        id: item.id,
        source: item.source,
      );
      if (_editingItem?.id == item.id) {
        _cancelForm();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final budgetState = ref.watch(budgetProvider);
    final overview = budgetState.currentOverview;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (overview == null) {
      return const Dialog(child: Padding(padding: EdgeInsets.all(20), child: Text('Data tidak tersedia')));
    }

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480, maxHeight: 640),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Kelola Pemasukan',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                        Text(
                          overview.month.displayName,
                          style: TextStyle(
                            color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                            fontSize: 12,
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
              const SizedBox(height: 14),

              // Total Income Card Banner
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isDark
                        ? [const Color(0xFF064E3B), const Color(0xFF065F46)]
                        : [const Color(0xFFD1FAE5), const Color(0xFFA7F3D0)],
                  ),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: AppTheme.safeGreen.withValues(alpha: 0.4),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppTheme.safeGreen.withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.south_west_rounded, color: AppTheme.safeGreen, size: 18),
                        ),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'TOTAL PEMASUKAN',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                                color: Color(0xFF047857),
                              ),
                            ),
                            Text(
                              '${overview.incomes.length} Sumber Pendapatan',
                              style: TextStyle(
                                fontSize: 11,
                                color: isDark ? Colors.grey.shade300 : Colors.grey.shade700,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        CurrencyFormatter.formatRupiah(overview.totalIncome),
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF047857),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Form (Add or Edit) OR List
              if (_isAddingNew || _editingItem != null) ...[
                // Inline Edit / Add Form
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E293B) : Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: AppTheme.safeGreen.withValues(alpha: 0.35),
                      width: 1.5,
                    ),
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _editingItem != null ? 'Edit Sumber Pemasukan' : 'Tambah Sumber Pemasukan',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close, size: 18),
                              onPressed: _cancelForm,
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        TextFormField(
                          controller: _sourceController,
                          decoration: InputDecoration(
                            labelText: 'Nama Sumber (misal: Gaji Abi, Bonus, dll)',
                            labelStyle: const TextStyle(fontSize: 12),
                            isDense: true,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          validator: (v) => (v == null || v.trim().isEmpty) ? 'Nama tidak boleh kosong' : null,
                        ),
                        const SizedBox(height: 10),
                        TextFormField(
                          controller: _amountController,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            RupiahInputFormatter(),
                          ],
                          decoration: InputDecoration(
                            labelText: 'Nominal (Rp)',
                            prefixText: 'Rp ',
                            labelStyle: const TextStyle(fontSize: 12),
                            isDense: true,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) return 'Nominal tidak boleh kosong';
                            final parsed = double.tryParse(v.replaceAll(RegExp(r'[^0-9]'), ''));
                            if (parsed == null || parsed <= 0) return 'Nominal harus lebih dari 0';
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton(
                              onPressed: _cancelForm,
                              child: const Text('Batal'),
                            ),
                            const SizedBox(width: 8),
                            FilledButton.icon(
                              style: FilledButton.styleFrom(
                                backgroundColor: AppTheme.safeGreen,
                                foregroundColor: Colors.white,
                              ),
                              onPressed: _saveIncome,
                              icon: const Icon(Icons.check, size: 16),
                              label: const Text('Simpan'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 14),
              ],

              // List of Incomes Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Daftar Pemasukan Bulan Ini',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                  ),
                  if (!_isAddingNew && _editingItem == null)
                    TextButton.icon(
                      onPressed: _startAdd,
                      icon: const Icon(Icons.add_circle_outline, size: 16),
                      label: const Text('Tambah', style: TextStyle(fontSize: 12)),
                      style: TextButton.styleFrom(
                        foregroundColor: AppTheme.safeGreen,
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),

              // Scrollable list
              Flexible(
                child: overview.incomes.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          child: Text(
                            'Belum ada sumber pemasukan.\nKetuk "+ Tambah" di atas.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
                          ),
                        ),
                      )
                    : ListView.separated(
                        shrinkWrap: true,
                        itemCount: overview.incomes.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final item = overview.incomes[index];
                          final isSelected = _editingItem?.id == item.id;

                          return Container(
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppTheme.safeGreen.withValues(alpha: 0.1)
                                  : (isDark ? const Color(0xFF1E293B) : Colors.grey.shade100),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected
                                    ? AppTheme.safeGreen
                                    : (isDark ? Colors.grey.shade800 : Colors.grey.shade300),
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: AppTheme.safeGreen.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Icon(Icons.wallet, size: 16, color: AppTheme.safeGreen),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          item.source,
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        Text(
                                          CurrencyFormatter.formatRupiah(item.amount),
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: AppTheme.safeGreen,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.edit_outlined, size: 18),
                                    tooltip: 'Edit Pemasukan',
                                    onPressed: () => _startEdit(item),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline, size: 18, color: AppTheme.dangerPrimary),
                                    tooltip: 'Hapus Pemasukan',
                                    onPressed: () => _confirmDelete(item),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),

              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Selesai'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

