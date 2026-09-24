import '../bootstrap_failure.dart';

final class BootstrapFailureCopy {
  final String title;
  final String message;

  const BootstrapFailureCopy({
    required this.title,
    required this.message,
  });
}

abstract final class BootstrapFailureLocalizations {
  static const BootstrapFailureCopy _englishConfiguration =
      BootstrapFailureCopy(
        title: 'H.O.R.U.S could not start',
        message:
            'The application configuration is unavailable or invalid. '
            'Install a correctly configured release or contact support.',
      );

  static const BootstrapFailureCopy _englishService =
      BootstrapFailureCopy(
        title: 'H.O.R.U.S could not start',
        message:
            'The application could not initialize its required services. '
            'Restart the app. If the problem continues, contact support.',
      );

  static const BootstrapFailureCopy _arabicConfiguration =
      BootstrapFailureCopy(
        title: 'تعذر تشغيل نظام حورس',
        message:
            'إعدادات تشغيل التطبيق غير متاحة أو غير صالحة. '
            'استخدم إصدارًا مُعدًا بشكل صحيح أو تواصل مع الدعم.',
      );

  static const BootstrapFailureCopy _arabicService =
      BootstrapFailureCopy(
        title: 'تعذر تشغيل نظام حورس',
        message:
            'تعذر تهيئة الخدمات المطلوبة لتشغيل التطبيق. '
            'أعد تشغيل التطبيق، وإذا استمرت المشكلة فتواصل مع الدعم.',
      );

  static BootstrapFailureCopy resolve({
    required String languageCode,
    required BootstrapFailureCode code,
  }) {
    final isArabic = languageCode.toLowerCase() == 'ar';

    return switch ((isArabic, code)) {
      (true, BootstrapFailureCode.invalidConfiguration) =>
        _arabicConfiguration,
      (true, BootstrapFailureCode.serviceInitializationFailed) =>
        _arabicService,
      (false, BootstrapFailureCode.invalidConfiguration) =>
        _englishConfiguration,
      (false, BootstrapFailureCode.serviceInitializationFailed) =>
        _englishService,
    };
  }
}
