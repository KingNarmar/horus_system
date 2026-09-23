import 'package:horus_system/features/company/domain/entities/company_role.dart';
import 'package:horus_system/features/company/data/models/company_user_model.dart';
import 'package:test/test.dart';

void main() {
  test('maps inactive member identity from management RPC row', () {
    final model = CompanyUserModel.fromRpcMap({
      'membership_id': 'membership-1',
      'company_id': 'company-1',
      'user_id': 'user-1',
      'member_role': 'driver',
      'is_active': false,
      'full_name': 'H.O.R.U.S Driver Test',
      'phone': null,
    });

    expect(model.id, 'membership-1');
    expect(model.companyId, 'company-1');
    expect(model.userId, 'user-1');
    expect(model.role, CompanyRole.driver);
    expect(model.isActive, isFalse);
    expect(model.displayName, 'H.O.R.U.S Driver Test');
    expect(model.phone, isNull);
  });

  test('rejects unsupported role values from management RPC', () {
    expect(
      () => CompanyUserModel.fromRpcMap({
        'membership_id': 'membership-1',
        'company_id': 'company-1',
        'user_id': 'user-1',
        'member_role': 'unsupported-role',
        'is_active': true,
        'full_name': 'Member',
        'phone': null,
      }),
      throwsA(isA<FormatException>()),
    );
  });
}
