// The quiet-waking level now prices only `trimp_net` (the CTL/ATL load).
// Headline strain is WHOOP's client formula (see whoop_day_strain_test.dart)
// and never reads it: a first day scores, and two users with different quiet
// levels get the same strain for the same heart rate.
//
// The day still persists its own `quiet_hrr` for later days, and `trimp_net`
// still waits for three prior levels.

import 'package:flutter_test/flutter_test.dart';

import 'package:openstrap_edge/compute/derivation_engine.dart';
import 'package:openstrap_edge/compute/onehz_pipeline.dart';
import 'package:openstrap_edge/compute/profile.dart';
import 'package:openstrap_edge/compute/substrate.dart';

// A fixed epoch second on a minute boundary, so N minutes of samples are N
// per-minute buckets.
const int _t0 = 1786699980;

/// [bouts] as (minutes, bpm), one sample per second, all of it waking.
Substrate _sub(List<(int, int)> bouts) {
  final ts = <int>[], hr = <int>[];
  final ax = <double>[], ay = <double>[], az = <double>[];
  var i = 0;
  for (final (mins, bpm) in bouts) {
    for (var s = 0; s < mins * 60; s++, i++) {
      ts.add(_t0 + i);
      hr.add(bpm);
      ax.add(0.01 * ((i % 7) - 3));
      ay.add(0.01 * ((i % 5) - 2));
      az.add(1.0);
    }
  }
  final n = ts.length;
  return Substrate(
    tsSec: ts,
    hr: hr,
    rrTsMs: const [],
    rrMs: const [],
    ax: ax,
    ay: ay,
    az: az,
    spo2Red: List<int>.filled(n, 0),
    spo2Ir: List<int>.filled(n, 0),
    skinTemp: List<int>.filled(n, 0),
    skinContact: List<int>.filled(n, 0),
    deviceFamily: 'gen4',
  );
}

/// The `strain_resting_hr_source_test` day: 300 min at 62 bpm, 60 at 130.
Substrate _daySub() => _sub(const [(300, 62), (60, 130)]);

/// RHR 50 / HRmax 187 (age 30): 45 min at 145, then 855 quiet minutes at 64.
Substrate _lowQuietSub() => _sub(const [(45, 145), (855, 64)]);

const _profile = Profile(ageYears: 35, sex: 'm', weightKg: 75, heightCm: 178);
const _profile30 = Profile(ageYears: 30, sex: 'm', weightKg: 75, heightCm: 178);

({Map<String, dynamic> scalars, Map<String, dynamic> bundle}) _run(
  Substrate sub, {
  required List<double> quietHrrHistory,
  Profile profile = _profile,
  double restingHr = 55,
}) {
  final scalars = <String, dynamic>{};
  final bundle = <String, dynamic>{};
  DerivationEngine.applyDayActivity(
    bundle: bundle,
    scalars: scalars,
    daySub: sub,
    profile: profile,
    sleepOnsetSec: 0,
    sleepOffsetSec: 0,
    dayStartSec: sub.tsSec.first,
    dayCalendarEndSec: sub.tsSec.last + 1,
    dataNowSec: sub.tsSec.last + 1,
    restingHr: restingHr,
    quietHrrHistory: quietHrrHistory,
  );
  return (scalars: scalars, bundle: bundle);
}

/// The same day through the pure pipeline. No sleep, so its resting HR is the
/// profile's — set to the anchor the engine half is handed.
Map<String, dynamic> _pipeline(
  Substrate sub, {
  required List<double> quietHrrHistory,
  int age = 35,
  int restingHr = 55,
}) =>
    deriveDayBundle(DayBundleInput(
      date: '2026-08-15',
      dayTsSec: sub.tsSec,
      dayHr: sub.hr,
      sleepTsSec: const [],
      sleepHr: const [],
      sleepRrTsMs: const [],
      sleepRrMs: const [],
      sleepSkinTemp: const [],
      sleepJson: const {},
      hypnoStages: const [],
      sleepOnsetSec: 0,
      sleepOffsetSec: 0,
      profile: {
        'age': age,
        'sex': 'm',
        'weight_kg': 75,
        'height_cm': 178,
        'resting_hr': restingHr,
      },
      deviceFamily: 'gen4',
      quietHrrHistory: quietHrrHistory,
    ).toJson());

void main() {
  group('quiet level prices trimp_net, not strain', () {
    test('no prior levels: strain scores, trimp_net waits', () {
      final r = _run(_daySub(), quietHrrHistory: const []);
      expect(r.scalars['strain'] as num, greaterThan(0));
      expect((r.bundle['absent_notes'] as Map).containsKey('strain'), isFalse);
      expect(r.scalars['trimp_net'], isNull);
      // The day's own level is still persisted for later days.
      expect(r.scalars['quiet_hrr'] as num, closeTo(0.0545, 0.0005));
    });

    test('seven prior levels: net load appears, strain does not move', () {
      final none = _run(_daySub(), quietHrrHistory: const []);
      final r = _run(_daySub(), quietHrrHistory: List.filled(7, 0.20));
      expect(r.scalars['strain'], none.scalars['strain']);
      // 62 bpm against RHR 55 / HRmax 183.5 = 7/128.5. Persisted for LATER
      // days; it never prices this one.
      expect(r.scalars['quiet_hrr'] as num, closeTo(0.0545, 0.0005));
      expect(r.scalars['trimp_net'] as num, closeTo(57.46, 0.1));
    });

    test('the pipeline envelope ignores the quiet history', () {
      Map<String, dynamic> env(int n) => ((_pipeline(_daySub(),
              quietHrrHistory: List.filled(n, 0.20))['clinical']
          as Map)['strain'] as Map).cast<String, dynamic>();
      expect(env(0)['value'], env(7)['value']);
      expect(env(0)['confidence'], env(7)['confidence']);
      expect(env(0)['value'], _run(_daySub(), quietHrrHistory: const [])
          .scalars['strain']);
    });

    test('re-deriving the same day is idempotent', () {
      final runs = [
        for (var i = 0; i < 3; i++)
          _run(_daySub(), quietHrrHistory: List.filled(7, 0.20)).scalars,
      ];
      for (final key in ['strain', 'trimp_net', 'quiet_hrr']) {
        expect(runs[1][key], runs[0][key], reason: key);
        expect(runs[2][key], runs[0][key], reason: key);
      }
    });

    test('a low-quiet user\'s 45-min run scores the same at any quiet level',
        () {
      final own = _run(_lowQuietSub(),
          quietHrrHistory: List.filled(7, 0.10),
          profile: _profile30,
          restingHr: 50);
      final ref = _run(_lowQuietSub(),
          quietHrrHistory: List.filled(7, 0.20),
          profile: _profile30,
          restingHr: 50);
      expect(own.scalars['strain'] as num, greaterThan(0));
      expect(own.scalars['strain'], ref.scalars['strain']);
    });

    test('the curve ends on the engine\'s headline', () {
      final engine = _run(_lowQuietSub(),
          quietHrrHistory: List.filled(7, 0.10),
          profile: _profile30,
          restingHr: 50);
      final bundle = _pipeline(_lowQuietSub(),
          quietHrrHistory: List.filled(7, 0.10), age: 30, restingHr: 50);
      final curve = ((bundle['series'] as Map)['strain_curve'] as List)
          .cast<Map>();
      expect(curve, hasLength(900));
      expect((curve.last['v'] as num).toDouble(),
          closeTo(engine.scalars['strain'] as num, 0.01));
      // Strain only accumulates: nothing banked falls back out.
      for (var i = 1; i < curve.length; i++) {
        expect((curve[i]['v'] as num).toDouble(),
            greaterThanOrEqualTo((curve[i - 1]['v'] as num).toDouble()));
      }
    });
  });
}
