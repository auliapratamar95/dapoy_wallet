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
  final VoidCallback? onTap;
  final bool showEditIndicator;

  const KpiCard({
    super.key,
    required this.title,
    required this.amount,
    required this.icon,
    required this.iconColor,
    this.subtitle,
    this.isExpense = false,
    this.isNegativeAlert = false,
    this.onTap,
    this.showEditIndicator = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final isCritical = isNegativeAlert && amount < 0;
    final isWarningState = isExpense || isCritical;

    final borderColor = isCritical
        ? AppTheme.dangerNeon
        : isExpense
            ? AppTheme.dangerPrimary.withValues(alpha: isDark ? 0.45 : 0.35)
            : (isDark ? const Color(0xFF1E293B) : Colors.grey.shade200);

    final cardBg = isDark
        ? (isExpense
            ? const Color(0xFF1F111D)
            : isCritical
                ? const Color(0xFF260D14)
                : const Color(0xFF131B2E))
        : (isExpense
            ? const Color(0xFFFFF1F2)
            : isCritical
                ? const Color(0xFFFFE4E6)
                : Colors.white);

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: isWarningState ? 1.5 : 1.0),
        boxShadow: isWarningState
            ? [
                BoxShadow(
                  color: AppTheme.dangerPrimary.withValues(alpha: isDark ? 0.25 : 0.08),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    if (isExpense) ...[
                      const Icon(Icons.local_fire_department, size: 13, color: AppTheme.dangerNeon),
                      const SizedBox(width: 3),
                    ],
                    Expanded(
                      child: Row(
                        children: [
                          Flexible(
                            child: Text(
                              title,
                              style: theme.textTheme.labelMedium?.copyWith(
                                color: isExpense
                                    ? AppTheme.dangerNeon
                                    : (isDark ? Colors.grey.shade400 : Colors.grey.shade600),
                                fontWeight: isExpense ? FontWeight.w800 : FontWeight.w600,
                                fontSize: 11,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (showEditIndicator) ...[
                            const SizedBox(width: 4),
                            Icon(
                              Icons.edit_outlined,
                              size: 11,
                              color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                            ),
                          ],
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        color: iconColor.withValues(alpha: isDark ? 0.22 : 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(icon, color: iconColor, size: 15),
                    ),
                  ],
                ),
            const SizedBox(height: 6),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                CurrencyFormatter.formatRupiah(amount),
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w900,
                  fontSize: 17,
                  color: isCritical
                      ? AppTheme.dangerNeon
                      : isExpense
                          ? (isDark ? const Color(0xFFFF5277) : const Color(0xFFBE123C))
                          : (isDark ? Colors.white : const Color(0xFF0F172A)),
                ),
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 2),
              Row(
                children: [
                  if (isExpense)
                    const Padding(
                      padding: EdgeInsets.only(right: 3.0),
                      child: Icon(Icons.warning_amber_rounded, size: 11, color: AppTheme.dangerFlame),
                    ),
                  Expanded(
                    child: Text(
                      subtitle!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontSize: 10,
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
    ),
  ),
);
  }
}
