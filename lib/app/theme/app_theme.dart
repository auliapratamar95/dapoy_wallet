import 'package:flutter/material.dart';

class AppTheme {
  // Brand & Semantic Colors
  static const Color primaryGreen = Color(0xFF0F766E); // Deep Teal / Emerald
  static const Color primaryLight = Color(0xFF14B8A6);
  static const Color accentIndigo = Color(0xFF4338CA);
  
  static const Color statusNormal = Color(0xFF10B981); // Emerald Green (<75%)
  static const Color statusApproaching = Color(0xFFF59E0B); // Amber (75-95%)
  static const Color statusNearLimit = Color(0xFFF97316); // Orange (95-100%)
  static const Color statusOverBudget = Color(0xFFEF4444); // Crimson (>100%)

  // Category Colors
  static const Map<String, Color> categoryColors = {
    'Wajib': Color(0xFF3B82F6),        // Blue
    'Keluarga': Color(0xFF8B5CF6),     // Purple
    'Anak': Color(0xFFEC4899),         // Pink
    'Transportasi': Color(0xFFF59E0B), // Amber
    'Rumah': Color(0xFF10B981),        // Emerald
    'Tabungan': Color(0xFF06B6D4),     // Cyan
    'Lain-lain': Color(0xFF6B7280),    // Slate Gray
  };

  static Color getCategoryColor(String? category) {
    if (category == null) return const Color(0xFF9CA3AF);
    return categoryColors[category] ?? const Color(0xFF6B7280);
  }

  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: ColorScheme.fromSeed(
      seedColor: primaryGreen,
      brightness: Brightness.light,
      primary: primaryGreen,
      surface: const Color(0xFFF8FAFC),
    ),
    scaffoldBackgroundColor: const Color(0xFFF1F5F9),
    cardTheme: CardThemeData(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200, width: 1),
      ),
    ),
    appBarTheme: const AppBarTheme(
      elevation: 0,
      scrolledUnderElevation: 0,
      backgroundColor: Colors.white,
      foregroundColor: Color(0xFF0F172A),
      centerTitle: false,
    ),
    fontFamily: 'Roboto',
  );

  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: ColorScheme.fromSeed(
      seedColor: primaryLight,
      brightness: Brightness.dark,
      primary: primaryLight,
      surface: const Color(0xFF1E293B),
    ),
    scaffoldBackgroundColor: const Color(0xFF0F172A),
    cardTheme: CardThemeData(
      elevation: 0,
      color: const Color(0xFF1E293B),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade800, width: 1),
      ),
    ),
    appBarTheme: const AppBarTheme(
      elevation: 0,
      scrolledUnderElevation: 0,
      backgroundColor: Color(0xFF1E293B),
      foregroundColor: Colors.white,
      centerTitle: false,
    ),
    fontFamily: 'Roboto',
  );
}
