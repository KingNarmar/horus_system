import 'package:horus_system/core/errors/common_failures.dart';
import 'package:horus_system/core/errors/failure.dart';
import 'package:horus_system/core/errors/failure_codes.dart';
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
import 'package:test/test.dart';

void main() {
  group('CompanyExpensesRepositoryImpl', () {
    test('adds expense and writes audit after successful mutation', () async {
      final operations = <String>[];
      final remoteDataSource = _FakeCompanyExpensesRemoteDataSource(
        operations: operations,
      );
      final auditRepository = _FakeAuditLogRepository(operations: operations);
      final repository = CompanyExpensesRepositoryImpl(
        remoteDataSource: remoteDataSource,
        createAuditLogUseCase: CreateAuditLogUseCase(auditRepository),
      );

      final result = await repository.addCompanyExpense(
        data: _writeData(),
        actorRole: 'accountant',
      );

      expect(result, isA<Success>());
      expect(result.dataOrNull?.id, _expenseId);
      expect(operations, ['add_expense', 'audit']);
      expect(
        auditRepository.logs.single.description,
        'company_expense_created',
      );
    });

    test('does not write audit when mutation fails', () async {
      final operations = <String>[];
      final remoteDataSource = _FakeCompanyExpensesRemoteDataSource(
        operations: operations,
        addError: Exception('mutation failed'),
      );
      final auditRepository = _FakeAuditLogRepository(operations: operations);
      final repository = CompanyExpensesRepositoryImpl(
        remoteDataSource: remoteDataSource,
        createAuditLogUseCase: CreateAuditLogUseCase(auditRepository),
      );

      final result = await repository.addCompanyExpense(
        data: _writeData(),
        actorRole: 'accountant',
      );

      expect(result, isA<FailureResult>());
      expect(result.failureOrNull, isA<UnexpectedFailure>());
      expect(operations, ['add_expense']);
      expect(auditRepository.logs, isEmpty);
    });

    test('propagates audit failure after successful mutation', () async {
      final remoteDataSource = _FakeCompanyExpensesRemoteDataSource();
      final auditRepository = _FakeAuditLogRepository(
        failure: const ValidationFailure(code: FailureCodes.serverError),
      );
      final repository = CompanyExpensesRepositoryImpl(
        remoteDataSource: remoteDataSource,
        createAuditLogUseCase: CreateAuditLogUseCase(auditRepository),
      );

      final result = await repository.addCompanyExpense(
        data: _writeData(),
        actorRole: 'accountant',
      );

      expect(result, isA<FailureResult>());
      expect(result.failureOrNull?.code, FailureCodes.serverError);
      expect(remoteDataSource.addCalls, 1);
    });

    test('updates after old snapshot lookup and audits last', () async {
      final operations = <String>[];
      final remoteDataSource = _FakeCompanyExpensesRemoteDataSource(
        operations: operations,
      );
      final auditRepository = _FakeAuditLogRepository(operations: operations);
      final repository = CompanyExpensesRepositoryImpl(
        remoteDataSource: remoteDataSource,
        createAuditLogUseCase: CreateAuditLogUseCase(auditRepository),
      );

      final result = await repository.updateCompanyExpense(
        id: _expenseId,
        data: _writeData(amount: 175),
        actorRole: 'accountant',
      );

      expect(result, isA<Success>());
      expect(result.dataOrNull?.amount, 175);
      expect(operations, ['get_expense', 'update_expense', 'audit']);
      expect(remoteDataSource.lastLookupCompanyId, _companyId);
      expect(remoteDataSource.lastLookupExpenseId, _expenseId);
      expect(
        auditRepository.logs.single.description,
        'company_expense_updated',
      );
      expect(auditRepository.logs.single.oldValues?['amount'], 125.5);
      expect(auditRepository.logs.single.newValues?['amount'], 175);
    });

    test('voids after old snapshot lookup and audits last', () async {
      final operations = <String>[];
      final remoteDataSource = _FakeCompanyExpensesRemoteDataSource(
        operations: operations,
      );
      final auditRepository = _FakeAuditLogRepository(operations: operations);
      final repository = CompanyExpensesRepositoryImpl(
        remoteDataSource: remoteDataSource,
        createAuditLogUseCase: CreateAuditLogUseCase(auditRepository),
      );

      final result = await repository.voidCompanyExpense(
        data: const CompanyExpenseVoidData(
          companyId: _companyId,
          expenseId: _expenseId,
          reason: 'duplicate',
        ),
        actorRole: 'accountant',
      );

      expect(result, isA<Success>());
      expect(result.dataOrNull?.isVoided, isTrue);
      expect(operations, ['get_expense', 'void_expense', 'audit']);
      expect(remoteDataSource.lastLookupCompanyId, _companyId);
      expect(remoteDataSource.lastLookupExpenseId, _expenseId);
      expect(
        auditRepository.logs.single.description,
        'company_expense_voided',
      );
      expect(auditRepository.logs.single.oldValues?['is_voided'], isFalse);
      expect(auditRepository.logs.single.newValues?['is_voided'], isTrue);
    });

    test('forwards company scope when loading expenses', () async {
      final remoteDataSource = _FakeCompanyExpensesRemoteDataSource();
      final repository = CompanyExpensesRepositoryImpl(
        remoteDataSource: remoteDataSource,
        createAuditLogUseCase: CreateAuditLogUseCase(_FakeAuditLogRepository()),
      );

      final result = await repository.getCompanyExpenses(
        companyId: _companyId,
        includeVoided: true,
      );

      expect(result, isA<Success>());
      expect(remoteDataSource.lastListCompanyId, _companyId);
      expect(remoteDataSource.lastIncludeVoided, isTrue);
    });
  });
}

const _companyId = 'company-1';
const _expenseId = 'expense-1';
const _categoryId = 'category-1';

CompanyExpenseWriteData _writeData({double amount = 125.5}) {
  return CompanyExpenseWriteData(
    companyId: _companyId,
    categoryId: _categoryId,
    amount: amount,
    expenseDate: DateTime.utc(2026, 8, 19),
  );
}

CompanyExpenseModel _expenseModel({
  double amount = 125.5,
  bool isVoided = false,
  String? voidReason,
}) {
  return CompanyExpenseModel(
    id: _expenseId,
    companyId: _companyId,
    categoryId: _categoryId,
    amount: amount,
    expenseDate: DateTime.utc(2026, 8, 19),
    isVoided: isVoided,
    voidReason: voidReason,
  );
}

class _FakeCompanyExpensesRemoteDataSource
    implements CompanyExpensesRemoteDataSource {
  final List<String>? operations;
  final Object? addError;
  int addCalls = 0;
  String? lastLookupCompanyId;
  String? lastLookupExpenseId;
  String? lastListCompanyId;
  bool? lastIncludeVoided;

  _FakeCompanyExpensesRemoteDataSource({this.operations, this.addError});

  @override
  Future<CompanyExpenseModel> addCompanyExpense({
    required CompanyExpenseWriteData data,
  }) async {
    addCalls++;
    operations?.add('add_expense');
    if (addError != null) throw addError!;
    return _expenseModel(amount: data.amount);
  }

  @override
  Future<List<CompanyExpenseCategoryModel>> getCategories({
    required String companyId,
    required bool includeInactive,
  }) async {
    return const [];
  }

  @override
  Future<List<CompanyExpenseModel>> getCompanyExpenses({
    required String companyId,
    required bool includeVoided,
  }) async {
    lastListCompanyId = companyId;
    lastIncludeVoided = includeVoided;
    return [_expenseModel()];
  }

  @override
  Future<CompanyExpenseModel> getCompanyExpenseById({
    required String companyId,
    required String id,
  }) async {
    lastLookupCompanyId = companyId;
    lastLookupExpenseId = id;
    operations?.add('get_expense');
    return _expenseModel();
  }

  @override
  Future<CompanyExpenseFormLookupsModel> getFormLookups({
    required String companyId,
  }) async {
    return const CompanyExpenseFormLookupsModel();
  }

  @override
  Future<CompanyExpenseModel> updateCompanyExpense({
    required String id,
    required CompanyExpenseWriteData data,
  }) async {
    operations?.add('update_expense');
    return _expenseModel(amount: data.amount);
  }

  @override
  Future<CompanyExpenseModel> voidCompanyExpense({
    required CompanyExpenseVoidData data,
  }) async {
    operations?.add('void_expense');
    return _expenseModel(isVoided: true, voidReason: data.reason);
  }
}

class _FakeAuditLogRepository implements AuditLogRepository {
  final Failure? failure;
  final List<String>? operations;
  final List<AuditLogWriteData> logs = [];

  _FakeAuditLogRepository({this.failure, this.operations});

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
