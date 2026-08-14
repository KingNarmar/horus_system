import 'package:flutter/widgets.dart';

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
  String get permissionViewFailure => _value('permissionViewFailure');
  String get invalidStatusFailure => _value('invalidStatusFailure');
  String get genericFailure => _value('genericFailure');
  String get free => _value('free');

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
      'basic' => _value('planBasic'),
      'pro' => _value('planPro'),
      'enterprise' => _value('planEnterprise'),
      _ => fallback,
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
    'title': 'Subscriptions',
    'description':
        'Review this company subscription status, available plans, and MVP plan limits.',
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
    'permissionViewFailure': 'Only the company owner can view subscriptions.',
    'invalidStatusFailure': 'The subscription status is not supported.',
    'genericFailure': 'The subscription information could not be loaded.',
    'free': 'Free',
    'pricePerMonth': '{price} / month',
    'limitValue': '{value}',
    'periodRange': '{start} to {end}',
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
    'title': 'الاشتراكات',
    'description':
        'مراجعة حالة اشتراك الشركة والخطط المتاحة وحدود الخطط الأولية.',
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
    'permissionViewFailure': 'يمكن لمالك الشركة فقط عرض الاشتراكات.',
    'invalidStatusFailure': 'حالة الاشتراك غير مدعومة.',
    'genericFailure': 'تعذر تحميل معلومات الاشتراك.',
    'free': 'مجانًا',
    'pricePerMonth': '{price} / شهر',
    'limitValue': '{value}',
    'periodRange': '{start} إلى {end}',
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
