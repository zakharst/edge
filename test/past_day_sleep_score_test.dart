// The score lived only in today's rollup, so a past day on Home showed hours
// and a formula change never reached the nights already on the phone. It is
// rebuilt at read time from the stored nights up to that day.

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';

import 'package:openstrap_edge/compute/derivation_engine.dart';
import 'package:openstrap_edge/compute/inputs/canonical.dart';
import 'package:openstrap_edge/data/db.dart';
import 'package:openstrap_edge/data/day_label.dart';
import 'package:openstrap_edge/ui2/screens/home_screen.dart';

import 'support/app_state_derive_harness.dart';

const _db = 'openstrap_past_day_sleep_score_test.db';

Map<String, dynamic> _night(int day, {double tst = 480, double waso = 10}) {
  final onset = DateTime(2026, 10, day - 1, 23).millisecondsSinceEpoch ~/ 1000;
  return {
    'date': '2026-10-${day.toString().padLeft(2, '0')}',
    'tst_min': tst,
    'efficiency': 95.0,
    'waso_min': waso,
    'awakenings': 1.0,
    'deep_min': 100.0,
    'rem_min': 120.0,
    'onset_sec': onset,
    'wake_sec': onset + 8 * 3600,
    'strain': 0.0,
    'nap_min': 0.0,
  };
}

Future<int?> _scoreOn(String date) async =>
    (HomeData.sleepScoreOf(await crossDayAsOf(date))?['value'] as num?)
        ?.toInt();

void main() {
  setUpAll(() => deriveDbSetUp(_db));
  tearDownAll(() => deriveDbTearDown(_db));

  test('each past night is scored on its own data', () async {
    await LocalDb.putBaseline(
      'crossday_input',
      jsonEncode({
        'algo_version': kAlgoVersion,
        'built_for_day': todayLabel(),
        'review_revision': await LocalDb.activityReviewRevision(),
        'days': [
          _night(10),
          _night(11),
          _night(12),
          _night(13, tst: 300, waso: 80),
          _night(14),
        ],
      }),
    );

    final good = await _scoreOn('2026-10-12');
    final broken = await _scoreOn('2026-10-13');
    expect(good, isNotNull);
    expect(broken, isNotNull);
    expect(broken!, lessThan(good!),
        reason: "the 13th's short, broken night is scored, not today's");
  });
}
