import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../compute/body_battery.dart';
import '../../data/day_label.dart';
import '../../state/locale_controller.dart';
import '../grammar.dart';
import '../theme.dart';
import 'biometric_explainer_sheet.dart';
import 'home_screen.dart';

/// Next-Gen Live Body Battery Card.
///
/// Models dynamic energy reserves (5..100%) from morning recovery and
/// daytime drain (cardio strain + waking hours).
/// Visual equation directly explains how the current score is derived.
class BodyBatteryCard extends StatelessWidget {
  final HomeData d;

  const BodyBatteryCard({super.key, required this.d});

  @override
  Widget build(BuildContext context) {
    final p = P.of(context);
    final isUk = LocaleController.displayLanguageCode == 'uk';
    final isToday = d.dayId == null || d.dayId == todayLabel();
    final battery = BodyBatteryCalculator.calculate(
      readinessVal: d.readiness.value,
      sleepQualityVal: d.sleepQuality.value ??
          (d.sleepMin.value != null ? 70.0 : null),
      strainVal: d.strain.value,
      dayId: d.dayId,
    );

    final current = battery.current;
    final color = battery.tierColor;

    return Pressable(
      onTap: () => BiometricExplainerSheet.show(
        context,
        topic: BiometricTopic.bodyBattery,
        data: battery,
      ),
      semanticLabel: isUk
          ? 'Рівень енергії: $current%. Натисніть для перегляду розрахунку.'
          : 'Body Battery: $current%. Tap to view breakdown.',
      child: Container(
        padding: const EdgeInsets.all(S.x4),
        decoration: BoxDecoration(
          color: p.card,
          borderRadius: R.rLg,
          border: Border.all(
            color: p.dark
                ? color.withValues(alpha: 0.35)
                : color.withValues(alpha: 0.2),
            width: 1.2,
          ),
          boxShadow: p.el(1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(S.x1),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: R.rSm,
                  ),
                  child: Icon(battery.icon, size: 14, color: color),
                ),
                const SizedBox(width: S.x2),
                Expanded(
                  child: Text(
                    isUk ? 'ЗАПАС ЕНЕРГІЇ' : 'BODY BATTERY',
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
                    color: color.withValues(alpha: 0.12),
                    borderRadius: R.rPill,
                    border: Border.all(
                      color: color.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Text(
                    isUk ? battery.statusUa : battery.status,
                    style: F.over.copyWith(
                      color: color,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: S.x3),

            // Main Battery Metric & Indicator
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      '$current%',
                      style: F.n48.copyWith(color: p.ink),
                    ),
                    const SizedBox(width: S.x2),
                    Text(
                      isToday
                          ? (isUk ? 'ЗАЛИШОК ЗАРАЗ' : 'LIVE ENERGY')
                          : (isUk ? 'НА КІНЕЦЬ ДНЯ' : 'END OF DAY'),
                      style: F.cap.copyWith(
                        color: color,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                Text(
                  isUk
                      ? 'Сон: +${battery.morningCharge}% · Витрати: -${battery.totalDrain}%'
                      : 'Recharge: +${battery.morningCharge}% · Spent: -${battery.totalDrain}%',
                  style: F.over.copyWith(color: p.ink3),
                ),
              ],
            ),
            const SizedBox(height: S.x2),

            // Progress Bar
            ClipRRect(
              borderRadius: R.rPill,
              child: LinearProgressIndicator(
                value: (current / 100.0).clamp(0.05, 1.0),
                minHeight: 7,
                backgroundColor: p.track,
                color: color,
              ),
            ),
            const SizedBox(height: S.x3),

            // ── VISUAL MATH LEDGER: 46% - 12% - 14% = 20% ──
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
                  _EquationNode(
                    value: '+${battery.morningCharge}%',
                    label: isUk ? 'Сон' : 'Sleep',
                    color: C.green,
                  ),
                  Text('-', style: F.head.copyWith(color: p.ink3)),
                  _EquationNode(
                    value: '${battery.strainDrain}%',
                    label: isUk ? 'Рух' : 'Active',
                    color: C.purple,
                  ),
                  Text('-', style: F.head.copyWith(color: p.ink3)),
                  _EquationNode(
                    value: '${battery.timeDrain}%',
                    label: isUk ? 'Час дня' : 'Daytime',
                    color: C.orange,
                  ),
                  Text('=', style: F.head.copyWith(color: p.ink3)),
                  _EquationNode(
                    value: '$current%',
                    label: isUk ? 'Зараз' : 'Remaining',
                    color: color,
                    highlight: true,
                  ),
                ],
              ),
            ),
            const SizedBox(height: S.x3),

            // Human Guidance
            Text(
              isUk ? battery.verdictUa : battery.verdict,
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
                  isUk ? 'Як рахується заряд' : 'How battery is calculated',
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

class _EquationNode extends StatelessWidget {
  final String value;
  final String label;
  final Color color;
  final bool highlight;

  const _EquationNode({
    required this.value,
    required this.label,
    required this.color,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    final p = P.of(context);
    return Column(
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
