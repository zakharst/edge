// Sleep score 0-100 for last night.
//
// WHOOP's Sleep Performance blends hours vs need, consistency, efficiency and
// sleep stress, and publishes neither the weights nor the curves. This one
// takes the same idea, adds disruption (WASO, awakenings) and a small
// restoration term (deep + REM share), and returns every component next to
// the total so the screen can say WHY the night scored what it did.
//
// Pure and isolate-safe: no DB, no clock, no locale.

/// One night's sleep window, for the consistency term.
typedef SleepWindow = ({int onsetSec, int wakeSec});

/// Component weights. Restoration is deliberately small: the 4-class stager
/// is a low-confidence wrist estimate and Deep is an unvalidated overlay, so
/// it may nudge the score but never carry it.
const kSleepScoreWeights = <String, double>{
  'sufficiency': 0.35,
  'efficiency': 0.20,
  'disruption': 0.20,
  'consistency': 0.15,
  'restoration': 0.10,
};

/// Nights the consistency term looks back over, last night included. WHOOP
/// uses four days for its own consistency figure.
const kConsistencyNights = 4;

/// Linear ramp from [lo] (0) to [hi] (100), clamped. [lo] > [hi] inverts it.
double _ramp(double x, double lo, double hi) =>
    ((x - lo) / (hi - lo)).clamp(0.0, 1.0) * 100.0;

/// Minutes from local noon, so an evening onset and the small hours after
/// midnight sit on one continuous axis (22:00 = 600, 01:00 = 780).
double _fromNoonMin(int epochSec) {
  final t = DateTime.fromMillisecondsSinceEpoch(epochSec * 1000);
  return ((t.hour * 60 + t.minute - 720) % 1440).toDouble();
}

double _meanAbsDev(List<double> xs) {
  final mean = xs.reduce((a, b) => a + b) / xs.length;
  return xs.map((x) => (x - mean).abs()).reduce((a, b) => a + b) / xs.length;
}

/// The score, or null when the night has no total sleep time or no need to
/// measure it against: without sufficiency the rest is not a sleep score.
///
/// Every other component is optional. A missing one is left out and the
/// weights of the present ones are rescaled to sum to 1; the returned
/// `components` says which were scored, so a partial score is never passed
/// off as a full one.
Map<String, dynamic>? sleepScore({
  required double? tstMin,
  required double? needMin,
  double? efficiencyPct,
  double? wasoMin,
  double? awakenings,
  double? deepMin,
  double? remMin,
  List<SleepWindow> recentNights = const [],
}) {
  if (tstMin == null || needMin == null || tstMin <= 0 || needMin <= 0) {
    return null;
  }
  final parts = <String, double?>{
    'sufficiency': _ramp(tstMin / needMin, 0.0, 1.0),
    // 70% in bed asleep is a poor night, 95% is as good as wrist data gets.
    'efficiency': efficiencyPct == null ? null : _ramp(efficiencyPct, 70, 95),
    'disruption': _disruption(wasoMin, awakenings),
    'consistency': _consistency(recentNights),
    // 15% deep + REM is very little restorative sleep, 45% is plenty.
    'restoration': (deepMin == null || remMin == null)
        ? null
        : _ramp((deepMin + remMin) / tstMin, 0.15, 0.45),
  };
  final present = {
    for (final e in parts.entries)
      if (e.value != null) e.key: e.value!,
  };
  final weightSum =
      present.keys.map((k) => kSleepScoreWeights[k]!).reduce((a, b) => a + b);
  final total = present.entries
      .map((e) => e.value * kSleepScoreWeights[e.key]! / weightSum)
      .reduce((a, b) => a + b);
  return {
    'value': total.round(),
    'components': {
      for (final e in parts.entries)
        e.key: {
          'score': e.value?.round(),
          'weight': kSleepScoreWeights[e.key],
        },
    },
    'need_min': needMin.round(),
  };
}

/// WASO 10 min or less is a calm night, 90 min awake is a broken one; 1
/// awakening is nothing, 10 is a lot. Mean of whichever is present.
double? _disruption(double? wasoMin, double? awakenings) {
  final xs = [
    if (wasoMin != null) _ramp(wasoMin, 90, 10),
    if (awakenings != null) _ramp(awakenings, 10, 1),
  ];
  return xs.isEmpty ? null : xs.reduce((a, b) => a + b) / xs.length;
}

/// Mean absolute deviation of bed and wake clock times over the last
/// [kConsistencyNights] nights: within 15 min is 100, an hour and a half of
/// drift or more is 0. Needs three nights to say anything.
double? _consistency(List<SleepWindow> nights) {
  final recent = nights.length > kConsistencyNights
      ? nights.sublist(nights.length - kConsistencyNights)
      : nights;
  if (recent.length < 3) return null;
  final onsetDev = _meanAbsDev([for (final n in recent) _fromNoonMin(n.onsetSec)]);
  final wakeDev = _meanAbsDev([for (final n in recent) _fromNoonMin(n.wakeSec)]);
  return _ramp((onsetDev + wakeDev) / 2, 90, 15);
}
