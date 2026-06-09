import 'package:flutter/widgets.dart';

import 'app_breakpoints.dart';

class ResponsiveLayout extends StatelessWidget {
  final Widget mobile;
  final Widget? tablet;
  final Widget? desktop;

  const ResponsiveLayout({
    required this.mobile,
    this.tablet,
    this.desktop,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final deviceType = AppBreakpoints.deviceTypeForWidth(
          constraints.maxWidth,
        );

        return switch (deviceType) {
          AppDeviceType.desktop => desktop ?? tablet ?? mobile,
          AppDeviceType.tablet => tablet ?? mobile,
          AppDeviceType.mobile => mobile,
        };
      },
    );
  }
}
