final class BusinessDocumentReference {
  final String value;

  const BusinessDocumentReference(this.value);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BusinessDocumentReference && other.value == value;

  @override
  int get hashCode => value.hashCode;
}
