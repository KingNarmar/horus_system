import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:horus_system/core/errors/common_failures.dart';
import 'package:horus_system/core/errors/failure_codes.dart';
import 'package:horus_system/core/utils/result.dart';
import 'package:horus_system/features/trips/domain/entities/trip_entity.dart';
import 'package:horus_system/features/trips/presentation/cubit/trips_state.dart';

import 'trips_realtime_test_fixtures.dart';

void main() {
  test('reconnect restores missed financial changes without closing details', () async {
    final trips = FakeTripsRepository();
    final ledger = FakeExpensesRepository()..current = [expense('existing')];
    final cubit = buildTripsRealtimeCubit(
      FakeDocumentsRepository(),
      expenseLedger: ledger,
      tripsRepository: trips,
    );
    addTearDown(cubit.close);
    await cubit.loadTrips(financeCompanyA);
    await cubit.loadTripDetails(tripA);
    cubit.setSearchQuery('000001');

    final beforeTrips = trips.listReads;
    final beforeExpenses = ledger.reads;
    ledger.current = [expense('existing'), expense('offline-1'), expense('offline-2')];

    await cubit.reconcileTripsAfterReconnect(financeCompanyA);

    final state = cubit.state as TripsLoaded;
    expect(trips.listReads, beforeTrips + 1);
    expect(ledger.reads, beforeExpenses + 1);
    expect(state.selectedTrip?.id, tripA.id);
    expect(state.selectedTripExpenses.map((entry) => entry.id), [
      'existing',
      'offline-1',
      'offline-2',
    ]);
    expect(state.selectedTripTotalExpenses?.minorUnits, 3750);
    expect(state.searchQuery, '000001');
    expect(state.isDetailsLoading, isFalse);
    expect(state.isExpensesLoading, isFalse);
  });

  test('reconnect while no Trip is selected updates list, not ledger', () async {
    final trips = FakeTripsRepository();
    final ledger = FakeExpensesRepository();
    final cubit = buildTripsRealtimeCubit(
      FakeDocumentsRepository(),
      expenseLedger: ledger,
      tripsRepository: trips,
    );
    addTearDown(cubit.close);
    await cubit.loadTrips(financeCompanyA);
    final beforeExpenses = ledger.reads;

    await cubit.reconcileTripsAfterReconnect(financeCompanyA);

    expect((cubit.state as TripsLoaded).selectedTrip, isNull);
    expect(ledger.reads, beforeExpenses);
    expect(trips.listReads, 2);
  });

  test('reconnect does not fetch financial data for operations', () async {
    final ledger = FakeExpensesRepository();
    final cubit = buildTripsRealtimeCubit(
      FakeDocumentsRepository(),
      expenseLedger: ledger,
    );
    addTearDown(cubit.close);
    await cubit.loadTrips(companyA);
    await cubit.loadTripDetails(tripA);

    await cubit.reconcileTripsAfterReconnect(companyA);

    expect((cubit.state as TripsLoaded).selectedTrip?.id, tripA.id);
    expect(ledger.reads, 0);
  });

  test('reconnect network read failure preserves last-known Trip and ledger', () async {
    final trips = FakeTripsRepository();
    final ledger = FakeExpensesRepository()..current = [expense('existing')];
    final cubit = buildTripsRealtimeCubit(
      FakeDocumentsRepository(),
      expenseLedger: ledger,
      tripsRepository: trips,
    );
    addTearDown(cubit.close);
    await cubit.loadTrips(financeCompanyA);
    await cubit.loadTripDetails(tripA);

    final failingTripRead = Completer<Result<List<TripEntity>>>();
    trips.pendingListReads.add(failingTripRead);
    ledger.pendingResults.add(
      const FailureResult(
        NetworkFailure(code: FailureCodes.networkStatusUnavailable),
      ),
    );
    final pending = cubit.reconcileTripsAfterReconnect(financeCompanyA);
    failingTripRead.complete(
      const FailureResult(
        NetworkFailure(code: FailureCodes.networkStatusUnavailable),
      ),
    );
    await pending;

    final failed = cubit.state as TripsLoaded;
    expect(failed.selectedTrip?.id, tripA.id);
    expect(failed.selectedTripExpenses.map((e) => e.id), ['existing']);

    ledger.current = [expense('existing'), expense('recovered')];
    await cubit.reconcileTripsAfterReconnect(financeCompanyA);
    final recovered = cubit.state as TripsLoaded;
    expect(recovered.selectedTripExpenses.map((e) => e.id), [
      'existing',
      'recovered',
    ]);
  });

  test('late reconnect cannot populate the next company financial state', () async {
    final trips = FakeTripsRepository();
    final ledger = FakeExpensesRepository()..current = [expense('old')];
    final cubit = buildTripsRealtimeCubit(
      FakeDocumentsRepository(),
      expenseLedger: ledger,
      tripsRepository: trips,
    );
    addTearDown(cubit.close);
    await cubit.loadTrips(financeCompanyA);
    await cubit.loadTripDetails(tripA);

    final delayed = Completer<Result<List<TripEntity>>>();
    trips.pendingListReads.add(delayed);
    final previous = cubit.reconcileTripsAfterReconnect(financeCompanyA);
    await Future<void>.delayed(Duration.zero);

    await cubit.loadTrips(companyB);
    delayed.complete(Success([tripA]));
    await previous;

    final latest = cubit.state as TripsLoaded;
    expect(latest.currentCompanyContext.companyId, companyB.companyId);
    expect(latest.selectedTrip, isNull);
    expect(latest.selectedTripExpenses, isEmpty);
  });
}
