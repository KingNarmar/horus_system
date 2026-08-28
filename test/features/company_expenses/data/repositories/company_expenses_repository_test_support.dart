import 'package:horus_system/core/errors/failure.dart';
import 'package:horus_system/core/utils/result.dart';
import 'package:horus_system/features/audit/domain/entities/audit_entity_type.dart';
import 'package:horus_system/features/audit/domain/entities/audit_log.dart';
import 'package:horus_system/features/audit/domain/entities/audit_log_write_data.dart';
import 'package:horus_system/features/audit/domain/entities/audit_module.dart';
import 'package:horus_system/features/audit/domain/repositories/audit_log_repository.dart';
import 'package:horus_system/features/audit/domain/usecases/create_audit_log_usecase.dart';
import 'package:horus_system/features/company_expenses/data/datasources/company_expenses_remote_data_source.dart';
import 'package:horus_system/features/company_expenses/data/models/company_expense_category_model.dart';
import 'package:horus_system/features/company_expenses/data/models/company_expense_form_lookups_model.dart';
import 'package:horus_system/features/company_expenses/data/models/company_expense_model.dart';
import 'package:horus_system/features/company_expenses/data/repositories/company_expenses_repository_impl.dart';
import 'package:horus_system/features/company_expenses/domain/entities/company_expense_void_data.dart';
import 'package:horus_system/features/company_expenses/domain/entities/company_expense_write_data.dart';

const testCompanyId = 'company-1';
const testExpenseId = 'expense-1';
const testCategoryId = 'category-1';

CompanyExpensesRepositoryImpl createCompanyExpensesRepository(
  FakeCompanyExpensesRemoteDataSource remoteDataSource, {
  FakeCompanyExpenseAuditLogRepository? auditRepository,
}) {
  return CompanyExpensesRepositoryImpl(
    remoteDataSource: remoteDataSource,
    createAuditLogUseCase: CreateAuditLogUseCase(
      auditRepository ?? FakeCompanyExpenseAuditLogRepository(),
    ),
  );
}

CompanyExpenseWriteData companyExpenseWriteData({double amount = 125.5}) {
  return CompanyExpenseWriteData(
    companyId: testCompanyId,
    categoryId: testCategoryId,
    amount: amount,
    expenseDate: DateTime.utc(2026, 8, 19),
  );
}

const companyExpenseVoidData = CompanyExpenseVoidData(
  companyId: testCompanyId,
  expenseId: testExpenseId,
  reason: 'duplicate',
);

CompanyExpenseModel companyExpenseModel({
  double amount = 125.5,
  bool isVoided = false,
  String? voidReason,
}) {
  return CompanyExpenseModel(
    id: testExpenseId,
    companyId: testCompanyId,
    categoryId: testCategoryId,
    amount: amount,
    expenseDate: DateTime.utc(2026, 8, 19),
    isVoided: isVoided,
    voidReason: voidReason,
  );
}

class ThrowingCompanyExpenseModel extends CompanyExpenseModel {
  ThrowingCompanyExpenseModel()
    : super(
        id: 'expense-broken',
        companyId: testCompanyId,
        categoryId: testCategoryId,
        amount: 1,
        expenseDate: DateTime.utc(2026, 8, 19),
        isVoided: false,
      );

  @override
  double get amount => throw StateError('mapping internal detail');
}

class FakeCompanyExpensesRemoteDataSource
    implements CompanyExpensesRemoteDataSource {
  final List<String>? operations;
  final Object? categoriesError;
  final Object? listError;
  final Object? formLookupsError;
  final Object? lookupError;
  final Object? addError;
  final Object? updateError;
  final Object? voidError;
  final List<CompanyExpenseModel>? listModels;

  int addCalls = 0;
  String? lastCategoriesCompanyId;
  bool? lastIncludeInactive;
  String? lastListCompanyId;
  bool? lastIncludeVoided;
  String? lastFormLookupsCompanyId;
  String? lastLookupCompanyId;
  String? lastLookupExpenseId;

  FakeCompanyExpensesRemoteDataSource({
    this.operations,
    this.categoriesError,
    this.listError,
    this.formLookupsError,
    this.lookupError,
    this.addError,
    this.updateError,
    this.voidError,
    this.listModels,
  });

  @override
  Future<CompanyExpenseModel> addCompanyExpense({
    required CompanyExpenseWriteData data,
  }) async {
    addCalls++;
    operations?.add('add_expense');
    if (addError != null) throw addError!;
    return companyExpenseModel(amount: data.amount);
  }

  @override
  Future<List<CompanyExpenseCategoryModel>> getCategories({
    required String companyId,
    required bool includeInactive,
  }) async {
    lastCategoriesCompanyId = companyId;
    lastIncludeInactive = includeInactive;
    if (categoriesError != null) throw categoriesError!;
    return const [];
  }

  @override
  Future<List<CompanyExpenseModel>> getCompanyExpenses({
    required String companyId,
    required bool includeVoided,
  }) async {
    lastListCompanyId = companyId;
    lastIncludeVoided = includeVoided;
    if (listError != null) throw listError!;
    return listModels ?? [companyExpenseModel()];
  }

  @override
  Future<CompanyExpenseModel> getCompanyExpenseById({
    required String companyId,
    required String id,
  }) async {
    lastLookupCompanyId = companyId;
    lastLookupExpenseId = id;
    operations?.add('get_expense');
    if (lookupError != null) throw lookupError!;
    return companyExpenseModel();
  }

  @override
  Future<CompanyExpenseFormLookupsModel> getFormLookups({
    required String companyId,
  }) async {
    lastFormLookupsCompanyId = companyId;
    if (formLookupsError != null) throw formLookupsError!;
    return const CompanyExpenseFormLookupsModel();
  }

  @override
  Future<CompanyExpenseModel> updateCompanyExpense({
    required String id,
    required CompanyExpenseWriteData data,
  }) async {
    operations?.add('update_expense');
    if (updateError != null) throw updateError!;
    return companyExpenseModel(amount: data.amount);
  }

  @override
  Future<CompanyExpenseModel> voidCompanyExpense({
    required CompanyExpenseVoidData data,
  }) async {
    operations?.add('void_expense');
    if (voidError != null) throw voidError!;
    return companyExpenseModel(isVoided: true, voidReason: data.reason);
  }
}

class FakeCompanyExpenseAuditLogRepository implements AuditLogRepository {
  final Failure? failure;
  final List<String>? operations;
  final List<AuditLogWriteData> logs = [];

  FakeCompanyExpenseAuditLogRepository({this.failure, this.operations});

  @override
  Future<Result<void>> createAuditLog({required AuditLogWriteData data}) async {
    operations?.add('audit');
    if (failure != null) return FailureResult<void>(failure!);
    logs.add(data);
    return const Success<void>(null);
  }

  @override
  Future<Result<List<AuditLog>>> getEntityAuditLogs({
    required String companyId,
    required AuditModule module,
    required AuditEntityType entityType,
    required String entityId,
  }) async {
    return const Success<List<AuditLog>>([]);
  }
}
