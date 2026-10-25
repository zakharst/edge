// A past day on Home shows that night's own sleep performance, rebuilt at read
// time from the stored nights up to that day, so a change to the reference
// reaches every night already on the phone.

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';

import 'package:openstrap_edge/compute/derivation_engine.dart';
import 'package:openstrap_edge/compute/inputs/canonical.dart';
import 'package:openstrap_edge/data/db.dart';
import 'package:openstrap_edge/data/day_label.dart';
import 'package:openstrap_edge/ui2/screens/home_screen.dart';

import 'support/app_state_derive_harness.dart';

const _db = 'openstrap_past_day_sleep_performance_test.db';

Map<String, dynamic> _night(int day, {double tst = 480}) {
  final onset = DateTime(2026, 10, day - 1, 23).millisecondsSinceEpoch ~/ 1000;
  return {
    'date': '2026-10-${day.toString().padLeft(2, '0')}',
    'tst_min': tst,
    'efficiency': 95.0,
    'onset_sec': onset,
    'wake_sec': onset + 8 * 3600,
    'strain': 0.0,
    'nap_min': 0.0,
  };
}

Future<double?> _perfOn(String date) async =>
    HomeData.sleepPerfOf(await crossDayAsOf(date)).value?.toDouble();

void main() {
  setUpAll(() => deriveDbSetUp(_db));
  tearDownAll(() => deriveDbTearDown(_db));

  test('each past night is measured on its own data', () async {
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
          _night(13, tst: 300),
          _night(14),
        ],
      }),
    );

    final full = await _perfOn('2026-10-12');
    final short = await _perfOn('2026-10-13');
    // The reference is the 7 h adult minimum (420 min). Night 12's 8 h (480 min)
    // is 800 / 7 ≈ 114.29 %, and the 13th's 5 h (300 min) is 500 / 7 ≈ 71.43 %.
    expect(full, closeTo(800 / 7, 1e-6));
    expect(short, closeTo(500 / 7, 1e-6));
  });
}
