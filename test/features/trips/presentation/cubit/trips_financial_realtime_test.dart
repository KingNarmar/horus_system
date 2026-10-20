import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:horus_system/core/errors/common_failures.dart';
import 'package:horus_system/core/utils/result.dart';
import 'package:horus_system/features/expenses/domain/entities/expense_ledger_entry.dart';
import 'package:horus_system/features/expenses/domain/failures/expense_ledger_failure_codes.dart';
import 'package:horus_system/features/trips/presentation/cubit/trips_state.dart';

import 'trips_realtime_test_fixtures.dart';

void main() {
  test(
    'financial hints coalesce and silently refresh selected ledger',
    () async {
      final documents = FakeDocumentsRepository();
      final ledger = FakeExpensesRepository();
      final cubit = buildTripsRealtimeCubit(documents, expenseLedger: ledger);
      addTearDown(cubit.close);
      await cubit.loadTrips(financeCompanyA);
      await cubit.loadTripDetails(tripA);

      final originalReads = ledger.reads;
      final delayed = Completer<Result<List<ExpenseLedgerEntry>>>();
      ledger.pendingReads.add(delayed);

      final refresh = cubit.refreshSelectedTripFinancialsFromRealtime();
      await Future<void>.delayed(Duration.zero);
      expect((cubit.state as TripsLoaded).isExpensesLoading, isFalse);

      await cubit.refreshSelectedTripFinancialsFromRealtime();
      final updated = expense('new-financial-entry');
      ledger.current = [updated];
      delayed.complete(const Success([]));
      await refresh;

      final latest = cubit.state as TripsLoaded;
      expect(ledger.reads, originalReads + 2);
      expect(latest.selectedTripExpenses, [updated]);
      expect(latest.selectedTrip?.id, tripA.id);
      expect(latest.isExpensesLoading, isFalse);
    },
  );

  test('late financial hints cannot update another company session', () async {
    final documents = FakeDocumentsRepository();
    final ledger = FakeExpensesRepository()..current = [expense('old')];
    final cubit = buildTripsRealtimeCubit(documents, expenseLedger: ledger);
    addTearDown(cubit.close);
    await cubit.loadTrips(financeCompanyA);
    await cubit.loadTripDetails(tripA);

    final delayed = Completer<Result<List<ExpenseLedgerEntry>>>();
    ledger.pendingReads.add(delayed);
    final refresh = cubit.refreshSelectedTripFinancialsFromRealtime();
    await Future<void>.delayed(Duration.zero);

    await cubit.loadTrips(companyB);
    delayed.complete(Success([expense('stale')]));
    await refresh;

    final latest = cubit.state as TripsLoaded;
    expect(latest.currentCompanyContext.companyId, 'company-b');
    expect(latest.selectedTripExpenses, isEmpty);
    expect(latest.selectedTrip, isNull);
  });

  test(
    'financial refresh clears stale entries on permission revocation',
    () async {
      final ledger = FakeExpensesRepository()..current = [expense('old')];
      final cubit = buildTripsRealtimeCubit(
        FakeDocumentsRepository(),
        expenseLedger: ledger,
      );
      addTearDown(cubit.close);
      await cubit.loadTrips(financeCompanyA);
      await cubit.loadTripDetails(tripA);
      expect((cubit.state as TripsLoaded).selectedTripExpenses, hasLength(1));

      ledger.pendingResults.add(
        const FailureResult<List<ExpenseLedgerEntry>>(
          PermissionFailure(code: ExpenseLedgerFailureCodes.permissionView),
        ),
      );
      await cubit.refreshSelectedTripFinancialsFromRealtime();

      final current = cubit.state as TripsLoaded;
      expect(current.selectedTripExpenses, isEmpty);
      expect(current.selectedTripTotalExpenses, isNull);
      expect(current.selectedTripNetProfit, isNull);
      expect(
        current.expensesFailure?.code,
        ExpenseLedgerFailureCodes.permissionView,
      );
    },
  );

  test('operations never perform financial refresh', () async {
    final ledger = FakeExpensesRepository();
    final cubit = buildTripsRealtimeCubit(
        FakeDocumentsRepository(),
        expenseLedger: ledger,
      );
    addTearDown(cubit.close);
    await cubit.loadTrips(companyA);
    await cubit.loadTripDetails(tripA);

    final reads = ledger.reads;
    await cubit.refreshSelectedTripFinancialsFromRealtime();
    expect(ledger.reads, reads);
  });
  test('failed local void drains pending financial invalidation', () async {
    final ledger = FakeExpensesRepository()..current = [expense('old')];
    final cubit = buildTripsRealtimeCubit(
      FakeDocumentsRepository(),
      expenseLedger: ledger,
    );
    addTearDown(cubit.close);
    await cubit.loadTrips(financeCompanyA);
    await cubit.loadTripDetails(tripA);

    final pending = Completer<Result<ExpenseLedgerEntry>>();
    ledger.pendingVoid = pending;
    final voiding = cubit.voidTripExpense(expense: ledger.current.single);
    await Future<void>.delayed(Duration.zero);

    final readsBeforeHint = ledger.reads;
    await cubit.refreshSelectedTripFinancialsFromRealtime();
    expect(ledger.reads, readsBeforeHint);

    final updated = expense('updated');
    ledger.current = [updated];
    pending.complete(
      const FailureResult<ExpenseLedgerEntry>(
        PermissionFailure(code: ExpenseLedgerFailureCodes.permissionManage),
      ),
    );
    await voiding;
    await Future<void>.delayed(Duration.zero);

    final latest = cubit.state as TripsLoaded;
    expect(latest.selectedTripExpenses, [updated]);
    expect(ledger.reads, readsBeforeHint + 1);
    expect(latest.isTripExpenseMutating, isFalse);
  });
}
