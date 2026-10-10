import 'package:flutter/material.dart';
import 'package:openstrap_analytics/onehz.dart' as ana;

import '../../data/local_repository.dart';
import '../../models/metric.dart';
import '../theme.dart';

/// Data-first preview of the experimental analytics.
///
/// Every value comes from the MOD app's on-device repository. Missing inputs
/// stay missing: this card never substitutes demo values or manufactures a
/// zero. The rep counter is intentionally withheld because live high-rate IMU
/// frames are RAM-only and therefore cannot be reconstructed from history.
class NextGenMvpCard extends StatefulWidget {
  final LocalRepository? repo;
  final String? dayId;
  final Metric strain;
  final Metric sleepMinutes;
  final Metric sleepNeedMinutes;

  const NextGenMvpCard({
    super.key,
    required this.repo,
    required this.dayId,
    this.strain = Metric.empty,
    this.sleepMinutes = Metric.empty,
    this.sleepNeedMinutes = Metric.empty,
  });

  @override
  State<NextGenMvpCard> createState() => _NextGenMvpCardState();
}

class _NextGenMvpCardState extends State<NextGenMvpCard> {
  Future<_NextGenData>? _future;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  @override
  void didUpdateWidget(covariant NextGenMvpCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.repo != widget.repo ||
        oldWidget.dayId != widget.dayId ||
        oldWidget.strain.value != widget.strain.value ||
        oldWidget.sleepMinutes.value != widget.sleepMinutes.value ||
        oldWidget.sleepNeedMinutes.value != widget.sleepNeedMinutes.value) {
      _reload();
    }
  }

  void _reload() {
    final repo = widget.repo;
    final day = widget.dayId;
    _future = repo == null || day == null
        ? null
        : _NextGenData.load(
            repo,
            day: day,
            strain: widget.strain.value?.toDouble(),
            sleepMinutes: widget.sleepMinutes.value?.toDouble(),
            sleepNeedMinutes: widget.sleepNeedMinutes.value?.toDouble(),
          );
  }

  @override
  Widget build(BuildContext context) {
    final future = _future;
    if (future == null) return const SizedBox.shrink();
    return FutureBuilder<_NextGenData>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        final data = snapshot.data;
        if (data == null) {
          return _card(
            context,
            const Text('Experimental metrics could not be read.'),
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _stressCard(context, data),
            _bioAgeCard(context, data),
            _sleepCard(context, data),
            _journalCard(context, data),
            _repCard(context),
          ],
        );
      },
    );
  }

  Widget _stressCard(BuildContext context, _NextGenData data) {
    final score = data.stressScore;
    return _card(
      context,
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _header(context, Icons.bolt, 'STRESS', C.orange),
          const SizedBox(height: 12),
          _value(context, score == null ? '—' : score.toStringAsFixed(0)),
          Text(
            score == null
                ? (data.stressNote ??
                      'Not enough measured RR data for this day.')
                : '${data.stressLevel ?? 'Measured'} · on-device RR analysis',
            style: TextStyle(color: P.of(context).ink2, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _bioAgeCard(BuildContext context, _NextGenData data) {
    final result = data.biologicalAge;
    return _card(
      context,
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _header(
            context,
            Icons.favorite,
            'BIOLOGICAL AGE · EXPERIMENTAL',
            C.red,
          ),
          const SizedBox(height: 12),
          _value(
            context,
            result == null ? '—' : result.biologicalAge.toStringAsFixed(1),
          ),
          Text(
            result == null
                ? 'Needs age, a measured HR ceiling, and enough RHR, HRV, sleep and step history.'
                : 'Chronological ${result.chronologicalAge.toStringAsFixed(0)} · '
                      'VO₂ ${_signed(result.vo2Modifier)} · HRV ${_signed(result.hrvModifier)}',
            style: TextStyle(color: P.of(context).ink2, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _sleepCard(BuildContext context, _NextGenData data) {
    final result = data.sleepNeed;
    return _card(
      context,
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _header(
            context,
            Icons.bedtime,
            'SLEEP PLANNER · EXPERIMENTAL',
            C.blue,
          ),
          const SizedBox(height: 12),
          _value(
            context,
            result == null ? '—' : _hours(result.totalNeedMinutes),
          ),
          Text(
            result == null
                ? 'Needs measured sleep, sleep need and today’s strain.'
                : 'Base ${result.baselineMinutes.round()} min · strain +${result.strainMinutes.round()} · '
                      'debt +${result.debtMinutes.round()} · naps −${result.napCreditMinutes.round()}',
            style: TextStyle(color: P.of(context).ink2, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _journalCard(BuildContext context, _NextGenData data) {
    final row = data.journalInsight;
    final delta = (row?['delta_pct'] as num?)?.toDouble();
    return _card(
      context,
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _header(context, Icons.book, 'JOURNAL INSIGHTS', C.purple),
          const SizedBox(height: 12),
          _value(context, row == null ? '—' : '${row['tag']}'),
          Text(
            row == null || delta == null
                ? 'No supported habit effect yet. More tagged days are needed.'
                : '${row['outcome_label']}: ${delta >= 0 ? '+' : ''}${delta.toStringAsFixed(1)}% · '
                      '${row['n_with']} with / ${row['n_without']} without',
            style: TextStyle(color: P.of(context).ink2, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _repCard(BuildContext context) => _card(
    context,
    Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _header(context, Icons.fitness_center, 'REP COUNTER', C.green),
        const SizedBox(height: 12),
        _value(context, '—'),
        Text(
          'Start a live exercise capture to count reps. Historical high-rate IMU is not stored.',
          style: TextStyle(color: P.of(context).ink2, fontSize: 12),
        ),
      ],
    ),
  );

  static String _signed(double value) =>
      '${value >= 0 ? '+' : ''}${value.toStringAsFixed(1)}y';

  static String _hours(double minutes) {
    final total = minutes.round();
    return '${total ~/ 60}h ${total % 60}m';
  }

  static Widget _value(BuildContext context, String value) => Text(
    value,
    style: TextStyle(
      color: P.of(context).ink,
      fontSize: 22,
      fontWeight: FontWeight.w600,
    ),
  );

  static Widget _header(
    BuildContext context,
    IconData icon,
    String title,
    Color color,
  ) => Row(
    children: [
      Icon(icon, color: color, size: 20),
      const SizedBox(width: 8),
      Text(
        title,
        style: TextStyle(
          color: P.of(context).ink3,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    ],
  );

  static Widget _card(BuildContext context, Widget child) => Card(
    color: P.of(context).card,
    elevation: 0,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
      side: BorderSide(color: P.of(context).line),
    ),
    margin: const EdgeInsets.only(bottom: 16),
    child: Padding(padding: const EdgeInsets.all(16), child: child),
  );
}

class _NextGenData {
  final double? stressScore;
  final String? stressLevel;
  final String? stressNote;
  final ana.BiologicalAgeResult? biologicalAge;
  final ana.SleepNeedResult? sleepNeed;
  final Map<String, dynamic>? journalInsight;

  const _NextGenData({
    this.stressScore,
    this.stressLevel,
    this.stressNote,
    this.biologicalAge,
    this.sleepNeed,
    this.journalInsight,
  });

  static Future<_NextGenData> load(
    LocalRepository repo, {
    required String day,
    required double? strain,
    required double? sleepMinutes,
    required double? sleepNeedMinutes,
  }) async {
    final results = await Future.wait<Object>([
      repo.getDayStress(day),
      repo.getProfile(),
      repo.getZones(),
      repo.getInsights(),
      repo.getJournalInsights(),
      repo.getDayNaps(day),
      repo.getChart('resting_hr'),
      repo.getChart('hrv'),
      repo.getChart('steps'),
    ]);
    final stress = results[0] as Map<String, dynamic>;
    final profile = results[1] as Map<String, dynamic>;
    final zones = results[2] as Map<String, dynamic>;
    final insights = results[3] as Map<String, dynamic>;
    final journal = results[4] as Map<String, dynamic>;
    final naps = results[5] as Map<String, dynamic>;

    final rhr = _tailValues(results[6] as Map<String, dynamic>, 14);
    final hrv = _tailValues(results[7] as Map<String, dynamic>, 14);
    final steps = _tailValues(results[8] as Map<String, dynamic>, 14);
    final age = (profile['age'] as num?)?.toDouble();
    final ceiling = zones['ceiling'];
    final maxHr = ceiling is Map ? (ceiling['bpm'] as num?)?.toDouble() : null;
    final regularity = _envelopeValue(insights['regularity']);
    final sri = regularity is Map
        ? (regularity['sri'] as num?)?.toDouble()
        : null;

    ana.BiologicalAgeResult? bio;
    if (age != null &&
        maxHr != null &&
        rhr.length >= 7 &&
        hrv.length >= 7 &&
        steps.length >= 7 &&
        sri != null) {
      bio = ana.BiologicalAgeCalculator.calculate(
        chronologicalAge: age,
        maxHr: maxHr,
        avgRhr: _mean(rhr),
        avgHrv: _mean(hrv),
        sleepConsistency: (sri.clamp(0, 100) / 100).toDouble(),
        avgDailySteps: _mean(steps),
      );
    }

    ana.SleepNeedResult? sleep;
    if (strain != null && sleepMinutes != null && sleepNeedMinutes != null) {
      sleep = ana.SleepNeedCalculator.calculate(
        strain: strain,
        previousTotalNeed: sleepNeedMinutes,
        previousActualSleep: sleepMinutes,
        napMinutes: (naps['nap_min'] as num?)?.toDouble() ?? 0,
      );
    }

    final journalRows = journal['insights'];
    final firstJournal =
        journalRows is List &&
            journalRows.isNotEmpty &&
            journalRows.first is Map
        ? (journalRows.first as Map).cast<String, dynamic>()
        : null;
    final stressValue = _number(stress['score']);

    return _NextGenData(
      stressScore: stressValue,
      stressLevel: stress['level']?.toString(),
      stressNote: stress['note']?.toString(),
      biologicalAge: bio,
      sleepNeed: sleep,
      journalInsight: firstJournal,
    );
  }

  static Object? _envelopeValue(Object? value) {
    if (value is Map && value.containsKey('value')) return value['value'];
    return value;
  }

  static double? _number(Object? value) {
    final unwrapped = _envelopeValue(value);
    return unwrapped is num ? unwrapped.toDouble() : null;
  }

  static List<double> _tailValues(Map<String, dynamic> chart, int count) {
    final points = chart['points'];
    final values = <double>[
      for (final point in (points is List ? points : const []))
        if (point is Map && point['v'] is num) (point['v'] as num).toDouble(),
    ];
    return values.length <= count
        ? values
        : values.sublist(values.length - count);
  }

  static double _mean(List<double> values) =>
      values.reduce((a, b) => a + b) / values.length;
}
