import 'package:horus_system/features/company/data/models/company_user_model.dart';
import 'package:horus_system/features/company/domain/entities/company_role.dart';
import 'package:test/test.dart';

void main() {
  group('CompanyUserModel.fromRpcMap', () {
    test('keeps optional profile fields null when profile data is absent', () {
      final model = CompanyUserModel.fromRpcMap(_rpcRow);

      expect(model.displayName, isNull);
      expect(model.phone, isNull);
      expect(model.id, 'company-user-1');
      expect(model.companyId, 'company-1');
      expect(model.userId, 'user-1');
      expect(model.role, CompanyRole.admin);
      expect(model.isActive, isTrue);
    });

    test('preserves an available display name when phone is absent', () {
      final model = CompanyUserModel.fromRpcMap({
        ..._rpcRow,
        'full_name': 'Company Admin',
      });

      expect(model.displayName, 'Company Admin');
      expect(model.phone, isNull);
    });

    test('preserves all available profile fields', () {
      final model = CompanyUserModel.fromRpcMap({
        ..._rpcRow,
        'full_name': 'Company Admin',
        'phone': '+971500000001',
      });

      expect(model.displayName, 'Company Admin');
      expect(model.phone, '+971500000001');
    });
  });
}

const _rpcRow = <String, dynamic>{
  'membership_id': 'company-user-1',
  'company_id': 'company-1',
  'user_id': 'user-1',
  'member_role': 'admin',
  'is_active': true,
  'full_name': null,
  'phone': null,
};
