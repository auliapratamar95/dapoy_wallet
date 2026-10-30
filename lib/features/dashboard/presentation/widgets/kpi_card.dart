import 'package:flutter/material.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/formatting/currency_formatter.dart';

class KpiCard extends StatelessWidget {
  final String title;
  final double amount;
  final IconData icon;
  final Color iconColor;
  final String? subtitle;
  final bool isExpense;
  final bool isNegativeAlert;

  const KpiCard({
    super.key,
    required this.title,
    required this.amount,
    required this.icon,
    required this.iconColor,
    this.subtitle,
    this.isExpense = false,
    this.isNegativeAlert = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Dangerous theme styling for Expense or Overbudget
    final isCritical = isNegativeAlert && amount < 0;
    final isWarningState = isExpense || isCritical;

    final borderColor = isCritical
        ? AppTheme.dangerNeon
        : isExpense
            ? AppTheme.dangerPrimary.withValues(alpha: isDark ? 0.45 : 0.35)
            : (isDark ? const Color(0xFF1E293B) : Colors.grey.shade200);

    final cardBg = isDark
        ? (isExpense
            ? const Color(0xFF1F111D) // Dark crimson-tinted obsidian
            : isCritical
                ? const Color(0xFF260D14)
                : const Color(0xFF131B2E))
        : (isExpense
            ? const Color(0xFFFFF1F2) // Light warning rose
            : isCritical
                ? const Color(0xFFFFE4E6)
                : Colors.white);

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor, width: isWarningState ? 1.6 : 1.2),
        boxShadow: isWarningState
            ? [
                BoxShadow(
                  color: AppTheme.dangerPrimary.withValues(alpha: isDark ? 0.25 : 0.08),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      if (isExpense) ...[
                        const Icon(Icons.local_fire_department, size: 14, color: AppTheme.dangerNeon),
                        const SizedBox(width: 4),
                      ],
                      Expanded(
                        child: Text(
                          title,
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: isExpense
                                ? AppTheme.dangerNeon
                                : (isDark ? Colors.grey.shade400 : Colors.grey.shade600),
                            fontWeight: isExpense ? FontWeight.w800 : FontWeight.w600,
                            letterSpacing: isExpense ? 0.4 : 0.0,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: isDark ? 0.22 : 0.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: iconColor.withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                  child: Icon(icon, color: iconColor, size: 18),
                ),
              ],
            ),
            const SizedBox(height: 10),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                CurrencyFormatter.formatRupiah(amount),
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w900,
                  fontSize: 20,
                  color: isCritical
                      ? AppTheme.dangerNeon
                      : isExpense
                          ? (isDark ? const Color(0xFFFF5277) : const Color(0xFFBE123C))
                          : (isDark ? Colors.white : const Color(0xFF0F172A)),
                ),
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  if (isExpense)
                    const Padding(
                      padding: EdgeInsets.only(right: 4.0),
                      child: Icon(Icons.warning_amber_rounded, size: 12, color: AppTheme.dangerFlame),
                    ),
                  Expanded(
                    child: Text(
                      subtitle!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontSize: 11,
                        fontWeight: isExpense ? FontWeight.w700 : FontWeight.normal,
                        color: isExpense
                            ? AppTheme.dangerFlame
                            : (isDark ? Colors.grey.shade400 : Colors.grey.shade600),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
