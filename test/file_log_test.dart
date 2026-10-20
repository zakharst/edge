// FileLog is the only field record of what the BLE stack did overnight. It
// has to keep every line whole, in order, and say when each one happened.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:openstrap_edge/sync/file_log.dart';

void main() {
  late Directory dir;
  late File file;

  setUp(() {
    dir = Directory.systemTemp.createTempSync('file_log_test');
    file = File('${dir.path}/openstrap_sync.log');
    FileLog.useFileForTest(file);
  });
  tearDown(() => dir.deleteSync(recursive: true));

  test('lines written without awaiting land whole and in order', () async {
    // AppState's _log fires FileLog.write unawaited, from every callback that
    // logs, so bursts of concurrent writes are the normal case.
    final writes = [
      for (var i = 0; i < 300; i++)
        FileLog.write('line $i ${'x' * (i % 40)}'),
    ];
    await Future.wait(writes);
    final lines = file.readAsLinesSync();
    expect(lines, hasLength(300));
    for (var i = 0; i < 300; i++) {
      expect(lines[i], endsWith(' line $i ${'x' * (i % 40)}'));
    }
  });

  test('every line starts with the wall-clock time it was written', () async {
    final before = DateTime.now();
    await FileLog.write('Connection dropped');
    final line = file.readAsLinesSync().single;
    final stamp = DateTime.parse(line.split(' ').first);
    expect(stamp.isBefore(before.subtract(const Duration(seconds: 1))), isFalse);
    expect(line, endsWith(' Connection dropped'));
  });
}
