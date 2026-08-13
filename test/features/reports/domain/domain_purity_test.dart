import 'dart:io';

import 'package:test/test.dart';

void main() {
  test('reports Domain stays independent of Flutter, Supabase and Data', () {
    final root = Directory('lib/features/reports/domain');
    final files = root
        .listSync(recursive: true)
        .whereType<File>()
        .where((file) => file.path.endsWith('.dart'));

    for (final file in files) {
      final source = file.readAsStringSync();
      expect(source, isNot(contains('package:flutter/')), reason: file.path);
      expect(source, isNot(contains('package:supabase')), reason: file.path);
      expect(source, isNot(contains('/data/')), reason: file.path);
      expect(source, isNot(contains('/presentation/')), reason: file.path);
    }
  });
}
