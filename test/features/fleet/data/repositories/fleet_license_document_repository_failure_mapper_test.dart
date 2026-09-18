import 'package:horus_system/core/errors/common_failures.dart';
import 'package:horus_system/features/fleet/data/repositories/fleet_license_document_repository_failure_mapper.dart';
import 'package:horus_system/features/fleet/domain/failures/fleet_license_document_failure_codes.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:test/test.dart';

void main() {
  const mapper = FleetLicenseDocumentRepositoryFailureMapper();

  group('FleetLicenseDocumentRepositoryFailureMapper', () {
    test('maps permission denial to typed permission failure', () {
      final failure = mapper.fromPostgrest(
        const PostgrestException(
          message: 'fleet_license_document_permission_denied',
          code: 'P3430',
        ),
      );

      expect(failure, isA<PermissionFailure>());
      expect(
        failure.code,
        FleetLicenseDocumentFailureCodes.permissionManage,
      );
    });

    test('maps missing active document to typed not-found failure', () {
      final failure = mapper.fromPostgrest(
        const PostgrestException(
          message: 'fleet_license_document_not_found',
          code: 'P3432',
        ),
      );

      expect(failure, isA<NotFoundFailure>());
      expect(failure.code, FleetLicenseDocumentFailureCodes.notFound);
    });

    test('maps one-active conflict to typed conflict failure', () {
      final failure = mapper.fromPostgrest(
        const PostgrestException(
          message: 'fleet_license_document_active_exists',
          code: 'P3433',
        ),
      );

      expect(failure, isA<ConflictFailure>());
      expect(
        failure.code,
        FleetLicenseDocumentFailureCodes.conflictActiveDocumentExists,
      );
    });

    test('sanitizes unknown backend errors', () {
      final failure = mapper.fromPostgrest(
        const PostgrestException(
          message: 'sensitive backend detail',
          code: 'XX000',
        ),
      );

      expect(failure, isA<ServerFailure>());
      expect(failure.code, FleetLicenseDocumentFailureCodes.serverError);
      expect(failure.message, isNull);
    });
  });
}
