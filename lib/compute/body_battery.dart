import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../ui2/theme.dart';

/// Body Battery / Physiological Energy State (Garmin/Firstbeat model).
///
/// Models dynamic energy reserves (5..100) from nocturnal recovery (ANS charge)
/// and cumulative daytime drain (cardiovascular strain + metabolic hours awake).
class BodyBatteryState {
  final int current; // 5..100
  final int morningCharge; // 25..99
  final int totalDrain; // cumulative drain for the day
  final int strainDrain; // drain from physical cardio load
  final int timeDrain; // baseline metabolic drain from waking hours
  final String status;
  final String verdict;
  final Color tierColor;
  final IconData icon;

  const BodyBatteryState({
    required this.current,
    required this.morningCharge,
    required this.totalDrain,
    required this.strainDrain,
    required this.timeDrain,
    required this.status,
    required this.verdict,
    required this.tierColor,
    required this.icon,
  });
}

class BodyBatteryCalculator {
  static BodyBatteryState calculate({
    num? readinessVal,
    num? sleepQualityVal,
    num? strainVal,
    String? dayId,
    DateTime? now,
  }) {
    final currentTime = now ?? DateTime.now();

    // 1. Morning Charge (0..100)
    final double rawCharge;
    if (readinessVal != null && sleepQualityVal != null) {
      rawCharge = readinessVal.toDouble() * 0.6 + sleepQualityVal.toDouble() * 0.4;
    } else if (readinessVal != null) {
      rawCharge = readinessVal.toDouble();
    } else if (sleepQualityVal != null) {
      rawCharge = sleepQualityVal.toDouble();
    } else {
      rawCharge = 70.0;
    }
    final morningCharge = rawCharge.round().clamp(25, 99);

    // 2. Physical Strain Drain (0..65)
    final s = (strainVal?.toDouble() ?? 0.0).clamp(0.0, 21.0);
    final strainDrain = (s * 3.0).round().clamp(0, 65);

    // 3. Time / Metabolic Drain (0..30)
    // Approximate wake at 07:30. Each hour awake has baseline metabolic cost ~1.8%.
    final double hoursAwake;
    final currentHour = currentTime.hour + currentTime.minute / 60.0;
    if (currentHour >= 7.5) {
      hoursAwake = (currentHour - 7.5).clamp(0.0, 16.0);
    } else {
      // Early morning before wake window: minimal drain
      hoursAwake = 0.5;
    }
    final timeDrain = (hoursAwake * 1.8).round().clamp(0, 30);

    // 4. Cumulative Drain & Net Energy
    final maxAllowedDrain = (morningCharge - 5).clamp(0, 95);
    final totalDrain = (strainDrain + timeDrain).clamp(0, maxAllowedDrain);
    final current = (morningCharge - totalDrain).clamp(5, 100);

    // 5. Categorization & Actionable Guidance
    final String status;
    final String verdict;
    final Color tierColor;
    final IconData icon;

    if (current >= 75) {
      status = 'HIGH ENERGY · ОПТИМАЛЬНИЙ РЕЗЕРВ';
      verdict =
          'Autonomic reserves fully charged. Ideal window for peak cardiovascular strain and high cognitive focus.';
      tierColor = C.green;
      icon = LucideIcons.batteryCharging;
    } else if (current >= 45) {
      status = 'STEADY ENERGY · ПОМІРНИЙ РЕЗЕРВ';
      verdict =
          'Balanced energy reserves. Sufficient for productive daily activity and Zone 2 aerobic training.';
      tierColor = C.yellow;
      icon = LucideIcons.batteryMedium;
    } else if (current >= 20) {
      status = 'LOW ENERGY · НИЗЬКИЙ РЕЗЕРВ';
      verdict =
          'Physiological fatigue accumulating. Avoid exhausting workouts; focus on recovery and an early bedtime.';
      tierColor = C.orange;
      icon = LucideIcons.batteryLow;
    } else {
      status = 'DEPLETED · ВИСНАЖЕННЯ';
      verdict =
          'Energy reserves critically depleted. The autonomic nervous system demands rest and restorative sleep.';
      tierColor = C.red;
      icon = LucideIcons.batteryWarning;
    }

    return BodyBatteryState(
      current: current,
      morningCharge: morningCharge,
      totalDrain: totalDrain,
      strainDrain: strainDrain,
      timeDrain: timeDrain,
      status: status,
      verdict: verdict,
      tierColor: tierColor,
      icon: icon,
    );
  }
}
