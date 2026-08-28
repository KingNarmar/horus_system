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
  String get manageUsers => 'إدارة المستخدمين';

  @override
  String get companySettingsTitle => 'إعدادات الشركة';

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
  String get failureAuthInvalidCredentials =>
      'البريد الإلكتروني أو كلمة المرور غير صحيحة.';

  @override
  String get failureAuthEmailNotConfirmed =>
      'أكّد بريدك الإلكتروني قبل تسجيل الدخول.';

  @override
  String get failureAuthAccountAlreadyExists =>
      'يوجد حساب بالفعل لهذا البريد الإلكتروني.';

  @override
  String get failureAuthWeakPassword => 'كلمة المرور لا تستوفي متطلبات الأمان.';

  @override
  String get failureAuthInvalidEmail => 'أدخل عنوان بريد إلكتروني صالحًا.';

  @override
  String get failureAuthRateLimited =>
      'تمت محاولات كثيرة. حاول مرة أخرى لاحقًا.';

  @override
  String get failureAuthError => 'تعذر إتمام إجراء الحساب. حاول مرة أخرى.';

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

  @override
  String get customersTitle => 'العملاء';

  @override
  String get addCustomerButton => 'إضافة عميل';

  @override
  String get addCustomerTitle => 'إضافة عميل';

  @override
  String get editCustomerTitle => 'تعديل عميل';

  @override
  String get editCustomerButton => 'تعديل';

  @override
  String get deactivateCustomerButton => 'إيقاف';

  @override
  String get reactivateCustomerButton => 'إعادة تفعيل';

  @override
  String get searchCustomersHint =>
      'ابحث في العملاء بالاسم أو المسؤول أو الهاتف أو البريد أو المدينة أو الدولة أو الرقم الضريبي';

  @override
  String get customersStatusAllFilter => 'الكل';

  @override
  String get customersStatusActiveFilter => 'النشط';

  @override
  String get customersStatusInactiveFilter => 'غير النشط';

  @override
  String get customerNameLabel => 'اسم العميل';

  @override
  String get customerNameRequired => 'اسم العميل مطلوب.';

  @override
  String get contactPersonLabel => 'الشخص المسؤول';

  @override
  String get taxRegistrationNumberLabel => 'الرقم الضريبي / TRN';

  @override
  String get addressLabel => 'العنوان';

  @override
  String get creditLimitLabel => 'حد الائتمان';

  @override
  String get creditLimitInvalid =>
      'حد الائتمان يجب أن يكون رقمًا صحيحًا غير سالب.';

  @override
  String get saveButton => 'حفظ';

  @override
  String get cancelButton => 'إلغاء';

  @override
  String get okButton => 'حسنًا';

  @override
  String get retryButton => 'إعادة المحاولة';

  @override
  String get noCustomersFound => 'لا يوجد عملاء.';

  @override
  String get noCustomersMatchFilters =>
      'لا يوجد عملاء مطابقون للبحث أو فلتر الحالة الحالي.';

  @override
  String get customerNameHeader => 'العميل';

  @override
  String get contactHeader => 'التواصل';

  @override
  String get statusHeader => 'الحالة';

  @override
  String get actionsHeader => 'الإجراءات';

  @override
  String contactPersonLine(String contactPerson) {
    return 'المسؤول: $contactPerson';
  }

  @override
  String phoneLine(String phone) {
    return 'الهاتف: $phone';
  }

  @override
  String emailLine(String email) {
    return 'البريد: $email';
  }

  @override
  String cityLine(String city) {
    return 'المدينة: $city';
  }

  @override
  String get customerViewDetails => 'التفاصيل';

  @override
  String get customerBasicInfo => 'البيانات الأساسية';

  @override
  String get customerAccountability => 'المسؤولية والمتابعة';

  @override
  String get customerActivityTimeline => 'سجل النشاط';

  @override
  String get customerCreatedBy => 'أنشأه';

  @override
  String get customerCreatedRole => 'دور المنشئ';

  @override
  String get customerCreatedAt => 'تاريخ الإنشاء';

  @override
  String get customerLastActivityBy => 'آخر إجراء بواسطة';

  @override
  String get customerLastActivityRole => 'دور آخر مستخدم';

  @override
  String get customerLastActivityAt => 'وقت آخر إجراء';

  @override
  String get customerLoadingActivity => 'جاري تحميل سجل النشاط...';

  @override
  String get customerNoActivityFound => 'لا يوجد نشاط مسجل لهذا العميل.';

  @override
  String get customerChanges => 'التغييرات';

  @override
  String get customerEmptyValue => 'فارغ';

  @override
  String get customerUnknownUser => 'مستخدم غير معروف';

  @override
  String get customerNotAvailable => 'غير متاح';

  @override
  String get customerConfirmDeactivateTitle => 'تأكيد إلغاء التفعيل';

  @override
  String get customerConfirmReactivateTitle => 'تأكيد إعادة التفعيل';

  @override
  String get customerConfirmDeactivateMessage =>
      'هل تريد إلغاء تفعيل هذا العميل؟';

  @override
  String get customerConfirmReactivateMessage =>
      'هل تريد إعادة تفعيل هذا العميل؟';

  @override
  String get customerSearchHintShort => 'ابحث في العملاء';

  @override
  String customerDetailsTitle(String name) {
    return 'تفاصيل $name';
  }

  @override
  String get customerAuditActionCreated => 'تم الإنشاء';

  @override
  String get customerAuditActionUpdated => 'تم التعديل';

  @override
  String get customerAuditActionDeactivated => 'تم التعطيل';

  @override
  String get customerAuditActionReactivated => 'تم التفعيل';

  @override
  String get customerAuditActionStatusChanged => 'تم تغيير الحالة';

  @override
  String get driversTitle => 'السائقون';

  @override
  String get addDriverButton => 'إضافة سائق';

  @override
  String get editDriverButton => 'تعديل';

  @override
  String get deactivateDriverButton => 'إيقاف';

  @override
  String get reactivateDriverButton => 'إعادة تفعيل';

  @override
  String get viewDriverDetails => 'عرض التفاصيل';

  @override
  String get driverDetails => 'تفاصيل السائق';

  @override
  String get searchDriversHint =>
      'ابحث بالاسم أو الهاتف أو الرقم القومي أو الرخصة';

  @override
  String get driversStatusAllFilter => 'الكل';

  @override
  String get driversStatusActiveFilter => 'النشط';

  @override
  String get driversStatusInactiveFilter => 'غير النشط';

  @override
  String get noDriversFound => 'لا يوجد سائقون.';

  @override
  String get noDriversMatchFilters =>
      'لا يوجد سائقون مطابقون للبحث أو فلتر الحالة الحالي.';

  @override
  String get driverNameLabel => 'اسم السائق';

  @override
  String get driverNameRequired => 'اسم السائق مطلوب.';

  @override
  String get nationalIdLabel => 'الرقم القومي';

  @override
  String get licenseNumberLabel => 'رقم الرخصة';

  @override
  String get licenseExpiryDateLabel => 'تاريخ انتهاء الرخصة';

  @override
  String get licenseExpiryDateMustBeFuture =>
      'تاريخ انتهاء الرخصة يجب أن يكون اليوم أو تاريخًا قادمًا.';

  @override
  String get driverImagesSectionTitle => 'صور السائق';

  @override
  String get driverProfileImageLabel => 'صورة السائق';

  @override
  String get driverLicenseImageLabel => 'صورة الرخصة';

  @override
  String get driverLicenseFrontImageLabel => 'وش الرخصة';

  @override
  String get driverLicenseBackImageLabel => 'ضهر الرخصة';

  @override
  String get driverNationalIdImageLabel => 'صورة البطاقة';

  @override
  String get driverNationalIdFrontImageLabel => 'وش البطاقة';

  @override
  String get driverNationalIdBackImageLabel => 'ضهر البطاقة';

  @override
  String get driverChooseImageFromFiles => 'اختيار ملف';

  @override
  String get driverTakeImageWithCamera => 'الكاميرا';

  @override
  String get driverImageAlreadyUploaded => 'تم رفع الصورة';

  @override
  String get driverImageSelectionFailedTitle => 'فشل اختيار الصورة';

  @override
  String get driverExistingImageValue => 'صورة موجودة';

  @override
  String get driverUpdatedImageValue => 'صورة محدثة';

  @override
  String get driverImagesLoading => 'جاري تحميل الصور...';

  @override
  String get notesLabel => 'ملاحظات';

  @override
  String get driverBasicInfo => 'البيانات الأساسية';

  @override
  String get driverAccountability => 'المسؤولية';

  @override
  String get driverActivityTimeline => 'سجل النشاط';

  @override
  String get driverCreatedBy => 'تم الإنشاء بواسطة';

  @override
  String get driverCreatedRole => 'الدور وقت الإنشاء';

  @override
  String get driverCreatedAt => 'تاريخ الإنشاء';

  @override
  String get driverLastActivityBy => 'آخر نشاط بواسطة';

  @override
  String get driverLastActivityRole => 'دور آخر نشاط';

  @override
  String get driverLastActivityAt => 'وقت آخر نشاط';

  @override
  String get driverLoadingActivity => 'جاري تحميل النشاط...';

  @override
  String get driverNoActivityFound => 'لا يوجد نشاط بعد.';

  @override
  String get driverUnknownUser => 'مستخدم غير معروف';

  @override
  String get driverNotAvailable => 'غير متاح';

  @override
  String get driverConfirmDeactivateTitle => 'تأكيد إيقاف السائق';

  @override
  String get driverConfirmReactivateTitle => 'تأكيد إعادة تفعيل السائق';

  @override
  String get driverConfirmDeactivateMessage => 'هل تريد إيقاف هذا السائق؟';

  @override
  String get driverConfirmReactivateMessage =>
      'هل تريد إعادة تفعيل هذا السائق؟';

  @override
  String driverDetailsTitle(String name) {
    return 'تفاصيل السائق: $name';
  }

  @override
  String get driverStatusActiveLabel => 'نشط';

  @override
  String get driverStatusInactiveLabel => 'غير نشط';

  @override
  String get driverAuditActionCreated => 'تم الإنشاء';

  @override
  String get driverAuditActionUpdated => 'تم التحديث';

  @override
  String get driverAuditActionDeactivated => 'تم الإيقاف';

  @override
  String get driverAuditActionReactivated => 'تمت إعادة التفعيل';

  @override
  String get driverAuditActionFinanceAdded => 'تم تسجيل حركة مالية';

  @override
  String get driverPhoneFieldLabel => 'الهاتف';

  @override
  String get driverStatusFieldLabel => 'الحالة';

  @override
  String auditTimelineHeader(String actorName, String role, String dateTime) {
    return '$actorName • $role • $dateTime';
  }

  @override
  String auditChangeLine(String field, String oldValue, String newValue) {
    return '$field: $oldValue → $newValue';
  }

  @override
  String get routesTitle => 'المسارات';

  @override
  String get addRouteButton => 'إضافة مسار';

  @override
  String get addRouteTitle => 'إضافة مسار';

  @override
  String get editRouteTitle => 'تعديل مسار';

  @override
  String get loadingLocationLabel => 'مكان التحميل';

  @override
  String get unloadingLocationLabel => 'مكان التفريغ';

  @override
  String get governorateFromLabel => 'محافظة التحميل';

  @override
  String get governorateToLabel => 'محافظة التفريغ';

  @override
  String get defaultFreightPriceLabel => 'سعر النقل الافتراضي';

  @override
  String get routeNotesLabel => 'ملاحظات';

  @override
  String get loadingLocationRequired => 'مكان التحميل مطلوب.';

  @override
  String get unloadingLocationRequired => 'مكان التفريغ مطلوب.';

  @override
  String get defaultFreightPriceInvalid => 'أدخل رقم صحيح غير سالب.';

  @override
  String get searchRoutesHint => 'ابحث في المسارات';

  @override
  String get routesStatusAllFilter => 'الكل';

  @override
  String get routesStatusActiveFilter => 'النشط';

  @override
  String get routesStatusInactiveFilter => 'غير النشط';

  @override
  String get noRoutesFound => 'لا توجد مسارات.';

  @override
  String get noRoutesMatchFilters =>
      'لا توجد مسارات مطابقة للبحث أو الفلتر الحالي.';

  @override
  String get routeDeactivateButton => 'إلغاء التفعيل';

  @override
  String get routeReactivateButton => 'إعادة التفعيل';

  @override
  String get confirmRouteDeactivateTitle => 'تأكيد إلغاء تفعيل المسار';

  @override
  String get confirmRouteReactivateTitle => 'تأكيد إعادة تفعيل المسار';

  @override
  String get confirmRouteDeactivateMessage => 'هل تريد إلغاء تفعيل هذا المسار؟';

  @override
  String get confirmRouteReactivateMessage => 'هل تريد إعادة تفعيل هذا المسار؟';

  @override
  String get routeLoadingHeader => 'التحميل';

  @override
  String get routeUnloadingHeader => 'التفريغ';

  @override
  String get routeGovernoratesHeader => 'المحافظات';

  @override
  String get routeDefaultPriceHeader => 'السعر الافتراضي';

  @override
  String get routeStatusHeader => 'الحالة';

  @override
  String get routeActiveStatusLabel => 'نشط';

  @override
  String get routeInactiveStatusLabel => 'غير نشط';

  @override
  String get routeEditButton => 'تعديل';

  @override
  String get routeViewDetails => 'عرض التفاصيل';

  @override
  String routeDetailsTitle(String name) {
    return 'تفاصيل المسار: $name';
  }

  @override
  String get routeBasicInfo => 'البيانات الأساسية';

  @override
  String get routeAccountability => 'المساءلة';

  @override
  String get routeCreatedBy => 'تم الإنشاء بواسطة';

  @override
  String get routeCreatedRole => 'دور منشئ السجل';

  @override
  String get routeCreatedAt => 'وقت الإنشاء';

  @override
  String get routeLastActivityBy => 'آخر نشاط بواسطة';

  @override
  String get routeLastActivityRole => 'دور آخر نشاط';

  @override
  String get routeLastActivityAt => 'وقت آخر نشاط';

  @override
  String get routeActivityTimeline => 'سجل النشاط';

  @override
  String get routeLoadingActivity => 'جاري تحميل النشاط...';

  @override
  String get routeNoActivityFound => 'لا يوجد نشاط بعد.';

  @override
  String get routeChanges => 'التغييرات';

  @override
  String get routeUnknownUser => 'مستخدم غير معروف';

  @override
  String get routeNotAvailable => 'غير متاح';

  @override
  String get routeAuditActionCreated => 'تم الإنشاء';

  @override
  String get routeAuditActionUpdated => 'تم التعديل';

  @override
  String get routeAuditActionDeactivated => 'تم إلغاء التفعيل';

  @override
  String get routeAuditActionReactivated => 'تمت إعادة التفعيل';

  @override
  String get routeAuditActionStatusChanged => 'تم تغيير الحالة';

  @override
  String routeAuditTimelineHeader(String actor, String role, String dateTime) {
    return '$actor ($role) - $dateTime';
  }

  @override
  String routeAuditChangeLine(String label, String oldValue, String newValue) {
    return '$label: من $oldValue إلى $newValue';
  }

  @override
  String get fleetTitle => 'الأسطول';

  @override
  String get tractorHeadsTab => 'رؤوس الجر';

  @override
  String get trailersTab => 'المقطورات';

  @override
  String get addTractorHeadButton => 'إضافة رأس جر';

  @override
  String get addTrailerButton => 'إضافة مقطورة';

  @override
  String get editTractorHeadTitle => 'تعديل رأس جر';

  @override
  String get editTrailerTitle => 'تعديل مقطورة';

  @override
  String get plateNumberLabel => 'رقم اللوحة';

  @override
  String get plateNumberRequired => 'رقم اللوحة مطلوب.';

  @override
  String get vehicleStatusLabel => 'حالة المركبة';

  @override
  String get vehicleLicenseExpiryDateLabel => 'تاريخ انتهاء الترخيص';

  @override
  String get expectedFuelConsumptionLabel => 'استهلاك الوقود المتوقع';

  @override
  String get expectedFuelConsumptionInvalid => 'أدخل رقم صحيح غير سالب.';

  @override
  String get vehicleNotesLabel => 'ملاحظات';

  @override
  String get technicalNotesLabel => 'ملاحظات فنية';

  @override
  String get searchFleetHint => 'ابحث برقم اللوحة أو الحالة أو الملاحظات';

  @override
  String get fleetStatusAllFilter => 'الكل';

  @override
  String get fleetStatusActiveFilter => 'النشط';

  @override
  String get fleetStatusInactiveFilter => 'غير النشط';

  @override
  String get noTractorHeadsFound => 'لا توجد رؤوس جر.';

  @override
  String get noTrailersFound => 'لا توجد مقطورات.';

  @override
  String get noFleetMatchFilters =>
      'لا توجد أصول مطابقة للبحث أو الفلتر الحالي.';

  @override
  String get fleetEditButton => 'تعديل';

  @override
  String get fleetDeactivateButton => 'إلغاء التفعيل';

  @override
  String get fleetReactivateButton => 'إعادة التفعيل';

  @override
  String get fleetDetailsButton => 'التفاصيل';

  @override
  String get fleetConfirmDeactivateTitle => 'تأكيد إلغاء التفعيل';

  @override
  String get fleetConfirmReactivateTitle => 'تأكيد إعادة التفعيل';

  @override
  String get fleetConfirmDeactivateMessage => 'هل تريد إلغاء تفعيل هذا الأصل؟';

  @override
  String get fleetConfirmReactivateMessage => 'هل تريد إعادة تفعيل هذا الأصل؟';

  @override
  String get vehicleStatusAvailable => 'متاح';

  @override
  String get vehicleStatusOnTrip => 'في رحلة';

  @override
  String get vehicleStatusLoading => 'تحميل';

  @override
  String get vehicleStatusUnloading => 'تفريغ';

  @override
  String get vehicleStatusMaintenance => 'صيانة';

  @override
  String get vehicleStatusStopped => 'متوقف';

  @override
  String get vehicleStatusInactive => 'غير نشط';

  @override
  String get fleetBasicInfo => 'البيانات الأساسية';

  @override
  String get fleetAccountability => 'المسؤولية والمتابعة';

  @override
  String get fleetActivityTimeline => 'سجل النشاط';

  @override
  String get fleetCreatedBy => 'أنشأه';

  @override
  String get fleetCreatedRole => 'دور المنشئ';

  @override
  String get fleetCreatedAt => 'تاريخ الإنشاء';

  @override
  String get fleetLastActivityBy => 'آخر إجراء بواسطة';

  @override
  String get fleetLastActivityRole => 'دور آخر مستخدم';

  @override
  String get fleetLastActivityAt => 'وقت آخر إجراء';

  @override
  String get fleetLoadingActivity => 'جاري تحميل سجل النشاط...';

  @override
  String get fleetNoActivityFound => 'لا يوجد نشاط مسجل لهذا الأصل.';

  @override
  String get fleetUnknownUser => 'مستخدم غير معروف';

  @override
  String get fleetNotAvailable => 'غير متاح';

  @override
  String get fleetChanges => 'التغييرات';

  @override
  String fleetDetailsTitle(String plateNumber) {
    return 'تفاصيل الأصل: $plateNumber';
  }

  @override
  String get fleetAuditActionCreated => 'تم الإنشاء';

  @override
  String get fleetAuditActionUpdated => 'تم التعديل';

  @override
  String get fleetAuditActionDeactivated => 'تم التعطيل';

  @override
  String get fleetAuditActionReactivated => 'تم التفعيل';

  @override
  String get fleetAuditActionStatusChanged => 'تم تغيير الحالة';

  @override
  String get driverFinanceTitle => 'حركات السائق المالية';

  @override
  String get driverBalancePlaceholderDescription =>
      'الرصيد السالب يعني أن السائق مدين للشركة، والرصيد الموجب يعني أن الشركة مدينة للسائق.';

  @override
  String get addDriverAdvanceButton => 'إضافة سلفة';

  @override
  String get addDriverChargeButton => 'إضافة مديونية على السائق';

  @override
  String get addDriverAdvanceTitle => 'إضافة سلفة للسائق';

  @override
  String get addDriverChargeTitle => 'إضافة مديونية على السائق';

  @override
  String get driverMovementAmountLabel => 'المبلغ';

  @override
  String get driverMovementDateLabel => 'التاريخ';

  @override
  String get driverMovementTripPickerComingSoon =>
      'ربط الرحلة اختياري. اتركها فارغة لتسجيل مديونية عامة على السائق.';

  @override
  String get driverMovementRelatedTripLabel => 'الرحلة المرتبطة';

  @override
  String get driverMovementGeneralChargeOption => 'مديونية عامة بدون ربط برحلة';

  @override
  String get loadingDriverTripOptions => 'جاري تحميل رحلات السائق...';

  @override
  String get noDriverTripsForCharge =>
      'لا توجد رحلات مرتبطة بهذا السائق بعد. يمكنك تسجيل مديونية عامة.';

  @override
  String get driverMovementNotesLabel => 'ملاحظات';

  @override
  String get totalAdvancesLabel => 'إجمالي السلف';

  @override
  String get totalDriverChargesLabel => 'إجمالي مديونيات السائق';

  @override
  String get netDriverBalanceLabel => 'الرصيد الحالي';

  @override
  String driverBalanceDriverOwesCompany(String amount) {
    return 'السائق مدين للشركة: $amount';
  }

  @override
  String driverBalanceCompanyOwesDriver(String amount) {
    return 'الشركة مدينة للسائق: $amount';
  }

  @override
  String get driverBalanceSettled => 'الرصيد مسوّى';

  @override
  String get noDriverFinancialMovements => 'لا توجد حركات مالية بعد.';

  @override
  String get loadingDriverFinancialMovements => 'جاري تحميل الحركات المالية...';

  @override
  String get savingDriverFinancialMovement => 'جاري الحفظ...';

  @override
  String get invalidDriverMovementAmount => 'أدخل مبلغ صحيح أكبر من صفر.';

  @override
  String get driverMovementTripLine => 'الرحلة';

  @override
  String get driverMovementTypeAdvance => 'سلفة';

  @override
  String get driverMovementTypeDriverCharge => 'مديونية على السائق';

  @override
  String get driverMovementTypeCashReturn => 'إرجاع نقدية';

  @override
  String get companyExpensesTitle => 'مصروفات الشركة';

  @override
  String get addCompanyExpenseButton => 'إضافة مصروف';

  @override
  String get addCompanyExpenseTitle => 'إضافة مصروف شركة';

  @override
  String get editCompanyExpenseTitle => 'تعديل مصروف شركة';

  @override
  String get companyExpenseCategoryLabel => 'التصنيف';

  @override
  String get companyExpenseCategoryRequired => 'التصنيف مطلوب.';

  @override
  String get companyExpenseAmountLabel => 'المبلغ';

  @override
  String get companyExpenseDateLabel => 'التاريخ';

  @override
  String get companyExpenseReferenceLabel => 'رقم المرجع';

  @override
  String get companyExpenseNotesLabel => 'ملاحظات';

  @override
  String get companyExpenseAmountInvalid => 'أدخل مبلغ صحيح أكبر من صفر.';

  @override
  String get searchCompanyExpensesHint =>
      'ابحث في التصنيف أو المبلغ أو المرجع أو الملاحظات';

  @override
  String get includeVoidedCompanyExpenses => 'إظهار الملغاة';

  @override
  String get noCompanyExpensesFound => 'لا توجد مصروفات شركة.';

  @override
  String get noCompanyExpensesMatchFilters =>
      'لا توجد مصروفات مطابقة للبحث الحالي.';

  @override
  String get companyExpenseVoidedStatus => 'ملغى';

  @override
  String get companyExpenseActiveStatus => 'نشط';

  @override
  String get voidCompanyExpenseButton => 'إلغاء';

  @override
  String get voidCompanyExpenseTitle => 'إلغاء مصروف الشركة';

  @override
  String get voidCompanyExpenseMessage =>
      'هل تريد إلغاء هذا المصروف؟ سيتم الاحتفاظ به في السجل كملغى.';

  @override
  String get voidReasonLabel => 'سبب الإلغاء';

  @override
  String get confirmButton => 'تأكيد';

  @override
  String companyExpenseCategoryLine(String categoryName) {
    return 'التصنيف: $categoryName';
  }

  @override
  String companyExpenseAmountLine(String amount) {
    return 'المبلغ: $amount';
  }

  @override
  String companyExpenseDateLine(String date) {
    return 'التاريخ: $date';
  }

  @override
  String companyExpenseReferenceLine(String reference) {
    return 'المرجع: $reference';
  }

  @override
  String get companyExpenseCategoryVehicleMaintenance => 'صيانة المركبات';

  @override
  String get companyExpenseCategorySpareParts => 'قطع الغيار';

  @override
  String get companyExpenseCategoryTires => 'الإطارات';

  @override
  String get companyExpenseCategoryOilsAndFluids => 'الزيوت والسوائل';

  @override
  String get companyExpenseCategoryLicensesAndRenewals => 'التراخيص والتجديدات';

  @override
  String get companyExpenseCategoryOfficeExpenses => 'مصروفات المكتب';

  @override
  String get companyExpenseCategoryRent => 'الإيجار';

  @override
  String get companyExpenseCategorySalaries => 'الرواتب';

  @override
  String get companyExpenseCategoryAdminCosts => 'المصروفات الإدارية';

  @override
  String get companyExpenseCategoryFines => 'الغرامات';

  @override
  String get companyExpenseCategoryOther => 'أخرى';

  @override
  String get failureUnexpectedError => 'حدث خطأ غير متوقع.';

  @override
  String get failureServerError => 'حدث خطأ في الخادم.';

  @override
  String get failureValidationCompanyIdRequired => 'معرّف الشركة مطلوب.';

  @override
  String get failureValidationCompanyContextRequired => 'سياق الشركة مطلوب.';

  @override
  String get failureCompanyNotAvailable =>
      'الشركة المحددة غير متاحة للمستخدم الحالي.';

  @override
  String get failurePermissionCompanyUsersView =>
      'هذا الدور لا يمكنه عرض مستخدمي الشركة.';

  @override
  String get failurePermissionCustomersView =>
      'لا يوجد صلاحية للوصول إلى العملاء.';

  @override
  String get failurePermissionCustomersManagement =>
      'لا يوجد صلاحية لإدارة العملاء.';

  @override
  String get failureValidationCustomerIdRequired => 'معرّف العميل مطلوب.';

  @override
  String get failureValidationCustomerNameRequired => 'اسم العميل مطلوب.';

  @override
  String get failureValidationCreditLimitNegative =>
      'حد الائتمان لا يمكن أن يكون رقمًا سالبًا.';

  @override
  String get failurePermissionDriversView =>
      'لا يوجد صلاحية للوصول إلى السائقين.';

  @override
  String get failurePermissionDriversManagement =>
      'لا يوجد صلاحية لإدارة السائقين.';

  @override
  String get failureValidationDriverIdRequired => 'معرّف السائق مطلوب.';

  @override
  String get failureValidationDriverNameRequired => 'اسم السائق مطلوب.';

  @override
  String get failureValidationDriverImageTooLarge =>
      'الصورة المختارة لازم تكون 5 ميجابايت أو أقل.';

  @override
  String get failureValidationDriverImageTypeUnsupported =>
      'نوع الصورة المختارة غير مدعوم. استخدم JPG أو PNG أو WebP أو HEIC أو HEIF.';

  @override
  String get failurePermissionFleetManagement =>
      'لا يوجد صلاحية لإدارة الأسطول.';

  @override
  String get failurePermissionFleetView => 'لا يوجد صلاحية للوصول إلى الأسطول.';

  @override
  String get failureValidationFleetPlateRequired => 'رقم اللوحة مطلوب.';

  @override
  String get failureValidationFleetFuelConsumptionNegative =>
      'استهلاك الوقود المتوقع لا يمكن أن يكون رقمًا سالبًا.';

  @override
  String get failurePermissionRoutesManagement =>
      'لا يوجد صلاحية لإدارة المسارات.';

  @override
  String get failurePermissionRoutesView =>
      'لا يوجد صلاحية للوصول إلى المسارات.';

  @override
  String get failureValidationRouteLoadingLocationRequired =>
      'مكان التحميل مطلوب.';

  @override
  String get failureValidationRouteUnloadingLocationRequired =>
      'مكان التفريغ مطلوب.';

  @override
  String get failureValidationRouteFreightPriceNegative =>
      'سعر النقل الافتراضي لا يمكن أن يكون رقمًا سالبًا.';

  @override
  String get failureValidationTripIdRequired => 'معرّف الرحلة مطلوب.';

  @override
  String get failurePermissionTripExpensesView =>
      'لا يوجد صلاحية لعرض مصروفات الرحلة.';

  @override
  String get failurePermissionTripExpensesManagement =>
      'لا يوجد صلاحية لإدارة مصروفات الرحلة.';

  @override
  String get failureValidationTripExpenseIdRequired =>
      'معرّف مصروف الرحلة مطلوب.';

  @override
  String get failureValidationTripExpenseTypeRequired => 'نوع المصروف مطلوب.';

  @override
  String get failureValidationTripExpenseNameRequired => 'اسم المصروف مطلوب.';

  @override
  String get failureValidationTripExpenseAmountPositive =>
      'مبلغ المصروف لازم يكون أكبر من صفر.';

  @override
  String get failurePermissionDriverFinanceView =>
      'لا يوجد صلاحية لعرض الحركات المالية للسائق.';

  @override
  String get failurePermissionDriverFinanceManagement =>
      'لا يوجد صلاحية لإدارة الحركات المالية للسائق.';

  @override
  String get failureValidationDriverFinanceAmountPositive =>
      'مبلغ حركة السائق لازم يكون أكبر من صفر.';

  @override
  String get failurePermissionCompanyExpensesView =>
      'لا يوجد صلاحية لعرض مصروفات الشركة.';

  @override
  String get failurePermissionCompanyExpensesManagement =>
      'لا يوجد صلاحية لإدارة مصروفات الشركة.';

  @override
  String get failureValidationCompanyExpenseIdRequired =>
      'معرّف مصروف الشركة مطلوب.';

  @override
  String get failureValidationCompanyExpenseCategoryRequired =>
      'تصنيف مصروف الشركة مطلوب.';

  @override
  String get failureValidationCompanyExpenseAmountPositive =>
      'مبلغ مصروف الشركة لازم يكون أكبر من صفر.';

  @override
  String get failureValidationAuditEntityIdRequired =>
      'معرّف سجل المراجعة مطلوب.';

  @override
  String get failureValidationAuditDescriptionRequired =>
      'وصف سجل المراجعة مطلوب.';

  @override
  String get unknownUser => 'مستخدم غير معروف';

  @override
  String get profileDetailsNotSetYet => 'لم يتم تعيين تفاصيل الملف الشخصي بعد';

  @override
  String get reportsTitle => 'التقارير';

  @override
  String get reportsReportLabel => 'التقرير';

  @override
  String get reportsFromDate => 'من تاريخ';

  @override
  String get reportsToDate => 'إلى تاريخ';

  @override
  String get reportsSelectDate => 'اختر تاريخًا';

  @override
  String get reportsApplyFilters => 'تطبيق';

  @override
  String get reportsClearFilters => 'مسح التواريخ';

  @override
  String get reportsLoading => 'جاري تحميل التقرير...';

  @override
  String get reportsRetry => 'إعادة المحاولة';

  @override
  String get reportsNoRows => 'لا توجد بيانات للفترة المحددة.';

  @override
  String get reportsNoAccess => 'لا توجد تقارير متاحة لهذا الدور.';

  @override
  String get reportsUnassigned => 'غير مسند';

  @override
  String get reportsAllDates => 'كل التواريخ';

  @override
  String get reportsNotAvailable => 'غير متاح';

  @override
  String get reportsTrip => 'الرحلة';

  @override
  String get reportsDate => 'التاريخ';

  @override
  String get reportsCustomer => 'العميل';

  @override
  String get reportsDriver => 'السائق';

  @override
  String get reportsTractorHead => 'رأس الجرار';

  @override
  String get reportsTrailer => 'المقطورة';

  @override
  String get reportsRoute => 'المسار';

  @override
  String get reportsStatus => 'الحالة';

  @override
  String get reportsTripsCount => 'عدد الرحلات';

  @override
  String get reportsLoadingOrder => 'أمر التحميل';

  @override
  String get reportsWaybill => 'البوليصة';

  @override
  String get reportsExpense => 'المصروف';

  @override
  String get reportsPaidBy => 'الدافع';

  @override
  String get reportsAmount => 'المبلغ';

  @override
  String get reportsTotalExpenses => 'إجمالي المصروفات';

  @override
  String get reportsFreight => 'سعر النقل';

  @override
  String get reportsNetProfit => 'صافي الربح';

  @override
  String get reportsTotalFreight => 'إجمالي النقل';

  @override
  String get reportsTotalNetProfit => 'إجمالي صافي الربح';

  @override
  String get reportsInvoice => 'الفاتورة';

  @override
  String get reportsIssueDate => 'تاريخ الإصدار';

  @override
  String get reportsDueDate => 'تاريخ الاستحقاق';

  @override
  String get reportsTotal => 'الإجمالي';

  @override
  String get reportsPaid => 'المدفوع';

  @override
  String get reportsRemaining => 'المتبقي';

  @override
  String get reportsTotalOutstanding => 'إجمالي المستحق';

  @override
  String get reportsTypeDailyTrips => 'الرحلات اليومية';

  @override
  String get reportsTypeTripsByCustomer => 'الرحلات حسب العميل';

  @override
  String get reportsTypeTripsByDriver => 'الرحلات حسب السائق';

  @override
  String get reportsTypeTripsByTractorHead => 'الرحلات حسب رأس الجرار';

  @override
  String get reportsTypeTripsByTrailer => 'الرحلات حسب المقطورة';

  @override
  String get reportsTypeTripExpenses => 'مصروفات الرحلات';

  @override
  String get reportsTypeTripNetProfit => 'صافي ربح الرحلات';

  @override
  String get reportsTypeOpenInvoices => 'الفواتير المفتوحة';

  @override
  String reportsGroupTrips(int count) {
    return '$count رحلة';
  }

  @override
  String reportsDateRange(String from, String to) {
    return 'الفترة: $from — $to';
  }

  @override
  String get reportsPaidByCompany => 'الشركة';

  @override
  String get reportsPaidByDriverAdvance => 'عهدة السائق';

  @override
  String get reportsPaidByDriverCash => 'دفع السائق';

  @override
  String get reportsPaidByCustomer => 'العميل';

  @override
  String get reportsPaidByOther => 'أخرى';

  @override
  String get reportsInvoiceStatusDraft => 'مسودة';

  @override
  String get reportsInvoiceStatusIssued => 'صادرة';

  @override
  String get reportsInvoiceStatusPartiallyPaid => 'مدفوعة جزئيًا';

  @override
  String get reportsInvoiceStatusPaid => 'مدفوعة';

  @override
  String get reportsInvoiceStatusCancelled => 'ملغاة';

  @override
  String get reportsPermissionFailure =>
      'هذا الدور غير مسموح له بعرض التقرير المحدد.';

  @override
  String get reportsInvalidDateRangeFailure =>
      'يجب ألا يكون تاريخ البداية بعد تاريخ النهاية.';

  @override
  String get reportsRegionalSettingsFailure =>
      'اضبط عملة الشركة والمنطقة الزمنية للعمل أولًا.';

  @override
  String get reportsCompanyNotFoundFailure => 'تعذر العثور على الشركة الحالية.';

  @override
  String get reportsSourceInvalidFailure =>
      'بيانات التقرير غير متسقة. أعد التحميل ثم حاول مرة أخرى.';

  @override
  String get reportsCurrencyMismatchFailure =>
      'البيانات المالية للتقرير لا تطابق عملة الشركة.';

  @override
  String get reportsFinancialDataInvalidFailure =>
      'تحتوي بيانات التقرير المالية على مبلغ أو رصيد غير صالح.';

  @override
  String get reportsInvoiceBalanceInvalidFailure =>
      'رصيد إحدى الفواتير غير متسق مع حالة الفاتورة ومدفوعاتها.';

  @override
  String get reportsLoadFailed => 'تعذر تحميل التقرير.';

  @override
  String get tripDetailsHeaderTitle => 'تفاصيل الرحلة';

  @override
  String get tripsTitle => 'الرحلات';

  @override
  String get addTripButton => 'إضافة رحلة';

  @override
  String get addTripTitle => 'إضافة رحلة';

  @override
  String get editTripTitle => 'تعديل رحلة';

  @override
  String get searchTripsHint => 'ابحث في الرحلات';

  @override
  String get noTripsFound => 'لا توجد رحلات.';

  @override
  String get noTripsMatchFilters =>
      'لا توجد رحلات مطابقة للبحث أو الفلتر الحالي.';

  @override
  String get tripCustomerHeader => 'العميل';

  @override
  String get tripRouteHeader => 'المسار';

  @override
  String get tripDriverHeader => 'السائق';

  @override
  String get tripVehicleHeader => 'المركبة';

  @override
  String get tripTractorHeadLabel => 'رأس الجرار';

  @override
  String get tripTrailerLabel => 'المقطورة';

  @override
  String get tripLoadingOrderHeader => 'أمر التحميل';

  @override
  String get tripWaybillHeader => 'رقم البوليصة';

  @override
  String get tripQuantityHeader => 'الكمية';

  @override
  String get tripTonsSuffix => 'طن';

  @override
  String get tripFreightPriceHeader => 'سعر النقل';

  @override
  String get tripTotalExpensesLabel => 'إجمالي المصروفات';

  @override
  String get tripNetProfitHeader => 'صافي الربح';

  @override
  String get tripViewDetails => 'عرض التفاصيل';

  @override
  String get tripEditButton => 'تعديل';

  @override
  String get tripUpdateStatus => 'تحديث الحالة';

  @override
  String get tripEmptyValue => '-';

  @override
  String get tripOptionalNone => 'بدون';

  @override
  String get tripScheduledLoadingAtLabel => 'موعد التحميل المخطط';

  @override
  String get tripScheduledDeliveryAtLabel => 'موعد التسليم المخطط';

  @override
  String get tripActualLoadingAtLabel => 'وقت التحميل الفعلي';

  @override
  String get tripActualDeliveryAtLabel => 'وقت التسليم الفعلي';

  @override
  String get tripBasicInfo => 'البيانات الأساسية';

  @override
  String get tripAccountability => 'المساءلة';

  @override
  String get tripActivityTimeline => 'سجل النشاط';

  @override
  String get tripStatusHistoryTitle => 'سجل حالات الرحلة';

  @override
  String get tripExpensesTitle => 'مصروفات الرحلة';

  @override
  String get tripLoadingExpenses => 'جاري تحميل المصروفات...';

  @override
  String get tripNoExpensesFound => 'لا توجد مصروفات بعد.';

  @override
  String get tripAddExpenseButton => 'إضافة مصروف';

  @override
  String get tripEditExpenseTitle => 'تعديل مصروف';

  @override
  String get tripAddExpenseTitle => 'إضافة مصروف';

  @override
  String get tripExpenseNameLabel => 'اسم المصروف';

  @override
  String get tripExpenseTypeLabel => 'نوع المصروف';

  @override
  String get tripExpenseTypeRequired => 'نوع المصروف مطلوب.';

  @override
  String get tripExpenseAmountLabel => 'المبلغ';

  @override
  String get tripExpensePaidByLabel => 'الدافع';

  @override
  String get tripExpenseDateLabel => 'تاريخ المصروف';

  @override
  String get tripExpenseDateHelperText => 'مثال: 2026-06-26';

  @override
  String get tripExpenseDateInvalid => 'أدخل تاريخ صحيح.';

  @override
  String get tripExpenseNameRequired => 'اسم المصروف مطلوب.';

  @override
  String get tripExpenseAmountPositive => 'المبلغ لازم يكون أكبر من صفر.';

  @override
  String get tripExpenseTypesUnavailable => 'أنواع المصروفات غير متاحة حاليًا.';

  @override
  String get tripLoadingActivity => 'جاري تحميل النشاط...';

  @override
  String get tripLoadingStatusHistory => 'جاري تحميل سجل الحالات...';

  @override
  String get tripLoadingLookups => 'جاري تحميل بيانات النموذج...';

  @override
  String get tripRequiredLookupsMissing =>
      'لازم يكون عندك عميل واحد ومسار واحد على الأقل قبل إنشاء رحلة.';

  @override
  String get tripNoActivityFound => 'لا يوجد نشاط بعد.';

  @override
  String get tripNoStatusHistoryFound => 'لا يوجد سجل حالات بعد.';

  @override
  String get tripCreatedBy => 'تم الإنشاء بواسطة';

  @override
  String get tripCreatedRole => 'دور منشئ السجل';

  @override
  String get tripCreatedAt => 'وقت الإنشاء';

  @override
  String get tripLastActivityBy => 'آخر نشاط بواسطة';

  @override
  String get tripLastActivityRole => 'دور آخر نشاط';

  @override
  String get tripLastActivityAt => 'وقت آخر نشاط';

  @override
  String get tripUnknownUser => 'مستخدم غير معروف';

  @override
  String get tripChanges => 'التغييرات';

  @override
  String get tripAuditDetails => 'التفاصيل';

  @override
  String get tripCloseButton => 'إغلاق';

  @override
  String get tripNextStatusLabel => 'الحالة التالية';

  @override
  String get tripStatusNotesLabel => 'ملاحظات تغيير الحالة';

  @override
  String get tripNoAvailableStatusActions =>
      'لا توجد حالات متاحة بعد الحالة الحالية.';

  @override
  String get tripCustomerRequired => 'العميل مطلوب.';

  @override
  String get tripRouteRequired => 'المسار مطلوب.';

  @override
  String get tripNumberInvalid => 'أدخل رقم صحيح غير سالب.';

  @override
  String get tripDateTimeHelperText => 'اختياري - مثال: 2026-06-20 14:30';

  @override
  String get tripDateTimeInvalid => 'أدخل تاريخ ووقت صحيحين.';

  @override
  String get tripDeliveryBeforeLoadingInvalid =>
      'موعد التسليم لا يمكن أن يكون قبل موعد التحميل.';

  @override
  String get tripsStatusAllFilter => 'الكل';

  @override
  String get tripsStatusOpenFilter => 'المفتوحة';

  @override
  String get tripsStatusCreatedFilter => 'جديدة';

  @override
  String get tripsStatusAssignedFilter => 'مخصصة';

  @override
  String get tripsStatusLoadedFilter => 'تم التحميل';

  @override
  String get tripsStatusOnRoadFilter => 'على الطريق';

  @override
  String get tripsStatusArrivedFilter => 'وصلت';

  @override
  String get tripsStatusDeliveredFilter => 'تم التسليم';

  @override
  String get tripsStatusDocumentsReceivedFilter => 'تم استلام المستندات';

  @override
  String get tripsStatusInvoicedFilter => 'تمت الفوترة';

  @override
  String get tripsStatusPaidFilter => 'مدفوعة';

  @override
  String get tripsStatusCancelledFilter => 'ملغاة';

  @override
  String tripCurrentStatusLine(String status) {
    return 'الحالة الحالية: $status';
  }

  @override
  String tripStatusHistoryLine(String oldStatus, String newStatus) {
    return 'من $oldStatus إلى $newStatus';
  }

  @override
  String tripChangedByLine(String actor, String role, String dateTime) {
    return '$actor ($role) - $dateTime';
  }

  @override
  String tripAuditTimelineHeader(String actor, String role, String dateTime) {
    return '$actor ($role) - $dateTime';
  }

  @override
  String tripAuditChangeLine(String label, String oldValue, String newValue) {
    return '$label: من $oldValue إلى $newValue';
  }

  @override
  String tripAuditDetailLine(String label, String value) {
    return '$label: $value';
  }

  @override
  String tripDetailsTitleText(String name) {
    return 'تفاصيل الرحلة: $name';
  }

  @override
  String tripUpdateStatusTitleText(String name) {
    return 'تحديث حالة الرحلة: $name';
  }

  @override
  String get tripExpensePaidByCompany => 'الشركة';

  @override
  String get tripExpensePaidByDriverAdvance => 'عهدة السائق';

  @override
  String get tripExpensePaidByDriverCash => 'دفع السائق';

  @override
  String get tripExpensePaidByCustomer => 'العميل';

  @override
  String get tripExpensePaidByOther => 'أخرى';

  @override
  String get tripExpenseTypeFuel => 'وقود';

  @override
  String get tripExpenseTypeRoadFees => 'رسوم طرق';

  @override
  String get tripExpenseTypeWeighbridge => 'ميزان';

  @override
  String get tripExpenseTypeLoading => 'تحميل';

  @override
  String get tripExpenseTypeUnloading => 'تفريغ';

  @override
  String get tripExpenseTypeFines => 'غرامات';

  @override
  String get tripExpenseTypeEmergencyMaintenance => 'صيانة طارئة';

  @override
  String get tripExpenseTypeDriverAdvance => 'عهدة سائق';

  @override
  String get tripExpenseTypeOther => 'أخرى';

  @override
  String get tripAuditActionCreated => 'تم الإنشاء';

  @override
  String get tripAuditActionUpdated => 'تم التعديل';

  @override
  String get tripAuditActionStatusChanged => 'تم تغيير الحالة';

  @override
  String get tripAuditActionDeactivated => 'تم إلغاء التفعيل';

  @override
  String get tripAuditActionReactivated => 'تمت إعادة التفعيل';

  @override
  String get tripAuditRoleOwner => 'مالك';

  @override
  String get tripAuditRoleAdmin => 'مدير';

  @override
  String get tripAuditRoleOperations => 'تشغيل';

  @override
  String get tripAuditRoleAccountant => 'محاسب';

  @override
  String get tripAuditRoleViewer => 'مشاهد';

  @override
  String get tripAuditRoleDriver => 'سائق';

  @override
  String get tripAuditFieldExpenseId => 'معرّف المصروف';

  @override
  String get tripAuditFieldTractorPlate => 'رقم رأس الجرار';

  @override
  String get tripAuditFieldTrailerPlate => 'رقم المقطورة';
}
