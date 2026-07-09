import '../../../../core/utils/result.dart';
import '../entities/company_expense.dart';
import '../entities/company_expense_category.dart';
import '../entities/company_expense_form_lookups.dart';
import '../entities/company_expense_void_data.dart';
import '../entities/company_expense_write_data.dart';

abstract class CompanyExpensesRepository {
  Future<Result<List<CompanyExpenseCategory>>> getCategories({
    required String companyId,
    bool includeInactive = false,
  });

  Future<Result<List<CompanyExpense>>> getCompanyExpenses({
    required String companyId,
    bool includeVoided = false,
  });

  Future<Result<CompanyExpenseFormLookups>> getFormLookups({
    required String companyId,
  });

  Future<Result<CompanyExpense>> addCompanyExpense({
    required CompanyExpenseWriteData data,
    required String actorRole,
  });

  Future<Result<CompanyExpense>> updateCompanyExpense({
    required String id,
    required CompanyExpenseWriteData data,
    required String actorRole,
  });

  Future<Result<CompanyExpense>> voidCompanyExpense({
    required CompanyExpenseVoidData data,
    required String actorRole,
  });
}
