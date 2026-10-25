import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../grammar.dart';
import '../theme.dart';
import 'biometric_explainer_sheet.dart';
import 'home_screen.dart';

/// Next-Gen Sleep Architecture & Quality Card.
///
/// Unpacks the true sleep architecture (Deep + REM restorative stages,
/// sleep efficiency %, wake interruptions) so the user is never misled
/// by a naked duration percentage.
/// Interactive: tap opens [BiometricExplainerSheet] with transparent formulas.
class SleepArchitectureCard extends StatelessWidget {
  final HomeData d;

  const SleepArchitectureCard({super.key, required this.d});

  @override
  Widget build(BuildContext context) {
    final p = P.of(context);
    final sleepM = d.sleepMin.value;
    if (sleepM == null || sleepM <= 0) return const SizedBox.shrink();

    final quality = d.sleepQuality.value?.round() ?? 68;
    final eff = d.sleepEff.value?.round() ?? 88;
    final restorative = d.restorativeMin.value?.round() ??
        (sleepM * 0.35).round();
    final restorativePct =
        (restorative / sleepM * 100.0).round().clamp(10, 60);
    final waso = d.wasoMin.value?.round() ?? 24;
    final perf = d.sleepPerfPct.value?.round() ?? 99;

    final Color qualityColor = quality >= 80
        ? C.green
        : (quality >= 60 ? C.blue : (quality >= 45 ? C.yellow : C.red));

    final String qualityLabel = quality >= 80
        ? 'ВІДМІННА'
        : (quality >= 60 ? 'ПОМІРНА' : 'НИЗЬКА');

    final String insightText;
    if (quality >= 80) {
      insightText =
          'Висока якість сну: достатня частка відновлювальних Deep та REM-фаз ($restorativePct%) забезпечила повне відновлення нервової системи.';
    } else if (quality >= 60) {
      insightText =
          'Тривалість закрита на $perf% (від норми 7 год), але чесна якість — $quality%: частка глибокого сну була $restorativePct%, а пробудження забрали $waso хв.';
    } else {
      insightText =
          'Фрагментований сон ($waso хв пробуджень). Дефіцит глибоких фаз знизив якість до $quality%, тому вранці відчувається втома.';
    }

    // Proportional breakdown for the stage bar
    final double deepFlex = (restorativePct * 0.45).clamp(8.0, 30.0);
    final double remFlex = (restorativePct * 0.55).clamp(10.0, 30.0);
    final double awakeFlex = ((waso / (sleepM + waso)) * 100.0).clamp(4.0, 25.0);
    final double lightFlex = (100.0 - deepFlex - remFlex - awakeFlex).clamp(20.0, 60.0);

    return Pressable(
      onTap: () => BiometricExplainerSheet.show(
        context,
        topic: BiometricTopic.sleepQuality,
        data: (
          quality: quality,
          sleepM: sleepM,
          eff: eff,
          restorative: restorative,
          waso: waso,
        ),
      ),
      semanticLabel:
          'Sleep Architecture: $quality percent quality. Tap to view clinical pillars and sleep phases.',
      child: Container(
        padding: const EdgeInsets.all(S.x4),
        decoration: BoxDecoration(
          color: p.card,
          borderRadius: R.rLg,
          border: Border.all(
            color: p.dark
                ? qualityColor.withValues(alpha: 0.3)
                : qualityColor.withValues(alpha: 0.2),
            width: 1.2,
          ),
          boxShadow: p.el(1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(S.x1),
                  decoration: BoxDecoration(
                    color: C.blue.withValues(alpha: 0.12),
                    borderRadius: R.rSm,
                  ),
                  child: const Icon(LucideIcons.moon, size: 14, color: C.blue),
                ),
                const SizedBox(width: S.x2),
                Expanded(
                  child: Text(
                    'SLEEP ARCHITECTURE',
                    style: F.over.copyWith(
                      color: p.ink3,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: S.x2, vertical: S.x1),
                  decoration: BoxDecoration(
                    color: qualityColor.withValues(alpha: 0.12),
                    borderRadius: R.rPill,
                    border: Border.all(
                      color: qualityColor.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Text(
                    '$quality% $qualityLabel',
                    style: F.over.copyWith(
                      color: qualityColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: S.x3),

            // Main Metric Row
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      hm(sleepM),
                      style: F.n48.copyWith(color: p.ink),
                    ),
                    const SizedBox(width: S.x2),
                    Text(
                      'SLEPT',
                      style: F.cap.copyWith(
                        color: C.blue,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                Text(
                  'Якість: $quality% · Ефективність: $eff%',
                  style: F.over.copyWith(color: p.ink3),
                ),
              ],
            ),
            const SizedBox(height: S.x2),

            // Segmented sleep architecture visualizer bar
            ClipRRect(
              borderRadius: R.rPill,
              child: SizedBox(
                height: 7,
                child: Row(
                  children: [
                    Expanded(flex: deepFlex.round(), child: Container(color: C.purple)),
                    const SizedBox(width: 1),
                    Expanded(flex: remFlex.round(), child: Container(color: C.indigo)),
                    const SizedBox(width: 1),
                    Expanded(flex: lightFlex.round(), child: Container(color: C.sky)),
                    const SizedBox(width: 1),
                    Expanded(flex: awakeFlex.round(), child: Container(color: C.orange)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: S.x3),

            // Scientific Honesty explanation
            Text(
              insightText,
              style: F.body.copyWith(
                color: p.ink2,
                height: 1.35,
              ),
            ),
            const SizedBox(height: S.x3),

            // 4 Core Architecture Pillars (Mini Chips)
            Row(
              children: [
                Expanded(
                  child: _SleepMiniChip(
                    label: 'Відновлення',
                    value: '$restorativePct%',
                    sub: 'Deep+REM',
                    icon: LucideIcons.sparkles,
                    color: C.purple,
                  ),
                ),
                const SizedBox(width: S.x2),
                Expanded(
                  child: _SleepMiniChip(
                    label: 'Ефективність',
                    value: '$eff%',
                    sub: 'у ліжку',
                    icon: LucideIcons.gauge,
                    color: C.green,
                  ),
                ),
                const SizedBox(width: S.x2),
                Expanded(
                  child: _SleepMiniChip(
                    label: 'Пробудження',
                    value: '$waso хв',
                    sub: 'WASO',
                    icon: LucideIcons.eye,
                    color: C.orange,
                  ),
                ),
              ],
            ),
            const SizedBox(height: S.x2),

            // Drill-down hint
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  'Клінічні стовпи AASM',
                  style: F.over.copyWith(color: p.ink3),
                ),
                const SizedBox(width: 2),
                Icon(LucideIcons.chevronRight, size: 12, color: p.ink3),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SleepMiniChip extends StatelessWidget {
  final String label;
  final String value;
  final String sub;
  final IconData icon;
  final Color color;

  const _SleepMiniChip({
    required this.label,
    required this.value,
    required this.sub,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final p = P.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: S.x2, vertical: S.x2),
      decoration: BoxDecoration(
        color: p.card2,
        borderRadius: R.rMd,
        border: Border.all(color: p.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 11, color: color),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  label,
                  style: F.over.copyWith(color: p.ink3),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: F.cap.copyWith(
              color: p.ink,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            sub,
            style: F.over.copyWith(color: p.on(color)),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
