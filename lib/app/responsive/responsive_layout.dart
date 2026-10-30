import 'package:flutter/material.dart';

enum DeviceScreenType {
  compact,  // Phone (< 600px)
  medium,   // Tablet portrait / large phone (600 - 899px)
  expanded, // Tablet landscape / Desktop (>= 900px)
}

class ResponsiveLayout {
  static const double compactBreakpoint = 600.0;
  static const double mediumBreakpoint = 900.0;

  static DeviceScreenType getDeviceType(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < compactBreakpoint) {
      return DeviceScreenType.compact;
    } else if (width < mediumBreakpoint) {
      return DeviceScreenType.medium;
    } else {
      return DeviceScreenType.expanded;
    }
  }

  static bool isCompact(BuildContext context) =>
      getDeviceType(context) == DeviceScreenType.compact;

  static bool isMedium(BuildContext context) =>
      getDeviceType(context) == DeviceScreenType.medium;

  static bool isExpanded(BuildContext context) =>
      getDeviceType(context) == DeviceScreenType.expanded;

  static double horizontalPadding(BuildContext context) {
    final type = getDeviceType(context);
    switch (type) {
      case DeviceScreenType.compact:
        return 16.0;
      case DeviceScreenType.medium:
        return 24.0;
      case DeviceScreenType.expanded:
        return 32.0;
    }
  }

  static int gridColumns(BuildContext context, {int compact = 2, int medium = 3, int expanded = 4}) {
    final type = getDeviceType(context);
    switch (type) {
      case DeviceScreenType.compact:
        return compact;
      case DeviceScreenType.medium:
        return medium;
      case DeviceScreenType.expanded:
        return expanded;
    }
  }
}

class ResponsiveBuilder extends StatelessWidget {
  final Widget Function(BuildContext context, DeviceScreenType screenType) builder;

  const ResponsiveBuilder({super.key, required this.builder});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenType = ResponsiveLayout.getDeviceType(context);
        return builder(context, screenType);
      },
    );
  }
}

