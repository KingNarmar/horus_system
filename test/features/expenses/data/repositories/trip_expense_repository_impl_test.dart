import 'package:horus_system/core/domain/value_objects/business_date.dart';
import 'package:horus_system/core/errors/common_failures.dart';
import 'package:horus_system/core/errors/failure_codes.dart';
import 'package:horus_system/core/utils/result.dart';
import 'package:horus_system/features/expenses/data/datasources/trip_expenses_remote_data_source.dart';
import 'package:horus_system/features/expenses/data/models/trip_expense_model.dart';
import 'package:horus_system/features/expenses/data/repositories/trip_expense_repo_impl.dart';
import 'package:horus_system/features/expenses/domain/entities/trip_expense_paid_by.dart';
import 'package:horus_system/features/expenses/domain/entities/trip_expense_write_data.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show PostgrestException;
import 'package:test/test.dart';

void main() {
  group('TripExpensesRepositoryImpl legacy path', () {
    test('adds expense through the mutation data source', () async {
      final operations = <String>[];
      final remoteDataSource = _FakeTripExpensesRemoteDataSource(
        operations: operations,
      );
      final repository = _repository(remoteDataSource);

      final result = await repository.addTripExpense(
        data: _writeData(),
        actorRole: 'accountant',
      );

      expect(result, isA<Success>());
      expect(result.dataOrNull?.id, _expenseId);
      expect(operations, ['add_expense']);
    });

    test(
      'updates expense without audit-only snapshot or total reads',
      () async {
        final operations = <String>[];
        final remoteDataSource = _FakeTripExpensesRemoteDataSource(
          operations: operations,
        );
        final repository = _repository(remoteDataSource);

        final result = await repository.updateTripExpense(
          id: _expenseId,
          data: _writeData(amount: 175),
          actorRole: 'accountant',
        );

        expect(result, isA<Success>());
        expect(result.dataOrNull?.amount, 175);
        expect(operations, ['update_expense']);
      },
    );

    test('sanitizes unexpected add failure', () async {
      final remoteDataSource = _FakeTripExpensesRemoteDataSource(
        addError: StateError('internal add detail'),
      );
      final repository = _repository(remoteDataSource);

      final result = await repository.addTripExpense(
        data: _writeData(),
        actorRole: 'accountant',
      );

      expect(result.failureOrNull, isA<UnexpectedFailure>());
      expect(result.failureOrNull?.code, FailureCodes.unexpectedError);
      expect(result.failureOrNull?.message, isNull);
    });

    test('sanitizes Postgrest update failure', () async {
      final remoteDataSource = _FakeTripExpensesRemoteDataSource(
        updateError: const PostgrestException(
          message: 'permission denied',
          code: '42501',
        ),
      );
      final repository = _repository(remoteDataSource);

      final result = await repository.updateTripExpense(
        id: _expenseId,
        data: _writeData(),
        actorRole: 'accountant',
      );

      expect(result.failureOrNull, isA<ServerFailure>());
      expect(result.failureOrNull?.code, FailureCodes.serverError);
      expect(result.failureOrNull?.message, isNull);
    });

    test('forwards company and trip scope when loading expenses', () async {
      final remoteDataSource = _FakeTripExpensesRemoteDataSource();
      final repository = _repository(remoteDataSource);

      final result = await repository.getTripExpenses(
        companyId: _companyId,
        tripId: _tripId,
      );

      expect(result, isA<Success>());
      expect(remoteDataSource.lastListCompanyId, _companyId);
      expect(remoteDataSource.lastListTripId, _tripId);
    });

    test('sanitizes scoped Postgrest read failure', () async {
      final remoteDataSource = _FakeTripExpensesRemoteDataSource(
        listError: const PostgrestException(
          message: 'read denied',
          code: '42501',
        ),
      );
      final repository = _repository(remoteDataSource);

      final result = await repository.getTripExpenses(
        companyId: _companyId,
        tripId: _tripId,
      );

      expect(result.failureOrNull, isA<ServerFailure>());
      expect(result.failureOrNull?.code, FailureCodes.serverError);
      expect(result.failureOrNull?.message, isNull);
    });

    test('sanitizes model mapping failures inside repository guard', () async {
      final remoteDataSource = _FakeTripExpensesRemoteDataSource(
        listModels: [_ThrowingTripExpenseModel()],
      );
      final repository = _repository(remoteDataSource);

      final result = await repository.getTripExpenses(
        companyId: _companyId,
        tripId: _tripId,
      );

      expect(result.failureOrNull, isA<UnexpectedFailure>());
      expect(result.failureOrNull?.code, FailureCodes.unexpectedError);
      expect(result.failureOrNull?.message, isNull);
    });
  });
}

const _companyId = 'company-1';
const _tripId = 'trip-1';
const _expenseId = 'expense-1';
const _expenseTypeId = 'expense-type-1';
const _tripTotal = 300.0;

TripExpensesRepositoryImpl _repository(
  _FakeTripExpensesRemoteDataSource remoteDataSource,
) {
  return TripExpensesRepositoryImpl(remoteDataSource: remoteDataSource);
}

BusinessDate _date(int year, int month, int day) {
  return BusinessDate(year: year, month: month, day: day);
}

TripExpenseWriteData _writeData({double amount = 125.5}) {
  return TripExpenseWriteData(
    companyId: _companyId,
    tripId: _tripId,
    expenseTypeId: _expenseTypeId,
    expenseName: 'Fuel',
    amount: amount,
    paidBy: TripExpensePaidBy.company,
    expenseDate: _date(2026, 8, 22),
    notes: 'note',
  );
}

TripExpenseModel _expenseModel({double amount = 100}) {
  return TripExpenseModel(
    id: _expenseId,
    companyId: _companyId,
    tripId: _tripId,
    expenseTypeId: _expenseTypeId,
    expenseName: 'Fuel',
    amount: amount,
    paidBy: 'company',
    expenseDate: _date(2026, 8, 22),
    notes: 'note',
    expenseTypeName: 'Fuel',
  );
}

class _ThrowingTripExpenseModel extends TripExpenseModel {
  _ThrowingTripExpenseModel()
    : super(
        id: 'expense-broken',
        companyId: _companyId,
        tripId: _tripId,
        expenseTypeId: _expenseTypeId,
        expenseName: 'ignored',
        amount: 1,
        paidBy: 'company',
        expenseDate: BusinessDate(year: 2026, month: 8, day: 22),
      );

  @override
  String get expenseName => throw StateError('mapping internal detail');
}

class _FakeTripExpensesRemoteDataSource
    implements TripExpensesRemoteDataSource {
  final List<String>? operations;
  final Object? listError;
  final Object? addError;
  final Object? updateError;
  final Object? totalReadError;
  final List<TripExpenseModel>? listModels;
  String? lastListCompanyId;
  String? lastListTripId;
  String? lastTotalReadCompanyId;
  String? lastTotalReadTripId;

  _FakeTripExpensesRemoteDataSource({
    this.operations,
    this.listError,
    this.addError,
    this.updateError,
    this.totalReadError,
    this.listModels,
  });

  @override
  Future<List<TripExpenseModel>> getTripExpenses({
    required String companyId,
    required String tripId,
  }) async {
    operations?.add('get_expenses');
    lastListCompanyId = companyId;
    lastListTripId = tripId;
    if (listError != null) throw listError!;
    return listModels ?? [_expenseModel()];
  }

  @override
  Future<TripExpenseModel> addTripExpense({
    required TripExpenseWriteData data,
  }) async {
    operations?.add('add_expense');
    if (addError != null) throw addError!;
    return _expenseModel(amount: data.amount);
  }

  @override
  Future<TripExpenseModel> updateTripExpense({
    required String id,
    required TripExpenseWriteData data,
  }) async {
    operations?.add('update_expense');
    if (updateError != null) throw updateError!;
    return _expenseModel(amount: data.amount);
  }

  @override
  Future<double> getTripTotalExpenses({
    required String companyId,
    required String tripId,
  }) async {
    operations?.add('read_total');
    lastTotalReadCompanyId = companyId;
    lastTotalReadTripId = tripId;
    if (totalReadError != null) throw totalReadError!;
    return _tripTotal;
  }
}

