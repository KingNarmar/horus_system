import 'package:horus_system/core/errors/common_failures.dart';
import 'package:horus_system/features/expenses/data/repositories/expense_ledger_repository_failure_mapper.dart';
import 'package:horus_system/features/expenses/domain/failures/expense_ledger_failure_codes.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show PostgrestException;
import 'package:test/test.dart';

void main() {
  group('ExpenseLedgerRepositoryFailureMapper', () {
    const mapper = ExpenseLedgerRepositoryFailureMapper();

    test('maps permission SQLSTATE without leaking backend text', () {
      const error = PostgrestException(
        message: 'sensitive permission detail',
        code: 'P2801',
      );

      final failure = mapper.fromPostgrest(error);

      expect(failure, isA<PermissionFailure>());
      expect(failure.code, ExpenseLedgerFailureCodes.permissionManage);
      expect(failure.message, isNull);
    });

    test('maps financial readiness and currency failures', () {
      const readinessError = PostgrestException(message: 'sensitive', code: 'P2804');
      const currencyError = PostgrestException(message: 'sensitive', code: 'P2805');

      expect(
        mapper.fromPostgrest(readinessError).code,
        ExpenseLedgerFailureCodes.financialConfigurationRequired,
      );
      expect(
        mapper.fromPostgrest(currencyError).code,
        ExpenseLedgerFailureCodes.currencyMismatch,
      );
    });

    test('maps amount, funding, and description validation failures', () {
      const amountError = PostgrestException(message: 'sensitive', code: 'P2808');
      const fundingError = PostgrestException(message: 'sensitive', code: 'P2809');
      const descriptionError = PostgrestException(
        message: 'sensitive description detail',
        code: 'P2810',
      );

      expect(
        mapper.fromPostgrest(amountError).code,
        ExpenseLedgerFailureCodes.validationAmountInvalid,
      );
      expect(
        mapper.fromPostgrest(fundingError).code,
        ExpenseLedgerFailureCodes.validationFundingSourceInvalid,
      );
      final descriptionFailure = mapper.fromPostgrest(descriptionError);
      expect(descriptionFailure, isA<ValidationFailure>());
      expect(
        descriptionFailure.code,
        ExpenseLedgerFailureCodes.validationDescriptionRequired,
      );
      expect(descriptionFailure.message, isNull);
    });

    test('sanitizes unknown Postgrest failure', () {
      const error = PostgrestException(message: 'database internals', code: 'XXXXX');

      final failure = mapper.fromPostgrest(error);

      expect(failure, isA<ServerFailure>());
      expect(failure.code, ExpenseLedgerFailureCodes.serverError);
      expect(failure.message, isNull);
    });
  });
}
