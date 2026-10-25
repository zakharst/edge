import 'package:flutter_test/flutter_test.dart';
import 'package:openstrap_edge/compute/body_battery.dart';

void main() {
  group('BodyBatteryCalculator', () {
    test('high morning recovery gives high initial battery', () {
      final res = BodyBatteryCalculator.calculate(
        readinessVal: 85.0,
        sleepQualityVal: 80.0,
        strainVal: 0.0,
        now: DateTime(2026, 10, 25, 8, 0), // 8:00 AM
      );
      expect(res.morningCharge, greaterThanOrEqualTo(80));
      expect(res.current, greaterThanOrEqualTo(80));
      expect(res.status, contains('HIGH ENERGY'));
    });

    test('daytime strain and hours awake drain battery progressively', () {
      final res = BodyBatteryCalculator.calculate(
        readinessVal: 70.0,
        sleepQualityVal: 65.0,
        strainVal: 12.0, // hard workout
        now: DateTime(2026, 10, 25, 18, 0), // 6:00 PM (10.5 hours awake)
      );
      expect(res.totalDrain, greaterThan(35));
      expect(res.current, lessThan(res.morningCharge));
      expect(res.current, greaterThanOrEqualTo(5)); // Never drops below 5% floor
    });

    test('low morning recovery with extreme strain drops to floor safely', () {
      final res = BodyBatteryCalculator.calculate(
        readinessVal: 30.0,
        sleepQualityVal: 30.0,
        strainVal: 18.0,
        now: DateTime(2026, 10, 25, 22, 0), // 10:00 PM
      );
      expect(res.current, equals(5)); // Clamped at 5
      expect(res.status, contains('DEPLETED'));
    });
  });
}
