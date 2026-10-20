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

  late final StreamController<RealtimeChangeSignal> documents =
      StreamController<RealtimeChangeSignal>(
        sync: true,
        onCancel: () => documentsCanceled = true,
      );

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
  }
}
