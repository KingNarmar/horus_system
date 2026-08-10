import 'package:horus_system/features/payment_methods/data/mappers/payment_method_mapper.dart';
import 'package:horus_system/features/payment_methods/data/models/payment_method_model.dart';
import 'package:horus_system/features/payment_methods/domain/entities/payment_method_write_data.dart';
import 'package:test/test.dart';

void main() {
  test('model maps persistence fields to a pure domain entity', () {
    final model = PaymentMethodModel(
      id: 'method-1',
      companyId: 'company-1',
      name: 'Cash',
      code: 'cash',
      isActive: true,
      createdBy: 'user-1',
      createdAt: DateTime.utc(2026, 8, 10),
    );

    final entity = model.toEntity();

    expect(entity.id, 'method-1');
    expect(entity.companyId, 'company-1');
    expect(entity.name, 'Cash');
    expect(entity.isActive, isTrue);
  });

  test('audit mapper preserves stable persistence values', () {
    final model = PaymentMethodModel(
      id: 'method-1',
      companyId: 'company-1',
      name: 'Cash',
      code: 'cash',
      isActive: false,
      createdBy: 'user-1',
      updatedBy: 'user-2',
      createdAt: DateTime.utc(2026, 8, 9),
      updatedAt: DateTime.utc(2026, 8, 10),
    );

    final values = model.toAuditValues();

    expect(values['company_id'], 'company-1');
    expect(values['name'], 'Cash');
    expect(values['code'], 'cash');
    expect(values['is_active'], isFalse);
    expect(values['created_by'], 'user-1');
    expect(values['updated_by'], 'user-2');
  });

  test('write mapper keeps persistence names out of domain write data', () {
    const data = PaymentMethodWriteData(
      companyId: 'company-1',
      name: 'Bank Transfer',
    );

    expect(data.toInsertMap(), {
      'company_id': 'company-1',
      'name': 'Bank Transfer',
    });
    expect(data.toUpdateMap(), {'name': 'Bank Transfer'});
  });
}
