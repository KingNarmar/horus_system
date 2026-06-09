enum AppDeviceType { mobile, tablet, desktop }

abstract final class AppBreakpoints {
  static const double tablet = 600;
  static const double desktop = 1024;

  static AppDeviceType deviceTypeForWidth(double width) {
    if (width >= desktop) {
      return AppDeviceType.desktop;
    }

    if (width >= tablet) {
      return AppDeviceType.tablet;
    }

    return AppDeviceType.mobile;
  }
}
