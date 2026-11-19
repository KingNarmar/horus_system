import 'package:flutter/widgets.dart';

import '../../domain/entities/company_entitlement.dart';
import '../../domain/entities/entitlement_feature.dart';
import '../../domain/entities/entitlement_resource.dart';
import '../../domain/policies/quota_usage_display_policy.dart';
import '../../domain/entities/subscription_status.dart';

final class SubscriptionsLocalizations {
  final Map<String, String> _values;

  const SubscriptionsLocalizations._(this._values);

  factory SubscriptionsLocalizations.forLocale(Locale locale) {
    return locale.languageCode == 'ar'
        ? const SubscriptionsLocalizations._(_ar)
        : const SubscriptionsLocalizations._(_en);
  }

  String _value(String key) => _values[key]!;

  String get title => _value('title');
  String get description => _value('description');
  String get currentPlan => _value('currentPlan');
  String get availablePlans => _value('availablePlans');
  String get noCurrentSubscription => _value('noCurrentSubscription');
  String get noAvailablePlans => _value('noAvailablePlans');
  String get loading => _value('loading');
  String get loadFailed => _value('loadFailed');
  String get retry => _value('retry');
  String get planLimits => _value('planLimits');
  String get planFeatures => _value('planFeatures');
  String get unlimited => _value('unlimited');
  String get users => _value('users');
  String get vehicles => _value('vehicles');
  String get customers => _value('customers');
  String get drivers => _value('drivers');
  String get routes => _value('routes');
  String get lifetimeTrips => _value('lifetimeTrips');
  String get lifetimeInvoices => _value('lifetimeInvoices');
  String get businessDocuments => _value('businessDocuments');
  String get tripsPerMonth => _value('tripsPerMonth');
  String get driverApp => _value('driverApp');
  String get advancedReports => _value('advancedReports');
  String get documentUpload => _value('documentUpload');
  String get maintenance => _value('maintenance');
  String get whatsappNotifications => _value('whatsappNotifications');
  String get included => _value('included');
  String get notIncluded => _value('notIncluded');
  String get status => _value('status');
  String get trialEndsAt => _value('trialEndsAt');
  String get currentPeriod => _value('currentPeriod');
  String get expiration => _value('expiration');
  String get noExpiration => _value('noExpiration');
  String get permissionViewFailure => _value('permissionViewFailure');
  String get invalidStatusFailure => _value('invalidStatusFailure');
  String get genericFailure => _value('genericFailure');
  String get free => _value('free');
  String get usageTitle => _value('usageTitle');
  String get usageDescription => _value('usageDescription');
  String get usageOverCap => _value('usageOverCap');
  String get usageNearCap => _value('usageNearCap');
  String get usageAtCap => _value('usageAtCap');
  String get usageNormal => _value('usageNormal');
  String get usageOutputsUnaffected => _value('usageOutputsUnaffected');
  String get usageRefreshing => _value('usageRefreshing');
  String get refreshUsage => _value('refreshUsage');
  String get capacityRequestTitle => _value('capacityRequestTitle');
  String get capacityRequestDescription => _value('capacityRequestDescription');
  String get capacityRequestButton => _value('capacityRequestButton');
  String get capacityRequestFailed => _value('capacityRequestFailed');
  String get entitlementInactiveNotice => _value('entitlementInactiveNotice');
  String resourceLabel(EntitlementResource resource) => switch (resource) {
    EntitlementResource.ownerCreatedCompanies => _value('companies'),
    EntitlementResource.companyUsers => users,
    EntitlementResource.customers => customers,
    EntitlementResource.drivers => drivers,
    EntitlementResource.combinedVehicles => vehicles,
    EntitlementResource.routes => routes,
    EntitlementResource.lifetimeTrips => lifetimeTrips,
    EntitlementResource.lifetimeInvoices => lifetimeInvoices,
    EntitlementResource.businessDocuments => businessDocuments,
  };

  String featureLabel(EntitlementFeature feature) => switch (feature) {
    EntitlementFeature.companyBranding => _value('featureCompanyBranding'),
    EntitlementFeature.invoicePdf => _value('featureInvoicePdf'),
    EntitlementFeature.reportPdf => _value('featureReportPdf'),
    EntitlementFeature.reportXlsx => _value('featureReportXlsx'),
    EntitlementFeature.documentUpload => documentUpload,
    EntitlementFeature.driverApp => driverApp,
    EntitlementFeature.advancedReports => advancedReports,
    EntitlementFeature.maintenance => maintenance,
    EntitlementFeature.whatsappNotifications => whatsappNotifications,
  };

  String quotaLevelLabel(QuotaUsageLevel level) => switch (level) {
    QuotaUsageLevel.normal => usageNormal,
    QuotaUsageLevel.nearLimit => usageNearCap,
    QuotaUsageLevel.atLimit => usageAtCap,
    QuotaUsageLevel.overLimit => usageOverCap,
    QuotaUsageLevel.unlimited => unlimited,
  };

  String usageRemaining(int count) =>
      _value('usageRemaining').replaceFirst('{count}', count.toString());

  String usageCount(int used, String max) => _value(
    'usageCount',
  ).replaceFirst('{used}', used.toString()).replaceFirst('{max}', max);

  String pricePerMonth(String price) {
    return _value('pricePerMonth').replaceFirst('{price}', price);
  }

  String limitValue(int value) {
    return _value('limitValue').replaceFirst('{value}', value.toString());
  }

  String periodRange(String start, String end) {
    return _value(
      'periodRange',
    ).replaceFirst('{start}', start).replaceFirst('{end}', end);
  }

  String planName(String code, String fallback) {
    return switch (code) {
      'free_starter' => _value('planFreeStarter'),
      'basic' => _value('planBasic'),
      'pro' => _value('planPro'),
      'enterprise' => _value('planEnterprise'),
      _ => fallback,
    };
  }

  String entitlementStatusLabel(CompanyEntitlementStatus status) {
    return switch (status) {
      CompanyEntitlementStatus.active => _value('statusActive'),
      CompanyEntitlementStatus.suspended => _value('statusSuspended'),
      CompanyEntitlementStatus.expired => _value('statusExpired'),
      CompanyEntitlementStatus.revoked => _value('statusRevoked'),
    };
  }

  String statusLabel(SubscriptionStatus status) {
    return switch (status) {
      SubscriptionStatus.trialing => _value('statusTrialing'),
      SubscriptionStatus.active => _value('statusActive'),
      SubscriptionStatus.pastDue => _value('statusPastDue'),
      SubscriptionStatus.cancelled => _value('statusCancelled'),
      SubscriptionStatus.expired => _value('statusExpired'),
      SubscriptionStatus.suspended => _value('statusSuspended'),
    };
  }

  static const Map<String, String> _en = {
    'companies': 'Companies',
    'usageNormal': 'Within limit',
    'usageNearCap': 'Approaching the plan limit',
    'usageAtCap': 'Plan limit reached; existing records remain accessible.',
    'usageOutputsUnaffected':
        'Reaching a quota does not remove existing records or basic PDF/XLSX exports.',
    'usageRefreshing': 'Refreshing server usage; values may be outdated.',
    'refreshUsage': 'Refresh usage',
    'capacityRequestTitle': 'Need more capacity?',
    'capacityRequestDescription':
        'Ask support to review the company limits. No upgrade is applied automatically.',
    'capacityRequestButton': 'Request more capacity',
    'capacityRequestFailed': 'Could not open the support page.',
    'entitlementInactiveNotice':
        'This plan is not currently effective. Features shown are not active access.',
    'featureCompanyBranding': 'Company branding',
    'featureInvoicePdf': 'Invoice PDF',
    'featureReportPdf': 'Report PDF',
    'featureReportXlsx': 'Report Excel (XLSX)',
    'usageTitle': 'Current resource usage',
    'usageDescription':
        'Server-verified active, lifetime and reserved-seat usage.',
    'usageOverCap': 'Above the plan limit; existing records remain accessible.',
    'usageRemaining': '{count} remaining',
    'usageCount': '{used} of {max} used',
    'title': 'Subscriptions',
    'description':
        'Review this company’s current access plan and expiration status.',
    'currentPlan': 'Current plan',
    'availablePlans': 'Available plans',
    'noCurrentSubscription':
        'This company does not have a subscription record yet.',
    'noAvailablePlans': 'No active subscription plans are available.',
    'loading': 'Loading subscriptions...',
    'loadFailed': 'Subscriptions could not be loaded.',
    'retry': 'Retry',
    'planLimits': 'Limits',
    'planFeatures': 'Features',
    'unlimited': 'Unlimited',
    'users': 'Users',
    'vehicles': 'Vehicles',
    'customers': 'Customers',
    'drivers': 'Drivers',
    'routes': 'Routes',
    'lifetimeTrips': 'Trips created (lifetime)',
    'lifetimeInvoices': 'Invoices created (lifetime)',
    'businessDocuments': 'Business documents',
    'tripsPerMonth': 'Trips per month',
    'driverApp': 'Driver app',
    'advancedReports': 'Advanced reports',
    'documentUpload': 'Document upload',
    'maintenance': 'Maintenance',
    'whatsappNotifications': 'WhatsApp notifications',
    'included': 'Included',
    'notIncluded': 'Not included',
    'status': 'Status',
    'trialEndsAt': 'Trial ends',
    'currentPeriod': 'Current period',
    'expiration': 'Expires',
    'noExpiration': 'No expiration',
    'statusRevoked': 'Revoked',
    'permissionViewFailure':
        'Only the company owner or administrator can view this plan.',
    'invalidStatusFailure': 'The subscription status is not supported.',
    'genericFailure': 'The subscription information could not be loaded.',
    'free': 'Free',
    'pricePerMonth': '{price} / month',
    'limitValue': '{value}',
    'periodRange': '{start} to {end}',
    'planFreeStarter': 'Free Starter',
    'planBasic': 'Basic',
    'planPro': 'Pro',
    'planEnterprise': 'Enterprise',
    'statusTrialing': 'Trialing',
    'statusActive': 'Active',
    'statusPastDue': 'Past due',
    'statusCancelled': 'Cancelled',
    'statusExpired': 'Expired',
    'statusSuspended': 'Suspended',
  };

  static const Map<String, String> _ar = {
    'companies': 'الشركات',
    'usageNormal': 'داخل الحد المسموح',
    'usageNearCap': 'الاقتراب من الحد المسموح',
    'usageAtCap': 'تم بلوغ الحد؛ تظل السجلات الحالية متاحة.',
    'usageOutputsUnaffected':
        'بلوغ الحصة لا يحذف السجلات الحالية ولا يمنع تصدير PDF أو Excel XLSX الأساسي.',
    'usageRefreshing':
        'جارٍ تحديث الاستخدام من الخادم؛ قد تكون الأرقام المعروضة قديمة.',
    'refreshUsage': 'تحديث الاستخدام',
    'capacityRequestTitle': 'محتاج سعة أكبر؟',
    'capacityRequestDescription':
        'اطلب من الدعم مراجعة حدود الشركة؛ لن تُمنح أي زيادة تلقائيًا.',
    'capacityRequestButton': 'طلب زيادة السعة',
    'capacityRequestFailed': 'تعذر فتح صفحة الدعم.',
    'entitlementInactiveNotice':
        'الخطة غير سارية حاليًا، وعرض المزايا لا يعني تفعيل صلاحية استخدامها.',
    'featureCompanyBranding': 'هوية الشركة',
    'featureInvoicePdf': 'فواتير PDF',
    'featureReportPdf': 'تقارير PDF',
    'featureReportXlsx': 'تقارير Excel XLSX',
    'usageTitle': 'استخدام موارد الشركة',
    'usageDescription':
        'الاستخدام النشط والتراكمي والمقاعد المحجوزة حسب سجلات الخادم.',
    'usageOverCap': 'تجاوز تاريخي للحد؛ تظل السجلات الحالية متاحة.',
    'usageRemaining': 'المتبقي {count}',
    'usageCount': 'المستخدم {used} من {max}',
    'title': 'الاشتراكات',
    'description': 'راجع خطة الوصول الحالية للشركة وحالة انتهاء صلاحيتها.',
    'currentPlan': 'الخطة الحالية',
    'availablePlans': 'الخطط المتاحة',
    'noCurrentSubscription': 'لا يوجد سجل اشتراك لهذه الشركة حتى الآن.',
    'noAvailablePlans': 'لا توجد خطط اشتراك نشطة متاحة.',
    'loading': 'جاري تحميل الاشتراكات...',
    'loadFailed': 'تعذر تحميل بيانات الاشتراكات.',
    'retry': 'إعادة المحاولة',
    'planLimits': 'الحدود',
    'planFeatures': 'المزايا',
    'unlimited': 'غير محدود',
    'users': 'المستخدمون',
    'vehicles': 'المركبات',
    'customers': 'العملاء',
    'drivers': 'السائقون',
    'routes': 'المسارات',
    'lifetimeTrips': 'الرحلات المُنشأة إجمالًا',
    'lifetimeInvoices': 'الفواتير المُنشأة إجمالًا',
    'businessDocuments': 'مستندات الأعمال',
    'tripsPerMonth': 'الرحلات شهريًا',
    'driverApp': 'تطبيق السائق',
    'advancedReports': 'تقارير متقدمة',
    'documentUpload': 'رفع المستندات',
    'maintenance': 'الصيانة',
    'whatsappNotifications': 'إشعارات واتساب',
    'included': 'متاح',
    'notIncluded': 'غير متاح',
    'status': 'الحالة',
    'trialEndsAt': 'نهاية الفترة التجريبية',
    'currentPeriod': 'الفترة الحالية',
    'expiration': 'تاريخ الانتهاء',
    'noExpiration': 'بدون تاريخ انتهاء',
    'statusRevoked': 'مسحوبة',
    'permissionViewFailure': 'يمكن لمالك الشركة أو مسؤولها فقط عرض هذه الخطة.',
    'invalidStatusFailure': 'حالة الاشتراك غير مدعومة.',
    'genericFailure': 'تعذر تحميل معلومات الاشتراك.',
    'free': 'مجانًا',
    'pricePerMonth': '{price} / شهر',
    'limitValue': '{value}',
    'periodRange': '{start} إلى {end}',
    'planFreeStarter': 'المجانية الأساسية',
    'planBasic': 'الأساسية',
    'planPro': 'الاحترافية',
    'planEnterprise': 'المؤسسات',
    'statusTrialing': 'تجريبية',
    'statusActive': 'نشطة',
    'statusPastDue': 'متأخرة الدفع',
    'statusCancelled': 'ملغاة',
    'statusExpired': 'منتهية',
    'statusSuspended': 'موقوفة',
  };
}

extension SubscriptionsLocalizationsContextX on BuildContext {
  SubscriptionsLocalizations get subscriptionsL10n =>
      SubscriptionsLocalizations.forLocale(Localizations.localeOf(this));
}
