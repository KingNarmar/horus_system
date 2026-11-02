import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Detects dialogs that accidentally inherit a page-scoped Bloc from a
/// sibling Navigator route. Add a widget regression test for any new pattern
/// not covered by this static contract.
void main() {
  test('dialog routes forward page-scoped Bloc providers', () {
    final sources = <String, String>{};
    for (final file in Directory('lib').listSync(recursive: true)) {
      if (file is File && file.path.endsWith('.dart')) {
        sources[file.path] = file.readAsStringSync();
      }
    }

    final dialogSources = <String, String>{};
    final dialogType = RegExp(
      r'\b(?:final\s+|base\s+)?class\s+([A-Z]\w*Dialog)\b',
    );
    for (final source in sources.values) {
      for (final match in dialogType.allMatches(source)) {
        final name = match.group(1)!;
        // Keep original source (including part files and generated delegates).
        dialogSources[name] = source;
      }
    }

    final unscoped = <String>[];
    final riskyDialogNames = <String>{};
    final opensRoute = RegExp(
      r'\b(?:showDialog|showGeneralDialog|showModalBottomSheet)(?:<[^>]+>)?\s*\(',
    );
    final blocLookup = RegExp(
      r'\b(?:BlocBuilder|BlocConsumer|BlocSelector|BlocListener)<',
    );
    final dialogConstructor = RegExp(r'\b([A-Z]\w*Dialog)\s*\(');
    final forwarded = RegExp(
      r'\b(?:MultiBlocProvider|BlocProvider)(?:<[^>]+>)?(?:\.value)?\s*\(',
    );

    for (final entry in sources.entries) {
      final source = entry.value;
      for (final open in opensRoute.allMatches(source)) {
        final openParen = source.indexOf('(', open.start);
        final closeParen = _closingParen(source, openParen);
        if (closeParen < 0) continue;
        final call = source.substring(openParen, closeParen + 1);
        final hasForwarding = forwarded.hasMatch(call);

        final explicitBloc = RegExp(r'\bbloc\s*:').hasMatch(call);
        if (blocLookup.hasMatch(call) && !hasForwarding && !explicitBloc) {
          unscoped.add(
            '${entry.key}:${_line(source, open.start)}: '
            'implicit BlocBuilder/Consumer inside dialog route',
          );
        }

        for (final match in dialogConstructor.allMatches(call)) {
          final name = match.group(1)!;
          final body = dialogSources[name];
          if (body == null) continue;
          if (blocLookup.hasMatch(body) && !hasForwarding && !explicitBloc) {
            unscoped.add(
              '${entry.key}:${_line(source, open.start)}: '
              '$name reads Bloc without forwarded route provider',
            );
          }
          if (body.contains('context.read<') ||
              body.contains('context.watch<')) {
            if (!hasForwarding) {
              riskyDialogNames.add(
                '${entry.key}:${_line(source, open.start)}: $name',
              );
            }
          }
        }
      }
    }

    // Diagnostic inventory of dialogs with a lookup but without an obvious
    // caller-side provider. May include dialogs whose own build creates the
    // provider; review these manually before treating them as violations.
    if (riskyDialogNames.isNotEmpty) {
      // ignore: avoid_print
      print(
        'DIALOG CONTEXT LOOKUP CANDIDATES:\n'
        '${riskyDialogNames.toList()..sort()}',
      );
    }

    expect(unscoped, isEmpty, reason: unscoped.join('\n'));
  });
}

int _line(String source, int offset) =>
    '\n'.allMatches(source.substring(0, offset)).length + 1;

int _closingParen(String source, int start) {
  var depth = 0;
  String? quote;
  for (var i = start; i < source.length; i++) {
    final char = source[i];
    if (quote != null) {
      if (char == '\\') {
        i++;
      } else if (char == quote) {
        quote = null;
      }
      continue;
    }
    if (char == "'" || char == '"') {
      quote = char;
      continue;
    }
    if (char == '/' && i + 1 < source.length && source[i + 1] == '/') {
      while (i < source.length && source[i] != '\n') {
        i++;
      }
      continue;
    }
    if (char == '/' && i + 1 < source.length && source[i + 1] == '*') {
      i += 2;
      while (i + 1 < source.length &&
          !(source[i] == '*' && source[i + 1] == '/')) {
        i++;
      }
      i++;
      continue;
    }
    if (char == '(') depth++;
    if (char == ')') {
      depth--;
      if (depth == 0) return i;
    }
  }
  return -1;
}
