import 'package:intl/intl.dart';

class DateFormatter {
  static final DateFormat _indonesianDateFormat = DateFormat('d MMMM yyyy', 'id_ID');
  static final DateFormat _shortDateFormat = DateFormat('d MMM', 'id_ID');

  static const List<String> indonesianMonths = [
    'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
    'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
  ];

  /// Format DateTime to Indonesian string: "25 Oktober 2026"
  static String formatFull(DateTime date) {
    try {
      return _indonesianDateFormat.format(date);
    } catch (_) {
      final monthName = indonesianMonths[date.month - 1];
      return '${date.day} $monthName ${date.year}';
    }
  }

  /// Format DateTime to short string: "25 Okt"
  static String formatShort(DateTime date) {
    try {
      return _shortDateFormat.format(date);
    } catch (_) {
      final monthName = indonesianMonths[date.month - 1].substring(0, 3);
      return '${date.day} $monthName';
    }
  }

  /// Get month display name from MMYY code, e.g. "1026" -> "Oktober 2026"
  static String getMonthNameFromCode(String code) {
    if (code.length != 4) return code;
    final mm = int.tryParse(code.substring(0, 2));
    final yy = int.tryParse(code.substring(2));
    if (mm != null && mm >= 1 && mm <= 12 && yy != null) {
      final monthName = indonesianMonths[mm - 1];
      return '$monthName 20$yy';
    }
    return code;
  }

  /// Parses an Indonesian date string (e.g. "25 Agustus", "1  Oktober", "29 Oktober 2026")
  /// into a DateTime given a reference year/month.
  static DateTime parseIndonesianDate(
    String dateStr, {
    int referenceYear = 2026,
    int referenceMonth = 10,
  }) {
    final clean = dateStr.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (clean.isEmpty) return DateTime(referenceYear, referenceMonth, 1);

    final parts = clean.split(' ');
    final day = int.tryParse(parts[0]) ?? 1;
    int month = referenceMonth;
    int year = referenceYear;

    if (parts.length >= 2) {
      final monthNameLower = parts[1].toLowerCase();
      for (int i = 0; i < indonesianMonths.length; i++) {
        if (indonesianMonths[i].toLowerCase() == monthNameLower) {
          month = i + 1;
          break;
        }
      }
    }

    if (parts.length >= 3) {
      final y = int.tryParse(parts[2]);
      if (y != null) {
        year = y < 100 ? 2000 + y : y;
      }
    } else {
      if (month > referenceMonth + 6) {
        year = referenceYear - 1;
      }
    }

    return DateTime(year, month, day);
  }

  /// Cleans extra whitespaces in date string (e.g. "1  Oktober" -> "1 Oktober")
  static String cleanDateString(String dateStr) {
    return dateStr.replaceAll(RegExp(r'\s+'), ' ').trim();
  }
}

