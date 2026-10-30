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
}

