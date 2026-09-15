import 'dart:math';

import '../../../errors/common_failures.dart';
import '../../../errors/failure.dart';
import '../../../utils/result.dart';
import '../../domain/entities/business_document_location.dart';
import '../../domain/entities/business_document_reference.dart';
import '../../domain/failures/business_document_failure_codes.dart';
import '../../domain/policies/business_document_file_policy.dart';

typedef BusinessDocumentObjectTokenFactory = String Function();

final class BusinessDocumentObjectPathBuilder {
  static final RegExp _uuidPattern = RegExp(
    r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$',
  );
  static final RegExp _segmentPattern = RegExp(
    r'^[a-z0-9](?:[a-z0-9-]{0,62}[a-z0-9])?$',
  );
  static final RegExp _tokenPattern = RegExp(r'^[0-9a-f]{32}$');
  static final RegExp _referencePattern = RegExp(
    r'^companies/([0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12})/'
    r'([a-z0-9](?:[a-z0-9-]{0,62}[a-z0-9])?)/'
    r'([0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12})/'
    r'([a-z0-9](?:[a-z0-9-]{0,62}[a-z0-9])?)/'
    r'[0-9a-f]{32}\.(?:pdf|jpg|jpeg|png|webp|heic|heif)$',
  );

  final BusinessDocumentObjectTokenFactory _tokenFactory;

  BusinessDocumentObjectPathBuilder({
    BusinessDocumentObjectTokenFactory? tokenFactory,
  }) : _tokenFactory = tokenFactory ?? _secureToken;

  Result<String> build({
    required BusinessDocumentLocation location,
    required String fileName,
  }) {
    final companyId = location.companyId.trim().toLowerCase();
    final scope = location.scope.trim().toLowerCase();
    final entityId = location.entityId.trim().toLowerCase();
    final documentKind = location.documentKind.trim().toLowerCase();

    if (!_uuidPattern.hasMatch(companyId) ||
        !_uuidPattern.hasMatch(entityId) ||
        !_segmentPattern.hasMatch(scope) ||
        !_segmentPattern.hasMatch(documentKind)) {
      return const FailureResult<String>(
        ValidationFailure(
          code: BusinessDocumentFailureCodes.validationLocationInvalid,
        ),
      );
    }

    final extension = BusinessDocumentFilePolicy.extensionForFileName(fileName);
    if (extension == null) {
      return const FailureResult<String>(
        ValidationFailure(
          code: BusinessDocumentFailureCodes.validationFileNameInvalid,
        ),
      );
    }

    final token = _tokenFactory().trim().toLowerCase();
    if (!_tokenPattern.hasMatch(token)) {
      return const FailureResult<String>(
        UnexpectedFailure(
          code: BusinessDocumentFailureCodes.unexpectedError,
        ),
      );
    }

    return Success<String>(
      'companies/$companyId/$scope/$entityId/$documentKind/$token$extension',
    );
  }

  Failure? validateReference({
    required String companyId,
    required BusinessDocumentReference reference,
  }) {
    final normalizedCompanyId = companyId.trim().toLowerCase();
    if (!_uuidPattern.hasMatch(normalizedCompanyId)) {
      return const ValidationFailure(
        code: BusinessDocumentFailureCodes.validationLocationInvalid,
      );
    }

    final match = _referencePattern.firstMatch(reference.value.trim());
    if (match == null) {
      return const ValidationFailure(
        code: BusinessDocumentFailureCodes.validationReferenceInvalid,
      );
    }

    if (match.group(1) != normalizedCompanyId) {
      return const PermissionFailure(
        code: BusinessDocumentFailureCodes.permissionAccess,
      );
    }

    return null;
  }

  static String _secureToken() {
    final random = Random.secure();
    final buffer = StringBuffer();
    for (var index = 0; index < 16; index++) {
      buffer.write(random.nextInt(256).toRadixString(16).padLeft(2, '0'));
    }
    return buffer.toString();
  }
}
