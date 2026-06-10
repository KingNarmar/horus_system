// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get appTitle => 'نظام حورس';

  @override
  String get appSubtitle => 'نظام موحّد لإدارة عمليات النقل الثقيل والمسارات';

  @override
  String get launchDescription => 'منصة SaaS لإدارة عمليات النقل الثقيل.';

  @override
  String get architectureBadge =>
      'Clean Architecture كما قال الكتاب • مبادئ SOLID';

  @override
  String get appShellDashboardLabel => 'لوحة التحكم';

  @override
  String get appShellDashboardDescription =>
      'نظرة مباشرة على عمليات الشركة والماليات.';

  @override
  String get appShellCustomersLabel => 'العملاء';

  @override
  String get appShellCustomersDescription =>
      'إدارة بيانات العملاء وحركة الحسابات.';

  @override
  String get appShellDriversLabel => 'السائقون';

  @override
  String get appShellDriversDescription =>
      'إدارة السائقين والحالة والإجراءات الخاصة بهم.';

  @override
  String get appShellFleetLabel => 'الأسطول';

  @override
  String get appShellFleetDescription => 'إدارة رؤوس الجر والمقطورات والتوافر.';

  @override
  String get appShellRoutesLabel => 'المسارات';

  @override
  String get appShellRoutesDescription =>
      'إدارة نقاط التحميل والتسليم وخطوط السير.';

  @override
  String get appShellTripsLabel => 'الرحلات';

  @override
  String get appShellTripsDescription =>
      'إنشاء الرحلات ومتابعتها وتحديث حالتها.';

  @override
  String get appShellExpensesLabel => 'المصروفات';

  @override
  String get appShellExpensesDescription =>
      'تسجيل تكاليف الرحلات والرسوم والحركات المالية.';

  @override
  String get appShellInvoicesLabel => 'الفواتير';

  @override
  String get appShellInvoicesDescription =>
      'إنشاء الفواتير وتسجيل المدفوعات ومتابعة الأرصدة.';

  @override
  String get appShellReportsLabel => 'التقارير';

  @override
  String get appShellReportsDescription =>
      'مراجعة التقارير التشغيلية والمالية.';

  @override
  String get appShellSettingsLabel => 'الإعدادات';

  @override
  String get appShellSettingsDescription =>
      'إدارة إعدادات الشركة والمستخدمين والأدوار والصلاحيات.';

  @override
  String get appShellMoreLabel => 'المزيد';

  @override
  String get logout => 'تسجيل الخروج';

  @override
  String companyWithName(String companyName) {
    return 'الشركة: $companyName';
  }

  @override
  String roleWithName(String roleName) {
    return 'الدور: $roleName';
  }

  @override
  String get companySettingsTitle => 'إعدادات الشركة';

  @override
  String get manageUsers => 'إدارة المستخدمين';

  @override
  String get noPermissionManageUsers => 'ليس لديك صلاحية لإدارة المستخدمين.';

  @override
  String get switchToArabic => 'العربية';

  @override
  String get switchToEnglish => 'English';

  @override
  String get adaptiveAccessNotice =>
      'نفس الموديولات متاحة على كل الأجهزة. الذي يتغير هو شكل الشاشة فقط وليس الإجراءات المتاحة.';

  @override
  String get roleOwner => 'مالك الشركة';

  @override
  String get roleAdmin => 'مدير الشركة';

  @override
  String get roleOperations => 'التشغيل';

  @override
  String get roleAccountant => 'المحاسب';

  @override
  String get roleViewer => 'مشاهد';

  @override
  String get roleDriver => 'سائق';
}
