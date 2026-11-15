import 'package:flutter/widgets.dart';

import '../../../../core/errors/failure.dart';
import '../../domain/failures/company_branding_failure_codes.dart';

final class CompanyBrandingLocalizations {
  final Map<String, String> _messages;

  const CompanyBrandingLocalizations._(this._messages);

  factory CompanyBrandingLocalizations.forLocale(Locale locale) =>
      locale.languageCode == 'ar'
          ? const CompanyBrandingLocalizations._(_ar)
          : const CompanyBrandingLocalizations._(_en);

  String _value(String key) => _messages[key]!;

  String get title => _value('title');
  String get description => _value('description');
  String get logoTitle => _value('logoTitle');
  String get logoOptional => _value('logoOptional');
  String get selectLogo => _value('selectLogo');
  String get replaceLogo => _value('replaceLogo');
  String get removeLogo => _value('removeLogo');
  String get noLogo => _value('noLogo');
  String get address => _value('address');
  String get registration => _value('registration');
  String get save => _value('save');
  String get saving => _value('saving');
  String get retry => _value('retry');
  String get uploadRetry => _value('uploadRetry');
  String get continueWithoutLogo => _value('continueWithoutLogo');
  String get createLogoRecovery => _value('createLogoRecovery');
  String get logoUpdated => _value('logoUpdated');
  String get logoRemoved => _value('logoRemoved');
  String get profileUpdated => _value('profileUpdated');
  String get nameRequired => _value('nameRequired');
  String get permissionDenied => _value('permissionDenied');
  String get profileInvalid => _value('profileInvalid');
  String get conflict => _value('conflict');
  String get companyUnavailable => _value('companyUnavailable');
  String get imageEmpty => _value('imageEmpty');
  String get imageTooLarge => _value('imageTooLarge');
  String get imageUnsupported => _value('imageUnsupported');
  String get imageReadFailed => _value('imageReadFailed');
  String get imageDownloadFailed => _value('imageDownloadFailed');
  String get cleanupPending => _value('cleanupPending');
  String get completionUnknown => _value('completionUnknown');
  String get operationFailed => _value('operationFailed');

  String errorMessage(Failure failure) => switch (failure.code) {
    CompanyBrandingFailureCodes.permissionDenied => permissionDenied,
    CompanyBrandingFailureCodes.profileInvalid ||
    CompanyBrandingFailureCodes.uploadInvalid => profileInvalid,
    CompanyBrandingFailureCodes.profileConflict ||
    CompanyBrandingFailureCodes.uploadConflict => conflict,
    CompanyBrandingFailureCodes.companyUnavailable => companyUnavailable,
    CompanyBrandingFailureCodes.imageEmpty => imageEmpty,
    CompanyBrandingFailureCodes.imageTooLarge => imageTooLarge,
    CompanyBrandingFailureCodes.imageUnsupported => imageUnsupported,
    CompanyBrandingFailureCodes.imageReadFailed => imageReadFailed,
    CompanyBrandingFailureCodes.logoReadFailed => imageDownloadFailed,
    CompanyBrandingFailureCodes.uploadCleanupPending => cleanupPending,
    CompanyBrandingFailureCodes.uploadCompletionUnknown => completionUnknown,
    _ => operationFailed,
  };

  static const _en = <String, String>{
    'title': 'Company profile and branding',
    'description': 'Business details used on future documents. Existing issued invoices keep their recorded identity.',
    'logoTitle': 'Company logo',
    'logoOptional': 'Optional. PNG, JPEG or WebP, up to 2 MB.',
    'selectLogo': 'Select logo',
    'replaceLogo': 'Replace logo',
    'removeLogo': 'Remove logo',
    'noLogo': 'No company logo selected.',
    'address': 'Business address',
    'registration': 'Registration / tax number (optional)',
    'save': 'Save company profile',
    'saving': 'Saving…',
    'retry': 'Retry',
    'uploadRetry': 'Retry logo upload',
    'continueWithoutLogo': 'Continue without logo',
    'createLogoRecovery': 'Your company was created successfully, but its logo could not be saved. Retry the logo or continue without it. The company will not be created again.',
    'logoUpdated': 'Company logo saved.',
    'logoRemoved': 'Company logo removed from the current profile. Historical invoices remain unchanged.',
    'profileUpdated': 'Company profile saved.',
    'nameRequired': 'Company name is required.',
    'permissionDenied': 'You do not have permission to edit company branding.',
    'profileInvalid': 'Review the company identity details and try again.',
    'conflict': 'Company profile changed elsewhere. Reload and retry.',
    'companyUnavailable': 'Company is not available. Select it again.',
    'imageEmpty': 'The selected image is empty.',
    'imageTooLarge': 'Company logos must be 2 MB or smaller.',
    'imageUnsupported': 'Select a valid PNG, JPEG or WebP image.',
    'imageReadFailed': 'Unable to read the selected image.',
    'imageDownloadFailed': 'Unable to display the private company logo.',
    'cleanupPending': 'The upload could not be fully recovered. Contact support before retrying.',
    'completionUnknown': 'The upload result is uncertain. Reload the company before trying again.',
    'operationFailed': 'Unable to update company branding. Please try again.',
  };

  static const _ar = <String, String>{
    'title': 'بيانات الشركة والهوية البصرية',
    'description': 'تُستخدم بيانات الشركة في المستندات الجديدة، وتظل بيانات الفواتير الصادرة سابقًا محفوظة كما هي.',
    'logoTitle': 'شعار الشركة',
    'logoOptional': 'اختياري. PNG أو JPEG أو WebP بحد أقصى ٢ ميجابايت.',
    'selectLogo': 'اختيار شعار',
    'replaceLogo': 'تغيير الشعار',
    'removeLogo': 'إزالة الشعار',
    'noLogo': 'لم يتم اختيار شعار للشركة.',
    'address': 'عنوان الشركة',
    'registration': 'رقم التسجيل / الرقم الضريبي (اختياري)',
    'save': 'حفظ بيانات الشركة',
    'saving': 'جارٍ الحفظ…',
    'retry': 'إعادة المحاولة',
    'uploadRetry': 'إعادة رفع الشعار',
    'continueWithoutLogo': 'المتابعة بدون شعار',
    'createLogoRecovery': 'تم إنشاء الشركة بنجاح، لكن تعذر حفظ الشعار. يمكنك إعادة رفعه أو المتابعة بدونه، ولن يتم إنشاء الشركة مرة أخرى.',
    'logoUpdated': 'تم حفظ شعار الشركة.',
    'logoRemoved': 'تمت إزالة الشعار الحالي مع الاحتفاظ بنسخ الفواتير القديمة.',
    'profileUpdated': 'تم حفظ بيانات الشركة.',
    'nameRequired': 'اسم الشركة مطلوب.',
    'permissionDenied': 'ليست لديك صلاحية تعديل بيانات الشركة أو شعارها.',
    'profileInvalid': 'راجع بيانات الشركة وحاول مجددًا.',
    'conflict': 'تم تعديل بيانات الشركة من مكان آخر. حدّث الصفحة وحاول مجددًا.',
    'companyUnavailable': 'الشركة غير متاحة. اخترها مرة أخرى.',
    'imageEmpty': 'ملف الصورة المحدد فارغ.',
    'imageTooLarge': 'يجب ألا يزيد حجم الشعار عن ٢ ميجابايت.',
    'imageUnsupported': 'اختر صورة PNG أو JPEG أو WebP صالحة.',
    'imageReadFailed': 'تعذر قراءة الصورة المحددة.',
    'imageDownloadFailed': 'تعذر عرض شعار الشركة المحمي.',
    'cleanupPending': 'تعذر إكمال معالجة فشل رفع الشعار. تواصل مع الدعم قبل إعادة المحاولة.',
    'completionUnknown': 'نتيجة رفع الشعار غير مؤكدة. حدّث بيانات الشركة قبل إعادة المحاولة.',
    'operationFailed': 'تعذر تعديل بيانات الشركة. حاول مجددًا.',
  };
}

extension CompanyBrandingLocalizationsX on BuildContext {
  CompanyBrandingLocalizations get companyBrandingL10n =>
      CompanyBrandingLocalizations.forLocale(Localizations.localeOf(this));
}
