enum BudgetStatus {
  onTrack,          // < 75%
  approachingLimit, // 75% - 95%
  nearLimit,        // 95% - 100%
  overBudget,       // > 100%
  noBudget,         // budget == 0
}

enum SyncStatus {
  synced,
  syncing,
  offlineCache,
  failed,
}

class MonthIdentifier implements Comparable<MonthIdentifier> {
  final String sheetName;
  final String displayName;
  final int? month;
  final int? year;
  final bool isMMYY;

  const MonthIdentifier({
    required this.sheetName,
    required this.displayName,
    this.month,
    this.year,
    required this.isMMYY,
  });

  @override
  int compareTo(MonthIdentifier other) {
    if (year != null && other.year != null) {
      final yearComp = year!.compareTo(other.year!);
      if (yearComp != 0) return yearComp;
    }
    if (month != null && other.month != null) {
      return month!.compareTo(other.month!);
    }
    return sheetName.compareTo(other.sheetName);
  }

  factory MonthIdentifier.fromSheetName(String sheetName) {
    final isMMYY = RegExp(r'^(0[1-9]|1[0-2])\d{2}$').hasMatch(sheetName);
    if (isMMYY) {
      final mm = int.parse(sheetName.substring(0, 2));
      final yy = int.parse('20${sheetName.substring(2)}');
      final monthNames = [
        'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
        'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
      ];
      final monthName = monthNames[mm - 1];
      return MonthIdentifier(
        sheetName: sheetName,
        displayName: '$monthName $yy',
        month: mm,
        year: yy,
        isMMYY: true,
      );
    } else {
      return MonthIdentifier(
        sheetName: sheetName,
        displayName: sheetName,
        isMMYY: false,
      );
    }
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MonthIdentifier && runtimeType == other.runtimeType && sheetName == other.sheetName;

  @override
  int get hashCode => sheetName.hashCode;
}

class IncomeSource {
  final String source;
  final double amount;
  final int row;

  const IncomeSource({
    required this.source,
    required this.amount,
    required this.row,
  });

  factory IncomeSource.fromJson(Map<String, dynamic> json) {
    return IncomeSource(
      source: json['source'] as String? ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      row: json['row'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
    'source': source,
    'amount': amount,
    'row': row,
  };
}

class BudgetItem {
  final String id;
  final String name;
  final double budget;
  final String category;
  final double actual;
  final double remaining;
  final int row;
  final String formulaOutput;

  const BudgetItem({
    required this.id,
    required this.name,
    required this.budget,
    required this.category,
    required this.actual,
    required this.remaining,
    required this.row,
    this.formulaOutput = '',
  });

  double get utilizationRate {
    if (budget <= 0) return actual > 0 ? 1.0 : 0.0;
    return actual / budget;
  }

  BudgetStatus get status {
    if (budget <= 0) return actual > 0 ? BudgetStatus.overBudget : BudgetStatus.noBudget;
    final rate = utilizationRate;
    if (rate > 1.0) return BudgetStatus.overBudget;
    if (rate >= 0.95) return BudgetStatus.nearLimit;
    if (rate >= 0.75) return BudgetStatus.approachingLimit;
    return BudgetStatus.onTrack;
  }

  BudgetItem copyWith({
    String? id,
    String? name,
    double? budget,
    String? category,
    double? actual,
    double? remaining,
    int? row,
    String? formulaOutput,
  }) {
    return BudgetItem(
      id: id ?? this.id,
      name: name ?? this.name,
      budget: budget ?? this.budget,
      category: category ?? this.category,
      actual: actual ?? this.actual,
      remaining: remaining ?? this.remaining,
      row: row ?? this.row,
      formulaOutput: formulaOutput ?? this.formulaOutput,
    );
  }

  factory BudgetItem.fromJson(Map<String, dynamic> json) {
    return BudgetItem(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      budget: (json['budget'] as num?)?.toDouble() ?? 0.0,
      category: json['category'] as String? ?? 'Lain-lain',
      actual: (json['actual'] as num?)?.toDouble() ?? 0.0,
      remaining: (json['remaining'] as num?)?.toDouble() ?? 0.0,
      row: json['row'] as int? ?? 0,
      formulaOutput: json['formula_output'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'budget': budget,
    'category': category,
    'actual': actual,
    'remaining': remaining,
    'row': row,
    'formula_output': formulaOutput,
  };
}

class DailyExpense {
  final String id;
  final String date;
  final int entryNumber;
  final String description;
  final double amount;
  final String? linkedBudgetItem;
  final int row;
  final bool isPendingSync;

  const DailyExpense({
    required this.id,
    required this.date,
    required this.entryNumber,
    required this.description,
    required this.amount,
    this.linkedBudgetItem,
    required this.row,
    this.isPendingSync = false,
  });

  DailyExpense copyWith({
    String? id,
    String? date,
    int? entryNumber,
    String? description,
    double? amount,
    String? linkedBudgetItem,
    int? row,
    bool? isPendingSync,
  }) {
    return DailyExpense(
      id: id ?? this.id,
      date: date ?? this.date,
      entryNumber: entryNumber ?? this.entryNumber,
      description: description ?? this.description,
      amount: amount ?? this.amount,
      linkedBudgetItem: linkedBudgetItem ?? this.linkedBudgetItem,
      row: row ?? this.row,
      isPendingSync: isPendingSync ?? this.isPendingSync,
    );
  }

  factory DailyExpense.fromJson(Map<String, dynamic> json) {
    return DailyExpense(
      id: json['id'] as String? ?? '',
      date: json['date'] as String? ?? '',
      entryNumber: json['entry_number'] as int? ?? 0,
      description: json['description'] as String? ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      linkedBudgetItem: json['linked_budget_item'] as String?,
      row: json['row'] as int? ?? 0,
      isPendingSync: json['is_pending_sync'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'date': date,
    'entry_number': entryNumber,
    'description': description,
    'amount': amount,
    'linked_budget_item': linkedBudgetItem,
    'row': row,
    'is_pending_sync': isPendingSync,
  };
}

class CategorySummary {
  final String category;
  final double budget;
  final double actual;
  final double remaining;

  const CategorySummary({
    required this.category,
    required this.budget,
    required this.actual,
    required this.remaining,
  });

  double get utilizationRate {
    if (budget <= 0) return actual > 0 ? 1.0 : 0.0;
    return actual / budget;
  }

  BudgetStatus get status {
    if (budget <= 0) return actual > 0 ? BudgetStatus.overBudget : BudgetStatus.noBudget;
    final rate = utilizationRate;
    if (rate > 1.0) return BudgetStatus.overBudget;
    if (rate >= 0.95) return BudgetStatus.nearLimit;
    if (rate >= 0.75) return BudgetStatus.approachingLimit;
    return BudgetStatus.onTrack;
  }

  factory CategorySummary.fromJson(Map<String, dynamic> json) {
    return CategorySummary(
      category: json['category'] as String? ?? '',
      budget: (json['budget'] as num?)?.toDouble() ?? 0.0,
      actual: (json['actual'] as num?)?.toDouble() ?? 0.0,
      remaining: (json['remaining'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() => {
    'category': category,
    'budget': budget,
    'actual': actual,
    'remaining': remaining,
  };
}

class MonthlyOverview {
  final MonthIdentifier month;
  final String title;
  final List<IncomeSource> incomes;
  final List<BudgetItem> budgetItems;
  final List<CategorySummary> categorySummaries;
  final List<DailyExpense> transactions;
  final double totalIncome;
  final double totalBudget;
  final double totalActual;
  final double totalRemaining;
  final double? bankBalance;
  final double? discrepancy;
  final SyncStatus syncStatus;
  final DateTime lastUpdated;

  const MonthlyOverview({
    required this.month,
    required this.title,
    required this.incomes,
    required this.budgetItems,
    required this.categorySummaries,
    required this.transactions,
    required this.totalIncome,
    required this.totalBudget,
    required this.totalActual,
    required this.totalRemaining,
    this.bankBalance,
    this.discrepancy,
    this.syncStatus = SyncStatus.synced,
    required this.lastUpdated,
  });

  MonthlyOverview copyWith({
    MonthIdentifier? month,
    String? title,
    List<IncomeSource>? incomes,
    List<BudgetItem>? budgetItems,
    List<CategorySummary>? categorySummaries,
    List<DailyExpense>? transactions,
    double? totalIncome,
    double? totalBudget,
    double? totalActual,
    double? totalRemaining,
    double? bankBalance,
    double? discrepancy,
    SyncStatus? syncStatus,
    DateTime? lastUpdated,
  }) {
    return MonthlyOverview(
      month: month ?? this.month,
      title: title ?? this.title,
      incomes: incomes ?? this.incomes,
      budgetItems: budgetItems ?? this.budgetItems,
      categorySummaries: categorySummaries ?? this.categorySummaries,
      transactions: transactions ?? this.transactions,
      totalIncome: totalIncome ?? this.totalIncome,
      totalBudget: totalBudget ?? this.totalBudget,
      totalActual: totalActual ?? this.totalActual,
      totalRemaining: totalRemaining ?? this.totalRemaining,
      bankBalance: bankBalance ?? this.bankBalance,
      discrepancy: discrepancy ?? this.discrepancy,
      syncStatus: syncStatus ?? this.syncStatus,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }
}

