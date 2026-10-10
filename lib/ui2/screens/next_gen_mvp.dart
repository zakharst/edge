import 'package:flutter/material.dart';
import '../theme.dart';
import '../../../../analytics/lib/wellness.dart'; // Import our new analytics package
// Assuming the relative path to analytics works, or import 'package:analytics/wellness.dart';

class NextGenMvpCard extends StatefulWidget {
  const NextGenMvpCard({super.key});

  @override
  State<NextGenMvpCard> createState() => _NextGenMvpCardState();
}

class _NextGenMvpCardState extends State<NextGenMvpCard> {
  // Temporary mock data for MVP to prove the UI works with the backend math
  final double currentHr = 85.0;
  final double baselineRhr = 50.0;
  final double currentHrv = 35.0;
  final double baselineHrv = 60.0;
  final double activityLevel = 0.0; // Sitting still

  @override
  Widget build(BuildContext context) {
    // Run our new algorithm!
    final stressResult = StressMonitorEngine.calculateStress(
      currentHr: currentHr,
      baselineRhr: baselineRhr,
      currentHrv: currentHrv,
      baselineHrv: baselineHrv,
      activityLevel: activityLevel,
    );

    final p = P.of(context); // Edge theme provider

    return Card(
      color: p.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: p.line),
      ),
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.bolt, color: p.orange, size: 20),
                const SizedBox(width: 8),
                Text(
                  "NEXT-GEN STRESS (MVP)",
                  style: TextStyle(
                    color: p.ink3,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              "Current Stress Score: ${stressResult.stressScore.toStringAsFixed(1)} / 3.0",
              style: TextStyle(
                color: p.ink,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              "Category: ${stressResult.category}",
              style: TextStyle(
                color: stressResult.stressScore >= 2.0 ? p.red : (stressResult.stressScore >= 1.0 ? p.orange : p.green),
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Calculated live from HR ($currentHr bpm) vs RHR ($baselineRhr bpm)",
              style: TextStyle(color: p.ink2, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
