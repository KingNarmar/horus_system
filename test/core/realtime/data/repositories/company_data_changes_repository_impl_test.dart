import 'dart:async';

import 'package:horus_system/core/errors/failure_codes.dart';
import 'package:horus_system/core/realtime/data/datasources/company_data_changes_remote_data_source.dart';
import 'package:horus_system/core/realtime/data/models/realtime_change_signal.dart';
import 'package:horus_system/core/realtime/data/repositories/company_data_changes_repository_impl.dart';
import 'package:horus_system/core/realtime/domain/entities/company_data_change.dart';
import 'package:test/test.dart';

void main() {
  test('seven private sources emit typed, targeted company changes', () async {
    final source = _Source();
    final repository = CompanyDataChangesRepositoryImpl(source);
    final changes = <CompanyDataChange>[];
    final subscription = repository.watchChanges(companyId: 'company-a').listen(
      (result) {
        final change = result.dataOrNull;
        if (change != null) changes.add(change);
      },
    );

    source.customers.add(RealtimeChangeSignal.changed);
    source.drivers.add(RealtimeChangeSignal.subscribed);
    source.fleet.add(RealtimeChangeSignal.changed);
    source.routes.add(RealtimeChangeSignal.changed);
    source.trips.add(RealtimeChangeSignal.changed);
    source.tripDocuments.add(RealtimeChangeSignal.changed);
    source.documents.add(RealtimeChangeSignal.changed);
    await Future<void>.delayed(Duration.zero);

    expect(changes.map((item) => item.resource).toList(), [
      CompanyDataResource.customers,
      CompanyDataResource.drivers,
      CompanyDataResource.fleet,
      CompanyDataResource.routes,
      CompanyDataResource.trips,
      CompanyDataResource.tripDocuments,
      CompanyDataResource.fleetLicenseDocuments,
    ]);
    expect(changes.every((item) => item.companyId == 'company-a'), isTrue);

    await subscription.cancel();
    expect(source.customerCanceled, isTrue);
    expect(source.driverCanceled, isTrue);
    expect(source.fleetCanceled, isTrue);
    expect(source.routesCanceled, isTrue);
    expect(source.tripsCanceled, isTrue);
    expect(source.tripDocumentsCanceled, isTrue);
    expect(source.documentsCanceled, isTrue);
    await source.close();
  });

  test(
    'finance channels are opt-in and both cancel with their session',
    () async {
      final source = _Source();
      final repository = CompanyDataChangesRepositoryImpl(source);
      final changes = <CompanyDataResource>[];
      final subscription = repository
          .watchChanges(
            companyId: 'company-a',
            additionalResources: const {
              CompanyDataResource.expenseLedger,
              CompanyDataResource.tripExpenses,
            },
          )
          .listen((result) {
            final change = result.dataOrNull;
            if (change != null) changes.add(change.resource);
          });

      source.expenseLedger.add(RealtimeChangeSignal.changed);
      source.tripExpenses.add(RealtimeChangeSignal.subscribed);
      await Future<void>.delayed(Duration.zero);

      expect(changes, [
        CompanyDataResource.expenseLedger,
        CompanyDataResource.tripExpenses,
      ]);
      await subscription.cancel();
      expect(source.expenseLedgerCanceled, isTrue);
      expect(source.tripExpensesCanceled, isTrue);
      await source.close();
    },
  );

  test('Company Expenses is finance-only opt-in and unsubscribes', () async {
    final source = _Source();
    final repository = CompanyDataChangesRepositoryImpl(source);
    final changes = <CompanyDataResource>[];
    final subscription = repository
        .watchChanges(
          companyId: 'company-a',
          additionalResources: const {CompanyDataResource.companyExpenses},
        )
        .listen((result) {
          final change = result.dataOrNull;
          if (change != null) changes.add(change.resource);
        });
    source.companyExpenses.add(RealtimeChangeSignal.changed);
    await Future<void>.delayed(Duration.zero);
    expect(changes, [CompanyDataResource.companyExpenses]);
    expect(source.expenseLedger.hasListener, isFalse);
    expect(source.tripExpenses.hasListener, isFalse);
    await subscription.cancel();
    expect(source.companyExpensesCanceled, isTrue);
    await source.close();
  });

  test('Driver Finance is finance-only opt-in and cleans up', () async {
    final source = _Source();
    final repository = CompanyDataChangesRepositoryImpl(source);
    final changes = <CompanyDataResource>[];
    final subscription = repository
        .watchChanges(
          companyId: 'company-a',
          additionalResources: const {CompanyDataResource.driverFinance},
        )
        .listen((result) {
          final change = result.dataOrNull;
          if (change != null) changes.add(change.resource);
        });
    source.driverFinance.add(RealtimeChangeSignal.changed);
    await Future<void>.delayed(Duration.zero);
    expect(changes, [CompanyDataResource.driverFinance]);
    expect(source.expenseLedger.hasListener, isFalse);
    expect(source.tripExpenses.hasListener, isFalse);
    await subscription.cancel();
    expect(source.driverFinanceCanceled, isTrue);
    await source.close();
  });

  test(
    'Driver Settlements is finance-only opt-in and cancels cleanly',
    () async {
      final source = _Source();
      final repository = CompanyDataChangesRepositoryImpl(source);
      final changes = <CompanyDataResource>[];
      final subscription = repository
          .watchChanges(
            companyId: 'company-a',
            additionalResources: const {CompanyDataResource.driverSettlements},
          )
          .listen((result) {
            final change = result.dataOrNull;
            if (change != null) changes.add(change.resource);
          });

      source.driverSettlements.add(RealtimeChangeSignal.subscribed);
      source.driverSettlements.add(RealtimeChangeSignal.changed);
      await Future<void>.delayed(Duration.zero);

      expect(changes, [
        CompanyDataResource.driverSettlements,
        CompanyDataResource.driverSettlements,
      ]);
      expect(source.driverFinance.hasListener, isFalse);
      expect(source.expenseLedger.hasListener, isFalse);
      await subscription.cancel();
      expect(source.driverSettlementsCanceled, isTrue);
      await source.close();
    },
  );

  test(
    'Invoices private channel is opt-in and cancels with the session',
    () async {
      final source = _Source();
      final repository = CompanyDataChangesRepositoryImpl(source);
      final changes = <CompanyDataResource>[];
      final subscription = repository
          .watchChanges(
            companyId: 'company-a',
            additionalResources: const {CompanyDataResource.invoices},
          )
          .listen((result) {
            final change = result.dataOrNull;
            if (change != null) changes.add(change.resource);
          });

      source.invoices.add(RealtimeChangeSignal.subscribed);
      source.invoices.add(RealtimeChangeSignal.changed);
      await Future<void>.delayed(Duration.zero);

      expect(changes, [
        CompanyDataResource.invoices,
        CompanyDataResource.invoices,
      ]);
      expect(source.expenseLedger.hasListener, isFalse);
      expect(source.driverSettlements.hasListener, isFalse);
      await subscription.cancel();
      expect(source.invoicesCanceled, isTrue);
      await source.close();
    },
  );

  test('transport error becomes a sanitized typed failure', () async {
    final source = _Source();
    final repository = CompanyDataChangesRepositoryImpl(source);
    final failures = <String>[];
    final subscription = repository.watchChanges(companyId: 'company-a').listen(
      (result) {
        final code = result.failureOrNull?.code;
        if (code != null) failures.add(code);
      },
    );

    source.drivers.add(RealtimeChangeSignal.unavailable);
    await Future<void>.delayed(Duration.zero);
    expect(failures, [FailureCodes.realtimeSubscriptionUnavailable]);
    await subscription.cancel();
    await source.close();
  });
}

final class _Source implements CompanyDataChangesRemoteDataSource {
  bool customerCanceled = false;
  bool driverCanceled = false;
  bool fleetCanceled = false;
  bool routesCanceled = false;
  bool tripsCanceled = false;
  bool tripDocumentsCanceled = false;
  bool documentsCanceled = false;
  bool driverFinanceCanceled = false;
  bool driverSettlementsCanceled = false;
  bool invoicesCanceled = false;
  bool expenseLedgerCanceled = false;
  bool companyExpensesCanceled = false;
  bool tripExpensesCanceled = false;

  late final StreamController<RealtimeChangeSignal> customers =
      StreamController<RealtimeChangeSignal>(
        sync: true,
        onCancel: () => customerCanceled = true,
      );
  late final StreamController<RealtimeChangeSignal> drivers =
      StreamController<RealtimeChangeSignal>(
        sync: true,
        onCancel: () => driverCanceled = true,
      );

  late final StreamController<RealtimeChangeSignal> fleet =
      StreamController<RealtimeChangeSignal>(
        sync: true,
        onCancel: () => fleetCanceled = true,
      );

  late final StreamController<RealtimeChangeSignal> routes =
      StreamController<RealtimeChangeSignal>(
        sync: true,
        onCancel: () => routesCanceled = true,
      );

  late final StreamController<RealtimeChangeSignal> trips =
      StreamController<RealtimeChangeSignal>(
        sync: true,
        onCancel: () => tripsCanceled = true,
      );

  late final StreamController<RealtimeChangeSignal> tripDocuments =
      StreamController<RealtimeChangeSignal>(
        sync: true,
        onCancel: () => tripDocumentsCanceled = true,
      );

  late final StreamController<RealtimeChangeSignal> companyExpenses =
      StreamController<RealtimeChangeSignal>.broadcast(
        sync: true,
        onCancel: () => companyExpensesCanceled = true,
      );

  late final StreamController<RealtimeChangeSignal> driverFinance =
      StreamController<RealtimeChangeSignal>.broadcast(
        sync: true,
        onCancel: () => driverFinanceCanceled = true,
      );

  late final StreamController<RealtimeChangeSignal> driverSettlements =
      StreamController<RealtimeChangeSignal>.broadcast(
        sync: true,
        onCancel: () => driverSettlementsCanceled = true,
      );

  late final StreamController<RealtimeChangeSignal> invoices =
      StreamController<RealtimeChangeSignal>.broadcast(
        sync: true,
        onCancel: () => invoicesCanceled = true,
      );

  late final StreamController<RealtimeChangeSignal> expenseLedger =
      StreamController<RealtimeChangeSignal>.broadcast(
        sync: true,
        onCancel: () => expenseLedgerCanceled = true,
      );

  late final StreamController<RealtimeChangeSignal> tripExpenses =
      StreamController<RealtimeChangeSignal>.broadcast(
        sync: true,
        onCancel: () => tripExpensesCanceled = true,
      );

  late final StreamController<RealtimeChangeSignal> documents =
      StreamController<RealtimeChangeSignal>(
        sync: true,
        onCancel: () => documentsCanceled = true,
      );

  @override
  Stream<RealtimeChangeSignal> watchCompanyExpenses({
    required String companyId,
  }) => companyExpenses.stream;

  @override
  Stream<RealtimeChangeSignal> watchDriverFinance({
    required String companyId,
  }) => driverFinance.stream;

  @override
  Stream<RealtimeChangeSignal> watchDriverSettlements({
    required String companyId,
  }) => driverSettlements.stream;

  @override
  Stream<RealtimeChangeSignal> watchInvoices({required String companyId}) =>
      invoices.stream;

  @override
  Stream<RealtimeChangeSignal> watchExpenseLedger({
    required String companyId,
  }) => expenseLedger.stream;

  @override
  Stream<RealtimeChangeSignal> watchTripExpenses({required String companyId}) =>
      tripExpenses.stream;

  @override
  Stream<RealtimeChangeSignal> watchRoutes({required String companyId}) =>
      routes.stream;

  @override
  Stream<RealtimeChangeSignal> watchTrips({required String companyId}) =>
      trips.stream;

  @override
  Stream<RealtimeChangeSignal> watchTripDocuments({
    required String companyId,
  }) => tripDocuments.stream;

  @override
  Stream<RealtimeChangeSignal> watchFleetLicenseDocuments({
    required String companyId,
  }) => documents.stream;

  @override
  Stream<RealtimeChangeSignal> watchCustomers({required String companyId}) =>
      customers.stream;

  @override
  Stream<RealtimeChangeSignal> watchDrivers({required String companyId}) =>
      drivers.stream;

  @override
  Stream<RealtimeChangeSignal> watchFleet({required String companyId}) =>
      fleet.stream;

  Future<void> close() async {
    await customers.close();
    await drivers.close();
    await fleet.close();
    await routes.close();
    await trips.close();
    await tripDocuments.close();
    await documents.close();
    await companyExpenses.close();
    await driverFinance.close();
    await driverSettlements.close();
    await invoices.close();
    await expenseLedger.close();
    await tripExpenses.close();
  }
}
