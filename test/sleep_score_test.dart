// The Home sleep ring used to be min(tst / need, 1): anyone who slept their
// need read 100% every morning, whatever the night was like. The score has to
// move with efficiency, disruption, consistency and restoration too.

import 'package:flutter_test/flutter_test.dart';
import 'package:openstrap_edge/compute/sleep_score.dart';

/// [n] nights at the same local clock times, oldest first.
List<SleepWindow> _nights(int n, {int bedH = 23, int wakeH = 7, int jitterMin = 0}) {
  return [
    for (var i = 0; i < n; i++)
      (
        onsetSec: DateTime(2026, 10, 10 + i, bedH, (i.isOdd ? jitterMin : 0))
                .millisecondsSinceEpoch ~/
            1000,
        wakeSec: DateTime(2026, 10, 11 + i, wakeH, (i.isOdd ? jitterMin : 0))
                .millisecondsSinceEpoch ~/
            1000,
      ),
  ];
}

int _score({
  double tst = 480,
  double need = 480,
  double? eff = 95,
  double? waso = 10,
  double? wakes = 1,
  double? deep = 100,
  double? rem = 120,
  List<SleepWindow>? nights,
}) =>
    sleepScore(
      tstMin: tst,
      needMin: need,
      efficiencyPct: eff,
      wasoMin: waso,
      awakenings: wakes,
      deepMin: deep,
      remMin: rem,
      recentNights: nights ?? _nights(4),
    )!['value'] as int;

void main() {
  test('a full, efficient, calm, regular night scores 100', () {
    expect(_score(), 100);
  });

  test('meeting the need is not enough when the night was broken', () {
    final broken = _score(eff: 78, waso: 70, wakes: 8);
    expect(broken, lessThan(75));
    expect(broken, greaterThan(30), reason: 'enough hours still counts');
  });

  test('sleeping past the need does not lift a poor night to 100', () {
    expect(_score(tst: 600, eff: 80, waso: 50), lessThan(90));
  });

  test('short sleep pulls the score down', () {
    expect(_score(tst: 300), lessThan(_score(tst: 450)));
    expect(_score(tst: 450), lessThan(_score()));
  });

  test('irregular bed and wake times cost points', () {
    final irregular = _score(nights: _nights(4, jitterMin: 0) ..add(
      (
        onsetSec: DateTime(2026, 10, 14, 2).millisecondsSinceEpoch ~/ 1000,
        wakeSec: DateTime(2026, 10, 14, 11).millisecondsSinceEpoch ~/ 1000,
      ),
    ));
    expect(irregular, lessThan(_score()));
  });

  test('bedtimes either side of midnight are close, not 23 hours apart', () {
    final nights = [
      for (var i = 0; i < 4; i++)
        (
          onsetSec: DateTime(2026, 10, 10 + i, i.isEven ? 23 : 24, i.isEven ? 50 : 10)
                  .millisecondsSinceEpoch ~/
              1000,
          wakeSec: DateTime(2026, 10, 11 + i, 7).millisecondsSinceEpoch ~/ 1000,
        ),
    ];
    final s = sleepScore(tstMin: 480, needMin: 480, recentNights: nights)!;
    expect((s['components'] as Map)['consistency']['score'], 100);
  });

  test('no total sleep or no need means no score, not a guess', () {
    expect(sleepScore(tstMin: null, needMin: 480), isNull);
    expect(sleepScore(tstMin: 480, needMin: null), isNull);
  });

  test('missing components are reported, and the rest still scores', () {
    final s = sleepScore(tstMin: 480, needMin: 480)!;
    expect(s['value'], 100);
    final c = s['components'] as Map;
    expect(c['sufficiency']['score'], 100);
    for (final k in ['efficiency', 'disruption', 'consistency', 'restoration']) {
      expect(c[k]['score'], isNull, reason: '$k had no input');
    }
  });

  test('two nights are too few to call a rhythm', () {
    final s = sleepScore(tstMin: 480, needMin: 480, recentNights: _nights(2))!;
    expect((s['components'] as Map)['consistency']['score'], isNull);
  });
}
