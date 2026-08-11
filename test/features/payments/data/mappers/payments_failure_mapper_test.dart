import 'package:horus_system/core/errors/common_failures.dart';
import 'package:horus_system/core/errors/failure_codes.dart';
import 'package:horus_system/features/company/domain/failures/company_failure_codes.dart';
import 'package:horus_system/features/payments/data/constants/payments_db_constants.dart';
import 'package:horus_system/features/payments/data/mappers/payments_failure_mapper.dart';
import 'package:horus_system/features/payments/domain/failures/payment_failure_codes.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:test/test.dart';

void main() {
  group('PaymentsFailureMapper', () {
    test('maps payment permission using supplied domain code', () {
      final failure = PaymentsFailureMapper.fromPostgrest(
        const PostgrestException(
          message: 'permission denied',
          code: PaymentsRpcErrorCodes.permissionDenied,
        ),
        permissionCode: PaymentFailureCodes.permissionManage,
      );

      expect(failure, isA<PermissionFailure>());
      expect(failure.code, PaymentFailureCodes.permissionManage);
    });

    test('maps overpayment and inactive method as typed conflicts', () {
      final overpayment = PaymentsFailureMapper.fromPostgrest(
        const PostgrestException(
          message: 'payment_overpayment',
          code: PaymentsRpcErrorCodes.overpayment,
        ),
        permissionCode: PaymentFailureCodes.permissionManage,
      );
      final inactive = PaymentsFailureMapper.fromPostgrest(
        const PostgrestException(
          message: 'payment_method_inactive',
          code: PaymentsRpcErrorCodes.paymentMethodInactive,
        ),
        permissionCode: PaymentFailureCodes.permissionManage,
      );

      expect(overpayment, isA<ConflictFailure>());
      expect(overpayment.code, PaymentFailureCodes.conflictOverpayment);
      expect(inactive, isA<ConflictFailure>());
      expect(inactive.code, PaymentFailureCodes.conflictPaymentMethodInactive);
    });

    test('maps regional settings failure without exposing DB text', () {
      final failure = PaymentsFailureMapper.fromPostgrest(
        const PostgrestException(
          message: 'internal database wording',
          code: PaymentsRpcErrorCodes.regionalSettingsNotConfigured,
        ),
        permissionCode: PaymentFailureCodes.permissionManage,
      );

      expect(failure, isA<ConflictFailure>());
      expect(
        failure.code,
        CompanyFailureCodes.conflictRegionalSettingsNotConfigured,
      );
      expect(failure.message, isNull);
    });

    test('maps direct table privilege denial to permission failure', () {
      final failure = PaymentsFailureMapper.fromPostgrest(
        const PostgrestException(message: 'permission denied', code: '42501'),
        permissionCode: PaymentFailureCodes.permissionView,
      );

      expect(failure, isA<PermissionFailure>());
      expect(failure.code, PaymentFailureCodes.permissionView);
    });

    test('sanitizes unknown persistence failures', () {
      final failure = PaymentsFailureMapper.fromPostgrest(
        const PostgrestException(
          message: 'secret backend details',
          code: 'XX999',
          details: 'private schema detail',
          hint: 'internal hint',
        ),
        permissionCode: PaymentFailureCodes.permissionView,
      );

      expect(failure, isA<ServerFailure>());
      expect(failure.code, FailureCodes.serverError);
      expect(failure.message, isNull);
    });
  });
}
