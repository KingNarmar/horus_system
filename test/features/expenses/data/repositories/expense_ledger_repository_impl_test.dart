import 'package:horus_system/core/domain/value_objects/business_date.dart';
import 'package:horus_system/core/domain/value_objects/currency_code.dart';
import 'package:horus_system/core/domain/value_objects/money.dart';
import 'package:horus_system/core/utils/result.dart';
import 'package:horus_system/features/expenses/data/datasources/expense_ledger_remote_data_source.dart';
import 'package:horus_system/features/expenses/data/models/expense_ledger_entry_model.dart';
import 'package:horus_system/features/expenses/data/repositories/expense_ledger_repository_impl.dart';
import 'package:horus_system/features/expenses/domain/entities/expense_attribution.dart';
import 'package:horus_system/features/expenses/domain/entities/expense_funding_source.dart';
import 'package:horus_system/features/expenses/domain/entities/expense_ledger_entry.dart';
import 'package:horus_system/features/expenses/domain/entities/expense_ledger_write_data.dart';
import 'package:horus_system/features/expenses/domain/failures/expense_ledger_failure_codes.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show PostgrestException;
import 'package:test/test.dart';

void main() {
  group('ExpenseLedgerRepositoryImpl', () {
    test('gets company-scoped entries and maps models to entities', () async {
      final remote = _FakeExpenseLedgerRemoteDataSource();
      final repository = ExpenseLedgerRepositoryImpl(remoteDataSource: remote);

      final result = await repository.getEntries(
        companyId: 'company-1',
        includeVoided: true,
      );

      expect(result, isA<Success<List<ExpenseLedgerEntry>>>());
      expect(remote.getCalls, 1);
      expect(remote.lastCompanyId, 'company-1');
      expect(remote.lastIncludeVoided, isTrue);
      expect(result.dataOrNull, hasLength(1));
      expect(result.dataOrNull?.single.amount.minorUnits, 12345);
      expect(result.dataOrNull?.single.amount.currency.value, 'AED');
      expect(result.dataOrNull?.single.attribution.tripId, 'trip-1');
    });

    test('gets trip entries through the company-scoped boundary', () async {
      final remote = _FakeExpenseLedgerRemoteDataSource();
      final repository = ExpenseLedgerRepositoryImpl(remoteDataSource: remote);

      final result = await repository.getEntriesForTrip(
        companyId: 'company-1',
        tripId: 'trip-1',
        includeVoided: true,
      );

      expect(result, isA<Success<List<ExpenseLedgerEntry>>>());
      expect(remote.getForTripCalls, 1);
      expect(remote.lastCompanyId, 'company-1');
      expect(remote.lastTripId, 'trip-1');
      expect(remote.lastIncludeVoided, isTrue);
      expect(result.dataOrNull, hasLength(1));
    });

    test('creates entries through the remote data source', () async {
      final remote = _FakeExpenseLedgerRemoteDataSource();
      final repository = ExpenseLedgerRepositoryImpl(remoteDataSource: remote);
      final data = _writeData();

      final result = await repository.createEntry(data);

      expect(result, isA<Success<ExpenseLedgerEntry>>());
      expect(remote.createCalls, 1);
      expect(identical(remote.lastWriteData, data), isTrue);
      expect(result.dataOrNull?.expenseTypeId, 'type-1');
    });

    test('voids entries using the company-scoped remote boundary', () async {
      final remote = _FakeExpenseLedgerRemoteDataSource();
      final repository = ExpenseLedgerRepositoryImpl(remoteDataSource: remote);

      final result = await repository.voidEntry(
        companyId: 'company-1',
        expenseId: 'expense-1',
        reason: 'duplicate',
      );

      expect(result, isA<Success<ExpenseLedgerEntry>>());
      expect(remote.voidCalls, 1);
      expect(remote.lastCompanyId, 'company-1');
      expect(remote.lastExpenseId, 'expense-1');
      expect(remote.lastReason, 'duplicate');
    });

    test('maps Postgrest failures to sanitized typed failures', () async {
      final remote = _FakeExpenseLedgerRemoteDataSource(
        error: const PostgrestException(
          message: 'sensitive currency details',
          code: 'P2805',
        ),
      );
      final repository = ExpenseLedgerRepositoryImpl(remoteDataSource: remote);

      final result = await repository.createEntry(_writeData());

      expect(
        result.failureOrNull?.code,
        ExpenseLedgerFailureCodes.currencyMismatch,
      );
      expect(result.failureOrNull?.message, isNull);
    });

    test('maps unexpected failures without leaking internal details', () async {
      final remote = _FakeExpenseLedgerRemoteDataSource(
        error: Exception('internal detail'),
      );
      final repository = ExpenseLedgerRepositoryImpl(remoteDataSource: remote);

      final result = await repository.getEntries(companyId: 'company-1');

      expect(
        result.failureOrNull?.code,
        ExpenseLedgerFailureCodes.unexpectedError,
      );
      expect(result.failureOrNull?.message, isNull);
    });
  });
}

ExpenseLedgerWriteData _writeData() {
  final currency = CurrencyCode.tryParse('AED')!;
  return ExpenseLedgerWriteData(
    companyId: 'company-1',
    expenseTypeId: 'type-1',
    amount: Money(minorUnits: 12345, currency: currency),
    currencyFractionDigits: 2,
    expenseDate: BusinessDate(year: 2026, month: 9, day: 15),
    fundingSource: ExpenseFundingSource.company,
    attribution: const ExpenseAttribution(tripId: 'trip-1'),
  );
}

final class _FakeExpenseLedgerRemoteDataSource
    implements ExpenseLedgerRemoteDataSource {
  final Object? error;

  int getCalls = 0;
  int getForTripCalls = 0;
  int createCalls = 0;
  int voidCalls = 0;
  String? lastCompanyId;
  String? lastTripId;
  bool? lastIncludeVoided;
  String? lastExpenseId;
  String? lastReason;
  ExpenseLedgerWriteData? lastWriteData;

  _FakeExpenseLedgerRemoteDataSource({this.error});

  @override
  Future<List<ExpenseLedgerEntryModel>> getEntries({
    required String companyId,
    required bool includeVoided,
  }) async {
    getCalls++;
    lastCompanyId = companyId;
    lastIncludeVoided = includeVoided;
    _throwIfConfigured();
    return const [_model];
  }

  @override
  Future<List<ExpenseLedgerEntryModel>> getEntriesForTrip({
    required String companyId,
    required String tripId,
    required bool includeVoided,
  }) async {
    getForTripCalls++;
    lastCompanyId = companyId;
    lastTripId = tripId;
    lastIncludeVoided = includeVoided;
    _throwIfConfigured();
    return const [_model];
  }

  @override
  Future<ExpenseLedgerEntryModel> createEntry(
    ExpenseLedgerWriteData data,
  ) async {
    createCalls++;
    lastWriteData = data;
    _throwIfConfigured();
    return _model;
  }

  @override
  Future<ExpenseLedgerEntryModel> voidEntry({
    required String companyId,
    required String expenseId,
    String? reason,
  }) async {
    voidCalls++;
    lastCompanyId = companyId;
    lastExpenseId = expenseId;
    lastReason = reason;
    _throwIfConfigured();
    return _model;
  }

  void _throwIfConfigured() {
    final configuredError = error;
    if (configuredError != null) throw configuredError;
  }

  static const _model = ExpenseLedgerEntryModel(
    id: 'expense-1',
    companyId: 'company-1',
    expenseTypeId: 'type-1',
    amountMinorUnits: 12345,
    currencyCode: 'AED',
    currencyFractionDigits: 2,
    expenseDate: '2026-09-15',
    fundingSource: 'company',
    tripId: 'trip-1',
    isVoided: false,
  );
}
