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

  @override
  String get loginWelcomeTitle => 'مرحبًا بك في نظام حورس';

  @override
  String get loginSubtitle => 'سجّل الدخول لمتابعة إدارة عمليات النقل الثقيل.';

  @override
  String get emailLabel => 'البريد الإلكتروني';

  @override
  String get passwordLabel => 'كلمة المرور';

  @override
  String get emailRequired => 'البريد الإلكتروني مطلوب.';

  @override
  String get passwordRequired => 'كلمة المرور مطلوبة.';

  @override
  String get loginButton => 'تسجيل الدخول';

  @override
  String get createNewAccountButton => 'إنشاء حساب جديد';

  @override
  String get createAccountTitle => 'إنشاء حساب';

  @override
  String get registerTitle => 'أنشئ حسابك في نظام حورس';

  @override
  String get registerSubtitle =>
      'الاسم الكامل ورقم الهاتف مطلوبان لإدارة مستخدمي الشركة.';

  @override
  String get fullNameLabel => 'الاسم الكامل';

  @override
  String get fullNameRequired => 'الاسم الكامل مطلوب.';

  @override
  String get phoneNumberLabel => 'رقم الهاتف';

  @override
  String get phoneNumberRequired => 'رقم الهاتف مطلوب.';

  @override
  String get passwordMinLength => 'كلمة المرور يجب ألا تقل عن 6 أحرف.';

  @override
  String get createAccountButton => 'إنشاء الحساب';

  @override
  String get checkYourEmailTitle => 'راجع بريدك الإلكتروني';

  @override
  String emailConfirmationMessage(String email) {
    return 'أرسلنا رابط تأكيد إلى $email. افتح البريد الإلكتروني وأكّد حسابك، ثم ارجع إلى نظام حورس وسجّل الدخول.';
  }

  @override
  String get backToLoginButton => 'العودة لتسجيل الدخول';

  @override
  String get createCompanyTitle => 'إنشاء شركة';

  @override
  String get createCompanyFormTitle => 'أنشئ شركتك';

  @override
  String get createCompanySubtitle =>
      'قم بإعداد أول مساحة عمل للشركة داخل نظام حورس.';

  @override
  String get companyNameLabel => 'اسم الشركة';

  @override
  String get companyNameRequired => 'اسم الشركة مطلوب.';

  @override
  String get businessTypeLabel => 'نوع النشاط';

  @override
  String get phoneLabel => 'الهاتف';

  @override
  String get countryLabel => 'الدولة';

  @override
  String get cityLabel => 'المدينة';

  @override
  String get createCompanyButton => 'إنشاء الشركة';

  @override
  String get companyContextLoadedTitle => 'تم تحميل سياق الشركة';

  @override
  String get companyContextNextStep =>
      'الخطوة التالية: سياق الشركة الحالي وواجهة التطبيق.';

  @override
  String get currentCompanyContextRequired => 'سياق الشركة الحالي مطلوب.';

  @override
  String get companyUsersTitle => 'مستخدمو الشركة';

  @override
  String get inviteButton => 'دعوة';

  @override
  String get noCompanyUsersFound => 'لا يوجد مستخدمون للشركة.';

  @override
  String get inviteFlowComingSoon => 'سيتم تنفيذ مسار الدعوة في Issue لاحق.';

  @override
  String get activeStatus => 'نشط';

  @override
  String get inactiveStatus => 'غير نشط';

  @override
  String roleLine(String roleName) {
    return 'الدور: $roleName';
  }

  @override
  String statusLine(String status) {
    return 'الحالة: $status';
  }

  @override
  String get incompleteProfileMessage =>
      'الملف الشخصي غير مكتمل. اطلب من هذا المستخدم استكمال ملفه الشخصي.';
}
