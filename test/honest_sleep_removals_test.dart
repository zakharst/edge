// The invented sleep numbers are deleted, not hidden: the weighted 0-100
// sleep score (weights 0.35/0.20/0.20/0.15/0.10 with no published method), the
// strain bonus on the sleep need and the strain-driven SleepNeedCalculator.
// Nothing in lib/ code may bring them back under the old names; the version
// changelog may still tell their history in comments.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

Iterable<File> _libDart() => Directory('lib')
    .listSync(recursive: true)
    .whereType<File>()
    .where((f) => f.path.endsWith('.dart'));

void main() {
  test('the weighted sleep score file is gone', () {
    expect(File('lib/compute/sleep_score.dart').existsSync(), isFalse);
  });

  test('nothing in lib/ refers to the removed sleep formulas', () {
    const banned = [
      'sleep_score.dart',
      'computeSleepScore',
      'SleepNeedCalculator',
      'SleepNeedResult',
      'strain_bonus',
    ];
    final hits = <String>[
      for (final f in _libDart())
        for (final line in f.readAsLinesSync())
          if (!line.trimLeft().startsWith('//'))
            for (final b in banned)
              if (line.contains(b)) '${f.path}: $b',
    ];
    expect(hits, isEmpty);
  });
}
