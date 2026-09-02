import 'package:horus_system/core/errors/common_failures.dart';
import 'package:horus_system/core/errors/failure_codes.dart';
import 'package:horus_system/features/expense_types/data/repositories/expense_type_repository_failure_mapper.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:test/test.dart';

void main() {
  const mapper = ExpenseTypeRepositoryFailureMapper();

  test('maps normalized unique violation to typed duplicate conflict', () {
    const error = PostgrestException(message: 'duplicate', code: '23505');
    final failure = mapper.fromPostgrest(
      error,
      permissionCode: FailureCodes.permissionExpenseTypesManagement,
    );
    expect(failure, isA<ConflictFailure>());
    expect(failure.code, FailureCodes.conflictExpenseTypeDuplicateName);
    expect(failure.message, isNull);
  });

  test('maps row-not-found and permission errors without backend details', () {
    final notFound = mapper.fromPostgrest(
      const PostgrestException(message: 'detail', code: 'PGRST116'),
      permissionCode: FailureCodes.permissionExpenseTypesManagement,
    );
    final permission = mapper.fromPostgrest(
      const PostgrestException(message: 'detail', code: '42501'),
      permissionCode: FailureCodes.permissionExpenseTypesManagement,
    );
    expect(notFound, isA<NotFoundFailure>());
    expect(notFound.code, FailureCodes.expenseTypeNotFound);
    expect(notFound.message, isNull);
    expect(permission, isA<PermissionFailure>());
    expect(permission.code, FailureCodes.permissionExpenseTypesManagement);
    expect(permission.message, isNull);
  });
}
