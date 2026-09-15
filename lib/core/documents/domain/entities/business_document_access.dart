final class BusinessDocumentAccess {
  final String value;

  const BusinessDocumentAccess(this.value);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BusinessDocumentAccess && other.value == value;

  @override
  int get hashCode => value.hashCode;
}
