final class BusinessDocumentReference {
  final String objectKey;

  const BusinessDocumentReference(this.objectKey);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BusinessDocumentReference && other.objectKey == objectKey;

  @override
  int get hashCode => objectKey.hashCode;
}
