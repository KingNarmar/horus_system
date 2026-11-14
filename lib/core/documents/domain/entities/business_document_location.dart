import 'business_document_reference.dart';

final class BusinessDocumentLocation {
  final String companyId;
  final String scope;
  final String entityId;
  final String documentKind;
  final BusinessDocumentReference? replacesReference;

  const BusinessDocumentLocation({
    required this.companyId,
    required this.scope,
    required this.entityId,
    required this.documentKind,
    this.replacesReference,
  });
}
