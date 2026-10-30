import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/formatting/currency_formatter.dart';
import '../../../budget/domain/models.dart';

class InfographicPieChart extends StatefulWidget {
  final List<CategorySummary> summaries;
  final double? size;

  const InfographicPieChart({
    super.key,
    required this.summaries,
    this.size,
  });

  @override
  State<InfographicPieChart> createState() => _InfographicPieChartState();
}

class _InfographicPieChartState extends State<InfographicPieChart>
    with SingleTickerProviderStateMixin {
  int selectedIndex = -1;
  late AnimationController _animationController;
  late Animation<double> _animation;

  static const Map<String, IconData> _categoryIcons = {
    'Wajib': Icons.verified_user_rounded,
    'Keluarga': Icons.family_restroom_rounded,
    'Anak': Icons.child_care_rounded,
    'Transportasi': Icons.directions_car_rounded,
    'Rumah': Icons.home_rounded,
    'Tabungan': Icons.savings_rounded,
    'Lain-lain': Icons.category_rounded,
  };

  static const List<Color> _palette = [
    Color(0xFFE91E63), // Vibrant Pink / Magenta
    Color(0xFFF97316), // Coral Orange
    Color(0xFFF59E0B), // Golden Amber
    Color(0xFF06B6D4), // Cyan Teal
    Color(0xFF6366F1), // Indigo
    Color(0xFF8B5CF6), // Purple
    Color(0xFF10B981), // Emerald
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  IconData _getIcon(String category) {
    return _categoryIcons[category] ?? Icons.pie_chart;
  }

  Color _getColor(int index, String category) {
    return _palette[index % _palette.length];
  }

  void _handleTap(Offset localPosition, double chartSize, double totalSpent,
      List<CategorySummary> valid) {
    final center = Offset(chartSize / 2, chartSize / 2);
    final dx = localPosition.dx - center.dx;
    final dy = localPosition.dy - center.dy;
    final distance = math.sqrt(dx * dx + dy * dy);

    final innerRadius = chartSize * 0.22;
    final maxOuter = chartSize * 0.46;

    if (distance < innerRadius || distance > maxOuter + 20) {
      setState(() => selectedIndex = -1);
      return;
    }

    var angle = math.atan2(dy, dx);
    angle = (angle + math.pi / 2) % (2 * math.pi);
    if (angle < 0) angle += 2 * math.pi;

    double cumulativeAngle = 0.0;
    for (int i = 0; i < valid.length; i++) {
      final sweep = (valid[i].actual / totalSpent) * 2 * math.pi;
      if (angle >= cumulativeAngle && angle < cumulativeAngle + sweep) {
        setState(() {
          selectedIndex = selectedIndex == i ? -1 : i;
        });
        return;
      }
      cumulativeAngle += sweep;
    }
  }

  @override
  Widget build(BuildContext context) {
    final valid = widget.summaries.where((s) => s.actual > 0).toList();
    final totalSpent = valid.fold<double>(0.0, (sum, s) => sum + s.actual);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (valid.isEmpty || totalSpent <= 0) {
      return const SizedBox(
        height: 200,
        child: Center(child: Text('Belum ada transaksi pengeluaran')),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        // Dynamically compute chart size based on available parent width
        // Ensures Samsung S7 (360px), iPhone 11 (375px), or large screens never overflow!
        final availableWidth = constraints.maxWidth;
        final chartSize = math.min(
          widget.size ?? 280.0,
          (availableWidth - 8).clamp(200.0, 320.0),
        );
        final centerRadius = chartSize * 0.23;

        final selectedItem = (selectedIndex >= 0 && selectedIndex < valid.length)
            ? valid[selectedIndex]
            : null;

        return Column(
          children: [
            GestureDetector(
              onTapUp: (details) =>
                  _handleTap(details.localPosition, chartSize, totalSpent, valid),
              child: AnimatedBuilder(
                animation: _animation,
                builder: (context, child) {
                  return SizedBox(
                    width: chartSize,
                    height: chartSize,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // 1. Custom Infographic Painter
                        CustomPaint(
                          size: Size(chartSize, chartSize),
                          painter: _InfographicPainter(
                            summaries: valid,
                            totalSpent: totalSpent,
                            selectedIndex: selectedIndex,
                            progress: _animation.value,
                            isDark: isDark,
                            getColor: _getColor,
                          ),
                        ),

                        // 2. Overlay Icons and Percentages on Slices
                        ..._buildSliceLabels(
                          valid: valid,
                          totalSpent: totalSpent,
                          chartSize: chartSize,
                          progress: _animation.value,
                        ),

                        // 3. Center Elevated Circular Badge
                        Container(
                          width: centerRadius * 2,
                          height: centerRadius * 2,
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF131B2E) : Colors.white,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isDark
                                  ? Colors.white.withValues(alpha: 0.12)
                                  : Colors.grey.shade200,
                              width: 3.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.12),
                                blurRadius: 12,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(6.0),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                if (selectedItem != null) ...[
                                  Text(
                                    selectedItem.category.toUpperCase(),
                                    style: TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 0.8,
                                      color: _getColor(selectedIndex, selectedItem.category),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 2),
                                  FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Text(
                                      CurrencyFormatter.formatRupiah(selectedItem.actual, compact: true),
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                                      ),
                                    ),
                                  ),
                                  Text(
                                    '${((selectedItem.actual / totalSpent) * 100).toStringAsFixed(1)}%',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                                    ),
                                  ),
                                ] else ...[
                                  Text(
                                    'TOTAL',
                                    style: TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 1.0,
                                      color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Text(
                                      CurrencyFormatter.formatRupiah(totalSpent, compact: true),
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                                      ),
                                    ),
                                  ),
                                  Text(
                                    'Pengeluaran',
                                    style: TextStyle(
                                      fontSize: 9,
                                      color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),

            // Modern Legend Cards with safe wrapping
            Wrap(
              spacing: 6,
              runSpacing: 6,
              alignment: WrapAlignment.center,
              children: List.generate(valid.length, (i) {
                final s = valid[i];
                final color = _getColor(i, s.category);
                final isSelected = selectedIndex == i;
                final pct = (s.actual / totalSpent) * 100;

                return Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(10),
                    onTap: () {
                      setState(() {
                        selectedIndex = selectedIndex == i ? -1 : i;
                      });
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? color.withValues(alpha: 0.18)
                            : (isDark ? const Color(0xFF1E293B) : Colors.grey.shade100),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isSelected ? color : Colors.transparent,
                          width: 1.2,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(3),
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(_getIcon(s.category), size: 10, color: Colors.white),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            s.category,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 3),
                          Text(
                            '${pct.toStringAsFixed(0)}%',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: color,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ),
          ],
        );
      },
    );
  }

  List<Widget> _buildSliceLabels({
    required List<CategorySummary> valid,
    required double totalSpent,
    required double chartSize,
    required double progress,
  }) {
    final widgets = <Widget>[];
    final center = chartSize / 2;
    double currentAngle = -math.pi / 2;

    final innerRadius = chartSize * 0.23;
    final baseOuter = chartSize * 0.38;
    final maxRatio = valid.fold<double>(0.0, (m, s) => s.actual > m ? s.actual : m) / totalSpent;

    for (int i = 0; i < valid.length; i++) {
      final s = valid[i];
      final ratio = s.actual / totalSpent;
      final sweepAngle = ratio * 2 * math.pi * progress;
      final midAngle = currentAngle + sweepAngle / 2;

      final extraRadius = ((ratio / (maxRatio > 0 ? maxRatio : 1)) * 16.0);
      final outerRadius = baseOuter + extraRadius + (selectedIndex == i ? 8.0 : 0.0);
      final labelRadius = innerRadius + (outerRadius - innerRadius) * 0.55;

      final lx = center + labelRadius * math.cos(midAngle);
      final ly = center + labelRadius * math.sin(midAngle);

      final pct = (ratio * 100).toStringAsFixed(0);

      // Only show text and icon on slices with sufficient sweep angle (>= 0.42 rad) to avoid overlapping
      if (sweepAngle >= 0.42 && progress > 0.6) {
        widgets.add(
          Positioned(
            left: lx - 18,
            top: ly - 16,
            child: IgnorePointer(
              child: SizedBox(
                width: 36,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _getIcon(s.category),
                      size: selectedIndex == i ? 15 : 13,
                      color: Colors.white,
                      shadows: const [
                        Shadow(color: Colors.black54, blurRadius: 4),
                      ],
                    ),
                    Text(
                      '$pct%',
                      style: const TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        shadows: [Shadow(color: Colors.black54, blurRadius: 4)],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }

      currentAngle += (ratio * 2 * math.pi);
    }

    return widgets;
  }
}

class _InfographicPainter extends CustomPainter {
  final List<CategorySummary> summaries;
  final double totalSpent;
  final int selectedIndex;
  final double progress;
  final bool isDark;
  final Color Function(int index, String category) getColor;

  _InfographicPainter({
    required this.summaries,
    required this.totalSpent,
    required this.selectedIndex,
    required this.progress,
    required this.isDark,
    required this.getColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final innerRadius = size.width * 0.23;
    final midBandRadius = size.width * 0.28;
    final baseOuter = size.width * 0.38;

    double currentAngle = -math.pi / 2;
    final maxRatio = summaries.fold<double>(0.0, (m, s) => s.actual > m ? s.actual : m) / totalSpent;
    final sliceSpacing = 0.035;

    for (int i = 0; i < summaries.length; i++) {
      final s = summaries[i];
      final ratio = s.actual / totalSpent;
      final fullSweep = ratio * 2 * math.pi;
      final sweepAngle = (fullSweep - sliceSpacing).clamp(0.01, 2 * math.pi) * progress;

      final isSelected = selectedIndex == i;
      final color = getColor(i, s.category);

      final extraRadius = ((ratio / (maxRatio > 0 ? maxRatio : 1)) * 16.0);
      final outerRadius = (baseOuter + extraRadius + (isSelected ? 8.0 : 0.0))
          .clamp(innerRadius + 10.0, size.width * 0.48);

      final outerPath = Path();
      outerPath.arcTo(
        Rect.fromCircle(center: center, radius: outerRadius),
        currentAngle + sliceSpacing / 2,
        sweepAngle,
        false,
      );
      outerPath.arcTo(
        Rect.fromCircle(center: center, radius: innerRadius),
        currentAngle + sliceSpacing / 2 + sweepAngle,
        -sweepAngle,
        false,
      );
      outerPath.close();

      final paint = Paint()
        ..style = PaintingStyle.fill
        ..isAntiAlias = true
        ..color = color;

      if (isSelected) {
        canvas.drawShadow(outerPath, color.withValues(alpha: 0.6), 8, true);
      }

      canvas.drawPath(outerPath, paint);

      // Inner translucent band for depth
      final bandPath = Path();
      bandPath.arcTo(
        Rect.fromCircle(center: center, radius: midBandRadius),
        currentAngle + sliceSpacing / 2,
        sweepAngle,
        false,
      );
      bandPath.arcTo(
        Rect.fromCircle(center: center, radius: innerRadius),
        currentAngle + sliceSpacing / 2 + sweepAngle,
        -sweepAngle,
        false,
      );
      bandPath.close();

      final bandPaint = Paint()
        ..style = PaintingStyle.fill
        ..isAntiAlias = true
        ..color = Colors.black.withValues(alpha: isDark ? 0.35 : 0.20);

      canvas.drawPath(bandPath, bandPaint);

      currentAngle += fullSweep;
    }
  }

  @override
  bool shouldRepaint(covariant _InfographicPainter oldDelegate) {
    return oldDelegate.selectedIndex != selectedIndex ||
        oldDelegate.progress != progress ||
        oldDelegate.totalSpent != totalSpent;
  }
}
