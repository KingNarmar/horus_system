import 'package:horus_system/core/errors/common_failures.dart';
import 'package:horus_system/core/errors/failure_codes.dart';
import 'package:horus_system/features/routes/data/repositories/route_repository_failure_mapper.dart';
import 'package:horus_system/features/routes/data/constants/route_db_contract.dart';
import 'package:horus_system/features/routes/domain/failures/route_failure_codes.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show PostgrestException;
import 'package:test/test.dart';

void main() {
  group('RouteRepositoryFailureMapper', () {
    const mapper = RouteRepositoryFailureMapper();

    test('maps secured Route read denial to view permission', () {
      const error = PostgrestException(
        message: 'route_read_permission_denied',
        code: RouteDbErrorCodes.readPermissionDenied,
        details: 'do not display this backend detail',
      );
      final failure = mapper.fromPostgrest(error);
      expect(failure, isA<PermissionFailure>());
      expect(failure.code, FailureCodes.permissionRoutesView);
      expect(failure.message, isNull);
    });

    test('maps finance rate stale, invalid input and missing Route', () {
      final cases = <String, String>{
        RouteDbErrorCodes.staleFinancialSnapshot:
            RouteFailureCodes.staleFinancialSnapshot,
        RouteDbErrorCodes.financialRateInvalid:
            FailureCodes.validationRouteFreightRateInvalid,
        RouteDbErrorCodes.financialRouteNotFound:
            RouteFailureCodes.notFound,
      };
      for (final entry in cases.entries) {
        final failure = mapper.fromPostgrest(
          PostgrestException(
            code: entry.key,
            message: 'sensitive SQL context',
            details: 'never show raw',
          ),
        );
        expect(failure.code, entry.value);
        expect(failure.message, isNull);
      }
    });

    test('maps server Route freight permission without raw details', () {
      const error = PostgrestException(
        message: 'route_default_freight_permission_denied',
        code: RouteDbErrorCodes.financialTermsPermissionDenied,
        details: 'internal SQL context',
      );
      final failure = mapper.fromPostgrest(error);
      expect(failure, isA<PermissionFailure>());
      expect(failure.code, RouteFailureCodes.financialTermsPermissionDenied);
      expect(failure.message, isNull);
    });

    test('sanitizes Postgrest failures to stable server error', () {
      const error = PostgrestException(
        message: 'permission denied',
        code: '42501',
        details: 'sensitive details',
        hint: 'sensitive hint',
      );

      final failure = mapper.fromPostgrest(error);

      expect(failure, isA<ServerFailure>());
      expect(failure.code, FailureCodes.serverError);
      expect(failure.message, isNull);
      expect(failure.code, isNot(error.code));
      expect(failure.message, isNot(error.message));
    });

    test('uses stable server error when Postgrest code is absent', () {
      const error = PostgrestException(message: 'database error');

      final failure = mapper.fromPostgrest(error);

      expect(failure, isA<ServerFailure>());
      expect(failure.code, FailureCodes.serverError);
      expect(failure.message, isNull);
    });

    test('sanitizes unexpected failures', () {
      final error = Exception('unexpected internal detail');

      final failure = mapper.fromUnexpected(error);

      expect(failure, isA<UnexpectedFailure>());
      expect(failure.code, FailureCodes.unexpectedError);
      expect(failure.message, isNull);
      expect(failure.message, isNot(error.toString()));
    });
  });
}
