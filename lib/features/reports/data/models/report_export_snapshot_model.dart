import 'report_model_parsing.dart';

/// Parses the server-frozen metadata without putting database JSON in Domain.
final class ReportExportSnapshotModel {
  final String snapshotId;
  final String sourceKind;
  final Map<String, dynamic> sourceHeader;
  final Map<String, int> streamCounts;

  ReportExportSnapshotModel._({
    required this.snapshotId,
    required this.sourceKind,
    required this.sourceHeader,
    required this.streamCounts,
  });

  factory ReportExportSnapshotModel.fromMap(Map<String, dynamic> source) {
    final id = requiredString(source['snapshot_id'], 'snapshot_id');
    if (id != requiredString(source['snapshot_token'], 'snapshot_token')) {
      throw const FormatException('Mismatched export snapshot token.');
    }
    final header = requiredMap(source['source_header'], 'source_header');
    final company = requiredMap(header['company'], 'company');
    requiredString(company['company_id'], 'company_id');
    requiredMap(header['period'], 'period');
    final rawCounts = requiredMap(source['stream_counts'], 'stream_counts');
    if (rawCounts.isEmpty) {
      throw const FormatException('Missing export stream counts.');
    }
    final counts = <String, int>{};
    for (final entry in rawCounts.entries) {
      final count = requiredInt(entry.value, 'stream_counts');
      if (count < 0) {
        throw const FormatException('Negative export stream count.');
      }
      counts[entry.key] = count;
    }
    return ReportExportSnapshotModel._(
      snapshotId: id,
      sourceKind: requiredString(source['source_kind'], 'source_kind'),
      sourceHeader: Map.unmodifiable(header),
      streamCounts: Map.unmodifiable(counts),
    );
  }

  String get companyId => requiredString(
    requiredMap(sourceHeader['company'], 'company')['company_id'],
    'company_id',
  );

  int countFor(String stream) {
    final count = streamCounts[stream];
    if (count == null) {
      throw FormatException('Missing export stream: $stream.');
    }
    return count;
  }
}

/// Every page carries the same frozen source ID and a strictly bounded array.
final class ReportExportSnapshotPageModel {
  final String snapshotToken;
  final String stream;
  final int totalRows;
  final List<Map<String, dynamic>> rows;
  final String? nextCursor;

  ReportExportSnapshotPageModel._({
    required this.snapshotToken,
    required this.stream,
    required this.totalRows,
    required this.rows,
    required this.nextCursor,
  });

  factory ReportExportSnapshotPageModel.fromMap(Map<String, dynamic> source) {
    final totalRows = requiredInt(source['total_rows'], 'total_rows');
    if (totalRows < 0) throw const FormatException('Negative source count.');
    return ReportExportSnapshotPageModel._(
      snapshotToken: requiredString(source['snapshot_token'], 'snapshot_token'),
      stream: requiredString(source['stream'], 'stream'),
      totalRows: totalRows,
      rows: List.unmodifiable(requiredMapList(source['rows'], 'rows')),
      nextCursor: optionalString(source['next_cursor'], 'next_cursor'),
    );
  }
}
