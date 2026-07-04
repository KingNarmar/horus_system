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
  String get driverFinanceTitle => 'حركات السائق المالية';

  @override
  String get driverBalancePlaceholderDescription =>
      'رصيد مبدئي محسوب من السلف والخصومات المسجلة حاليًا. التسوية الشهرية ستنفذ لاحقًا.';

  @override
  String get addDriverAdvanceButton => 'إضافة سلفة';

  @override
  String get addDriverDeductionButton => 'إضافة خصم';

  @override
  String get addDriverAdvanceTitle => 'إضافة سلفة للسائق';

  @override
  String get addDriverDeductionTitle => 'إضافة خصم للسائق';

  @override
  String get driverMovementAmountLabel => 'المبلغ';

  @override
  String get driverMovementDateLabel => 'التاريخ';

  @override
  String get driverMovementTripPickerComingSoon =>
      'اختيار الرحلة سيتم لاحقًا من قائمة الرحلات. سيتم حفظ هذا الخصم كخصم عام الآن.';

  @override
  String get driverMovementRelatedTripLabel => 'الرحلة المرتبطة';

  @override
  String get driverMovementGeneralDeductionOption => 'خصم عام بدون ربط برحلة';

  @override
  String get loadingDriverTripOptions => 'جاري تحميل رحلات السائق...';

  @override
  String get noDriverTripsForDeduction =>
      'لا توجد رحلات مرتبطة بهذا السائق بعد. يمكنك حفظه كخصم عام.';

  @override
  String get driverMovementNotesLabel => 'ملاحظات';

  @override
  String get totalAdvancesLabel => 'إجمالي السلف';

  @override
  String get totalDeductionsLabel => 'إجمالي الخصومات';

  @override
  String get netDriverBalanceLabel => 'الرصيد الحالي';

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
  String get driverMovementTypeDeduction => 'خصم';

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
}
