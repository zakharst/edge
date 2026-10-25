import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../compute/body_battery.dart';
import '../../data/day_label.dart';
import '../theme.dart';
import 'home_screen.dart';

/// Next-Gen Live Body Battery Card.
///
/// Models dynamic energy reserves (5..100%) from morning recovery and
/// daytime drain (cardio strain + waking hours).
class BodyBatteryCard extends StatelessWidget {
  final HomeData d;

  const BodyBatteryCard({super.key, required this.d});

  @override
  Widget build(BuildContext context) {
    final p = P.of(context);
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

    return Container(
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
                  'BODY BATTERY · ЖИТТЄВА БАТАРЕЙКА',
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
                  '$current% ⚡ ${current >= 75 ? "ВИСОКИЙ" : (current >= 45 ? "ПОМІРНИЙ" : "НИЗЬКИЙ")}',
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
                    isToday ? 'LIVE ENERGY' : 'END OF DAY',
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
                'Заряд: ${battery.morningCharge}% · Спалено: -${battery.totalDrain}%',
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
              minHeight: 8,
              backgroundColor: p.track,
              color: color,
            ),
          ),
          const SizedBox(height: S.x3),

          // Verdict Line
          Text(
            battery.verdict,
            style: F.body.copyWith(color: p.ink2, height: 1.3),
          ),
          const SizedBox(height: S.x3),

          // Breakdown Chips
          Row(
            children: [
              Expanded(
                child: _BatteryMiniChip(
                  label: 'Ранковий старт',
                  value: '${battery.morningCharge}%',
                  icon: LucideIcons.sunrise,
                  color: C.green,
                ),
              ),
              const SizedBox(width: S.x2),
              Expanded(
                child: _BatteryMiniChip(
                  label: 'Навантаження',
                  value: '-${battery.strainDrain}%',
                  icon: LucideIcons.zap,
                  color: C.purple,
                ),
              ),
              const SizedBox(width: S.x2),
              Expanded(
                child: _BatteryMiniChip(
                  label: 'Стрес / час',
                  value: '-${battery.timeDrain}%',
                  icon: LucideIcons.clock,
                  color: C.orange,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BatteryMiniChip extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _BatteryMiniChip({
    required this.label,
    required this.value,
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
        ],
      ),
    );
  }
}
