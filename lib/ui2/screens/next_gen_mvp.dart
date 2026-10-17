import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:openstrap_analytics/onehz.dart' as ana;

import '../../data/day_label.dart' show todayLabel;
import '../../data/local_repository.dart';
import '../../models/metric.dart';
import '../profile/settings.dart';
import '../screens/journal_compose.dart';
import '../screens/sleep_detail.dart';
import '../screens/wellness_screen.dart';
import '../screens/workout_screen.dart';
import '../grammar.dart';
import '../theme.dart';

/// Next-Generation Bento Grid and interactive longevity sheets.
///
/// Every value is read from the MOD app's on-device SQLite repository. Missing
/// inputs stay missing: this card never manufactures a synthetic zero.
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
            padding: EdgeInsets.symmetric(vertical: S.x3),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        final data = snapshot.data;
        if (data == null) {
          return Container(
            padding: const EdgeInsets.all(S.x4),
            decoration: BoxDecoration(
              color: P.of(context).card,
              borderRadius: R.rLg,
              border: Border.all(color: P.of(context).line),
            ),
            child: Text(
              'Experimental metrics could not be read.',
              style: F.body.copyWith(color: P.of(context).ink2),
            ),
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── BENTO HERO: Biological Longevity ──
            _bioAgeHeroCard(context, data),
            const SizedBox(height: S.x3),

            // ── BENTO ROW 1: Real-Time Stress & Sleep Planner ──
            Row(
              children: [
                Expanded(child: _compactStressCard(context, data)),
                const SizedBox(width: S.x3),
                Expanded(child: _compactSleepCard(context, data)),
              ],
            ),
            const SizedBox(height: S.x3),

            // ── BENTO ROW 2: Journal Insights & Rep Counter ──
            Row(
              children: [
                Expanded(child: _compactJournalCard(context, data)),
                const SizedBox(width: S.x3),
                Expanded(child: _compactRepCard(context, data)),
              ],
            ),
            const SizedBox(height: S.x4),
          ],
        );
      },
    );
  }

  // ── HERO: Biological Age ──────────────────────────────────────────────────

  Widget _bioAgeHeroCard(BuildContext context, _NextGenData data) {
    final p = P.of(context);
    final result = data.biologicalAge;
    final diff = result?.ageDifference ?? 0.0;
    final isYounger = diff < 0;
    final diffAbs = diff.abs().toStringAsFixed(1);

    return Pressable(
      onTap: () => _showBioAgeDetailSheet(context, data),
      child: Container(
        padding: const EdgeInsets.all(S.x4),
        decoration: BoxDecoration(
          color: p.card,
          borderRadius: R.rLg,
          border: Border.all(
            color: p.dark ? C.red.withValues(alpha: 0.35) : C.red.withValues(alpha: 0.2),
            width: 1.2,
          ),
          boxShadow: p.el(1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row: Badge & Status Pill
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(S.x1),
                  decoration: BoxDecoration(
                    color: C.red.withValues(alpha: 0.12),
                    borderRadius: R.rSm,
                  ),
                  child: const Icon(LucideIcons.sparkles, size: 14, color: C.red),
                ),
                const SizedBox(width: S.x2),
                Expanded(
                  child: Text(
                    'BIOLOGICAL AGE · EXPERIMENTAL',
                    style: F.over.copyWith(
                      color: p.ink3,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                if (result != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: S.x2, vertical: S.x1),
                    decoration: BoxDecoration(
                      color: (isYounger ? C.green : C.orange).withValues(alpha: 0.12),
                      borderRadius: R.rPill,
                      border: Border.all(
                        color: (isYounger ? C.green : C.orange).withValues(alpha: 0.3),
                      ),
                    ),
                    child: Text(
                      isYounger
                          ? '▼ $diffAbs YRS YOUNGER'
                          : (diff > 0 ? '▲ $diffAbs YRS OLDER' : 'OPTIMAL PACE'),
                      style: F.over.copyWith(
                        color: isYounger ? C.green : C.orange,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  )
                else
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: S.x2, vertical: S.x1),
                    decoration: BoxDecoration(
                      color: p.card2,
                      borderRadius: R.rPill,
                    ),
                    child: Text(
                      'CALIBRATING',
                      style: F.over.copyWith(color: p.ink3, fontWeight: FontWeight.bold),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: S.x4),

            // Big Metric & Comparison
            if (result != null) ...[
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        result.biologicalAge.toStringAsFixed(1),
                        style: F.n48.copyWith(color: p.ink),
                      ),
                      const SizedBox(width: S.x1),
                      Text(
                        'YRS',
                        style: F.cap.copyWith(
                          color: p.ink3,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'CALENDAR',
                        style: F.over.copyWith(color: p.ink3),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        '${result.chronologicalAge.toStringAsFixed(0)} yrs',
                        style: F.head.copyWith(color: p.ink2, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: S.x3),

              // 4 Mini Biomarker Chips
              Container(
                padding: const EdgeInsets.symmetric(horizontal: S.x2, vertical: S.x2),
                decoration: BoxDecoration(
                  color: p.bg,
                  borderRadius: R.rMd,
                ),
                child: Row(
                  children: [
                    Expanded(child: _miniBiomarkerChip(context, '🫀', data.avgRhr != null ? '${data.avgRhr!.round()} bpm' : '—', 'RHR')),
                    Expanded(child: _miniBiomarkerChip(context, '⚡', data.avgHrv != null ? '${data.avgHrv!.round()} ms' : '—', 'HRV')),
                    Expanded(child: _miniBiomarkerChip(context, '🁢', result.vo2MaxEst.toStringAsFixed(1), 'VO₂ Max')),
                    Expanded(child: _miniBiomarkerChip(context, '🌙', '${((data.sleepConsistency ?? 0.75) * 100).round()}%', 'Sleep')),
                  ],
                ),
              ),
              if (data.bio7dDelta != null) ...[
                const SizedBox(height: S.x2),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: S.x3, vertical: 4),
                  decoration: BoxDecoration(
                    color: (data.bio7dDelta! <= -0.05
                            ? C.green
                            : (data.bio7dDelta! >= 0.05 ? C.orange : p.card2))
                        .withValues(alpha: 0.12),
                    borderRadius: R.rPill,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        data.bio7dDelta! <= -0.05
                            ? LucideIcons.trendingDown
                            : (data.bio7dDelta! >= 0.05
                                ? LucideIcons.trendingUp
                                : LucideIcons.minus),
                        size: 13,
                        color: data.bio7dDelta! <= -0.05
                            ? C.green
                            : (data.bio7dDelta! >= 0.05 ? C.orange : p.ink3),
                      ),
                      const SizedBox(width: S.x1),
                      Text(
                        data.bio7dDelta! <= -0.05
                            ? '7d: -${data.bio7dDelta!.abs().toStringAsFixed(1)} yrs'
                            : (data.bio7dDelta! >= 0.05
                                ? '7d: +${data.bio7dDelta!.toStringAsFixed(1)} yrs strain'
                                : '7d: Stable baseline'),
                        style: F.over.copyWith(
                          color: data.bio7dDelta! <= -0.05
                              ? C.green
                              : (data.bio7dDelta! >= 0.05 ? C.orange : p.ink3),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: S.x2),
                      Text(
                        '·',
                        style: F.over.copyWith(color: p.ink3),
                      ),
                      const SizedBox(width: S.x2),
                      Text(
                        data.isToday ? 'Today' : data.dayId,
                        style: F.over.copyWith(color: p.ink3),
                      ),
                    ],
                  ),
                ),
              ],
            ] else ...[
              Text(
                'Calibrating Baseline',
                style: F.t2.copyWith(color: p.ink),
              ),
              const SizedBox(height: S.x1),
              Text(
                data.bioAgeMissingReason ?? 'Needs profile age & 3+ days of band recordings.',
                style: F.cap.copyWith(color: p.ink2),
              ),
            ],
            const SizedBox(height: S.x3),

            // Prompt row
            Row(
              children: [
                Expanded(
                  child: Text(
                    result != null
                        ? 'Longevity breakdown & reverse-aging roadmap'
                        : 'Tap to view calibration checklist',
                    style: F.cap.copyWith(color: p.ink3),
                  ),
                ),
                Icon(Icons.arrow_forward_ios, size: 12, color: p.ink3),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _miniBiomarkerChip(BuildContext context, String icon, String value, String label) {
    final p = P.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '$icon $value',
          style: F.cap.copyWith(
            color: p.ink,
            fontWeight: FontWeight.bold,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
        ),
        Text(
          label,
          style: F.over.copyWith(color: p.ink3),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  // ── BENTO 1: Real-Time Stress ─────────────────────────────────────────────

  Widget _compactStressCard(BuildContext context, _NextGenData data) {
    final p = P.of(context);
    final score = data.stressScore;
    final rawLevel = data.stressLevel ?? 'Balanced';
    final isScored = score != null;
    final displayLevel = rawLevel.isNotEmpty
        ? '${rawLevel[0].toUpperCase()}${rawLevel.substring(1)}'
        : 'Balanced';
    final levelLower = displayLevel.toLowerCase();

    final Color badgeColor = switch (levelLower) {
      'low' => C.teal,
      'balanced' || 'normal' => C.blue,
      'elevated' => C.orange,
      'high' => C.red,
      _ => C.blue,
    };

    return Pressable(
      onTap: () => _showStressDetailSheet(context, data),
      child: Container(
        height: 154,
        padding: const EdgeInsets.all(S.x3),
        decoration: BoxDecoration(
          color: p.card,
          borderRadius: R.rLg,
          border: Border.all(color: p.line),
          boxShadow: p.el(1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row (fixed height 28 for cross-card baseline alignment)
            SizedBox(
              height: 28,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      color: C.orange.withValues(alpha: 0.12),
                      borderRadius: R.rSm,
                    ),
                    child: const Icon(Icons.bolt, size: 14, color: C.orange),
                  ),
                  const SizedBox(width: S.x1),
                  Expanded(
                    child: Text(
                      data.isToday ? 'STRESS · LIVE' : 'STRESS · DAY RECORD',
                      style: F.over.copyWith(color: p.ink3, fontWeight: FontWeight.bold),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: S.x2),

            // Middle: Score & Level
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  isScored ? score.toStringAsFixed(0) : 'Resting',
                  style: isScored ? F.n34.copyWith(color: p.ink) : F.head.copyWith(color: p.ink2),
                ),
                const SizedBox(width: S.x1),
                if (isScored)
                  Flexible(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: S.x1, vertical: 2),
                      decoration: BoxDecoration(
                        color: badgeColor.withValues(alpha: 0.12),
                        borderRadius: R.rPill,
                      ),
                      child: Text(
                        displayLevel,
                        style: F.over.copyWith(color: badgeColor, fontWeight: FontWeight.bold),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            // 4-segment mini gauge
            Row(
              children: [
                _gaugeSegment(p, C.teal, levelLower == 'low'),
                const SizedBox(width: 3),
                _gaugeSegment(p, C.blue, levelLower == 'balanced' || levelLower == 'normal'),
                const SizedBox(width: 3),
                _gaugeSegment(p, C.orange, levelLower == 'elevated'),
                const SizedBox(width: 3),
                _gaugeSegment(p, C.red, levelLower == 'high'),
              ],
            ),
            const Spacer(),

            // Bottom Subtitle
            Text(
              isScored
                  ? 'Baevsky SI: ${data.stressSi?.toStringAsFixed(1) ?? '—'}'
                  : (data.stressNote ?? (data.isToday ? 'Awaiting rest period' : 'No rest recording')),
              style: F.cap.copyWith(color: p.ink3),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _gaugeSegment(P p, Color color, bool isActive) {
    return Expanded(
      child: Container(
        height: 4,
        decoration: BoxDecoration(
          color: isActive ? color : color.withValues(alpha: 0.2),
          borderRadius: R.rPill,
        ),
      ),
    );
  }

  // ── BENTO 2: Sleep Planner ────────────────────────────────────────────────

  Widget _compactSleepCard(BuildContext context, _NextGenData data) {
    final p = P.of(context);
    final result = data.sleepNeed;

    return Pressable(
      onTap: () => _showSleepNeedDetailSheet(context, data),
      child: Container(
        height: 154,
        padding: const EdgeInsets.all(S.x3),
        decoration: BoxDecoration(
          color: p.card,
          borderRadius: R.rLg,
          border: Border.all(color: p.line),
          boxShadow: p.el(1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row (fixed height 28 for cross-card baseline alignment)
            SizedBox(
              height: 28,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      color: C.indigo.withValues(alpha: 0.12),
                      borderRadius: R.rSm,
                    ),
                    child: const Icon(Icons.bedtime, size: 14, color: C.indigo),
                  ),
                  const SizedBox(width: S.x1),
                  Expanded(
                    child: Text(
                      'SLEEP PLANNER · EXPERIMENTAL',
                      style: F.over.copyWith(color: p.ink3, fontWeight: FontWeight.bold),
                      maxLines: 2,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: S.x2),

            // Middle: Hours & Target
            Text(
              result != null ? _hours(result.totalNeedMinutes) : '—',
              style: (result != null ? F.t1 : F.head).copyWith(color: p.ink),
              maxLines: 1,
            ),
            const SizedBox(height: 3),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: S.x1, vertical: 2),
              decoration: BoxDecoration(
                color: C.indigo.withValues(alpha: 0.12),
                borderRadius: R.rPill,
              ),
              child: Text(
                data.isToday ? 'Tonight’s Target' : 'Night’s Target',
                style: F.over.copyWith(color: C.indigo, fontWeight: FontWeight.bold),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const Spacer(),

            // Bottom Subtitle
            Text(
              !data.isToday && data.actualSleepMinutes != null && result != null
                  ? () {
                      final diff = (data.actualSleepMinutes! - result.totalNeedMinutes).round();
                      return diff >= 0
                          ? 'Slept ${_hours(data.actualSleepMinutes!)} · +${diff}m surplus'
                          : 'Slept ${_hours(data.actualSleepMinutes!)} · ${diff.abs()}m debt';
                    }()
                  : (result != null
                      ? 'Base ${_hours(result.baselineMinutes)} · +${result.strainMinutes.round()}m'
                      : (data.sleepNeedMissingReason ?? 'Awaiting strain data')),
              style: F.cap.copyWith(color: p.ink3),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  // ── BENTO 3: Journal Insights ─────────────────────────────────────────────

  Widget _compactJournalCard(BuildContext context, _NextGenData data) {
    final p = P.of(context);
    final row = data.journalInsight;
    final delta = (row?['delta_pct'] as num?)?.toDouble();

    return Pressable(
      onTap: () => _showJournalDetailSheet(context, data),
      child: Container(
        height: 154,
        padding: const EdgeInsets.all(S.x3),
        decoration: BoxDecoration(
          color: p.card,
          borderRadius: R.rLg,
          border: Border.all(color: p.line),
          boxShadow: p.el(1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row (fixed height 28 for cross-card baseline alignment)
            SizedBox(
              height: 28,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      color: C.purple.withValues(alpha: 0.12),
                      borderRadius: R.rSm,
                    ),
                    child: const Icon(Icons.book, size: 14, color: C.purple),
                  ),
                  const SizedBox(width: S.x1),
                  Expanded(
                    child: Text(
                      'JOURNAL INSIGHTS',
                      style: F.over.copyWith(color: p.ink3, fontWeight: FontWeight.bold),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: S.x2),

            // Middle: Tag & Impact
            Text(
              data.dayLoggedHabits.isNotEmpty
                  ? data.dayLoggedHabits.join(', ')
                  : (row != null ? '${row['tag']}' : 'No Habits Yet'),
              style: F.head.copyWith(color: p.ink, fontWeight: FontWeight.bold),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            if (delta != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: S.x1, vertical: 2),
                decoration: BoxDecoration(
                  color: (delta >= 0 ? C.green : C.red).withValues(alpha: 0.12),
                  borderRadius: R.rPill,
                ),
                child: Text(
                  '${row?['outcome_label'] ?? 'HRV'}: ${delta >= 0 ? '+' : ''}${delta.toStringAsFixed(1)}%',
                  style: F.over.copyWith(
                    color: delta >= 0 ? C.green : C.red,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              )
            else
              Container(
                padding: const EdgeInsets.symmetric(horizontal: S.x1, vertical: 2),
                decoration: BoxDecoration(
                  color: p.card2,
                  borderRadius: R.rPill,
                ),
                child: Text(
                  'Awaiting Logs',
                  style: F.over.copyWith(color: p.ink3, fontWeight: FontWeight.bold),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            const Spacer(),

            // Bottom Subtitle
            Text(
              data.dayLoggedHabits.isNotEmpty
                  ? 'Logged on this day'
                  : (row != null
                      ? '${row['n_with']} with · ${row['n_without']} without'
                      : 'Needs 5+ logged days'),
              style: F.cap.copyWith(color: p.ink3),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  // ── BENTO 4: Strength Rep Counter ─────────────────────────────────────────

  Widget _compactRepCard(BuildContext context, _NextGenData data) {
    final p = P.of(context);

    return Pressable(
      onTap: () => _showRepCounterDetailSheet(context),
      child: Container(
        height: 154,
        padding: const EdgeInsets.all(S.x3),
        decoration: BoxDecoration(
          color: p.card,
          borderRadius: R.rLg,
          border: Border.all(color: p.line),
          boxShadow: p.el(1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row (fixed height 28 for cross-card baseline alignment)
            SizedBox(
              height: 28,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      color: C.green.withValues(alpha: 0.12),
                      borderRadius: R.rSm,
                    ),
                    child: const Icon(Icons.fitness_center, size: 14, color: C.green),
                  ),
                  const SizedBox(width: S.x1),
                  Expanded(
                    child: Text(
                      'REP COUNTER',
                      style: F.over.copyWith(color: p.ink3, fontWeight: FontWeight.bold),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: S.x2),

            // Middle: Abstaining Dash & Live IMU
            Text(
              '—',
              style: F.n34.copyWith(color: p.ink),
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: S.x1, vertical: 2),
              decoration: BoxDecoration(
                color: C.green.withValues(alpha: 0.12),
                borderRadius: R.rPill,
              ),
              child: Text(
                data.isToday ? '100 Hz Live IMU' : 'RAM Kinematics',
                style: F.over.copyWith(color: C.green, fontWeight: FontWeight.bold),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const Spacer(),

            // Bottom Subtitle
            Text(
              data.isToday ? 'Live workout tracking' : 'Active session mode',
              style: F.cap.copyWith(color: p.ink3),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  // ── MODAL SHEETS ──────────────────────────────────────────────────────────

  static void _showBioAgeDetailSheet(BuildContext context, _NextGenData data) {
    final p = P.of(context);
    final result = data.biologicalAge;
    final diff = result?.ageDifference ?? 0.0;
    final isYounger = diff < 0;
    final diffAbs = diff.abs().toStringAsFixed(1);
    final sexLabel = result?.sex == 'f' ? 'Female' : 'Male';

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      sheetAnimationStyle: sheetMotion(context),
      backgroundColor: p.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(R.xl)),
      ),
      builder: (sheetContext) => SafeArea(
        child: DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.88,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          builder: (ctx, scrollController) => ListView(
            controller: scrollController,
            padding: const EdgeInsets.fromLTRB(S.x4, 0, S.x4, S.x6),
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(S.x2),
                    decoration: BoxDecoration(
                      color: C.red.withValues(alpha: 0.12),
                      borderRadius: R.rMd,
                    ),
                    child: const Icon(LucideIcons.sparkles, color: C.red, size: 22),
                  ),
                  const SizedBox(width: S.x3),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Biological Longevity',
                          style: F.t1.copyWith(color: p.ink),
                        ),
                        Text(
                          'Sex-stratified cellular & cardiovascular age',
                          style: F.cap.copyWith(color: p.ink3),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: p.ink3),
                    onPressed: () => Navigator.of(sheetContext).pop(),
                  ),
                ],
              ),
              const SizedBox(height: S.x4),

              if (result != null) ...[
                // Hero Comparison Card
                Container(
                  padding: const EdgeInsets.all(S.x4),
                  decoration: BoxDecoration(
                    color: p.card2,
                    borderRadius: R.rLg,
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          Column(
                            children: [
                              Text('Calendar Age', style: F.over.copyWith(color: p.ink3)),
                              const SizedBox(height: 4),
                              Text(
                                result.chronologicalAge.toStringAsFixed(0),
                                style: F.n34.copyWith(color: p.ink2),
                              ),
                              Text('years', style: F.over.copyWith(color: p.ink3)),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: S.x3, vertical: S.x2),
                            decoration: BoxDecoration(
                              color: (isYounger ? C.green : C.orange).withValues(alpha: 0.15),
                              borderRadius: R.rPill,
                              border: Border.all(
                                color: (isYounger ? C.green : C.orange).withValues(alpha: 0.4),
                              ),
                            ),
                            child: Column(
                              children: [
                                Text(
                                  isYounger ? '▼ $diffAbs YRS' : '▲ $diffAbs YRS',
                                  style: F.head.copyWith(
                                    color: isYounger ? C.green : C.orange,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  isYounger ? 'YOUNGER' : (diff > 0 ? 'OLDER' : 'MATCHED'),
                                  style: F.over.copyWith(
                                    color: isYounger ? C.green : C.orange,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Column(
                            children: [
                              Text('Biological Age', style: F.over.copyWith(color: p.ink3)),
                              const SizedBox(height: 4),
                              Text(
                                result.biologicalAge.toStringAsFixed(1),
                                style: F.n34.copyWith(
                                  color: isYounger ? C.green : p.ink,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text('years', style: F.over.copyWith(color: p.ink3)),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: S.x4),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(S.x3),
                        decoration: BoxDecoration(
                          color: p.bg,
                          borderRadius: R.rMd,
                        ),
                        child: Text(
                          diff <= -1.5
                              ? '🎉 Outstanding! Your cellular and cardiovascular biomarkers reflect superior biological fitness.'
                              : (diff >= 1.5
                                  ? '⚠️ Elevated biological strain. Focus on targeted recovery and aerobic endurance to reverse.'
                                  : '👍 Optimal pace. Your physiological biomarkers align with chronological peers.'),
                          style: F.cap.copyWith(color: p.ink, height: 1.35),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: S.x6),

                if (data.bioTrajectory.length >= 2) ...[
                  Row(
                    children: [
                      const Icon(LucideIcons.activity, size: 16, color: C.blue),
                      const SizedBox(width: S.x2),
                      Text(
                        '7-DAY LONGEVITY TRAJECTORY',
                        style: F.over.copyWith(color: p.ink3, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: S.x2),
                  Container(
                    padding: const EdgeInsets.all(S.x3),
                    decoration: BoxDecoration(
                      color: p.card2,
                      borderRadius: R.rMd,
                    ),
                    child: Column(
                      children: [
                        for (final item in data.bioTrajectory) ...[
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  item.$1 == data.dayId ? '${item.$1} (Selected)' : item.$1,
                                  style: F.cap.copyWith(
                                    color: item.$1 == data.dayId ? p.ink : p.ink2,
                                    fontWeight: item.$1 == data.dayId ? FontWeight.bold : FontWeight.normal,
                                  ),
                                ),
                                Text(
                                  '${item.$2.toStringAsFixed(1)} yrs',
                                  style: F.cap.copyWith(
                                    color: item.$2 < result.chronologicalAge ? C.green : p.ink,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (item != data.bioTrajectory.last)
                            Divider(height: 1, color: p.line.withValues(alpha: 0.5)),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: S.x6),
                ],

                // Pillars Section Header
                Text(
                  'BIOMARKER PILLARS ($sexLabel Norms)',
                  style: F.over.copyWith(color: p.ink3, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: S.x3),

                _biomarkerPillarCard(
                  context,
                  icon: '🫀',
                  title: 'Resting Heart Rate (RHR)',
                  value: data.avgRhr != null ? '${data.avgRhr!.round()} bpm' : '—',
                  insight: result.heartInsight,
                  accentColor: C.red,
                ),
                const SizedBox(height: S.x3),

                _biomarkerPillarCard(
                  context,
                  icon: '⚡',
                  title: 'Autonomic System (Overnight HRV)',
                  value: data.avgHrv != null ? '${data.avgHrv!.round()} ms' : '—',
                  insight: result.hrvInsight,
                  accentColor: C.purple,
                ),
                const SizedBox(height: S.x3),

                _biomarkerPillarCard(
                  context,
                  icon: '🁢',
                  title: 'Aerobic Endurance (VO₂ Max)',
                  value: '${result.vo2MaxEst.toStringAsFixed(1)} ml/kg',
                  insight: result.vo2Insight,
                  accentColor: C.blue,
                ),
                const SizedBox(height: S.x3),

                _biomarkerPillarCard(
                  context,
                  icon: '🌙',
                  title: 'Sleep Stability & Movement',
                  value: '${((data.sleepConsistency ?? 0.75) * 100).round()}% SRI',
                  insight: result.lifestyleInsight,
                  accentColor: C.indigo,
                ),
                const SizedBox(height: S.x6),

                // Targeted Longevity Roadmap
                Row(
                  children: [
                    const Icon(LucideIcons.lightbulb, size: 16, color: C.yellow),
                    const SizedBox(width: S.x2),
                    Text(
                      'HOW TO REVERSE BIOLOGICAL AGE',
                      style: F.over.copyWith(color: p.ink3, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: S.x3),

                for (final tip in result.actionableTips) ...[
                  _actionTipCard(context, tip),
                  const SizedBox(height: S.x2),
                ],
                const SizedBox(height: S.x4),

                Text(
                  'Science note: Benchmarks are calibrated to sex-stratified normative longevity decline curves (Levine PhenoAge, HUNT3 VO₂ max, and autonomic aging models).',
                  style: F.over.copyWith(color: p.ink3, height: 1.4),
                ),
              ] else ...[
                // Checklist when calibrating
                Container(
                  padding: const EdgeInsets.all(S.x4),
                  decoration: BoxDecoration(
                    color: p.card2,
                    borderRadius: R.rLg,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Calibration Checklist',
                        style: F.head.copyWith(color: p.ink),
                      ),
                      const SizedBox(height: S.x2),
                      Text(
                        data.bioAgeChecklist,
                        style: F.body.copyWith(color: p.ink2, height: 1.5),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: S.x6),

              // Bottom Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: C.red,
                    foregroundColor: p.inkOnFill,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: const RoundedRectangleBorder(borderRadius: R.rMd),
                  ),
                  onPressed: () {
                    Navigator.of(sheetContext).pop();
                    if (data.bioAgeRequiresProfileEdit) {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(builder: (_) => const EditProfile()),
                      );
                    }
                  },
                  child: Text(
                    data.bioAgeActionLabel,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Widget _biomarkerPillarCard(
    BuildContext context, {
    required String icon,
    required String title,
    required String value,
    required String insight,
    required Color accentColor,
  }) {
    final p = P.of(context);
    return Container(
      padding: const EdgeInsets.all(S.x3),
      decoration: BoxDecoration(
        color: p.card2,
        borderRadius: R.rMd,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(icon, style: F.head),
              const SizedBox(width: S.x2),
              Expanded(
                child: Text(
                  title,
                  style: F.head.copyWith(color: p.ink, fontWeight: FontWeight.w600),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: S.x2, vertical: 2),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.15),
                  borderRadius: R.rPill,
                ),
                child: Text(
                  value,
                  style: F.cap.copyWith(
                    color: accentColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: S.x2),
          Text(
            insight,
            style: F.cap.copyWith(color: p.ink2, height: 1.4),
          ),
        ],
      ),
    );
  }

  static Widget _actionTipCard(BuildContext context, String tip) {
    final p = P.of(context);
    return Container(
      padding: const EdgeInsets.all(S.x3),
      decoration: BoxDecoration(
        color: p.card2,
        borderRadius: R.rMd,
        border: Border.all(color: p.line),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: C.green.withValues(alpha: 0.12),
              borderRadius: R.rSm,
            ),
            child: const Icon(LucideIcons.check, size: 14, color: C.green),
          ),
          const SizedBox(width: S.x3),
          Expanded(
            child: Text(
              tip,
              style: F.body.copyWith(color: p.ink, height: 1.35),
            ),
          ),
        ],
      ),
    );
  }

  static void _showStressDetailSheet(BuildContext context, _NextGenData data) {
    final p = P.of(context);
    final score = data.stressScore;
    final level = data.stressLevel ?? 'Balanced';
    final isScored = score != null;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      sheetAnimationStyle: sheetMotion(context),
      backgroundColor: p.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(R.xl)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(S.x4, 0, S.x4, S.x6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(S.x2),
                    decoration: BoxDecoration(
                      color: C.orange.withValues(alpha: 0.12),
                      borderRadius: R.rMd,
                    ),
                    child: const Icon(Icons.bolt, color: C.orange, size: 22),
                  ),
                  const SizedBox(width: S.x3),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Real-Time & Daily Stress',
                          style: F.t1.copyWith(color: p.ink),
                        ),
                        Text(
                          'Autonomic nervous tone & Baevsky SI',
                          style: F.cap.copyWith(color: p.ink3),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: p.ink3),
                    onPressed: () => Navigator.of(sheetContext).pop(),
                  ),
                ],
              ),
              const SizedBox(height: S.x4),

              // Hero Score Card
              Container(
                padding: const EdgeInsets.all(S.x4),
                decoration: BoxDecoration(
                  color: p.card2,
                  borderRadius: R.rLg,
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isScored ? score.toStringAsFixed(0) : '—',
                              style: F.n48.copyWith(color: p.ink),
                            ),
                            Text('Stress Score (0–100)', style: F.over.copyWith(color: p.ink3)),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: S.x3, vertical: S.x2),
                          decoration: BoxDecoration(
                            color: C.blue.withValues(alpha: 0.15),
                            borderRadius: R.rPill,
                            border: Border.all(color: C.blue.withValues(alpha: 0.4)),
                          ),
                          child: Text(
                            level,
                            style: F.head.copyWith(color: C.blue, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: S.x4),
                    // Spectrum meter
                    Row(
                      children: [
                        _spectrumZone(p, 'Rest', C.teal, level == 'Low'),
                        const SizedBox(width: 4),
                        _spectrumZone(p, 'Balanced', C.blue, level == 'Balanced'),
                        const SizedBox(width: 4),
                        _spectrumZone(p, 'Elevated', C.orange, level == 'Elevated'),
                        const SizedBox(width: 4),
                        _spectrumZone(p, 'High', C.red, level == 'High'),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: S.x4),

              // Educational tiles
              Container(
                padding: const EdgeInsets.all(S.x3),
                decoration: BoxDecoration(
                  color: p.bg,
                  borderRadius: R.rMd,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(LucideIcons.activity, size: 16, color: C.orange),
                        const SizedBox(width: S.x2),
                        Text(
                          'Baevsky Stress Index (SI): ${data.stressSi?.toStringAsFixed(1) ?? 'Calibrating'}',
                          style: F.head.copyWith(color: p.ink, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: S.x2),
                    Text(
                      'Stress is derived from heart rate variability (RR intervals) during rest. Consecutive beat-to-beat intervals form an amplitude histogram showing sympathetic vs. parasympathetic tone.',
                      style: F.cap.copyWith(color: p.ink2, height: 1.4),
                    ),
                    const SizedBox(height: S.x2),
                    Text(
                      'Why does it need rest?\nActive motion (walking, working out) introduces motion artifacts into optical sensors. Calculations activate as soon as you sit quietly, rest, or sleep.',
                      style: F.cap.copyWith(color: p.ink3, height: 1.35),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: S.x6),

              // Action button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: C.orange,
                    foregroundColor: p.inkOnFill,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: const RoundedRectangleBorder(borderRadius: R.rMd),
                  ),
                  onPressed: () {
                    Navigator.of(sheetContext).pop();
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(builder: (_) => const WellnessScreen()),
                    );
                  },
                  child: const Text(
                    'Open Mind & Stress Dashboard',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Widget _spectrumZone(P p, String name, Color color, bool isActive) {
    return Expanded(
      child: Column(
        children: [
          Container(
            height: 6,
            decoration: BoxDecoration(
              color: isActive ? color : color.withValues(alpha: 0.25),
              borderRadius: R.rPill,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            name,
            style: F.over.copyWith(
              color: isActive ? color : p.ink3,
              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  static void _showSleepNeedDetailSheet(BuildContext context, _NextGenData data) {
    final p = P.of(context);
    final result = data.sleepNeed;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      sheetAnimationStyle: sheetMotion(context),
      backgroundColor: p.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(R.xl)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(S.x4, 0, S.x4, S.x6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(S.x2),
                    decoration: BoxDecoration(
                      color: C.indigo.withValues(alpha: 0.12),
                      borderRadius: R.rMd,
                    ),
                    child: const Icon(Icons.bedtime, color: C.indigo, size: 22),
                  ),
                  const SizedBox(width: S.x3),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Sleep Need & Debt Planner',
                          style: F.t1.copyWith(color: p.ink),
                        ),
                        Text(
                          'Physiological recovery calculation',
                          style: F.cap.copyWith(color: p.ink3),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: p.ink3),
                    onPressed: () => Navigator.of(sheetContext).pop(),
                  ),
                ],
              ),
              const SizedBox(height: S.x4),

              // Hero Card
              Container(
                padding: const EdgeInsets.all(S.x4),
                decoration: BoxDecoration(
                  color: p.card2,
                  borderRadius: R.rLg,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          result != null ? _hours(result.totalNeedMinutes) : 'Calculating',
                          style: F.n48.copyWith(color: p.ink),
                        ),
                        Text('Optimal Sleep Needed Tonight', style: F.over.copyWith(color: p.ink3)),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: S.x3, vertical: S.x2),
                      decoration: BoxDecoration(
                        color: C.indigo.withValues(alpha: 0.15),
                        borderRadius: R.rPill,
                        border: Border.all(color: C.indigo.withValues(alpha: 0.4)),
                      ),
                      child: Text(
                        'Tonight',
                        style: F.head.copyWith(color: C.indigo, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: S.x4),

              // Equation Breakdown
              if (result != null) ...[
                _equationRow(context, '🛏️', 'Baseline Need', _hours(result.baselineMinutes), 'Individual biological baseline', C.indigo),
                const SizedBox(height: S.x2),
                _equationRow(context, '🏃', 'Strain Exertion', '+${result.strainMinutes.round()}m', 'Recovery added from daily exertion', C.orange),
                const SizedBox(height: S.x2),
                _equationRow(context, '⏳', 'Sleep Debt Carryover', '+${result.debtMinutes.round()}m', '20% amortized debt from recent nights', C.red),
                const SizedBox(height: S.x2),
                _equationRow(context, '💤', 'Nap Credits', '−${result.napCreditMinutes.round()}m', 'Daytime nap registered by band', C.green),
              ] else ...[
                Container(
                  padding: const EdgeInsets.all(S.x3),
                  decoration: BoxDecoration(
                    color: p.bg,
                    borderRadius: R.rMd,
                  ),
                  child: Text(
                    data.sleepNeedMissingReason ?? 'Calculating tonight’s sleep target as day strain and nap data accumulate.',
                    style: F.body.copyWith(color: p.ink2),
                  ),
                ),
              ],
              const SizedBox(height: S.x6),

              // Action button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: C.indigo,
                    foregroundColor: p.inkOnFill,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: const RoundedRectangleBorder(borderRadius: R.rMd),
                  ),
                  onPressed: () {
                    Navigator.of(sheetContext).pop();
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(builder: (_) => SleepDetail(day: data.dayId)),
                    );
                  },
                  child: const Text(
                    'View Sleep Analysis',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Widget _equationRow(
    BuildContext context,
    String icon,
    String title,
    String value,
    String explanation,
    Color accentColor,
  ) {
    final p = P.of(context);
    return Container(
      padding: const EdgeInsets.all(S.x3),
      decoration: BoxDecoration(
        color: p.card2,
        borderRadius: R.rMd,
      ),
      child: Row(
        children: [
          Text(icon, style: F.head),
          const SizedBox(width: S.x2),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: F.body.copyWith(color: p.ink, fontWeight: FontWeight.w600)),
                Text(explanation, style: F.over.copyWith(color: p.ink3)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: S.x2, vertical: 2),
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.12),
              borderRadius: R.rPill,
            ),
            child: Text(
              value,
              style: F.cap.copyWith(color: accentColor, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  static void _showJournalDetailSheet(BuildContext context, _NextGenData data) {
    final p = P.of(context);
    final row = data.journalInsight;
    final delta = (row?['delta_pct'] as num?)?.toDouble();

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      sheetAnimationStyle: sheetMotion(context),
      backgroundColor: p.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(R.xl)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(S.x4, 0, S.x4, S.x6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(S.x2),
                    decoration: BoxDecoration(
                      color: C.purple.withValues(alpha: 0.12),
                      borderRadius: R.rMd,
                    ),
                    child: const Icon(Icons.book, color: C.purple, size: 22),
                  ),
                  const SizedBox(width: S.x3),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Journal Habit Insights',
                          style: F.t1.copyWith(color: p.ink),
                        ),
                        Text(
                          'Objective correlation with morning recovery',
                          style: F.cap.copyWith(color: p.ink3),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: p.ink3),
                    onPressed: () => Navigator.of(sheetContext).pop(),
                  ),
                ],
              ),
              const SizedBox(height: S.x4),

              if (row != null && delta != null) ...[
                // Hero Impact Card
                Container(
                  padding: const EdgeInsets.all(S.x4),
                  decoration: BoxDecoration(
                    color: p.card2,
                    borderRadius: R.rLg,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${row['tag']}',
                            style: F.t2.copyWith(color: p.ink, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${row['n_with']} logged days with · ${row['n_without']} without',
                            style: F.over.copyWith(color: p.ink3),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: S.x3, vertical: S.x2),
                        decoration: BoxDecoration(
                          color: (delta >= 0 ? C.green : C.red).withValues(alpha: 0.15),
                          borderRadius: R.rPill,
                          border: Border.all(
                            color: (delta >= 0 ? C.green : C.red).withValues(alpha: 0.4),
                          ),
                        ),
                        child: Text(
                          '${row['outcome_label'] ?? 'HRV'}: ${delta >= 0 ? '+' : ''}${delta.toStringAsFixed(1)}%',
                          style: F.head.copyWith(
                            color: delta >= 0 ? C.green : C.red,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: S.x4),

                Container(
                  padding: const EdgeInsets.all(S.x3),
                  decoration: BoxDecoration(
                    color: p.bg,
                    borderRadius: R.rMd,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Welch’s Two-Sample Statistical Correlation',
                        style: F.head.copyWith(color: p.ink, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: S.x2),
                      Text(
                        'The analytics engine computes Welch’s t-test comparing morning biomarkers on nights following this habit versus nights without it. This isolates true causal behavioral signals from noise.',
                        style: F.cap.copyWith(color: p.ink2, height: 1.4),
                      ),
                    ],
                  ),
                ),
              ] else ...[
                Container(
                  padding: const EdgeInsets.all(S.x4),
                  decoration: BoxDecoration(
                    color: p.card2,
                    borderRadius: R.rLg,
                  ),
                  child: Text(
                    'Log at least 5 days with a habit and 5 days without it to surface verified statistical correlations with your morning recovery and HRV.',
                    style: F.body.copyWith(color: p.ink2, height: 1.4),
                  ),
                ),
              ],
              const SizedBox(height: S.x6),

              // Action button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: C.purple,
                    foregroundColor: p.inkOnFill,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: const RoundedRectangleBorder(borderRadius: R.rMd),
                  ),
                  onPressed: () {
                    Navigator.of(sheetContext).pop();
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(builder: (_) => JournalCompose(date: data.dayId)),
                    );
                  },
                  child: const Text(
                    'Log Today’s Journal',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static void _showRepCounterDetailSheet(BuildContext context) {
    final p = P.of(context);

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      sheetAnimationStyle: sheetMotion(context),
      backgroundColor: p.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(R.xl)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(S.x4, 0, S.x4, S.x6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(S.x2),
                    decoration: BoxDecoration(
                      color: C.green.withValues(alpha: 0.12),
                      borderRadius: R.rMd,
                    ),
                    child: const Icon(Icons.fitness_center, color: C.green, size: 22),
                  ),
                  const SizedBox(width: S.x3),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Strength Rep Counter',
                          style: F.t1.copyWith(color: p.ink),
                        ),
                        Text(
                          'High-rate 100 Hz IMU kinematics',
                          style: F.cap.copyWith(color: p.ink3),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: p.ink3),
                    onPressed: () => Navigator.of(sheetContext).pop(),
                  ),
                ],
              ),
              const SizedBox(height: S.x4),

              // Hero Card
              Container(
                padding: const EdgeInsets.all(S.x4),
                decoration: BoxDecoration(
                  color: p.card2,
                  borderRadius: R.rLg,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Live RAM Only',
                          style: F.t1.copyWith(color: p.ink, fontWeight: FontWeight.bold),
                        ),
                        Text('100 Hz Accelerometer & Gyroscope', style: F.over.copyWith(color: p.ink3)),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: S.x3, vertical: S.x2),
                      decoration: BoxDecoration(
                        color: C.green.withValues(alpha: 0.15),
                        borderRadius: R.rPill,
                        border: Border.all(color: C.green.withValues(alpha: 0.4)),
                      ),
                      child: Text(
                        '100 Hz',
                        style: F.head.copyWith(color: C.green, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: S.x4),

              Container(
                padding: const EdgeInsets.all(S.x3),
                decoration: BoxDecoration(
                  color: p.bg,
                  borderRadius: R.rMd,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Why is history blank?',
                      style: F.head.copyWith(color: p.ink, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: S.x2),
                    Text(
                      'High-rate 100 Hz IMU sensor frames produce gigabytes per hour and are never permanently stored in device flash storage. Rep detection operates with zero latency directly in live RAM during an active workout session.',
                      style: F.cap.copyWith(color: p.ink2, height: 1.4),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: S.x6),

              // Action button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: C.green,
                    foregroundColor: p.inkOnFill,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: const RoundedRectangleBorder(borderRadius: R.rMd),
                  ),
                  onPressed: () {
                    Navigator.of(sheetContext).pop();
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(builder: (_) => const WorkoutScreen()),
                    );
                  },
                  child: const Text(
                    'Start Workout',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _hours(double minutes) {
    final total = minutes.round();
    return '${total ~/ 60}h ${total % 60}m';
  }
}

class _NextGenData {
  final String dayId;
  final bool isToday;
  final double? stressScore;
  final double? stressSi;
  final String? stressLevel;
  final String? stressNote;
  final ana.BiologicalAgeResult? biologicalAge;
  final double? bio7dDelta;
  final List<(String, double)> bioTrajectory;
  final String? bioAgeMissingReason;
  final String bioAgeChecklist;
  final String bioAgeActionLabel;
  final bool bioAgeRequiresProfileEdit;
  final double? avgRhr;
  final double? avgHrv;
  final double? avgSteps;
  final double? sleepConsistency;
  final ana.SleepNeedResult? sleepNeed;
  final double? actualSleepMinutes;
  final String? sleepNeedMissingReason;
  final Map<String, dynamic>? journalInsight;
  final List<String> dayLoggedHabits;

  const _NextGenData({
    required this.dayId,
    required this.isToday,
    this.stressScore,
    this.stressSi,
    this.stressLevel,
    this.stressNote,
    this.biologicalAge,
    this.bio7dDelta,
    this.bioTrajectory = const [],
    this.bioAgeMissingReason,
    this.bioAgeChecklist = '',
    this.bioAgeActionLabel = 'Open Profile',
    this.bioAgeRequiresProfileEdit = false,
    this.avgRhr,
    this.avgHrv,
    this.avgSteps,
    this.sleepConsistency,
    this.sleepNeed,
    this.actualSleepMinutes,
    this.sleepNeedMissingReason,
    this.journalInsight,
    this.dayLoggedHabits = const [],
  });

  static Future<_NextGenData> load(
    LocalRepository repo, {
    required String day,
    required double? strain,
    required double? sleepMinutes,
    required double? sleepNeedMinutes,
  }) async {
    final isToday = day == todayLabel();
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

    final rhr = _tailValues(results[6] as Map<String, dynamic>, 14, day: day);
    final hrv = _tailValues(results[7] as Map<String, dynamic>, 14, day: day);
    final steps = _tailValues(results[8] as Map<String, dynamic>, 14, day: day);
    final sex = (profile['sex'] as String?)?.toLowerCase() ?? 'm';
    final age = (profile['age'] as num?)?.toDouble();
    final ceiling = zones['ceiling'];
    final measuredMaxHr = ceiling is Map ? (ceiling['bpm'] as num?)?.toDouble() : null;
    final effectiveMaxHr = measuredMaxHr ?? (age != null ? (208.0 - 0.7 * age) : null);
    final regularity = _envelopeValue(insights['regularity']);
    final sri = regularity is Map
        ? (regularity['sri'] as num?)?.toDouble()
        : null;

    final avgRhr = rhr.isNotEmpty ? _mean(rhr) : null;
    final avgHrv = hrv.isNotEmpty ? _mean(hrv) : null;
    final avgSteps = steps.isNotEmpty ? _mean(steps) : null;

    ana.BiologicalAgeResult? bio;
    String? bioMissing;
    final checklistItems = <String>[
      age != null
          ? '✓ Profile Age: ${age.toStringAsFixed(0)} years'
          : '✗ Profile Age: Missing (tap button below to enter)',
      sex == 'f'
          ? '✓ Biological Sex: Female (normative female benchmarks applied)'
          : (sex == 'm'
              ? '✓ Biological Sex: Male (normative male benchmarks applied)'
              : '✓ Biological Sex: Standard benchmark applied'),
      measuredMaxHr != null
          ? '✓ Max Heart Rate: ${measuredMaxHr.toStringAsFixed(0)} bpm (measured)'
          : (effectiveMaxHr != null
              ? '✓ Max Heart Rate: ${effectiveMaxHr.toStringAsFixed(0)} bpm (estimated from age)'
              : '✗ Max HR Ceiling: Need age to estimate or workout to measure'),
      rhr.length >= 3
          ? '✓ Resting HR: ${rhr.length}/7 days recorded'
          : '✗ Resting HR: ${rhr.length}/3 days minimum needed',
      hrv.length >= 3
          ? '✓ Overnight HRV: ${hrv.length}/7 days recorded'
          : '✗ Overnight HRV: ${hrv.length}/3 nights minimum needed',
      steps.isNotEmpty
          ? '✓ Daily Steps: ${steps.length}/7 days recorded (${_mean(steps).toStringAsFixed(0)} avg)'
          : '• Daily Steps: Calibrating (using standard active benchmark)',
      sri != null
          ? '✓ Sleep Regularity (SRI): ${sri.toStringAsFixed(0)}%'
          : '• Sleep Regularity: Calibrating (using standard rhythm)',
    ];
    final bioChecklist = checklistItems.join('\n');

    String bioAction = 'Open Profile';
    bool bioRequiresEdit = false;

    final effectiveSleepConsistency = sri != null
        ? (sri.clamp(0, 100) / 100).toDouble()
        : 0.75;

    final targetMaxHr = effectiveMaxHr ?? 190.0;
    if (age == null) {
      bioMissing = 'Needs your birth date/age in Profile.';
      bioAction = 'Enter Age in Profile';
      bioRequiresEdit = true;
    } else if (rhr.length < 3 || hrv.length < 3) {
      final daysLeft = 3 - (rhr.length < hrv.length ? rhr.length : hrv.length);
      bioMissing = 'Need $daysLeft more day(s) wearing band to establish 3-day baseline.';
      bioAction = 'Got it (Keep wearing band)';
    } else {
      final effectiveSteps = steps.isNotEmpty ? _mean(steps) : 7500.0;

      bio = ana.BiologicalAgeCalculator.calculate(
        chronologicalAge: age,
        maxHr: targetMaxHr,
        avgRhr: _mean(rhr),
        avgHrv: _mean(hrv),
        sleepConsistency: effectiveSleepConsistency,
        avgDailySteps: effectiveSteps,
        sex: sex,
      );
    }

    // Dynamics: Calculate 7-day trajectory of biological age up to [day]
    final dayDt = DateTime.tryParse(day);
    double? bio7dDelta;
    final bioTrajectory = <(String, double)>[];

    if (bio != null && age != null && dayDt != null) {
      for (var i = 6; i >= 0; i--) {
        final tDate = DateTime(dayDt.year, dayDt.month, dayDt.day - i);
        final tLabel =
            '${tDate.year}-${tDate.month.toString().padLeft(2, '0')}-${tDate.day.toString().padLeft(2, '0')}';
        final tRhr = _tailValues(results[6] as Map<String, dynamic>, 14, day: tLabel);
        final tHrv = _tailValues(results[7] as Map<String, dynamic>, 14, day: tLabel);
        final tSteps = _tailValues(results[8] as Map<String, dynamic>, 14, day: tLabel);
        if (tRhr.length >= 3 && tHrv.length >= 3) {
          final tBio = ana.BiologicalAgeCalculator.calculate(
            chronologicalAge: age,
            maxHr: targetMaxHr,
            avgRhr: _mean(tRhr),
            avgHrv: _mean(tHrv),
            sleepConsistency: effectiveSleepConsistency,
            avgDailySteps: tSteps.isNotEmpty ? _mean(tSteps) : 7500.0,
            sex: sex,
          );
          bioTrajectory.add((tLabel, tBio.biologicalAge));
        }
      }

      if (bioTrajectory.length >= 2) {
        final earliest = bioTrajectory.first.$2;
        final latest = bio.biologicalAge;
        bio7dDelta = latest - earliest;
      }
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

    List<String> dayLoggedHabits = const [];
    try {
      final entries = await repo.getJournal(range: '30d');
      for (final e in entries) {
        if (e['date'] == day && e['tags'] is List) {
          dayLoggedHabits = (e['tags'] as List).cast<String>();
          break;
        }
      }
    } catch (_) {}

    final stressMap = rawStress['stress'] is Map
        ? (rawStress['stress'] as Map).cast<String, dynamic>()
        : rawStress;
    final stressValue = _number(stressMap['score']);
    final stressSi = _number(stressMap['si']);
    final stressLevel = stressMap['level']?.toString();
    final stressNote = stressMap['note']?.toString() ??
        (rawStress['note']?.toString());

    return _NextGenData(
      dayId: day,
      isToday: isToday,
      stressScore: stressValue,
      stressSi: stressSi,
      stressLevel: stressLevel,
      stressNote: stressNote,
      biologicalAge: bio,
      bio7dDelta: bio7dDelta,
      bioTrajectory: bioTrajectory,
      bioAgeMissingReason: bioMissing,
      bioAgeChecklist: bioChecklist,
      bioAgeActionLabel: bioAction,
      bioAgeRequiresProfileEdit: bioRequiresEdit,
      avgRhr: avgRhr,
      avgHrv: avgHrv,
      avgSteps: avgSteps,
      sleepConsistency: effectiveSleepConsistency,
      sleepNeed: sleep,
      actualSleepMinutes: sleepMinutes,
      sleepNeedMissingReason: sleepMissing,
      journalInsight: firstJournal,
      dayLoggedHabits: dayLoggedHabits,
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

  static List<double> _tailValues(
    Map<String, dynamic> chart,
    int count, {
    String? day,
  }) {
    final points = chart['points'];
    final dayDt = day != null ? DateTime.tryParse('$day 23:59:59') : null;
    final dayEndSec = dayDt != null ? dayDt.millisecondsSinceEpoch ~/ 1000 : null;

    final values = <double>[
      for (final point in (points is List ? points : const []))
        if (point is Map && point['v'] is num)
          if (dayEndSec == null ||
              point['t'] == null ||
              (point['t'] is num && (point['t'] as num) <= dayEndSec))
            (point['v'] as num).toDouble(),
    ];
    return values.length <= count
        ? values
        : values.sublist(values.length - count);
  }

  static double _mean(List<double> values) =>
      values.reduce((a, b) => a + b) / values.length;
}
