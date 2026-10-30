import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/models.dart';

class BudgetState {
  final List<MonthIdentifier> availableMonths;
  final MonthIdentifier? selectedMonth;
  final MonthlyOverview? currentOverview;
  final Map<String, MonthlyOverview> allOverviews;
  final bool isLoading;
  final String? errorMessage;
  final bool isOffline;
  final bool isUsingSupabase;

  const BudgetState({
    this.availableMonths = const [],
    this.selectedMonth,
    this.currentOverview,
    this.allOverviews = const {},
    this.isLoading = false,
    this.errorMessage,
    this.isOffline = false,
    this.isUsingSupabase = false,
  });

  BudgetState copyWith({
    List<MonthIdentifier>? availableMonths,
    MonthIdentifier? selectedMonth,
    MonthlyOverview? currentOverview,
    Map<String, MonthlyOverview>? allOverviews,
    bool? isLoading,
    String? errorMessage,
    bool? isOffline,
    bool? isUsingSupabase,
  }) {
    return BudgetState(
      availableMonths: availableMonths ?? this.availableMonths,
      selectedMonth: selectedMonth ?? this.selectedMonth,
      currentOverview: currentOverview ?? this.currentOverview,
      allOverviews: allOverviews ?? this.allOverviews,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      isOffline: isOffline ?? this.isOffline,
      isUsingSupabase: isUsingSupabase ?? this.isUsingSupabase,
    );
  }
}

class BudgetNotifier extends StateNotifier<BudgetState> {
  BudgetNotifier() : super(const BudgetState(isLoading: true)) {
    loadInitialData();
  }

  static const String _kLocalExpensesPrefix = 'dapoy_wallet_expenses_';

  SupabaseClient? get _supabase {
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

  Future<void> loadInitialData() async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    // 1. Try loading from Supabase Cloud
    final client = _supabase;
    if (client != null) {
      try {
        final monthsRes = await client.from('budget_months').select().order('id');
        if (monthsRes.isNotEmpty) {
          final Map<String, MonthlyOverview> overviews = {};
          final List<MonthIdentifier> months = [];

          for (final m in monthsRes) {
            final sheetName = m['id'] as String;
            final monthId = MonthIdentifier.fromSheetName(sheetName);
            months.add(monthId);

            // Fetch Incomes, Budget Items, Daily Expenses
            final incomesRes = await client.from('income_sources').select().eq('month_id', sheetName);
            final itemsRes = await client.from('budget_items').select().eq('month_id', sheetName);
            final txsRes = await client.from('daily_expenses').select().eq('month_id', sheetName).order('row_number');

            final incomes = incomesRes.map((e) => IncomeSource(
              source: e['source'] as String? ?? '',
              amount: (e['amount'] as num?)?.toDouble() ?? 0.0,
              row: e['row_number'] as int? ?? 0,
            )).toList();

            final budgetItems = itemsRes.map((e) => BudgetItem(
              id: e['id'] as String? ?? '',
              name: e['name'] as String? ?? '',
              category: e['category'] as String? ?? 'Lain-lain',
              budget: (e['budget'] as num?)?.toDouble() ?? 0.0,
              actual: (e['actual'] as num?)?.toDouble() ?? 0.0,
              remaining: (e['remaining'] as num?)?.toDouble() ?? 0.0,
              row: e['row_number'] as int? ?? 0,
            )).toList();

            final transactions = txsRes.map((e) => DailyExpense(
              id: e['id'] as String? ?? '',
              date: e['date'] as String? ?? '',
              entryNumber: e['entry_number'] as int? ?? 1,
              description: e['description'] as String? ?? '',
              amount: (e['amount'] as num?)?.toDouble() ?? 0.0,
              linkedBudgetItem: e['linked_budget_item'] as String?,
              row: e['row_number'] as int? ?? 0,
            )).toList();

            // Summarize categories
            final Map<String, List<BudgetItem>> byCat = {};
            for (final item in budgetItems) {
              byCat.putIfAbsent(item.category, () => []).add(item);
            }
            final categorySummaries = byCat.entries.map((entry) {
              final b = entry.value.fold<double>(0.0, (s, i) => s + i.budget);
              final a = entry.value.fold<double>(0.0, (s, i) => s + i.actual);
              return CategorySummary(category: entry.key, budget: b, actual: a, remaining: b - a);
            }).toList();

            final totalIncome = incomes.fold<double>(0.0, (s, i) => s + i.amount);
            final totalBudget = budgetItems.fold<double>(0.0, (s, b) => s + b.budget);
            final totalActual = budgetItems.fold<double>(0.0, (s, b) => s + b.actual);
            final totalRemaining = totalBudget - totalActual;

            final bankBalance = (m['bank_balance'] as num?)?.toDouble();
            final discrepancy = (m['discrepancy'] as num?)?.toDouble();

            overviews[sheetName] = MonthlyOverview(
              month: monthId,
              title: m['title'] as String? ?? m['display_name'] as String? ?? sheetName,
              incomes: incomes,
              budgetItems: budgetItems,
              categorySummaries: categorySummaries,
              transactions: transactions,
              totalIncome: totalIncome,
              totalBudget: totalBudget,
              totalActual: totalActual,
              totalRemaining: totalRemaining,
              bankBalance: bankBalance,
              discrepancy: discrepancy,
              syncStatus: SyncStatus.synced,
              lastUpdated: DateTime.now(),
            );
          }

          months.sort();
          final defaultMonth = months.isNotEmpty ? months.last : null;

          state = state.copyWith(
            availableMonths: months,
            selectedMonth: defaultMonth,
            currentOverview: defaultMonth != null ? overviews[defaultMonth.sheetName] : null,
            allOverviews: overviews,
            isLoading: false,
            isUsingSupabase: true,
          );
          return;
        }
      } catch (e) {
        debugPrint('Supabase fetch bypassed: $e. Falling back to local data.');
      }
    }

    // 2. Fallback to Local Asset Data
    try {
      final jsonString = await rootBundle.loadString('assets/budget_data.json');
      final data = jsonDecode(jsonString) as Map<String, dynamic>;
      final sheets = data['sheets'] as Map<String, dynamic>;

      final Map<String, MonthlyOverview> overviews = {};
      final List<MonthIdentifier> months = [];

      for (final entry in sheets.entries) {
        final sheetName = entry.key;
        final sheetData = entry.value as Map<String, dynamic>;

        final monthId = MonthIdentifier.fromSheetName(sheetName);
        if (monthId.isMMYY) {
          months.add(monthId);
        }

        final title = sheetData['title'] as String? ?? sheetName;
        final incomes = (sheetData['incomes'] as List<dynamic>? ?? [])
            .map((e) => IncomeSource.fromJson(e as Map<String, dynamic>))
            .toList();

        final budgetItems = (sheetData['budget_items'] as List<dynamic>? ?? [])
            .map((e) => BudgetItem.fromJson(e as Map<String, dynamic>))
            .toList();

        final categorySummaries = (sheetData['category_summaries'] as List<dynamic>? ?? [])
            .map((e) => CategorySummary.fromJson(e as Map<String, dynamic>))
            .toList();

        final transactions = (sheetData['transactions'] as List<dynamic>? ?? [])
            .map((e) => DailyExpense.fromJson(e as Map<String, dynamic>))
            .toList();

        final kpis = sheetData['kpis'] as Map<String, dynamic>? ?? {};
        final double totalIncome = (kpis['Total Pemasukan'] as num?)?.toDouble() ??
            incomes.fold<double>(0.0, (sum, i) => sum + i.amount);
        final double totalBudget = (kpis['Total Budget'] as num?)?.toDouble() ??
            budgetItems.fold<double>(0.0, (sum, b) => sum + b.budget);
        final double totalActual = (kpis['Total Pengeluaran'] as num?)?.toDouble() ??
            budgetItems.fold<double>(0.0, (sum, b) => sum + b.actual);
        final double totalRemaining = (kpis['Total Sisa'] as num?)?.toDouble() ??
            (totalBudget - totalActual);

        final bankBalance = (sheetData['bank_balance'] as num?)?.toDouble();
        final discrepancy = (sheetData['discrepancy'] as num?)?.toDouble();

        overviews[sheetName] = MonthlyOverview(
          month: monthId,
          title: title,
          incomes: incomes,
          budgetItems: budgetItems,
          categorySummaries: categorySummaries,
          transactions: transactions,
          totalIncome: totalIncome,
          totalBudget: totalBudget,
          totalActual: totalActual,
          totalRemaining: totalRemaining,
          bankBalance: bankBalance,
          discrepancy: discrepancy,
          syncStatus: SyncStatus.synced,
          lastUpdated: DateTime.now(),
        );
      }

      months.sort();

      // Load locally cached added transactions
      final prefs = await SharedPreferences.getInstance();
      for (final m in months) {
        final key = '$_kLocalExpensesPrefix${m.sheetName}';
        final cached = prefs.getString(key);
        if (cached != null) {
          final list = (jsonDecode(cached) as List<dynamic>)
              .map((e) => DailyExpense.fromJson(e as Map<String, dynamic>))
              .toList();
          if (overviews.containsKey(m.sheetName)) {
            overviews[m.sheetName] = _recalculateOverview(
              overviews[m.sheetName]!,
              additionalTransactions: list,
            );
          }
        }
      }

      final defaultMonth = months.isNotEmpty ? months.last : null;

      state = state.copyWith(
        availableMonths: months,
        selectedMonth: defaultMonth,
        currentOverview: defaultMonth != null ? overviews[defaultMonth.sheetName] : null,
        allOverviews: overviews,
        isLoading: false,
        isUsingSupabase: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Gagal memuat data: $e',
      );
    }
  }

  void selectMonth(MonthIdentifier month) {
    if (state.allOverviews.containsKey(month.sheetName)) {
      state = state.copyWith(
        selectedMonth: month,
        currentOverview: state.allOverviews[month.sheetName],
      );
    }
  }

  Future<void> addTransaction({
    required String date,
    required String description,
    required double amount,
    required String? linkedBudgetItem,
  }) async {
    final current = state.currentOverview;
    if (current == null) return;

    final newExpense = DailyExpense(
      id: '${current.month.sheetName}_tx_${DateTime.now().millisecondsSinceEpoch}',
      date: date,
      entryNumber: current.transactions.length + 1,
      description: description,
      amount: amount,
      linkedBudgetItem: linkedBudgetItem,
      row: 0,
      isPendingSync: true,
    );

    final updated = _recalculateOverview(
      current,
      additionalTransactions: [newExpense],
    );

    // Save to Supabase Cloud if online
    final client = _supabase;
    if (client != null && state.isUsingSupabase) {
      try {
        await client.from('daily_expenses').insert({
          'id': newExpense.id,
          'month_id': current.month.sheetName,
          'date': date,
          'entry_number': newExpense.entryNumber,
          'description': description,
          'amount': amount,
          'linked_budget_item': linkedBudgetItem,
          'row_number': 0,
        });

        // Also update budget item actual in Supabase
        if (linkedBudgetItem != null) {
          final matched = updated.budgetItems.firstWhere(
            (b) => b.name == linkedBudgetItem,
            orElse: () => updated.budgetItems.first,
          );
          await client.from('budget_items').update({
            'actual': matched.actual,
            'remaining': matched.remaining,
          }).eq('id', matched.id);
        }
      } catch (e) {
        debugPrint('Supabase insert note: $e');
      }
    }

    // Save locally
    final prefs = await SharedPreferences.getInstance();
    final key = '$_kLocalExpensesPrefix${current.month.sheetName}';
    final existingLocalJson = prefs.getString(key);
    List<DailyExpense> localList = [];
    if (existingLocalJson != null) {
      localList = (jsonDecode(existingLocalJson) as List<dynamic>)
          .map((e) => DailyExpense.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    localList.add(newExpense);
    await prefs.setString(key, jsonEncode(localList.map((e) => e.toJson()).toList()));

    final newOverviews = Map<String, MonthlyOverview>.from(state.allOverviews);
    newOverviews[current.month.sheetName] = updated;

    state = state.copyWith(
      currentOverview: updated,
      allOverviews: newOverviews,
    );
  }

  Future<void> deleteTransaction(DailyExpense expense) async {
    final current = state.currentOverview;
    if (current == null) return;

    final updatedTransactions = current.transactions.where((t) => t.id != expense.id).toList();
    final updated = _recalculateWithTransactions(current, updatedTransactions);

    // Delete in Supabase if online
    final client = _supabase;
    if (client != null && state.isUsingSupabase) {
      try {
        await client.from('daily_expenses').delete().eq('id', expense.id);
      } catch (e) {
        debugPrint('Supabase delete error: $e');
      }
    }

    // Update local cache
    final prefs = await SharedPreferences.getInstance();
    final key = '$_kLocalExpensesPrefix${current.month.sheetName}';
    final existingLocalJson = prefs.getString(key);
    if (existingLocalJson != null) {
      var localList = (jsonDecode(existingLocalJson) as List<dynamic>)
          .map((e) => DailyExpense.fromJson(e as Map<String, dynamic>))
          .where((e) => e.id != expense.id)
          .toList();
      await prefs.setString(key, jsonEncode(localList.map((e) => e.toJson()).toList()));
    }

    final newOverviews = Map<String, MonthlyOverview>.from(state.allOverviews);
    newOverviews[current.month.sheetName] = updated;

    state = state.copyWith(
      currentOverview: updated,
      allOverviews: newOverviews,
    );
  }

  MonthlyOverview _recalculateOverview(
    MonthlyOverview overview, {
    required List<DailyExpense> additionalTransactions,
  }) {
    final allTxs = List<DailyExpense>.from(overview.transactions)..addAll(additionalTransactions);
    return _recalculateWithTransactions(overview, allTxs);
  }

  MonthlyOverview _recalculateWithTransactions(
    MonthlyOverview overview,
    List<DailyExpense> txs,
  ) {
    final Map<String, double> itemSpent = {};
    for (final tx in txs) {
      if (tx.linkedBudgetItem != null && tx.linkedBudgetItem!.isNotEmpty) {
        itemSpent[tx.linkedBudgetItem!] = (itemSpent[tx.linkedBudgetItem!] ?? 0.0) + tx.amount;
      }
    }

    final updatedItems = overview.budgetItems.map((item) {
      final additional = itemSpent[item.name];
      if (additional != null) {
        final newActual = additional;
        final newRemaining = item.budget - newActual;
        return item.copyWith(
          actual: newActual,
          remaining: newRemaining,
        );
      }
      return item;
    }).toList();

    final Map<String, List<BudgetItem>> byCat = {};
    for (final item in updatedItems) {
      byCat.putIfAbsent(item.category, () => []).add(item);
    }

    final updatedCategories = byCat.entries.map((entry) {
      final budget = entry.value.fold<double>(0.0, (s, i) => s + i.budget);
      final actual = entry.value.fold<double>(0.0, (s, i) => s + i.actual);
      return CategorySummary(
        category: entry.key,
        budget: budget,
        actual: actual,
        remaining: budget - actual,
      );
    }).toList();

    final totalActual = updatedItems.fold<double>(0.0, (s, i) => s + i.actual);
    final totalRemaining = overview.totalBudget - totalActual;

    return overview.copyWith(
      budgetItems: updatedItems,
      categorySummaries: updatedCategories,
      transactions: txs,
      totalActual: totalActual,
      totalRemaining: totalRemaining,
      lastUpdated: DateTime.now(),
    );
  }
}

final budgetProvider = StateNotifierProvider<BudgetNotifier, BudgetState>((ref) {
  return BudgetNotifier();
});

final themeModeProvider = StateProvider<ThemeMode>((ref) => ThemeMode.light);
