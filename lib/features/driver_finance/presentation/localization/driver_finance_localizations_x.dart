import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/driver_financial_movement_type.dart';

extension DriverFinanceLocalizationsX on AppLocalizations {
  bool get _isArabicDriverFinance => localeName.startsWith('ar');

  String get driverFinanceTitle =>
      _isArabicDriverFinance ? 'حركات السائق المالية' : 'Driver finance';

  String get driverBalancePlaceholderTitle =>
      _isArabicDriverFinance ? 'رصيد السائق' : 'Driver balance';

  String get driverBalancePlaceholderDescription => _isArabicDriverFinance
      ? 'رصيد مبدئي محسوب من السلف والخصومات المسجلة حاليًا. التسوية الشهرية ستنفذ لاحقًا.'
      : 'Initial balance calculated from recorded advances and deductions. Monthly settlement will be implemented later.';

  String get addDriverAdvanceButton =>
      _isArabicDriverFinance ? 'إضافة سلفة' : 'Add advance';

  String get addDriverDeductionButton =>
      _isArabicDriverFinance ? 'إضافة خصم' : 'Add deduction';

  String get addDriverAdvanceTitle =>
      _isArabicDriverFinance ? 'إضافة سلفة للسائق' : 'Add driver advance';

  String get addDriverDeductionTitle =>
      _isArabicDriverFinance ? 'إضافة خصم للسائق' : 'Add driver deduction';

  String get driverMovementAmountLabel =>
      _isArabicDriverFinance ? 'المبلغ' : 'Amount';

  String get driverMovementDateLabel =>
      _isArabicDriverFinance ? 'التاريخ' : 'Date';

  String get driverMovementTripIdLabel => _isArabicDriverFinance
      ? 'معرّف الرحلة (اختياري)'
      : 'Trip id (optional)';

  String get driverMovementTripPickerComingSoon => _isArabicDriverFinance
      ? 'اختيار الرحلة سيتم لاحقًا من قائمة الرحلات. سيتم حفظ هذا الخصم كخصم عام الآن.'
      : 'Trip selection will be added later. This deduction will be saved as a general deduction for now.';

  String get driverMovementNotesLabel =>
      _isArabicDriverFinance ? 'ملاحظات' : 'Notes';

  String get totalAdvancesLabel =>
      _isArabicDriverFinance ? 'إجمالي السلف' : 'Total advances';

  String get totalDeductionsLabel =>
      _isArabicDriverFinance ? 'إجمالي الخصومات' : 'Total deductions';

  String get netDriverBalanceLabel =>
      _isArabicDriverFinance ? 'الرصيد الحالي' : 'Current balance';

  String get noDriverFinancialMovements => _isArabicDriverFinance
      ? 'لا توجد حركات مالية بعد.'
      : 'No financial movements yet.';

  String get loadingDriverFinancialMovements => _isArabicDriverFinance
      ? 'جاري تحميل الحركات المالية...'
      : 'Loading driver financial movements...';

  String get savingDriverFinancialMovement =>
      _isArabicDriverFinance ? 'جاري الحفظ...' : 'Saving...';

  String get invalidDriverMovementAmount => _isArabicDriverFinance
      ? 'أدخل مبلغ صحيح أكبر من صفر.'
      : 'Enter a valid amount greater than zero.';

  String get driverMovementTripLine =>
      _isArabicDriverFinance ? 'الرحلة' : 'Trip';

  String driverMovementTypeLabel(DriverFinancialMovementType type) {
    return switch (type) {
      DriverFinancialMovementType.advance =>
        _isArabicDriverFinance ? 'سلفة' : 'Advance',
      DriverFinancialMovementType.deduction =>
        _isArabicDriverFinance ? 'خصم' : 'Deduction',
    };
  }
}
