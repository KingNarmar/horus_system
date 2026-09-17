import 'package:horus_system/core/domain/value_objects/business_date.dart';
import 'package:horus_system/core/domain/value_objects/currency_code.dart';
import 'package:horus_system/core/domain/value_objects/money.dart';
import 'package:horus_system/features/drivers/data/mappers/driver_compensation_mapper.dart';
import 'package:horus_system/features/drivers/data/models/driver_compensation_model.dart';
import 'package:horus_system/features/drivers/domain/entities/driver_compensation_write_data.dart';
import 'package:test/test.dart';

void main() {
  group('DriverCompensationModelMapper', () {
    test('maps exact money and effective dates to Domain', () {
      const model = DriverCompensationModel(
        id: 'revision-1',
        companyId: 'company-1',
        driverId: 'driver-1',
        amountMinorUnits: 550000,
        currencyCode: 'AED',
        currencyFractionDigits: 2,
        effectiveFrom: '2026-08-01',
        effectiveTo: '2026-12-31',
        contractReference: 'EMP-002',
        contractDocumentReference:
            'companies/11111111-1111-1111-1111-111111111111/driver-compensation/22222222-2222-2222-2222-222222222222/employment-contract/aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa.pdf',
      );

      final entity = model.toEntity();

      expect(entity.amount.minorUnits, 550000);
      expect(entity.amount.currency.value, 'AED');
      expect(entity.currencyFractionDigits, 2);
      expect(entity.effectiveFrom, BusinessDate(year: 2026, month: 8, day: 1));
      expect(entity.effectiveTo, BusinessDate(year: 2026, month: 12, day: 31));
      expect(entity.contractReference, 'EMP-002');
      expect(entity.contractDocumentReference, isNotNull);
    });

    test('maps write data to canonical database fields', () {
      final data = DriverCompensationWriteData(
        companyId: 'company-1',
        driverId: 'driver-1',
        amount: Money(
          minorUnits: 500000,
          currency: CurrencyCode.tryParse('AED')!,
        ),
        currencyFractionDigits: 2,
        effectiveFrom: BusinessDate(year: 2026, month: 1, day: 1),
        effectiveTo: BusinessDate(year: 2026, month: 7, day: 31),
        contractReference: 'EMP-001',
      );

      final map = data.toInsertMap(revisionId: 'revision-1');

      expect(map['id'], 'revision-1');
      expect(map['company_id'], 'company-1');
      expect(map['driver_id'], 'driver-1');
      expect(map['amount_minor_units'], 500000);
      expect(map['currency_code'], 'AED');
      expect(map['currency_fraction_digits'], 2);
      expect(map['effective_from'], '2026-01-01');
      expect(map['effective_to'], '2026-07-31');
      expect(map['contract_reference'], 'EMP-001');
      expect(map['contract_document_reference'], isNull);
    });
  });
}
