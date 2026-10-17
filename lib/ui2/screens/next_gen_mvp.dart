import 'package:flutter/material.dart';
import 'package:openstrap_analytics/onehz.dart' as ana;

import '../../data/local_repository.dart';
import '../../models/metric.dart';
import '../profile/settings.dart';
import '../screens/journal_compose.dart';
import '../screens/sleep_detail.dart';
import '../screens/wellness_screen.dart';
import '../screens/workout_screen.dart';
import '../grammar.dart';
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
            child: const Text('Experimental metrics could not be read.'),
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
    final note = data.stressNote;
    return _card(
      context,
      onTap: () => _showDetailSheet(
        context,
        title: 'Real-Time & Daily Stress',
        icon: Icons.bolt,
        color: C.orange,
        scoreText: score == null ? 'Not Scored' : score.toStringAsFixed(0),
        subtitle: score == null ? 'Awaiting Rest Period' : '${data.stressLevel ?? 'Measured'} autonomic stress',
        explanation: 'Stress is measured via the Baevsky Stress Index (SI) using heart rate variability (RR intervals) during rest.\n\n'
            'Why does it say not scored yet?\n'
            'Your band captures heart rate continuously, but the Baevsky Stress Index specifically requires consecutive beat-to-beat (RR) intervals when you are resting or sleeping.\n\n'
            'When motion is high (walking, working, working out), RR telemetry contains motion artifacts and cannot form a valid histogram.\n\n'
            'What to do:\n'
            'No manual setup needed. Once you relax, rest or complete tonight’s sleep, the stress score will calculate automatically.',
        actionLabel: 'Open Mind & Stress Dashboard',
        onAction: () => Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (_) => const WellnessScreen()),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _header(context, Icons.bolt, 'STRESS · TAP FOR DETAILS', C.orange),
              Icon(Icons.chevron_right, size: 18, color: P.of(context).ink3),
            ],
          ),
          const SizedBox(height: 12),
          _value(context, score == null ? '—' : score.toStringAsFixed(0)),
          Text(
            score == null
                ? (note != null && note.isNotEmpty
                    ? 'Needs: $note'
                    : 'Awaiting quiet rest or sleep period to calculate Baevsky SI. Tap for details.')
                : '${data.stressLevel ?? 'Measured'} · Baevsky SI: ${data.stressSi?.toStringAsFixed(1) ?? '—'}. Tap for details.',
            style: F.cap.copyWith(color: P.of(context).ink2),
          ),
        ],
      ),
    );
  }

  Widget _bioAgeCard(BuildContext context, _NextGenData data) {
    final result = data.biologicalAge;
    return _card(
      context,
      onTap: () => _showDetailSheet(
        context,
        title: 'Biological Age',
        icon: Icons.favorite,
        color: C.red,
        scoreText: result == null ? 'Calibrating' : '${result.biologicalAge.toStringAsFixed(1)} yrs',
        subtitle: result == null
            ? (data.bioAgeMissingReason ?? 'Missing Baseline Inputs')
            : 'Chronological: ${result.chronologicalAge.toStringAsFixed(0)} yrs',
        explanation: result == null
            ? 'To calculate your Biological Age, the algorithm needs:\n\n'
                '${data.bioAgeChecklist}\n\n'
                'Why this matters:\n'
                'Biological Age compares your cellular and cardiovascular fitness against chronological age benchmarks using VO₂ Max, Resting HR, overnight HRV, sleep consistency and activity.'
            : 'Biological Age estimates your cellular and cardiovascular fitness compared to chronological peers using 4 primary biomarker pillars:\n\n'
                '1. VO₂ Max Estimate (Uth–Sørensen model based on Max HR / Resting HR ratio).\n'
                '2. Overnight HRV (Higher HRV reduces biological age).\n'
                '3. Resting Heart Rate (Sub-50 bpm gives positive rejuvenation credits).\n'
                '4. Lifestyle: Sleep Consistency (SRI) & Average Daily Step volume.\n\n'
                'Requirements to calculate:\n'
                '• Profile Age & Birthdate\n'
                '• 7+ days of Resting HR and overnight HRV\n'
                '• 7+ days of steps recorded\n'
                '• At least 3 nights to calculate Sleep Regularity Index (SRI).',
        actionLabel: data.bioAgeActionLabel,
        onAction: () {
          if (data.bioAgeRequiresProfileEdit) {
            Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const EditProfile()),
            );
          }
        },
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _header(
                context,
                Icons.favorite,
                'BIOLOGICAL AGE · EXPERIMENTAL',
                C.red,
              ),
              Icon(Icons.chevron_right, size: 18, color: P.of(context).ink3),
            ],
          ),
          const SizedBox(height: 12),
          _value(
            context,
            result == null ? '—' : result.biologicalAge.toStringAsFixed(1),
          ),
          Text(
            result == null
                ? 'Missing: ${data.bioAgeMissingReason ?? 'Profile age, measured Max HR, and 7 days of RHR/HRV.'} (Tap to fix)'
                : 'Chronological ${result.chronologicalAge.toStringAsFixed(0)} · '
                    'VO₂ ${_signed(result.vo2Modifier)} · HRV ${_signed(result.hrvModifier)} · '
                    'RHR ${_signed(result.rhrModifier)} · Lifestyle ${_signed(result.lifestyleModifier)}',
            style: F.cap.copyWith(color: P.of(context).ink2),
          ),
        ],
      ),
    );
  }

  Widget _sleepCard(BuildContext context, _NextGenData data) {
    final result = data.sleepNeed;
    return _card(
      context,
      onTap: () => _showDetailSheet(
        context,
        title: 'Sleep Need & Debt Planner',
        icon: Icons.bedtime,
        color: C.blue,
        scoreText: result == null ? 'Calculating' : _hours(result.totalNeedMinutes),
        subtitle: result == null ? 'Awaiting inputs' : 'Tonight’s Recommended Target',
        explanation: 'The Sleep Planner dynamically computes your optimal sleep duration based on physiological exertion:\n\n'
            'Formula: Total Need = Baseline Need + Strain Exertion + Accumulated Sleep Debt − Nap Credits\n\n'
            '• Baseline: Your individual biological baseline (typically ~7h 45m).\n'
            '• Strain Load: High daily cardiovascular strain adds minutes to physiological recovery time.\n'
            '• Sleep Debt: 20% of previous nights’ unfulfilled sleep need is carried over to prevent chronic fatigue.\n'
            '• Nap Credit: Daytime naps recorded by the strap directly reduce tonight’s need.',
        actionLabel: 'View Sleep Analysis',
        onAction: () => Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (_) => SleepDetail(day: widget.dayId)),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _header(
                context,
                Icons.bedtime,
                'SLEEP PLANNER · EXPERIMENTAL',
                C.blue,
              ),
              Icon(Icons.chevron_right, size: 18, color: P.of(context).ink3),
            ],
          ),
          const SizedBox(height: 12),
          _value(
            context,
            result == null ? '—' : _hours(result.totalNeedMinutes),
          ),
          Text(
            result == null
                ? 'Missing: ${data.sleepNeedMissingReason ?? 'Today’s strain or sleep baseline.'} (Tap to view)'
                : 'Base ${result.baselineMinutes.round()}m + Strain ${result.strainMinutes.round()}m + '
                    'Debt ${result.debtMinutes.round()}m − Naps ${result.napCreditMinutes.round()}m',
            style: F.cap.copyWith(color: P.of(context).ink2),
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
      onTap: () => _showDetailSheet(
        context,
        title: 'Journal Habit Insights',
        icon: Icons.book,
        color: C.purple,
        scoreText: row == null ? 'No Insights Yet' : '${row['tag']}',
        subtitle: row == null ? 'Need 5+ tagged days' : '${delta != null && delta >= 0 ? '+' : ''}${delta?.toStringAsFixed(1) ?? ''}% impact on recovery',
        explanation: 'Journal Insights correlate your daily self-reported habits (e.g. late caffeine, alcohol, magnesium, meditation) with your objective morning recovery score and HRV.\n\n'
            'How to get insights?\n'
            'Log your daily behaviors consistently. The engine calculates Welch’s t-test once you have at least 5 days with a habit and 5 days without it, surfacing true statistical correlations.',
        actionLabel: 'Log Today’s Journal',
        onAction: () => Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (_) => JournalCompose(date: widget.dayId)),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _header(context, Icons.book, 'JOURNAL INSIGHTS', C.purple),
              Icon(Icons.chevron_right, size: 18, color: P.of(context).ink3),
            ],
          ),
          const SizedBox(height: 12),
          _value(context, row == null ? '—' : '${row['tag']}'),
          Text(
            row == null || delta == null
                ? 'Missing: at least 5 logged journal entries with tags. Tap to log journal.'
                : '${row['outcome_label']}: ${delta >= 0 ? '+' : ''}${delta.toStringAsFixed(1)}% · '
                    '${row['n_with']} with / ${row['n_without']} without (Tap for details)',
            style: F.cap.copyWith(color: P.of(context).ink2),
          ),
        ],
      ),
    );
  }

  Widget _repCard(BuildContext context) => _card(
    context,
    onTap: () => _showDetailSheet(
      context,
      title: 'Strength Rep Counter',
      icon: Icons.fitness_center,
      color: C.green,
      scoreText: 'Live Sensor Only',
      subtitle: 'Real-time IMU Processing',
      explanation: 'OpenStrap counts exercise repetitions in real time using the band’s high-rate 100 Hz accelerometer and gyroscope.\n\n'
          'Why is history blank?\n'
          'Because high-rate 100 Hz IMU streams are gigabytes per hour and are never stored permanently in device memory. Rep counting runs purely in live RAM during an active workout session.',
      actionLabel: 'Start Workout',
      onAction: () => Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => const WorkoutScreen()),
      ),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _header(context, Icons.fitness_center, 'REP COUNTER', C.green),
            Icon(Icons.chevron_right, size: 18, color: P.of(context).ink3),
          ],
        ),
        const SizedBox(height: 12),
        _value(context, '—'),
        Text(
          'Start a live exercise capture to count reps. Historical high-rate IMU is not stored. Tap for info.',
          style: F.cap.copyWith(color: P.of(context).ink2),
        ),
      ],
    ),
  );

  static void _showDetailSheet(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Color color,
    required String scoreText,
    required String subtitle,
    required String explanation,
    required String actionLabel,
    required VoidCallback onAction,
  }) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: P.of(context).card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 24),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title,
                    style: F.t1.copyWith(
                      color: P.of(sheetContext).ink,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(sheetContext).pop(),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: P.of(sheetContext).bg,
                borderRadius: R.rMd,
              ),
              child: Row(
                children: [
                  Text(
                    scoreText,
                    style: F.display.copyWith(
                      color: P.of(sheetContext).ink,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      subtitle,
                      style: F.head.copyWith(color: P.of(sheetContext).ink2),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              explanation,
              style: F.body.copyWith(
                color: P.of(sheetContext).ink2,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: color,
                  foregroundColor: P.of(sheetContext).inkOnFill,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: R.rMd),
                ),
                onPressed: () {
                  Navigator.of(sheetContext).pop();
                  onAction();
                },
                child: Text(
                  actionLabel,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _signed(double value) =>
      '${value >= 0 ? '+' : ''}${value.toStringAsFixed(1)}y';

  static String _hours(double minutes) {
    final total = minutes.round();
    return '${total ~/ 60}h ${total % 60}m';
  }

  static Widget _value(BuildContext context, String value) => Text(
    value,
    style: F.t2.copyWith(color: P.of(context).ink),
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
        style: F.cap.copyWith(
          color: P.of(context).ink3,
          fontWeight: FontWeight.bold,
        ),
      ),
    ],
  );

  static Widget _card(
    BuildContext context, {
    required Widget child,
    VoidCallback? onTap,
  }) => Card(
    color: P.of(context).card,
    elevation: 0,
    clipBehavior: Clip.antiAlias,
    shape: RoundedRectangleBorder(
      borderRadius: R.rMd,
      side: BorderSide(color: P.of(context).line),
    ),
    margin: const EdgeInsets.only(bottom: 16),
    child: Pressable(
      onTap: onTap,
      child: Padding(padding: const EdgeInsets.all(16), child: child),
    ),
  );
}

class _NextGenData {
  final double? stressScore;
  final double? stressSi;
  final String? stressLevel;
  final String? stressNote;
  final ana.BiologicalAgeResult? biologicalAge;
  final String? bioAgeMissingReason;
  final String bioAgeChecklist;
  final String bioAgeActionLabel;
  final bool bioAgeRequiresProfileEdit;
  final ana.SleepNeedResult? sleepNeed;
  final String? sleepNeedMissingReason;
  final Map<String, dynamic>? journalInsight;

  const _NextGenData({
    this.stressScore,
    this.stressSi,
    this.stressLevel,
    this.stressNote,
    this.biologicalAge,
    this.bioAgeMissingReason,
    this.bioAgeChecklist = '',
    this.bioAgeActionLabel = 'Open Profile',
    this.bioAgeRequiresProfileEdit = false,
    this.sleepNeed,
    this.sleepNeedMissingReason,
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
    final rawStress = results[0] as Map<String, dynamic>;
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
    String? bioMissing;
    final checklistItems = <String>[
      age != null
          ? '✓ Age in Profile: ${age.toStringAsFixed(0)} years'
          : '✗ Profile Age: Missing (tap button below to enter)',
      maxHr != null
          ? '✓ Max Heart Rate: ${maxHr.toStringAsFixed(0)} bpm'
          : '✗ Max HR Ceiling: Need workout/cardio strain data',
      rhr.length >= 7
          ? '✓ Resting HR: ${rhr.length}/7 days baseline recorded'
          : '✗ Resting HR: ${rhr.length}/7 days (wear band for ${7 - rhr.length} more days)',
      hrv.length >= 7
          ? '✓ Overnight HRV: ${hrv.length}/7 days baseline recorded'
          : '✗ Overnight HRV: ${hrv.length}/7 days (sleep with band for ${7 - hrv.length} more nights)',
      steps.length >= 7
          ? '✓ Daily Steps: ${steps.length}/7 days recorded'
          : '✗ Daily Steps: ${steps.length}/7 days (sync band for ${7 - steps.length} more days)',
      sri != null
          ? '✓ Sleep Regularity (SRI): ${sri.toStringAsFixed(0)}%'
          : '✗ Sleep Regularity (SRI): Need 3+ consecutive nights recorded',
    ];
    final bioChecklist = checklistItems.join('\n');

    String bioAction = 'Open Profile';
    bool bioRequiresEdit = false;

    if (age == null) {
      bioMissing = 'Needs your birth date/age in Profile.';
      bioAction = 'Enter Age in Profile';
      bioRequiresEdit = true;
    } else if (maxHr == null) {
      bioMissing = 'Needs Max HR — record a workout or cardio session to set your HR ceiling.';
      bioAction = 'Got it (Requires workout)';
    } else if (rhr.length < 7 || hrv.length < 7) {
      final daysLeft = 7 - (rhr.length < hrv.length ? rhr.length : hrv.length);
      bioMissing = 'Need $daysLeft more days/nights wearing the band to establish your 7-day RHR & HRV baseline.';
      bioAction = 'Got it (Keep wearing band)';
    } else if (steps.length < 7) {
      final stepsLeft = 7 - steps.length;
      bioMissing = 'Need $stepsLeft more days of step tracking to establish your baseline.';
      bioAction = 'Got it (Keep wearing band)';
    } else if (sri == null) {
      bioMissing = 'Need 3+ nights of sleep tracking to calculate Sleep Regularity Index (SRI).';
      bioAction = 'Got it (Sleep with band tonight)';
    } else {
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
    String? sleepMissing;
    if (strain == null) {
      sleepMissing = 'Awaiting day activity — calculated as your daily strain accumulates.';
    } else if (sleepMinutes == null || sleepNeedMinutes == null) {
      sleepMissing = 'Needs last night’s sleep data to calculate carryover sleep debt.';
    } else {
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

    final stressMap = rawStress['stress'] is Map
        ? (rawStress['stress'] as Map).cast<String, dynamic>()
        : rawStress;
    final stressValue = _number(stressMap['score']);
    final stressSi = _number(stressMap['si']);
    final stressLevel = stressMap['level']?.toString();
    final stressNote = stressMap['note']?.toString() ??
        (rawStress['note']?.toString());

    return _NextGenData(
      stressScore: stressValue,
      stressSi: stressSi,
      stressLevel: stressLevel,
      stressNote: stressNote,
      biologicalAge: bio,
      bioAgeMissingReason: bioMissing,
      bioAgeChecklist: bioChecklist,
      bioAgeActionLabel: bioAction,
      bioAgeRequiresProfileEdit: bioRequiresEdit,
      sleepNeed: sleep,
      sleepNeedMissingReason: sleepMissing,
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
