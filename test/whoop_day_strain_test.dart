// Day strain is WHOOP's client formula (analytics `whoopStrain`) over the
// day's 1 Hz HR, in both halves: the pure pipeline's envelope and the engine's
// recompute. No quiet-level history, so a first day scores; HRmax is WHOOP's
// regression raised to the lifetime held max; a wearable's minutes-apart HR
// abstains instead of scoring near zero.

import 'package:flutter_test/flutter_test.dart';

import 'package:openstrap_edge/compute/derivation_engine.dart';
import 'package:openstrap_edge/compute/hr_max.dart' show whoopStrainMaxHr;
import 'package:openstrap_edge/compute/inputs/garmin_inputs.dart'
    show kGarminFamily;
import 'package:openstrap_edge/compute/onehz_pipeline.dart';
import 'package:openstrap_edge/compute/profile.dart';
import 'package:openstrap_edge/compute/substrate.dart';

const int _t0 = 1786699980;

/// [bouts] as (minutes, bpm), one sample per second.
Substrate _sub(List<(int, int)> bouts, {String family = 'gen4'}) {
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
    deviceFamily: family,
  );
}

const _profile = Profile(ageYears: 30, sex: 'm', weightKg: 75, heightCm: 178);

({Map<String, dynamic> scalars, Map<String, dynamic> bundle}) _engine(
  Substrate sub, {
  double restingHr = 60,
  double? observedHrCeilingBpm,
}) {
  final scalars = <String, dynamic>{};
  final bundle = <String, dynamic>{};
  DerivationEngine.applyDayActivity(
    bundle: bundle,
    scalars: scalars,
    daySub: sub,
    profile: _profile,
    sleepOnsetSec: 0,
    sleepOffsetSec: 0,
    dayStartSec: sub.tsSec.first,
    dayCalendarEndSec: sub.tsSec.last + 1,
    dataNowSec: sub.tsSec.last + 1,
    restingHr: restingHr,
    observedHrCeilingBpm: observedHrCeilingBpm,
  );
  return (scalars: scalars, bundle: bundle);
}

Map<String, dynamic> _pipeline(Substrate sub, {double? observedHrCeilingBpm}) =>
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
        'age': 30,
        'sex': 'm',
        'weight_kg': 75,
        'height_cm': 178,
        'resting_hr': 60,
      },
      deviceFamily: sub.deviceFamily,
      observedHrCeilingBpm: observedHrCeilingBpm,
    ).toJson());

void main() {
  test('WHOOP regression for a 30 y man is the strain HRmax', () {
    expect(whoopStrainMaxHr(30, 'm'), closeTo(194.22558602834593, 1e-9));
    // The lifetime held max replaces it only when higher.
    expect(whoopStrainMaxHr(30, 'm', lifetimeObservedBpm: 201), 201);
    expect(whoopStrainMaxHr(30, 'm', lifetimeObservedBpm: 180),
        closeTo(194.2256, 1e-4));
    expect(whoopStrainMaxHr(null, 'm'), isNull);
    expect(whoopStrainMaxHr(30, null), isNull);
  });

  test('a first day scores with no quiet-level history (915 @85 + 45 @145)',
      () {
    final sub = _sub(const [(915, 85), (45, 145)]);
    final r = _engine(sub);
    // The analytics scenario table, end to end through the engine.
    expect(r.scalars['strain'], 11.0);
    expect(r.scalars['strain_max_hr'] as num, closeTo(194.2256, 1e-4));
    expect((r.bundle['absent_notes'] as Map).containsKey('strain'), isFalse);
  });

  test('engine and pipeline compute the same strain', () {
    final sub = _sub(const [(870, 85), (90, 165)]);
    final eng = _engine(sub);
    final pipe = _pipeline(sub);
    final env = (pipe['clinical'] as Map)['strain'] as Map;
    expect(env['value'], 18.3);
    expect(eng.scalars['strain'], env['value']);
    expect((pipe['scalars'] as Map)['strain_max_hr'],
        eng.scalars['strain_max_hr']);
    // One point per minute, ending at the headline.
    final curve = (pipe['series'] as Map)['strain_curve'] as List;
    expect(curve.length, 960);
    expect((curve.last as Map)['v'], 18.3);
  });

  test('a higher lifetime ceiling widens the reserve and lowers strain', () {
    final sub = _sub(const [(870, 85), (90, 165)]);
    final base = _engine(sub).scalars['strain'] as num;
    final r = _engine(sub, observedHrCeilingBpm: 205);
    expect(r.scalars['strain_max_hr'], 205);
    expect(r.scalars['strain'] as num, lessThan(base));
    expect(
        (_pipeline(sub, observedHrCeilingBpm: 205)['clinical'] as Map)['strain']
            ['value'],
        r.scalars['strain']);
  });

  test('a wearable family abstains with need_input hr_1hz in both halves', () {
    final sub = _sub(const [(870, 85), (90, 165)], family: kGarminFamily);
    final eng = _engine(sub);
    expect(eng.scalars.containsKey('strain'), isTrue);
    expect(eng.scalars['strain'], isNull);
    expect((eng.bundle['absent_notes'] as Map)['strain'],
        needInputNote('hr_1hz'));
    final env = (_pipeline(sub)['clinical'] as Map)['strain'] as Map;
    expect(env['confidence'], 0);
    expect(env['note'], needInputNote('hr_1hz'));
  });
}
