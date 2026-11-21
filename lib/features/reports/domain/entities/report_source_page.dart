/// One bounded, immutable, server-authoritative source page.
///
/// `snapshotToken` identifies a server-frozen result, not a client timestamp.
/// The `nextCursor` is opaque and scoped to that snapshot and source stream.
final class ReportSourcePage<T> {
  final String snapshotToken;
  final int totalRows;
  final List<T> rows;
  final String? nextCursor;

  ReportSourcePage({
    required this.snapshotToken,
    required this.totalRows,
    required List<T> rows,
    required this.nextCursor,
  }) : rows = List.unmodifiable(rows);
}
