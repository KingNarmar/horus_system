import 'package:horus_system/features/expenses/data/mappers/expense_ledger_mapper.dart';
import 'package:horus_system/features/expenses/data/models/expense_ledger_entry_model.dart';
import 'package:horus_system/features/expenses/domain/entities/expense_funding_source.dart';
import 'package:test/test.dart';

void main() {
  group('ExpenseLedgerEntryModelMapper', () {
    test('maps exact money business date funding and attribution', () {
      const model = ExpenseLedgerEntryModel(
        id: 'expense-1',
        companyId: 'company-1',
        expenseTypeId: 'type-1',
        amountMinorUnits: 12345,
        currencyCode: 'AED',
        currencyFractionDigits: 2,
        expenseDate: '2026-09-15',
        fundingSource: 'driver_advance',
        tripId: 'trip-1',
        isVoided: false,
      );

      final entity = model.toEntity();

      expect(entity.amount.minorUnits, 12345);
      expect(entity.amount.currency.value, 'AED');
      expect(entity.currencyFractionDigits, 2);
      expect(entity.expenseDate.year, 2026);
      expect(entity.expenseDate.month, 9);
      expect(entity.expenseDate.day, 15);
      expect(entity.fundingSource, ExpenseFundingSource.driverAdvance);
      expect(entity.attribution.tripId, 'trip-1');
      expect(entity.attribution.driverId, isNull);
    });

    test('rejects unsupported funding source from persistence', () {
      const model = ExpenseLedgerEntryModel(
        id: 'expense-1',
        companyId: 'company-1',
        expenseTypeId: 'type-1',
        amountMinorUnits: 100,
        currencyCode: 'AED',
        currencyFractionDigits: 2,
        expenseDate: '2026-09-15',
        fundingSource: 'unsupported',
        isVoided: false,
      );

      expect(model.toEntity, throwsFormatException);
    });
  });
}
