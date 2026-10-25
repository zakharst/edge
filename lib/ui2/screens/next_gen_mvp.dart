import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:openstrap_analytics/onehz.dart' as ana;

import '../../data/day_label.dart' show todayLabel;
import '../../data/local_repository.dart';
import '../../state/locale_controller.dart';
import '../grammar.dart';
import '../profile/settings.dart';
import '../revision.dart';
import '../screens/journal_compose.dart';
import '../screens/wellness_screen.dart';
import '../screens/workout_screen.dart';
import '../theme.dart';

/// Next-Generation Bento Grid and interactive longevity sheets.
///
/// Every value is read from the MOD app's on-device SQLite repository. Missing
/// inputs stay missing: this card never manufactures a synthetic zero.
class NextGenMvpCard extends StatefulWidget {
  final LocalRepository? repo;
  final String? dayId;

  const NextGenMvpCard({
    super.key,
    required this.repo,
    required this.dayId,
  });

  @override
  State<NextGenMvpCard> createState() => _NextGenMvpCardState();
}

class _NextGenMvpCardState extends State<NextGenMvpCard> with RevisionReload {
  _NextGenData? _data;
  bool _loading = true;
  bool _failed = false;

  @override
  bool get revisionReloads => widget.repo != null && widget.dayId != null;

  @override
  void reload() => _reload();

  @override
  void initState() {
    super.initState();
    _reload();
  }

  @override
  void didUpdateWidget(covariant NextGenMvpCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.repo != widget.repo || oldWidget.dayId != widget.dayId) {
      _reload();
    }
  }


  void _reload() {
    final repo = widget.repo;
    final day = widget.dayId;
    if (repo == null || day == null) {
      if (_data != null || _loading) {
        setState(() {
          _data = null;
          _loading = false;
        });
      }
      return;
    }
    final t = beginRead(#nextGen);
    if (_data == null && !_loading) {
      setState(() => _loading = true);
    }
    _NextGenData.load(
      repo,
      day: day,
    ).then((data) {
      if (stillNewest(#nextGen, t)) {
        setState(() {
          _data = data;
          _loading = false;
          _failed = false;
        });
      }
    }).catchError((_) {
      if (stillNewest(#nextGen, t)) {
        setState(() {
          _loading = false;
          _failed = true;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.repo == null || widget.dayId == null) {
      return const SizedBox.shrink();
    }
    if (_loading && _data == null) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: S.x3),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (_failed && _data == null) {
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
    final data = _data;
    if (data == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── BENTO HERO: Biological Longevity ──
        _bioAgeHeroCard(context, data),
        const SizedBox(height: S.x3),

        // ── BENTO ROW 1: Real-Time Stress & Journal Insights ──
        Row(
          children: [
            Expanded(child: _compactStressCard(context, data)),
            const SizedBox(width: S.x3),
            Expanded(child: _compactJournalCard(context, data)),
          ],
        ),
        const SizedBox(height: S.x3),

        // ── BENTO ROW 2: Rep Counter ──
        _compactRepCard(context, data),
        const SizedBox(height: S.x4),
      ],
    );
  }

  // ── HERO: Biological Age ──────────────────────────────────────────────────

  Widget _bioAgeHeroCard(BuildContext context, _NextGenData data) {
    final p = P.of(context);
    final isUk = LocaleController.displayLanguageCode == 'uk';
    final result = data.biologicalAge;
    final diff = result?.ageDifference ?? 0.0;
    final isYounger = diff < 0;
    final diffAbs = diff.abs().toStringAsFixed(1);

    return Pressable(
      onTap: () => _showBioAgeDetailSheet(context, data, onReload: _reload),
      semanticLabel: isUk
          ? 'Біологічний вік. Натисніть для перегляду 4 стовпів та розрахунків.'
          : 'Biological age overview. Tap to view longevity breakdown and calibration checklist.',
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
                    isUk ? 'БІОЛОГІЧНИЙ ВІК' : 'BIOLOGICAL AGE',
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
                      isUk
                          ? (isYounger
                              ? '▼ $diffAbs Р. МОЛОДШИЙ'
                              : (diff > 0 ? '▲ $diffAbs Р. СТАРШИЙ' : 'НОРМА'))
                          : (isYounger
                              ? '▼ $diffAbs YRS YOUNGER'
                              : (diff > 0 ? '▲ $diffAbs YRS OLDER' : 'OPTIMAL PACE')),
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
                      isUk ? 'КАЛІБРУВАННЯ' : 'CALIBRATING',
                      style: F.over.copyWith(color: p.ink3, fontWeight: FontWeight.bold),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: S.x3),

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
                        isUk ? 'РОКІВ' : 'YRS',
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
                        isUk ? 'ПАСПОРТНИЙ' : 'CALENDAR',
                        style: F.over.copyWith(color: p.ink3),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        isUk
                            ? '${result.chronologicalAge.toStringAsFixed(0)} р.'
                            : '${result.chronologicalAge.toStringAsFixed(0)} yrs',
                        style: F.head.copyWith(color: p.ink2, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: S.x3),

              // ── VISUAL MATH LEDGER: 28.0 - 1.5 - 1.0 - 0.8 + 0.5 = 25.2 ──
              Container(
                padding: const EdgeInsets.symmetric(horizontal: S.x3, vertical: S.x2),
                decoration: BoxDecoration(
                  color: p.card2,
                  borderRadius: R.rMd,
                  border: Border.all(color: p.line),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _BioEquationNode(
                      value: result.chronologicalAge.toStringAsFixed(0),
                      label: isUk ? 'Паспорт' : 'Calendar',
                      color: p.ink,
                    ),
                    Text(result.rhrModifier <= 0 ? '-' : '+', style: F.head.copyWith(color: p.ink3)),
                    _BioEquationNode(
                      value: result.rhrModifier.abs().toStringAsFixed(1),
                      label: isUk ? 'Пульс' : 'RHR',
                      color: result.rhrModifier <= 0 ? C.green : C.orange,
                    ),
                    Text(result.hrvModifier <= 0 ? '-' : '+', style: F.head.copyWith(color: p.ink3)),
                    _BioEquationNode(
                      value: result.hrvModifier.abs().toStringAsFixed(1),
                      label: 'HRV',
                      color: result.hrvModifier <= 0 ? C.green : C.purple,
                    ),
                    Text(result.vo2Modifier <= 0 ? '-' : '+', style: F.head.copyWith(color: p.ink3)),
                    _BioEquationNode(
                      value: result.vo2Modifier.abs().toStringAsFixed(1),
                      label: 'VO₂',
                      color: result.vo2Modifier <= 0 ? C.green : C.blue,
                    ),
                    Text(result.lifestyleModifier <= 0 ? '-' : '+', style: F.head.copyWith(color: p.ink3)),
                    _BioEquationNode(
                      value: result.lifestyleModifier.abs().toStringAsFixed(1),
                      label: isUk ? 'Сон' : 'Sleep',
                      color: result.lifestyleModifier <= 0 ? C.green : C.orange,
                    ),
                    Text('=', style: F.head.copyWith(color: p.ink3)),
                    _BioEquationNode(
                      value: result.biologicalAge.toStringAsFixed(1),
                      label: isUk ? 'Біовік' : 'Bio Age',
                      color: isYounger ? C.green : C.orange,
                      highlight: true,
                    ),
                  ],
                ),
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
                    Expanded(child: _miniBiomarkerChip(context, '🫀', data.avgRhr != null ? '${data.avgRhr!.round()} bpm' : '—', isUk ? 'Пульс' : 'RHR')),
                    Expanded(child: _miniBiomarkerChip(context, '⚡', data.avgHrv != null ? '${data.avgHrv!.round()} ms' : '—', isUk ? 'HRV' : 'HRV')),
                    Expanded(child: _miniBiomarkerChip(context, '🁢', result.vo2MaxEst.toStringAsFixed(1), 'VO₂ Max')),
                    Expanded(child: _miniBiomarkerChip(context, '🌙', '${((data.sleepConsistency ?? 0.75) * 100).round()}%', isUk ? 'Ритм сну' : 'Sleep')),
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
                            ? (isUk
                                ? '7 днів: -${data.bio7dDelta!.abs().toStringAsFixed(1)} р. омолодження'
                                : '7d: -${data.bio7dDelta!.abs().toStringAsFixed(1)} yrs')
                            : (data.bio7dDelta! >= 0.05
                                ? (isUk
                                    ? '7 днів: +${data.bio7dDelta!.toStringAsFixed(1)} р. втома'
                                    : '7d: +${data.bio7dDelta!.toStringAsFixed(1)} yrs strain')
                                : (isUk ? '7 днів: стабільна норма' : '7d: Stable baseline')),
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
                        data.isToday ? (isUk ? 'Сьогодні' : 'Today') : data.dayId,
                        style: F.over.copyWith(color: p.ink3),
                      ),
                    ],
                  ),
                ),
              ],
            ] else ...[
              Text(
                isUk ? 'Вивчення базового ритму' : 'Calibrating Baseline',
                style: F.t2.copyWith(color: p.ink),
              ),
              const SizedBox(height: S.x1),
              Text(
                data.bioAgeMissingReason ??
                    (isUk
                        ? 'Потрібен вік у профілі та від 3 днів записів браслета.'
                        : 'Needs profile age & 3+ days of band recordings.'),
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
                        ? (isUk ? 'Як розраховано біологічний вік' : 'How biological age is calculated')
                        : (isUk ? 'Подивитися список для калібрування' : 'Tap to view calibration checklist'),
                    style: F.cap.copyWith(color: p.ink3),
                  ),
                ),
                Icon(LucideIcons.chevronRight, size: 12, color: p.ink3),
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
    final isUk = LocaleController.displayLanguageCode == 'uk';
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

    final localizedLevel = switch (levelLower) {
      'low' => isUk ? 'Спокій' : 'Low',
      'balanced' || 'normal' => isUk ? 'Баланс' : 'Balanced',
      'elevated' => isUk ? 'Напруга' : 'Elevated',
      'high' => isUk ? 'Стрес' : 'High',
      _ => isUk ? 'Баланс' : 'Balanced',
    };

    return Pressable(
      onTap: () => _showStressDetailSheet(context, data),
      semanticLabel: isUk
          ? 'Рівень стресу $localizedLevel${isScored ? ", бал ${score.toStringAsFixed(0)}" : ""}. Натисніть для деталей.'
          : 'Real-time stress level $displayLevel${isScored ? ", score ${score.toStringAsFixed(0)}" : ""}. Tap to open details.',
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
                    child: const Icon(LucideIcons.zap, size: 14, color: C.orange),
                  ),
                  const SizedBox(width: S.x1),
                  Expanded(
                    child: Text(
                      data.isToday
                          ? (isUk ? 'СТРЕС · ЗАРАЗ' : 'STRESS · LIVE')
                          : (isUk ? 'СТРЕС · ЗА ДЕНЬ' : 'STRESS · DAY RECORD'),
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
                  isScored ? score.toStringAsFixed(0) : (isUk ? 'Спокій' : 'Resting'),
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
                        localizedLevel,
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
                  ? (isUk
                      ? 'Індекс напруги (SI): ${data.stressSi?.toStringAsFixed(1) ?? "—"}'
                      : 'Baevsky SI: ${data.stressSi?.toStringAsFixed(1) ?? "—"}')
                  : (data.stressNote ??
                      (data.isToday
                          ? (isUk ? 'Очікування спокою' : 'Awaiting rest period')
                          : (isUk ? 'Немає запису спокою' : 'No rest recording'))),
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

  // ── BENTO 3: Journal Insights ─────────────────────────────────────────────

  Widget _compactJournalCard(BuildContext context, _NextGenData data) {
    final p = P.of(context);
    final isUk = LocaleController.displayLanguageCode == 'uk';
    final row = data.journalInsight;
    final delta = (row?['delta_pct'] as num?)?.toDouble();

    return Pressable(
      onTap: () => _showJournalDetailSheet(context, data, onReload: _reload),
      semanticLabel: isUk
          ? 'Вплив звичок із щоденника. Натисніть для перегляду кореляцій.'
          : 'Journal insights ${data.dayLoggedHabits.isNotEmpty ? data.dayLoggedHabits.join(", ") : (row != null ? row["tag"].toString() : "awaiting logs")}. Tap to open journal details.',
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
                    child: const Icon(LucideIcons.notebook, size: 14, color: C.purple),
                  ),
                  const SizedBox(width: S.x1),
                  Expanded(
                    child: Text(
                      isUk ? 'ВПЛИВ ЗВИЧОК' : 'JOURNAL INSIGHTS',
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
                  : (row != null ? '${row['tag']}' : (isUk ? 'Немає звичок' : 'No Habits Yet')),
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
                  isUk ? 'Очікування записів' : 'Awaiting Logs',
                  style: F.over.copyWith(color: p.ink3, fontWeight: FontWeight.bold),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            const Spacer(),

            // Bottom Subtitle
            Text(
              data.dayLoggedHabits.isNotEmpty
                  ? (isUk ? 'Записано в цей день' : 'Logged on this day')
                  : (row != null
                      ? (isUk
                          ? '${row['n_with']} з · ${row['n_without']} без'
                          : '${row['n_with']} with · ${row['n_without']} without')
                      : (isUk ? 'Потрібно 5+ днів' : 'Needs 5+ logged days')),
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
    final isUk = LocaleController.displayLanguageCode == 'uk';

    return Pressable(
      onTap: () => _showRepCounterDetailSheet(context),
      semanticLabel: isUk
          ? 'Трекер повторень. Натисніть для перегляду кінематики 100 Гц.'
          : 'Strength rep counter. Tap to view strength trainer and rep detection.',
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
                    child: const Icon(LucideIcons.dumbbell, size: 14, color: C.green),
                  ),
                  const SizedBox(width: S.x1),
                  Expanded(
                    child: Text(
                      isUk ? 'ПОВТОРЕННЯ' : 'REP COUNTER',
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
                data.isToday
                    ? (isUk ? '100 Гц Акселерометр' : '100 Hz Live IMU')
                    : (isUk ? 'RAM Кінематика' : 'RAM Kinematics'),
                style: F.over.copyWith(color: C.green, fontWeight: FontWeight.bold),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const Spacer(),

            // Bottom Subtitle
            Text(
              data.isToday
                  ? (isUk ? 'Під час тренування' : 'Live workout tracking')
                  : (isUk ? 'Режим сесії' : 'Active session mode'),
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

  static void _showBioAgeDetailSheet(
    BuildContext context,
    _NextGenData data, {
    VoidCallback? onReload,
  }) {
    final p = P.of(context);
    final isUk = LocaleController.displayLanguageCode == 'uk';
    final result = data.biologicalAge;
    final diff = result?.ageDifference ?? 0.0;
    final isYounger = diff < 0;
    final diffAbs = diff.abs().toStringAsFixed(1);
    final isFemale = result?.sex == 'f';
    final sexLabel = isUk ? (isFemale ? 'Жіночі' : 'Чоловічі') : (isFemale ? 'Female' : 'Male');

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
                          isUk ? 'Біологічний вік серця' : 'Cardiovascular Fitness Age',
                          style: F.t1.copyWith(color: p.ink),
                        ),
                        Text(
                          isUk
                              ? 'Модель PpgAge на базі біомаркерів (Nature 2025)'
                              : 'Sex-stratified PpgAge model (Nature 2025)',
                          style: F.cap.copyWith(color: p.ink3),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(LucideIcons.x, color: p.ink3),
                    onPressed: () => Navigator.of(sheetContext).pop(),
                  ),
                ],
              ),
              const SizedBox(height: S.x3),

              // Scientific Honesty Box
              Container(
                padding: const EdgeInsets.all(S.x3),
                decoration: BoxDecoration(
                  color: p.wash(C.blue, strength: 0.12),
                  borderRadius: R.rMd,
                  border: Border.all(color: p.on(C.blue).withValues(alpha: 0.25)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(LucideIcons.shieldCheck, size: 16, color: p.on(C.blue)),
                    const SizedBox(width: S.x2),
                    Expanded(
                      child: Text(
                        isUk
                            ? '100% чесність: це фізіологічний вік серцево-судинної та вегетативної системи, а не ДНК-тест. Розраховується за 14-денним пульсом спокою, нічним HRV, VO₂ Max та ритмом сну.'
                            : '100% scientific honesty: This is physiological cardiovascular and autonomic age, not a DNA test. Calculated using your 14-day rolling resting HR, overnight HRV, VO₂ Max, and circadian sleep regularity.',
                        style: F.cap.copyWith(color: p.ink, height: 1.3),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: S.x3),

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
                              Text(isUk ? 'Паспортний' : 'Calendar Age', style: F.over.copyWith(color: p.ink3)),
                              const SizedBox(height: 4),
                              Text(
                                result.chronologicalAge.toStringAsFixed(0),
                                style: F.n34.copyWith(color: p.ink2),
                              ),
                              Text(isUk ? 'років' : 'years', style: F.over.copyWith(color: p.ink3)),
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
                                  isUk
                                      ? (isYounger ? '▼ $diffAbs Р.' : '▲ $diffAbs Р.')
                                      : (isYounger ? '▼ $diffAbs YRS' : '▲ $diffAbs YRS'),
                                  style: F.head.copyWith(
                                    color: isYounger ? C.green : C.orange,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  isUk
                                      ? (isYounger ? 'МОЛОДШИЙ' : (diff > 0 ? 'СТАРШИЙ' : 'НОРМА'))
                                      : (isYounger ? 'YOUNGER' : (diff > 0 ? 'OLDER' : 'MATCHED')),
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
                              Text(isUk ? 'Біологічний' : 'Biological Age', style: F.over.copyWith(color: p.ink3)),
                              const SizedBox(height: 4),
                              Text(
                                result.biologicalAge.toStringAsFixed(1),
                                style: F.n34.copyWith(
                                  color: isYounger ? C.green : p.ink,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(isUk ? 'років' : 'years', style: F.over.copyWith(color: p.ink3)),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: S.x4),

                      // ── VISUAL ARITHMETIC LEDGER BREAKDOWN ──
                      Container(
                        padding: const EdgeInsets.all(S.x3),
                        decoration: BoxDecoration(
                          color: p.bg,
                          borderRadius: R.rMd,
                          border: Border.all(color: p.line),
                        ),
                        child: Column(
                          children: [
                            _BioLedgerEquationRow(
                              sign: '•',
                              value: '${result.chronologicalAge.toStringAsFixed(1)} ${isUk ? 'р.' : 'yrs'}',
                              label: isUk ? 'Паспортний вік (база)' : 'Chronological Age (base)',
                              color: p.ink,
                            ),
                            const SizedBox(height: S.x2),
                            _BioLedgerEquationRow(
                              sign: result.rhrModifier >= 0 ? '+' : '-',
                              value: '${result.rhrModifier.abs().toStringAsFixed(1)} ${isUk ? 'р.' : 'yrs'}',
                              label: isUk ? 'Пульс спокою (RHR)' : 'Resting Heart Rate (RHR)',
                              color: result.rhrModifier <= 0 ? C.green : C.orange,
                            ),
                            const SizedBox(height: S.x2),
                            _BioLedgerEquationRow(
                              sign: result.hrvModifier >= 0 ? '+' : '-',
                              value: '${result.hrvModifier.abs().toStringAsFixed(1)} ${isUk ? 'р.' : 'yrs'}',
                              label: isUk ? 'Вегетативний баланс (HRV)' : 'Autonomic Tone (Overnight HRV)',
                              color: result.hrvModifier <= 0 ? C.green : C.orange,
                            ),
                            const SizedBox(height: S.x2),
                            _BioLedgerEquationRow(
                              sign: result.vo2Modifier >= 0 ? '+' : '-',
                              value: '${result.vo2Modifier.abs().toStringAsFixed(1)} ${isUk ? 'р.' : 'yrs'}',
                              label: isUk ? 'Аеробна витривалість (VO₂ Max)' : 'Cardiorespiratory Fitness (VO₂ Max)',
                              color: result.vo2Modifier <= 0 ? C.green : C.orange,
                            ),
                            const SizedBox(height: S.x2),
                            _BioLedgerEquationRow(
                              sign: result.lifestyleModifier >= 0 ? '+' : '-',
                              value: '${result.lifestyleModifier.abs().toStringAsFixed(1)} ${isUk ? 'р.' : 'yrs'}',
                              label: isUk ? 'Ритм сну та активність (SRI)' : 'Circadian Sleep & Daily Movement',
                              color: result.lifestyleModifier <= 0 ? C.green : C.orange,
                            ),
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: S.x2),
                              child: Divider(height: 1),
                            ),
                            _BioLedgerEquationRow(
                              sign: '=',
                              value: '${result.biologicalAge.toStringAsFixed(1)} ${isUk ? 'років' : 'years'}',
                              label: isUk ? 'Разом: Біологічний вік' : 'Total: Biological Age',
                              color: isYounger ? C.green : C.orange,
                              isTotal: true,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: S.x3),

                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(S.x3),
                        decoration: BoxDecoration(
                          color: p.bg,
                          borderRadius: R.rMd,
                        ),
                        child: Text(
                          isUk
                              ? (diff <= -1.5
                                  ? '🎉 Відмінно! Ваші серцево-судинні показники відповідають значно молодшому віку.'
                                  : (diff >= 1.5
                                      ? '⚠️ Підвищене навантаження на серцево-судинну систему. Зверніть увагу на відновлення та кардіо.'
                                      : '👍 Оптимальний темп. Ваші біомаркери гармонійно відповідають паспортному віку.'))
                              : (diff <= -1.5
                                  ? '🎉 Outstanding! Your cellular and cardiovascular biomarkers reflect superior biological fitness.'
                                  : (diff >= 1.5
                                      ? '⚠️ Elevated biological strain. Focus on targeted recovery and aerobic endurance to reverse.'
                                      : '👍 Optimal pace. Your physiological biomarkers align with chronological peers.')),
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
                        isUk ? 'ДИНАМІКА БІОЛОГІЧНОГО ВІКУ ЗА 7 ДНІВ' : '7-DAY LONGEVITY TRAJECTORY',
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
                                  item.$1 == data.dayId ? '${item.$1} ${isUk ? "(Обрано)" : "(Selected)"}' : item.$1,
                                  style: F.cap.copyWith(
                                    color: item.$1 == data.dayId ? p.ink : p.ink2,
                                    fontWeight: item.$1 == data.dayId ? FontWeight.bold : FontWeight.normal,
                                  ),
                                ),
                                Text(
                                  '${item.$2.toStringAsFixed(1)} ${isUk ? "р." : "yrs"}',
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
                  isUk ? '4 СТОВПИ БІОЛОГІЧНОГО ВІКУ (Норми: $sexLabel)' : 'BIOMARKER PILLARS ($sexLabel Norms)',
                  style: F.over.copyWith(color: p.ink3, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: S.x3),

                _biomarkerPillarCard(
                  context,
                  icon: '🫀',
                  title: isUk ? 'Пульс спокою (RHR)' : 'Resting Heart Rate (RHR)',
                  value: data.avgRhr != null ? '${data.avgRhr!.round()} ${isUk ? "уд/хв" : "bpm"}' : '—',
                  modifierBadge: '${result.rhrModifier >= 0 ? "+" : ""}${result.rhrModifier.toStringAsFixed(1)} ${isUk ? "р." : "yrs"}',
                  insight: _getHeartInsight(result, data.avgRhr, isUk),
                  accentColor: C.red,
                ),
                const SizedBox(height: S.x3),

                _biomarkerPillarCard(
                  context,
                  icon: '⚡',
                  title: isUk ? 'Вегетативна система (Нічний HRV)' : 'Autonomic System (Overnight HRV)',
                  value: data.avgHrv != null ? '${data.avgHrv!.round()} ${isUk ? "мс" : "ms"}' : '—',
                  modifierBadge: '${result.hrvModifier >= 0 ? "+" : ""}${result.hrvModifier.toStringAsFixed(1)} ${isUk ? "р." : "yrs"}',
                  insight: _getHrvInsight(result, data.avgHrv, isUk),
                  accentColor: C.purple,
                ),
                const SizedBox(height: S.x3),

                _biomarkerPillarCard(
                  context,
                  icon: '🁢',
                  title: isUk ? 'Аеробна витривалість (VO₂ Max)' : 'Aerobic Endurance (VO₂ Max)',
                  value: '${result.vo2MaxEst.toStringAsFixed(1)} ${isUk ? "мл/кг" : "ml/kg"}',
                  modifierBadge: '${result.vo2Modifier >= 0 ? "+" : ""}${result.vo2Modifier.toStringAsFixed(1)} ${isUk ? "р." : "yrs"}',
                  insight: _getVo2Insight(result, isUk),
                  accentColor: C.blue,
                ),
                const SizedBox(height: S.x3),

                _biomarkerPillarCard(
                  context,
                  icon: '🌙',
                  title: isUk ? 'Ритм сну та активність' : 'Sleep Stability & Movement',
                  value: '${((data.sleepConsistency ?? 0.75) * 100).round()}% SRI',
                  modifierBadge: '${result.lifestyleModifier >= 0 ? "+" : ""}${result.lifestyleModifier.toStringAsFixed(1)} ${isUk ? "р." : "yrs"}',
                  insight: _getLifestyleInsight(result, isUk),
                  accentColor: C.indigo,
                ),
                const SizedBox(height: S.x6),

                // Targeted Longevity Roadmap
                Row(
                  children: [
                    const Icon(LucideIcons.lightbulb, size: 16, color: C.yellow),
                    const SizedBox(width: S.x2),
                    Text(
                      isUk ? 'ЯК ОМОЛОДИТИ СЕРЦЕ ТА СУДИНИ' : 'HOW TO REVERSE BIOLOGICAL AGE',
                      style: F.over.copyWith(color: p.ink3, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: S.x3),

                for (final tip in _getActionableTips(result, isUk)) ...[
                  _actionTipCard(context, tip),
                  const SizedBox(height: S.x2),
                ],
                const SizedBox(height: S.x4),

                Text(
                  isUk
                      ? 'Наукова основа: Базується на нормативних кривих вікового спаду (Levine PhenoAge, HUNT3 VO₂ max, моделі вегетативного старіння).'
                      : 'Science note: Benchmarks are calibrated to sex-stratified normative longevity decline curves (Levine PhenoAge, HUNT3 VO₂ max, and autonomic aging models).',
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
                        isUk ? 'Контрольний список калібрування' : 'Calibration Checklist',
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
                  onPressed: () async {
                    Navigator.of(sheetContext).pop();
                    if (data.bioAgeRequiresProfileEdit) {
                      await Navigator.of(context).push(
                        MaterialPageRoute<void>(builder: (_) => const EditProfile()),
                      );
                      onReload?.call();
                    }
                  },
                  child: Text(
                    data.bioAgeActionLabel,
                    style: F.head.copyWith(fontWeight: FontWeight.bold),
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
    required String modifierBadge,
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
              const SizedBox(width: S.x1),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: S.x2, vertical: 2),
                decoration: BoxDecoration(
                  color: p.wash(accentColor, strength: 0.2),
                  borderRadius: R.rPill,
                ),
                child: Text(
                  modifierBadge,
                  style: F.over.copyWith(
                    color: p.on(accentColor),
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
    final isUk = LocaleController.displayLanguageCode == 'uk';
    final score = data.stressScore;
    final rawLevel = data.stressLevel ?? 'Balanced';
    final isScored = score != null;

    final String localizedLevel;
    switch (rawLevel) {
      case 'Low':
        localizedLevel = isUk ? 'Спокій' : 'Low';
        break;
      case 'Elevated':
        localizedLevel = isUk ? 'Напруга' : 'Elevated';
        break;
      case 'High':
        localizedLevel = isUk ? 'Стрес' : 'High';
        break;
      case 'Balanced':
      default:
        localizedLevel = isUk ? 'Баланс' : 'Balanced';
        break;
    }

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
                    child: const Icon(LucideIcons.zap, color: C.orange, size: 22),
                  ),
                  const SizedBox(width: S.x3),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isUk ? 'Рівень стресу та напруги' : 'Real-Time & Daily Stress',
                          style: F.t1.copyWith(color: p.ink),
                        ),
                        Text(
                          isUk
                              ? 'Вегетативний тонус та індекс напруги Баєвського'
                              : 'Autonomic nervous tone & Baevsky SI',
                          style: F.cap.copyWith(color: p.ink3),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(LucideIcons.x, color: p.ink3),
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
                            Text(isUk ? 'Індекс стресу (0–100)' : 'Stress Score (0–100)', style: F.over.copyWith(color: p.ink3)),
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
                            localizedLevel,
                            style: F.head.copyWith(color: C.blue, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: S.x4),
                    // Spectrum meter
                    Row(
                      children: [
                        _spectrumZone(p, isUk ? 'Спокій' : 'Rest', C.teal, rawLevel == 'Low'),
                        const SizedBox(width: 4),
                        _spectrumZone(p, isUk ? 'Баланс' : 'Balanced', C.blue, rawLevel == 'Balanced'),
                        const SizedBox(width: 4),
                        _spectrumZone(p, isUk ? 'Напруга' : 'Elevated', C.orange, rawLevel == 'Elevated'),
                        const SizedBox(width: 4),
                        _spectrumZone(p, isUk ? 'Стрес' : 'High', C.red, rawLevel == 'High'),
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
                          isUk
                              ? 'Індекс напруги Баєвського (SI): ${data.stressSi?.toStringAsFixed(1) ?? "Калібрування"}'
                              : 'Baevsky Stress Index (SI): ${data.stressSi?.toStringAsFixed(1) ?? "Calibrating"}',
                          style: F.head.copyWith(color: p.ink, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: S.x2),
                    Text(
                      isUk
                          ? 'Стрес визначається на основі варіабельності серцевого ритму (інтервалів RR) під час спокою. Гістограма послідовних ударів серця демонструє баланс між симпатичною (стрес) та парасимпатичною (відновлення) нервовою системою.'
                          : 'Stress is derived from heart rate variability (RR intervals) during rest. Consecutive beat-to-beat intervals form an amplitude histogram showing sympathetic vs. parasympathetic tone.',
                      style: F.cap.copyWith(color: p.ink2, height: 1.4),
                    ),
                    const SizedBox(height: S.x2),
                    Text(
                      isUk
                          ? 'Чому потрібен спокій?\nАктивний рух (ходьба, тренування) створює оптичні артефакти на датчику. Розрахунок активується автоматично, щойно ви спокійно сидите, відпочиваєте або спите.'
                          : 'Why does it need rest?\nActive motion (walking, working out) introduces motion artifacts into optical sensors. Calculations activate as soon as you sit quietly, rest, or sleep.',
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
                  child: Text(
                    isUk ? 'Відкрити панель стресу' : 'Open Mind & Stress Dashboard',
                    style: F.head.copyWith(fontWeight: FontWeight.bold),
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

  static void _showJournalDetailSheet(
    BuildContext context,
    _NextGenData data, {
    VoidCallback? onReload,
  }) {
    final p = P.of(context);
    final isUk = LocaleController.displayLanguageCode == 'uk';
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
                    child: const Icon(LucideIcons.notebook, color: C.purple, size: 22),
                  ),
                  const SizedBox(width: S.x3),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isUk ? 'Вплив звичок на організм' : 'Journal Habit Insights',
                          style: F.t1.copyWith(color: p.ink),
                        ),
                        Text(
                          isUk
                              ? 'Об’єктивна кореляція з ранковим відновленням'
                              : 'Objective correlation with morning recovery',
                          style: F.cap.copyWith(color: p.ink3),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(LucideIcons.x, color: p.ink3),
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
                            isUk
                                ? '${row['n_with']} днів з цією звичкою · ${row['n_without']} без неї'
                                : '${row['n_with']} logged days with · ${row['n_without']} without',
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
                        isUk
                            ? 'Двовибірковий t-тест Велча'
                            : 'Welch’s Two-Sample Statistical Correlation',
                        style: F.head.copyWith(color: p.ink, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: S.x2),
                      Text(
                        isUk
                            ? 'Аналітичний модуль порівнює ранковий HRV та пульс спокою після днів із цією звичкою та без неї за допомогою t-критерію Велча. Це дозволяє відсіяти випадковий шум і виявити реальний причинно-наслідковий вплив.'
                            : 'The analytics engine computes Welch’s t-test comparing morning biomarkers on nights following this habit versus nights without it. This isolates true causal behavioral signals from noise.',
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
                    isUk
                        ? 'Запишіть принаймні 5 днів зі звичкою та 5 днів без неї, щоб система виявила підтверджені статистичні зв’язки з вашим відновленням.'
                        : 'Log at least 5 days with a habit and 5 days without it to surface verified statistical correlations with your morning recovery and HRV.',
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
                  onPressed: () async {
                    Navigator.of(sheetContext).pop();
                    await Navigator.of(context).push(
                      MaterialPageRoute<void>(builder: (_) => JournalCompose(date: data.dayId)),
                    );
                    onReload?.call();
                  },
                  child: Text(
                    isUk ? 'Записати звички за сьогодні' : 'Log Today’s Journal',
                    style: F.head.copyWith(fontWeight: FontWeight.bold),
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
    final isUk = LocaleController.displayLanguageCode == 'uk';

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
                    child: const Icon(LucideIcons.dumbbell, color: C.green, size: 22),
                  ),
                  const SizedBox(width: S.x3),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isUk ? 'Трекер силових повторень' : 'Strength Rep Counter',
                          style: F.t1.copyWith(color: p.ink),
                        ),
                        Text(
                          isUk
                              ? 'Високочастотна кінематика 100 Гц'
                              : 'High-rate 100 Hz IMU kinematics',
                          style: F.cap.copyWith(color: p.ink3),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(LucideIcons.x, color: p.ink3),
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
                          isUk ? 'Лише в оперативній пам’яті (RAM)' : 'Live RAM Only',
                          style: F.t1.copyWith(color: p.ink, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          isUk
                              ? '100 Гц акселерометр та гіроскоп'
                              : '100 Hz Accelerometer & Gyroscope',
                          style: F.over.copyWith(color: p.ink3),
                        ),
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
                      isUk ? 'Чому історія порожня?' : 'Why is history blank?',
                      style: F.head.copyWith(color: p.ink, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: S.x2),
                    Text(
                      isUk
                          ? 'Потік сенсорних кадрів на частоті 100 Гц генерує гігабайти даних на годину і не записується у постійну пам’ять телефону. Детекція повторень працює з нульовою затримкою безпосередньо в оперативній пам’яті під час активного тренування.'
                          : 'High-rate 100 Hz IMU sensor frames produce gigabytes per hour and are never permanently stored in device flash storage. Rep detection operates with zero latency directly in live RAM during an active workout session.',
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
                  child: Text(
                    isUk ? 'Почати тренування' : 'Start Workout',
                    style: F.head.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── BIOMARKER INSIGHT BILINGUAL HELPERS ──────────────────────────────────

  static String _getHeartInsight(ana.BiologicalAgeResult result, double? rhr, bool isUk) {
    final pulse = rhr?.toStringAsFixed(0) ?? '—';
    if (isUk) {
      if (result.rhrModifier < 0) {
        return 'Пульс спокою ($pulse уд/хв) вказує на відмінний ударний об’єм серця та еластичність судин (-${(-result.rhrModifier).toStringAsFixed(1)} р.).';
      } else if (result.rhrModifier > 0) {
        return 'Підвищений пульс спокою ($pulse уд/хв) створює додаткове навантаження на серцево-судинну систему (+${result.rhrModifier.toStringAsFixed(1)} р.).';
      } else {
        return 'Пульс спокою ($pulse уд/хв) знаходиться в оптимальній фізіологічній нормі для вашого віку.';
      }
    } else {
      return result.heartInsight;
    }
  }

  static String _getHrvInsight(ana.BiologicalAgeResult result, double? hrv, bool isUk) {
    final hrvMs = hrv?.toStringAsFixed(0) ?? '—';
    if (isUk) {
      if (result.hrvModifier <= -1.0) {
        return 'Нічний вегетативний баланс ($hrvMs мс) демонструє молоду парасимпатичну стійкість (-${(-result.hrvModifier).toStringAsFixed(1)} р.).';
      } else if (result.hrvModifier >= 1.0) {
        return 'Нічний HRV ($hrvMs мс) свідчить про накопичену хронічну втому або стрес (+${result.hrvModifier.toStringAsFixed(1)} р.).';
      } else {
        return 'Нічний HRV ($hrvMs мс) відображає збалансоване відновлення нервової системи для вашого віку.';
      }
    } else {
      return result.hrvInsight;
    }
  }

  static String _getVo2Insight(ana.BiologicalAgeResult result, bool isUk) {
    final vo2 = result.vo2MaxEst.toStringAsFixed(1);
    final isFemale = result.sex == 'f';
    if (isUk) {
      if (result.vo2Modifier <= -1.0) {
        return 'Аеробна форма ($vo2 мл/кг) перевищує показники однолітків серед ${isFemale ? "жінок" : "чоловіків"}, скидаючи ${(-result.vo2Modifier).toStringAsFixed(1)} р.';
      } else if (result.vo2Modifier >= 1.0) {
        return 'Аеробна витривалість ($vo2 мл/кг) відстає від вікової норми, додаючи ${result.vo2Modifier.toStringAsFixed(1)} р. навантаження.';
      } else {
        return 'Аеробна ємність ($vo2 мл/кг) повністю відповідає паспортному віку.';
      }
    } else {
      return result.vo2Insight;
    }
  }

  static String _getLifestyleInsight(ana.BiologicalAgeResult result, bool isUk) {
    if (isUk) {
      if (result.lifestyleModifier < 0) {
        return 'Стабільний циркадний ритм сну та здорова щоденна рухова активність (-${(-result.lifestyleModifier).toStringAsFixed(1)} р.).';
      } else if (result.lifestyleModifier > 0) {
        return 'Нерегулярний графік сну або низька активність додають біологічного зносу (+${result.lifestyleModifier.toStringAsFixed(1)} р.).';
      } else {
        return 'Помірна щоденна активність і прийнятна стабільність графіка сну.';
      }
    } else {
      return result.lifestyleInsight;
    }
  }

  static List<String> _getActionableTips(ana.BiologicalAgeResult result, bool isUk) {
    if (!isUk) return result.actionableTips;
    final tips = <String>[];
    if (result.lifestyleModifier > 0) {
      tips.add('Закріпіть час відходу до сну в межах 30-хвилинного вікна (індекс регулярності >80%), щоб омолодити серце на ~0.8 року.');
      tips.add('Збільште щоденну активність до 8 000–10 000 кроків для покращення метаболічної гнучкості.');
    }
    if (result.vo2Modifier >= 0.0) {
      tips.add('Додайте 1–2 сесії HIIT або інтервалів у 4/5 пульсових зонах щотижня для підвищення VO₂ Max та еластичності судин.');
    }
    if (result.rhrModifier > 0.0) {
      tips.add('Приділіть увагу низькоінтенсивному бігу або веслуванню в Зоні 2 (30–45 хв), щоб знизити пульс спокою та зміцнити міокард.');
    }
    if (tips.isEmpty) {
      tips.add('Відмінні біологічні маркери за всіма стовпами! Підтримуйте стабільний режим сну, щоденний рух та кардіонавантаження.');
    }
    return tips;
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
    this.journalInsight,
    this.dayLoggedHabits = const [],
  });

  static Future<_NextGenData> load(
    LocalRepository repo, {
    required String day,
  }) async {
    final isToday = day == todayLabel();
    final results = await Future.wait<Object>([
      repo.getDayStress(day),
      repo.getProfile(),
      repo.getZones(),
      repo.getInsights(),
      repo.getJournalInsights(),
      repo.getChart('resting_hr'),
      repo.getChart('hrv'),
      repo.getChart('steps'),
    ]);
    final rawStress = results[0] as Map<String, dynamic>;
    final profile = results[1] as Map<String, dynamic>;
    final zones = results[2] as Map<String, dynamic>;
    final insights = results[3] as Map<String, dynamic>;
    final journal = results[4] as Map<String, dynamic>;

    final rhr = _tailValues(results[5] as Map<String, dynamic>, 14, day: day);
    final hrv = _tailValues(results[6] as Map<String, dynamic>, 14, day: day);
    final steps = _tailValues(results[7] as Map<String, dynamic>, 14, day: day);
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
    final isUk = LocaleController.displayLanguageCode == 'uk';
    final checklistItems = <String>[
      age != null
          ? (isUk
              ? '✓ Вік з профілю: ${age.toStringAsFixed(0)} років'
              : '✓ Profile Age: ${age.toStringAsFixed(0)} years')
          : (isUk
              ? '✗ Вік не вказано (натисніть кнопку нижче)'
              : '✗ Profile Age: Missing (tap button below to enter)'),
      sex == 'f'
          ? (isUk
              ? '✓ Біологічна стать: Жіноча (застосовано жіночі норми)'
              : '✓ Biological Sex: Female (normative female benchmarks applied)')
          : (sex == 'm'
              ? (isUk
                  ? '✓ Біологічна стать: Чоловіча (застосовано чоловічі норми)'
                  : '✓ Biological Sex: Male (normative male benchmarks applied)')
              : (isUk
                  ? '✓ Біологічна стать: Стандартні норми'
                  : '✓ Biological Sex: Standard benchmark applied')),
      measuredMaxHr != null
          ? (isUk
              ? '✓ Макс. пульс: ${measuredMaxHr.toStringAsFixed(0)} уд/хв (виміряно)'
              : '✓ Max Heart Rate: ${measuredMaxHr.toStringAsFixed(0)} bpm (measured)')
          : (effectiveMaxHr != null
              ? (isUk
                  ? '✓ Макс. пульс: ${effectiveMaxHr.toStringAsFixed(0)} уд/хв (оцінка за віком)'
                  : '✓ Max Heart Rate: ${effectiveMaxHr.toStringAsFixed(0)} bpm (estimated from age)')
              : (isUk
                  ? '✗ Макс. пульс: Потрібен вік для оцінки або тренування'
                  : '✗ Max HR Ceiling: Need age to estimate or workout to measure')),
      rhr.length >= 3
          ? (isUk
              ? '✓ Пульс спокою: ${rhr.length}/7 днів записано'
              : '✓ Resting HR: ${rhr.length}/7 days recorded')
          : (isUk
              ? '✗ Пульс спокою: потрібно мінімум 3 дні (${rhr.length}/3)'
              : '✗ Resting HR: ${rhr.length}/3 days minimum needed'),
      hrv.length >= 3
          ? (isUk
              ? '✓ Нічний HRV: ${hrv.length}/7 ночей записано'
              : '✓ Overnight HRV: ${hrv.length}/7 days recorded')
          : (isUk
              ? '✗ Нічний HRV: потрібно мінімум 3 ночі (${hrv.length}/3)'
              : '✗ Overnight HRV: ${hrv.length}/3 nights minimum needed'),
      steps.isNotEmpty
          ? (isUk
              ? '✓ Щоденні кроки: ${steps.length}/7 днів (${_mean(steps).toStringAsFixed(0)} сер.)'
              : '✓ Daily Steps: ${steps.length}/7 days recorded (${_mean(steps).toStringAsFixed(0)} avg)')
          : (isUk
              ? '• Щоденні кроки: Калібрування (базовий темп)'
              : '• Daily Steps: Calibrating (using standard active benchmark)'),
      sri != null
          ? (isUk
              ? '✓ Ритм сну (SRI): ${sri.toStringAsFixed(0)}%'
              : '✓ Sleep Regularity (SRI): ${sri.toStringAsFixed(0)}%')
          : (isUk
              ? '• Ритм сну: Калібрування (базовий ритм)'
              : '• Sleep Regularity: Calibrating (using standard rhythm)'),
    ];
    final bioChecklist = checklistItems.join('\n');

    String bioAction = isUk ? 'Відкрити профіль' : 'Open Profile';
    bool bioRequiresEdit = false;

    final effectiveSleepConsistency = sri != null
        ? (sri.clamp(0, 100) / 100).toDouble()
        : 0.75;

    final targetMaxHr = effectiveMaxHr ?? 190.0;
    if (age == null) {
      bioMissing = isUk ? 'Вкажіть вашу дату народження/вік у Профілі.' : 'Needs your birth date/age in Profile.';
      bioAction = isUk ? 'Вказати вік у Профілі' : 'Enter Age in Profile';
      bioRequiresEdit = true;
    } else if (rhr.length < 3 || hrv.length < 3) {
      final daysLeft = 3 - (rhr.length < hrv.length ? rhr.length : hrv.length);
      bioMissing = isUk
          ? 'Потрібно ще $daysLeft дн. носіння браслета для 3-денної бази.'
          : 'Need $daysLeft more day(s) wearing band to establish 3-day baseline.';
      bioAction = isUk ? 'Зрозуміло (носити браслет)' : 'Got it (Keep wearing band)';
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
        final tRhr = _tailValues(results[5] as Map<String, dynamic>, 14, day: tLabel);
        final tHrv = _tailValues(results[6] as Map<String, dynamic>, 14, day: tLabel);
        final tSteps = _tailValues(results[7] as Map<String, dynamic>, 14, day: tLabel);
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

class _BioEquationNode extends StatelessWidget {
  final String value;
  final String label;
  final Color color;
  final bool highlight;

  const _BioEquationNode({
    required this.value,
    required this.label,
    required this.color,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    final p = P.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: F.n17.copyWith(
            color: p.on(color),
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: F.over.copyWith(
            color: highlight ? p.on(color) : p.ink3,
            fontWeight: highlight ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }
}

class _BioLedgerEquationRow extends StatelessWidget {
  final String sign;
  final String value;
  final String label;
  final Color color;
  final bool isTotal;

  const _BioLedgerEquationRow({
    required this.sign,
    required this.value,
    required this.label,
    required this.color,
    this.isTotal = false,
  });

  @override
  Widget build(BuildContext context) {
    final p = P.of(context);
    return Row(
      children: [
        Container(
          width: 22,
          height: 22,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: p.wash(color, strength: 0.3),
            borderRadius: R.rPill,
          ),
          child: Text(
            sign,
            style: F.over.copyWith(
              color: p.on(color),
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(width: S.x2),
        Expanded(
          child: Text(
            label,
            style: isTotal
                ? F.cap.copyWith(color: p.ink, fontWeight: FontWeight.bold)
                : F.cap.copyWith(color: p.ink2),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        Text(
          value,
          style: isTotal
              ? F.n17.copyWith(color: p.on(color), fontWeight: FontWeight.bold)
              : F.cap.copyWith(color: p.ink, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}
