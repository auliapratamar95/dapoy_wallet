import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

class CurrencyFormatter {
  static final NumberFormat _rupiahFormat = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  static final NumberFormat _rupiahDecimalFormat = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 2,
  );

  static final NumberFormat _plainNumberFormat = NumberFormat.decimalPattern('id_ID');

  /// Formats a number to Rupiah string.
  /// Example: 14700000 -> "Rp 14.700.000"
  static String formatRupiah(num? value, {bool compact = false, bool showDecimalsIfAny = false}) {
    if (value == null) return 'Rp 0';
    
    if (compact) {
      final absVal = value.abs();
      if (absVal >= 1000000000) {
        return 'Rp ${(value / 1000000000).toStringAsFixed(1).replaceAll('.', ',')} Miliar';
      } else if (absVal >= 1000000) {
        return 'Rp ${(value / 1000000).toStringAsFixed(1).replaceAll('.', ',')} Jt';
      } else if (absVal >= 1000) {
        return 'Rp ${(value / 1000).toStringAsFixed(0)} Rb';
      }
    }

    if (showDecimalsIfAny && (value % 1 != 0)) {
      return _rupiahDecimalFormat.format(value);
    }
    
    return _rupiahFormat.format(value);
  }

  /// Formats plain number according to Indonesian locale
  static String formatNumber(num? value) {
    if (value == null) return '0';
    return _plainNumberFormat.format(value);
  }

  /// Parse IDR input string to double
  static double parseRupiah(String input) {
    final cleaned = input.replaceAll(RegExp(r'[^0-9,-]'), '').replaceAll(',', '.');
    return double.tryParse(cleaned) ?? 0.0;
  }
}

/// Auto-formats numeric input into Indonesian Rupiah thousands format (e.g., 50.000, 1.500.000)
class RupiahInputFormatter extends TextInputFormatter {
  static final NumberFormat _thousandsFormat = NumberFormat('#,###', 'id_ID');

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) {
      return newValue.copyWith(text: '');
    }

    // Only allow digits
    final digits = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) {
      return newValue.copyWith(text: '');
    }

    final number = int.tryParse(digits) ?? 0;
    final formatted = _thousandsFormat.format(number);

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
