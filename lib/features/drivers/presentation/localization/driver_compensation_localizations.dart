import 'package:flutter/widgets.dart';

import '../../../../core/errors/failure.dart';
import '../../../../core/localization/app_localizations_extension.dart';
import '../../../../core/localization/financial_readiness_localizations.dart';
import '../../../company/domain/failures/company_failure_codes.dart';
import '../../domain/failures/driver_compensation_failure_codes.dart';

final class DriverCompensationLocalizations {
  final String sectionTitle;
  final String currentCompensation;
  final String history;
  final String noHistory;
  final String noCurrentCompensation;
  final String addRevision;
  final String addRevisionTitle;
  final String amountLabel;
  final String effectiveFromLabel;
  final String effectiveToLabel;
  final String ongoingLabel;
  final String contractReferenceLabel;
  final String contractDocumentLabel;
  final String noContractDocument;
  final String chooseContractDocument;
  final String attachContractDocument;
  final String openContractDocument;
  final String endRevision;
  final String endRevisionTitle;
  final String selectedFileLabel;
  final String save;
  final String cancel;
  final String saving;
  final String filePickerFailed;
  final String openDocumentFailed;
  final String permissionView;
  final String permissionManage;
  final String amountPositive;
  final String currencyMismatch;
  final String invalidPeriod;
  final String invalidContractReference;
  final String overlap;
  final String alreadyEnded;
  final String documentAlreadyAttached;
  final String documentNotFound;
  final String revisionNotFound;
  final String driverNotFound;
  final String notFoundForDate;
  final String serverError;
  final String unexpectedError;

  const DriverCompensationLocalizations._({
    required this.sectionTitle,
    required this.currentCompensation,
    required this.history,
    required this.noHistory,
    required this.noCurrentCompensation,
    required this.addRevision,
    required this.addRevisionTitle,
    required this.amountLabel,
    required this.effectiveFromLabel,
    required this.effectiveToLabel,
    required this.ongoingLabel,
    required this.contractReferenceLabel,
    required this.contractDocumentLabel,
    required this.noContractDocument,
    required this.chooseContractDocument,
    required this.attachContractDocument,
    required this.openContractDocument,
    required this.endRevision,
    required this.endRevisionTitle,
    required this.selectedFileLabel,
    required this.save,
    required this.cancel,
    required this.saving,
    required this.filePickerFailed,
    required this.openDocumentFailed,
    required this.permissionView,
    required this.permissionManage,
    required this.amountPositive,
    required this.currencyMismatch,
    required this.invalidPeriod,
    required this.invalidContractReference,
    required this.overlap,
    required this.alreadyEnded,
    required this.documentAlreadyAttached,
    required this.documentNotFound,
    required this.revisionNotFound,
    required this.driverNotFound,
    required this.notFoundForDate,
    required this.serverError,
    required this.unexpectedError,
  });

  factory DriverCompensationLocalizations.forLocale(Locale locale) {
    return locale.languageCode == 'ar' ? _arabic : _english;
  }

  static const _english = DriverCompensationLocalizations._(
    sectionTitle: 'Compensation & employment contract',
    currentCompensation: 'Current compensation',
    history: 'Compensation history',
    noHistory: 'No compensation history has been recorded yet.',
    noCurrentCompensation:
        'No compensation is effective on the current business date.',
    addRevision: 'Add compensation revision',
    addRevisionTitle: 'Add compensation revision',
    amountLabel: 'Compensation amount',
    effectiveFromLabel: 'Effective from',
    effectiveToLabel: 'Effective to',
    ongoingLabel: 'Ongoing',
    contractReferenceLabel: 'Contract reference',
    contractDocumentLabel: 'Signed contract attached',
    noContractDocument: 'No signed contract attached',
    chooseContractDocument: 'Choose contract file',
    attachContractDocument: 'Attach signed contract',
    openContractDocument: 'Open signed contract',
    endRevision: 'End revision',
    endRevisionTitle: 'End compensation revision',
    selectedFileLabel: 'Selected file',
    save: 'Save',
    cancel: 'Cancel',
    saving: 'Saving…',
    filePickerFailed: 'The contract file could not be read.',
    openDocumentFailed: 'The signed contract could not be opened.',
    permissionView: 'You do not have permission to view driver compensation.',
    permissionManage:
        'You do not have permission to manage driver compensation.',
    amountPositive: 'Compensation amount must be greater than zero.',
    currencyMismatch: 'Compensation currency must match the company currency.',
    invalidPeriod: 'The compensation effective period is invalid.',
    invalidContractReference: 'The contract reference is invalid.',
    overlap: 'This compensation period overlaps an existing revision.',
    alreadyEnded: 'This compensation revision has already ended.',
    documentAlreadyAttached:
        'A signed contract is already attached to this revision.',
    documentNotFound: 'No signed contract is attached to this revision.',
    revisionNotFound: 'The compensation revision could not be found.',
    driverNotFound: 'The driver could not be found for this company.',
    notFoundForDate: 'No compensation revision applies to this business date.',
    serverError: 'Driver compensation could not be loaded or saved.',
    unexpectedError: 'An unexpected driver compensation error occurred.',
  );

  static const _arabic = DriverCompensationLocalizations._(
    sectionTitle: 'التعويض وعقد العمل',
    currentCompensation: 'التعويض الحالي',
    history: 'سجل التعويضات',
    noHistory: 'لم يتم تسجيل أي تعويضات حتى الآن.',
    noCurrentCompensation: 'لا يوجد تعويض ساري في تاريخ العمل الحالي.',
    addRevision: 'إضافة تعديل تعويض',
    addRevisionTitle: 'إضافة تعديل تعويض',
    amountLabel: 'قيمة التعويض',
    effectiveFromLabel: 'ساري من',
    effectiveToLabel: 'ساري حتى',
    ongoingLabel: 'مستمر',
    contractReferenceLabel: 'مرجع العقد',
    contractDocumentLabel: 'العقد الموقّع مرفق',
    noContractDocument: 'لا يوجد عقد موقّع مرفق',
    chooseContractDocument: 'اختيار ملف العقد',
    attachContractDocument: 'إرفاق العقد الموقّع',
    openContractDocument: 'فتح العقد الموقّع',
    endRevision: 'إنهاء الفترة',
    endRevisionTitle: 'إنهاء فترة التعويض',
    selectedFileLabel: 'الملف المختار',
    save: 'حفظ',
    cancel: 'إلغاء',
    saving: 'جارٍ الحفظ…',
    filePickerFailed: 'تعذر قراءة ملف العقد.',
    openDocumentFailed: 'تعذر فتح العقد الموقّع.',
    permissionView: 'ليس لديك صلاحية لعرض تعويضات السائق.',
    permissionManage: 'ليس لديك صلاحية لإدارة تعويضات السائق.',
    amountPositive: 'يجب أن تكون قيمة التعويض أكبر من صفر.',
    currencyMismatch: 'يجب أن تطابق عملة التعويض عملة الشركة.',
    invalidPeriod: 'فترة سريان التعويض غير صحيحة.',
    invalidContractReference: 'مرجع العقد غير صحيح.',
    overlap: 'فترة التعويض تتداخل مع فترة مسجلة بالفعل.',
    alreadyEnded: 'تم إنهاء فترة التعويض هذه بالفعل.',
    documentAlreadyAttached: 'يوجد عقد موقّع مرفق بهذه الفترة بالفعل.',
    documentNotFound: 'لا يوجد عقد موقّع مرفق بهذه الفترة.',
    revisionNotFound: 'تعذر العثور على فترة التعويض.',
    driverNotFound: 'تعذر العثور على السائق داخل هذه الشركة.',
    notFoundForDate: 'لا توجد فترة تعويض تنطبق على تاريخ العمل هذا.',
    serverError: 'تعذر تحميل أو حفظ بيانات تعويض السائق.',
    unexpectedError: 'حدث خطأ غير متوقع في بيانات تعويض السائق.',
  );
}

extension DriverCompensationLocalizationsBuildContextX on BuildContext {
  DriverCompensationLocalizations get driverCompensationL10n =>
      DriverCompensationLocalizations.forLocale(Localizations.localeOf(this));
}

String driverCompensationFailureMessage(BuildContext context, Failure failure) {
  final l10n = context.driverCompensationL10n;
  return switch (failure.code) {
    DriverCompensationFailureCodes.permissionView => l10n.permissionView,
    DriverCompensationFailureCodes.permissionManage => l10n.permissionManage,
    DriverCompensationFailureCodes.validationAmountPositive =>
      l10n.amountPositive,
    DriverCompensationFailureCodes.validationCurrencyMismatch =>
      l10n.currencyMismatch,
    DriverCompensationFailureCodes.validationEffectivePeriodInvalid =>
      l10n.invalidPeriod,
    DriverCompensationFailureCodes.validationContractReferenceInvalid =>
      l10n.invalidContractReference,
    DriverCompensationFailureCodes.conflictOverlap => l10n.overlap,
    DriverCompensationFailureCodes.conflictRevisionAlreadyEnded =>
      l10n.alreadyEnded,
    DriverCompensationFailureCodes.conflictDocumentAlreadyAttached =>
      l10n.documentAlreadyAttached,
    DriverCompensationFailureCodes.notFoundDocument => l10n.documentNotFound,
    DriverCompensationFailureCodes.notFoundRevision => l10n.revisionNotFound,
    DriverCompensationFailureCodes.notFoundDriver => l10n.driverNotFound,
    DriverCompensationFailureCodes.notFoundForDate => l10n.notFoundForDate,
    DriverCompensationFailureCodes.serverError => l10n.serverError,
    DriverCompensationFailureCodes.unexpectedError => l10n.unexpectedError,
    CompanyFailureCodes.conflictFinancialSettingsNotConfigured =>
      context.financialReadinessL10n.configurationRequired,
    _ => context.l10n.localizedErrorMessage(failure),
  };
}
