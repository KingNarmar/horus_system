import 'dart:async';

import '../../../errors/common_failures.dart';
import '../../../errors/failure_codes.dart';
import '../../../utils/result.dart';
import '../../domain/entities/company_data_change.dart';
import '../../domain/repositories/company_data_changes_repository.dart';
import '../datasources/company_data_changes_remote_data_source.dart';
import '../models/realtime_change_signal.dart';

/// Combines multiple private transport topics into one company-domain stream.
/// Ownership and transport cancellation stay outside Domain and Presentation.
final class CompanyDataChangesRepositoryImpl
    implements CompanyDataChangesRepository {
  final CompanyDataChangesRemoteDataSource _dataSource;

  const CompanyDataChangesRepositoryImpl(this._dataSource);

  @override
  Stream<Result<CompanyDataChange>> watchChanges({
    required String companyId,
    Set<CompanyDataResource> additionalResources = const {},
  }) {
    late final StreamController<Result<CompanyDataChange>> controller;
    final subscriptions = <StreamSubscription<RealtimeChangeSignal>>[];
    var disposed = false;

    const unavailable = FailureResult<CompanyDataChange>(
      NetworkFailure(code: FailureCodes.realtimeSubscriptionUnavailable),
    );

    void subscribe({
      required Stream<RealtimeChangeSignal> stream,
      required CompanyDataResource resource,
    }) {
      subscriptions.add(
        stream.listen(
          (signal) {
            if (disposed || controller.isClosed) return;
            if (signal == RealtimeChangeSignal.unavailable) {
              controller.add(unavailable);
              return;
            }
            // Successful rejoin also signals authoritative reconciliation.
            controller.add(
              Success(
                CompanyDataChange(companyId: companyId, resource: resource),
              ),
            );
          },
          onError: (Object _, StackTrace _) {
            if (!disposed && !controller.isClosed) {
              controller.add(unavailable);
            }
          },
          onDone: () {
            if (!disposed && !controller.isClosed) {
              controller.add(unavailable);
            }
          },
        ),
      );
    }

    controller = StreamController<Result<CompanyDataChange>>(
      onListen: () {
        try {
          subscribe(
            stream: _dataSource.watchCustomers(companyId: companyId),
            resource: CompanyDataResource.customers,
          );
          subscribe(
            stream: _dataSource.watchDrivers(companyId: companyId),
            resource: CompanyDataResource.drivers,
          );
          subscribe(
            stream: _dataSource.watchFleet(companyId: companyId),
            resource: CompanyDataResource.fleet,
          );
          subscribe(
            stream: _dataSource.watchRoutes(companyId: companyId),
            resource: CompanyDataResource.routes,
          );
          subscribe(
            stream: _dataSource.watchTrips(companyId: companyId),
            resource: CompanyDataResource.trips,
          );
          subscribe(
            stream: _dataSource.watchTripDocuments(companyId: companyId),
            resource: CompanyDataResource.tripDocuments,
          );
          subscribe(
            stream: _dataSource.watchFleetLicenseDocuments(
              companyId: companyId,
            ),
            resource: CompanyDataResource.fleetLicenseDocuments,
          );
          if (additionalResources.contains(CompanyDataResource.expenseLedger)) {
            subscribe(
              stream: _dataSource.watchExpenseLedger(companyId: companyId),
              resource: CompanyDataResource.expenseLedger,
            );
          }
          if (additionalResources.contains(CompanyDataResource.tripExpenses)) {
            subscribe(
              stream: _dataSource.watchTripExpenses(companyId: companyId),
              resource: CompanyDataResource.tripExpenses,
            );
          }
        } catch (_) {
          if (!disposed && !controller.isClosed) {
            controller.add(unavailable);
          }
        }
      },
      onCancel: () async {
        disposed = true;
        // Expose channel teardown failure to the session owner.
        await Future.wait(subscriptions.map((item) => item.cancel()));
      },
    );

    return controller.stream;
  }
}
