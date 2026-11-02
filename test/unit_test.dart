import 'package:flutter_test/flutter_test.dart';
import 'package:dapoy_wallet/core/formatting/currency_formatter.dart';
import 'package:dapoy_wallet/features/budget/domain/models.dart';

void main() {
  group('MonthIdentifier tests', () {
    test('Parses MMYY correctly and sorts chronologically', () {
      final sep = MonthIdentifier.fromSheetName('0926');
      final oct = MonthIdentifier.fromSheetName('1026');
      final nov = MonthIdentifier.fromSheetName('1126');

      expect(sep.isMMYY, true);
      expect(sep.month, 9);
      expect(sep.year, 2026);
      expect(sep.displayName, 'September 2026');

      expect(oct.displayName, 'Oktober 2026');
      expect(nov.displayName, 'November 2026');

      final list = [nov, sep, oct]..sort();
      expect(list, [sep, oct, nov]);
    });

    test('Non-MMYY sheet handles gracefully', () {
      final nonMmyy = MonthIdentifier.fromSheetName('November 2024');
      expect(nonMmyy.isMMYY, false);
      expect(nonMmyy.displayName, 'November 2024');
    });
  });

  group('CurrencyFormatter tests', () {
    test('Formats Rupiah correctly with id_ID convention', () {
      expect(CurrencyFormatter.formatRupiah(14700000), 'Rp 14.700.000');
      expect(CurrencyFormatter.formatRupiah(50000), 'Rp 50.000');
      expect(CurrencyFormatter.formatRupiah(0), 'Rp 0');
    });

    test('Compact format works', () {
      expect(CurrencyFormatter.formatRupiah(14700000, compact: true), 'Rp 14,7 Jt');
      expect(CurrencyFormatter.formatRupiah(50000, compact: true), 'Rp 50 Rb');
    });

    test('Parses Rupiah string into double', () {
      expect(CurrencyFormatter.parseRupiah('Rp 14.700.000'), 14700000.0);
      expect(CurrencyFormatter.parseRupiah('50.000'), 50000.0);
    });
  });

  group('BudgetItem domain status calculations', () {
    test('Calculates onTrack, nearLimit, and overBudget statuses', () {
      const itemOnTrack = BudgetItem(
        id: '1',
        name: 'Item 1',
        budget: 100000,
        category: 'Wajib',
        actual: 50000,
        remaining: 50000,
        row: 5,
      );
      expect(itemOnTrack.status, BudgetStatus.onTrack);
      expect(itemOnTrack.utilizationRate, 0.5);

      const itemNearLimit = BudgetItem(
        id: '2',
        name: 'Item 2',
        budget: 100000,
        category: 'Wajib',
        actual: 96000,
        remaining: 4000,
        row: 6,
      );
      expect(itemNearLimit.status, BudgetStatus.nearLimit);

      const itemOverBudget = BudgetItem(
        id: '3',
        name: 'Item 3',
        budget: 100000,
        category: 'Wajib',
        actual: 120000,
        remaining: -20000,
        row: 7,
      );
      expect(itemOverBudget.status, BudgetStatus.overBudget);
    });

    test('Budget editing recalculates remaining and status accurately', () {
      final original = BudgetItem(
        id: '1026_b_1',
        name: 'Belanja',
        budget: 500000,
        category: 'Keluarga',
        actual: 400000,
        remaining: 100000,
        row: 10,
      );
      expect(original.utilizationRate, 0.8);
      expect(original.status, BudgetStatus.approachingLimit);

      // User increases budget to 1.000.000
      final edited = original.copyWith(
        budget: 1000000,
        remaining: 1000000 - original.actual,
      );
      expect(edited.budget, 1000000);
      expect(edited.remaining, 600000);
      expect(edited.utilizationRate, 0.4);
      expect(edited.status, BudgetStatus.onTrack);
    });
  });

  group('IncomeSource tests', () {
    test('IncomeSource serialization and copyWith work seamlessly', () {
      final inc = IncomeSource(id: 'inc_1', source: 'Gaji Abi', amount: 15000000);
      expect(inc.id, 'inc_1');
      expect(inc.source, 'Gaji Abi');
      expect(inc.amount, 15000000);

      final json = inc.toJson();
      final fromJson = IncomeSource.fromJson(json);
      expect(fromJson.id, 'inc_1');
      expect(fromJson.source, 'Gaji Abi');
      expect(fromJson.amount, 15000000);

      final updated = inc.copyWith(amount: 18000000, source: 'Gaji Abi + Bonus');
      expect(updated.amount, 18000000);
      expect(updated.source, 'Gaji Abi + Bonus');
      expect(updated.id, 'inc_1');
    });
  });

  group('RupiahInputFormatter & Transaction editing tests', () {
    test('RupiahInputFormatter auto-formats digits with Indonesian thousand separator', () {
      final formatter = RupiahInputFormatter();
      final res1 = formatter.formatEditUpdate(
        TextEditingValue.empty,
        const TextEditingValue(text: '50000'),
      );
      expect(res1.text, '50.000');

      final res2 = formatter.formatEditUpdate(
        TextEditingValue.empty,
        const TextEditingValue(text: '15000000'),
      );
      expect(res2.text, '15.000.000');
    });

    test('DailyExpense copyWith updates transaction fields accurately', () {
      const tx = DailyExpense(
        id: 'tx_1',
        date: '25 Oktober',
        entryNumber: 1,
        description: 'BBM',
        amount: 50000,
        linkedBudgetItem: 'BBM MOTOR',
        row: 1,
      );

      final edited = tx.copyWith(
        description: 'BBM Pertamax Turbo',
        amount: 75000,
        linkedBudgetItem: 'BBM MOBIL',
      );

      expect(edited.id, 'tx_1');
      expect(edited.description, 'BBM Pertamax Turbo');
      expect(edited.amount, 75000);
      expect(edited.linkedBudgetItem, 'BBM MOBIL');
    });
  });
}

