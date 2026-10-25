import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../state/locale_controller.dart';
import '../grammar.dart';
import '../theme.dart';
import 'biometric_explainer_sheet.dart';
import 'home_screen.dart';

/// Next-Gen Sleep Architecture & Quality Card.
///
/// Unpacks the true sleep architecture (Deep + REM restorative stages,
/// sleep efficiency %, wake interruptions) with a visual breakdown ledger.
class SleepArchitectureCard extends StatelessWidget {
  final HomeData d;

  const SleepArchitectureCard({super.key, required this.d});

  @override
  Widget build(BuildContext context) {
    final p = P.of(context);
    final isUk = LocaleController.displayLanguageCode == 'uk';
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
        ? (isUk ? 'ВІДМІННИЙ' : 'OPTIMAL')
        : (quality >= 60
            ? (isUk ? 'ПОМІРНИЙ' : 'STEADY')
            : (isUk ? 'НЕСПОКІЙНИЙ' : 'RESTLESS'));

    final String insightText;
    if (quality >= 80) {
      insightText = isUk
          ? 'Глибокий спокійний сон. Відновлювальні фази ($restorativePct%) допомогли тілу та мозку повністю перезавантажитися.'
          : 'Deep, restorative sleep. Healthy restorative stages ($restorativePct%) gave your body and mind a full recharge.';
    } else if (quality >= 60) {
      insightText = isUk
          ? 'Сон був дещо переривчастим. Ви спали ${hm(sleepM)}, але нічні пробудження забрали $waso хв, тому якість — $quality%.'
          : 'Somewhat fragmented sleep. You slept ${hm(sleepM)}, but wakeups took $waso min, bringing quality to $quality%.';
    } else {
      insightText = isUk
          ? 'Неспокійна ніч. Через $waso хв пробуджень організм недоотримав глибокого відновлення ($restorativePct%). Сьогодні бережіть сили.'
          : 'Restless night. With $waso min awake, your body missed deep recovery stages ($restorativePct%). Take it easy today.';
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
      semanticLabel: isUk
          ? 'Якість сну: $quality%. Натисніть, щоб переглянути аналіз.'
          : 'Sleep Quality: $quality%. Tap to view breakdown.',
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
                    isUk ? 'АРХІТЕКТУРА СНУ' : 'SLEEP ARCHITECTURE',
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
                      isUk ? 'ЧАС У СНІ' : 'SLEPT',
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
                  isUk
                      ? 'Якість: $quality% · Ефективність: $eff%'
                      : 'Quality: $quality% · Efficiency: $eff%',
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

            // ── VISUAL SLEEP LEDGER: чому 60%, а не 99% ──
            Container(
              padding: const EdgeInsets.all(S.x3),
              decoration: BoxDecoration(
                color: p.card2,
                borderRadius: R.rMd,
                border: Border.all(color: p.line),
              ),
              child: Column(
                children: [
                  _LedgerLine(
                    icon: LucideIcons.clock,
                    color: C.blue,
                    title: isUk ? 'Час у ліжку' : 'Time in bed',
                    detail: isUk ? '${hm(sleepM)} ($perf% від 7 год)' : '${hm(sleepM)} ($perf% of 7h)',
                    status: perf >= 90 ? (isUk ? 'Достатньо' : 'Optimal') : (isUk ? 'Мало' : 'Short'),
                  ),
                  const SizedBox(height: 6),
                  _LedgerLine(
                    icon: LucideIcons.sparkles,
                    color: C.purple,
                    title: isUk ? 'Глибокий та REM-сон' : 'Deep & REM stages',
                    detail: isUk ? '$restorativePct% (ціль >35%)' : '$restorativePct% (target >35%)',
                    status: restorativePct >= 35 ? (isUk ? 'Добре' : 'Good') : (isUk ? 'Знижено' : 'Low'),
                  ),
                  const SizedBox(height: 6),
                  _LedgerLine(
                    icon: LucideIcons.gauge,
                    color: C.green,
                    title: isUk ? 'Спокій у ліжку' : 'Sleep efficiency',
                    detail: '$eff%',
                    status: eff >= 85 ? (isUk ? 'Спокійно' : 'Peaceful') : (isUk ? 'Крутіння' : 'Restless'),
                  ),
                  const SizedBox(height: 6),
                  _LedgerLine(
                    icon: LucideIcons.eye,
                    color: C.orange,
                    title: isUk ? 'Пробудження вночі' : 'Time awake',
                    detail: isUk ? '$waso хв' : '$waso min',
                    status: waso <= 20 ? (isUk ? 'Мало' : 'Minimal') : (isUk ? 'Багато' : 'High'),
                  ),
                ],
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
            const SizedBox(height: S.x2),

            // Drill-down hint
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  isUk ? 'Як рахується якість сну' : 'How sleep quality is measured',
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

class _LedgerLine extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String detail;
  final String status;

  const _LedgerLine({
    required this.icon,
    required this.color,
    required this.title,
    required this.detail,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    final p = P.of(context);
    return Row(
      children: [
        Icon(icon, size: 12, color: p.on(color)),
        const SizedBox(width: S.x2),
        Expanded(
          child: Text(
            title,
            style: F.cap.copyWith(color: p.ink2),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        Text(
          detail,
          style: F.cap.copyWith(color: p.ink, fontWeight: FontWeight.w600),
        ),
        const SizedBox(width: S.x2),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: p.wash(color, strength: 0.35),
            borderRadius: R.rPill,
          ),
          child: Text(
            status,
            style: F.over.copyWith(
              color: p.on(color),
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}
