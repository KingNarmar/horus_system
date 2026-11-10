import 'package:horus_system/features/fleet/data/repositories/fleet_repository_failure_mapper.dart';
import 'package:horus_system/features/subscriptions/domain/failures/quota_failure_codes.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show PostgrestException;
import 'package:test/test.dart';

void main() {
  test('direct REST quota denials become safe localized conflict failures', () {
    const error = PostgrestException(
      message: QuotaFailureCodes.combinedVehiclesReached,
      code: 'P2860',
    );
    final failure = const FleetRepositoryFailureMapper().fromPostgrest(error);
    expect(failure.code, QuotaFailureCodes.combinedVehiclesReached);
    expect(failure.message, isNull);
  });

  test('malformed DB policy is never reported as available capacity', () {
    const error = PostgrestException(
      message: 'internal backend error',
      code: 'P2862',
    );
    final failure = const FleetRepositoryFailureMapper().fromPostgrest(error);
    expect(failure.code, QuotaFailureCodes.unavailable);
  });
}
