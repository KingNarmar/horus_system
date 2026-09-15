import 'package:horus_system/core/errors/failure.dart';
import 'package:horus_system/core/utils/result.dart';
import 'package:horus_system/features/expense_types/domain/entities/expense_type.dart';
import 'package:horus_system/features/expense_types/domain/repositories/expense_types_repository.dart';

final class FakeExpenseTypesRepository implements ExpenseTypesRepository {
  List<ExpenseType> types = const [];
  List<ExpenseType> activeTypes = const [];
  List<ExpenseType> ledgerEligibleTypes = const [];
  Failure? nextFailure;
  String? lastCatalogCompanyId;
  String? lastActiveCompanyId;
  String? lastLedgerEligibleCompanyId;
  int getAllCalls = 0;
  int getActiveCalls = 0;
  int getLedgerEligibleCalls = 0;

  @override
  Future<Result<List<ExpenseType>>> getExpenseTypes({
    required String companyId,
  }) async {
    getAllCalls += 1;
    lastCatalogCompanyId = companyId;
    final failure = nextFailure;
    if (failure != null) return FailureResult(failure);
    return Success(types);
  }

  @override
  Future<Result<List<ExpenseType>>> getActiveExpenseTypes({
    required String companyId,
  }) async {
    getActiveCalls += 1;
    lastActiveCompanyId = companyId;
    final failure = nextFailure;
    if (failure != null) return FailureResult(failure);
    return Success(activeTypes);
  }

  @override
  Future<Result<List<ExpenseType>>> getLedgerEligibleExpenseTypes({
    required String companyId,
  }) async {
    getLedgerEligibleCalls += 1;
    lastLedgerEligibleCompanyId = companyId;
    final failure = nextFailure;
    if (failure != null) return FailureResult(failure);
    return Success(ledgerEligibleTypes);
  }
}
