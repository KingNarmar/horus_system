import 'package:flutter_test/flutter_test.dart';
import 'package:horus_system/core/errors/common_failures.dart';
import 'package:horus_system/features/trips/data/repositories/trip_document_repository_failure_mapper.dart';
import 'package:horus_system/features/trips/domain/failures/trip_document_failure_codes.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  const mapper = TripDocumentRepositoryFailureMapper();

  test('maps max active documents to stable conflict failure', () {
    final failure = mapper.fromPostgrest(
      const PostgrestException(
        message: 'trip_document_max_active',
        code: 'P3423',
      ),
    );

    expect(failure, isA<ConflictFailure>());
    expect(
      failure.code,
      TripDocumentFailureCodes.conflictMaxActiveDocuments,
    );
  });

  test('maps evidence loss to stable conflict failure', () {
    final failure = mapper.fromPostgrest(
      const PostgrestException(
        message: 'trip_document_required_evidence',
        code: 'P3424',
      ),
    );

    expect(failure, isA<ConflictFailure>());
    expect(failure.code, TripDocumentFailureCodes.conflictEvidenceRequired);
  });

  test('maps unknown backend errors to sanitized server failure', () {
    final failure = mapper.fromPostgrest(
      const PostgrestException(message: 'sensitive detail', code: 'XX000'),
    );

    expect(failure, isA<ServerFailure>());
    expect(failure.code, TripDocumentFailureCodes.serverError);
  });
}
