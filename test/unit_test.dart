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
  });
}

