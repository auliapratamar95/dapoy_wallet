import 'package:flutter/material.dart';

enum FinancialDangerLevel {
  safe,      // < 50%
  cautious,  // 50% - 75%
  warning,   // 75% - 95%
  danger,    // > 95%
}

class AppTheme {
  // === DANGER & PSYCHOLOGICAL ALERT COLORS ===
  static const Color dangerPrimary = Color(0xFFE11D48); // Intense Ruby / Crimson
  static const Color dangerNeon = Color(0xFFFF2A55);    // High-Voltage Neon Red
  static const Color dangerFlame = Color(0xFFFF4500);   // Fire Orange
  static const Color warningAmber = Color(0xFFF59E0B);  // Hazard Amber
  
  static const Color safeGreen = Color(0xFF10B981);     // Emerald Disciplined
  static const Color safeCyan = Color(0xFF06B6D4);      // Calm Cyan
  static const Color savingsTeal = Color(0xFF0D9488);   // Vault Teal

  // Aliases for compatibility
  static const Color primaryGreen = safeGreen;
  static const Color primaryLight = safeCyan;
  static const Color statusNormal = safeGreen;
  static const Color statusApproaching = warningAmber;
  static const Color statusNearLimit = dangerFlame;
  static const Color statusOverBudget = dangerNeon;

  // Category Colors with High-Contrast Vividness
  static const Map<String, Color> categoryColors = {
    'Wajib': Color(0xFF3B82F6),        // High-vis Blue
    'Keluarga': Color(0xFF8B5CF6),     // Royal Purple
    'Anak': Color(0xFFEC4899),         // Hot Pink
    'Transportasi': Color(0xFFF97316), // Hazard Orange
    'Rumah': Color(0xFF14B8A6),        // Petrol Teal
    'Tabungan': Color(0xFF10B981),     // Protected Green
    'Lain-lain': Color(0xFFE11D48),    // Crimson Alert
  };

  static Color getCategoryColor(String? category) {
    if (category == null) return const Color(0xFF6B7280);
    return categoryColors[category] ?? const Color(0xFFF43F5E);
  }

  static FinancialDangerLevel getDangerLevel(double utilizationRate) {
    if (utilizationRate > 0.95) return FinancialDangerLevel.danger;
    if (utilizationRate >= 0.75) return FinancialDangerLevel.warning;
    if (utilizationRate >= 0.50) return FinancialDangerLevel.cautious;
    return FinancialDangerLevel.safe;
  }

  static Color getDangerColor(double utilizationRate) {
    final level = getDangerLevel(utilizationRate);
    switch (level) {
      case FinancialDangerLevel.danger:
        return dangerNeon;
      case FinancialDangerLevel.warning:
        return dangerFlame;
      case FinancialDangerLevel.cautious:
        return warningAmber;
      case FinancialDangerLevel.safe:
        return safeGreen;
    }
  }

  static String getDangerLabel(double utilizationRate) {
    final level = getDangerLevel(utilizationRate);
    switch (level) {
      case FinancialDangerLevel.danger:
        return '🔥 BAHAYA KRITIS';
      case FinancialDangerLevel.warning:
        return '⚠️ SIAGA BATAS';
      case FinancialDangerLevel.cautious:
        return '⚡ WASPADA';
      case FinancialDangerLevel.safe:
        return '🛡️ AMAN';
    }
  }

  // === LIGHT THEME (High-Contrast Clean Hazard) ===
  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: ColorScheme.fromSeed(
      seedColor: dangerPrimary,
      brightness: Brightness.light,
      primary: dangerPrimary,
      secondary: dangerFlame,
      surface: const Color(0xFFFFFFFF),
    ),
    scaffoldBackgroundColor: const Color(0xFFF8FAFC),
    cardTheme: CardThemeData(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: Colors.grey.shade200, width: 1.2),
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

  // === DARK THEME (Cyber Stealth & Neon Alert) ===
  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: ColorScheme.fromSeed(
      seedColor: dangerNeon,
      brightness: Brightness.dark,
      primary: dangerNeon,
      secondary: dangerFlame,
      surface: const Color(0xFF131B2E),
    ),
    scaffoldBackgroundColor: const Color(0xFF0A0F1D), // Obsidian Dark
    cardTheme: CardThemeData(
      elevation: 0,
      color: const Color(0xFF131B2E),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: Color(0xFF1E293B), width: 1.2),
      ),
    ),
    appBarTheme: const AppBarTheme(
      elevation: 0,
      scrolledUnderElevation: 0,
      backgroundColor: Color(0xFF0A0F1D),
      foregroundColor: Colors.white,
      centerTitle: false,
    ),
    fontFamily: 'Roboto',
  );
}
