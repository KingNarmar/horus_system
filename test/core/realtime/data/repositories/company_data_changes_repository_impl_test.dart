import 'package:horus_system/core/errors/failure_codes.dart';
import 'package:horus_system/core/realtime/data/datasources/company_data_changes_remote_data_source.dart';
import 'package:horus_system/core/realtime/data/models/realtime_change_signal.dart';
import 'package:horus_system/core/realtime/data/repositories/company_data_changes_repository_impl.dart';
import 'package:test/test.dart';

void main() {
  test('data errors map to a typed, sanitized failure', () async {
    final repository = CompanyDataChangesRepositoryImpl(_UnavailableSource());
    final results = await repository.watchChanges(companyId: 'company-1').toList();
    expect(results.single.failureOrNull?.code,
        FailureCodes.realtimeSubscriptionUnavailable);
  });
}

final class _UnavailableSource implements CompanyDataChangesRemoteDataSource {
  @override
  Stream<RealtimeChangeSignal> watchCustomers({required String companyId}) {
    return Stream.value(RealtimeChangeSignal.unavailable);
  }
}
