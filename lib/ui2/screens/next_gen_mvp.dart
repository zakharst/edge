import 'package:flutter/material.dart';
import '../theme.dart';
import 'package:openstrap_analytics/onehz.dart';

class NextGenMvpCard extends StatefulWidget {
  const NextGenMvpCard({super.key});

  @override
  State<NextGenMvpCard> createState() => _NextGenMvpCardState();
}

class _NextGenMvpCardState extends State<NextGenMvpCard> {
  // Real-Time Stress Mock Data
  final double currentHr = 85.0;
  final double baselineRhr = 50.0;
  final double currentHrv = 35.0;
  final double baselineHrv = 60.0;
  final double activityLevel = 0.0; // Sitting still

  // Biological Age Mock Data
  final double chronologicalAge = 35.0;
  final double maxHr = 190.0;
  final double bioAvgRhr = 52.0;
  final double bioAvgHrv = 65.0;
  final double sleepConsistency = 0.88;
  final double avgDailySteps = 12500;

  // Sleep Need Mock Data
  final double strain = 14.5;
  final double previousTotalNeed = 480.0;
  final double previousActualSleep = 420.0;
  final double napMinutes = 30.0;

  // Journal Insights Mock Data
  final Map<DateTime, List<String>> mockJournal = {
    for (int i = 0; i < 20; i++) 
      DateTime.now().subtract(Duration(days: i)): i % 3 == 0 ? ['Magnesium (Mock)'] : [],
  };
  final Map<DateTime, double> mockMetrics = {
    for (int i = 0; i < 20; i++) 
      DateTime.now().subtract(Duration(days: i)): i % 3 == 0 ? 85.0 : 60.0,
  };

  // Rep Counter Mock Data
  final List<Vector3> simulatedSquats = [
    Vector3(0, 0, 1.0), Vector3(0, 0, 1.5), Vector3(0, 0, 0.5), Vector3(0, 0, 1.0), // Rep 1
    Vector3(0, 0, 1.0), Vector3(0, 0, 1.4), Vector3(0, 0, 0.6), Vector3(0, 0, 1.0), // Rep 2
    Vector3(0, 0, 1.0), Vector3(0, 0, 1.6), Vector3(0, 0, 0.4), Vector3(0, 0, 1.0), // Rep 3
  ];
  
  Widget _buildCardHeader(P p, IconData icon, String title, Color color) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            color: p.ink3,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildCard(P p, Widget child) {
    return Card(
      color: p.card,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: p.line),
      ),
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = P.of(context); 

    // 1. Stress Calculation
    final stressResult = StressMonitorEngine.calculateStress(
      currentHr: currentHr,
      baselineRhr: baselineRhr,
      currentHrv: currentHrv,
      baselineHrv: baselineHrv,
      activityLevel: activityLevel,
    );

    // 2. Biological Age Calculation
    final bioAgeResult = BiologicalAgeCalculator.calculate(
      chronologicalAge: chronologicalAge,
      maxHr: maxHr,
      avgRhr: bioAvgRhr,
      avgHrv: bioAvgHrv,
      sleepConsistency: sleepConsistency,
      avgDailySteps: avgDailySteps,
    );

    // 3. Sleep Need Calculation
    final sleepNeedResult = SleepNeedCalculator.calculate(
      strain: strain,
      previousTotalNeed: previousTotalNeed,
      previousActualSleep: previousActualSleep,
      napMinutes: napMinutes,
    );

    // 4. Journal Correlation
    final List<HabitImpact> impacts = JournalCorrelationEngine.analyze(
      journalEntries: mockJournal, 
      targetMetrics: mockMetrics,
    );
    final journalImpact = impacts.isNotEmpty ? impacts.first : null;

    // 5. Rep Counter
    final repResult = RepCounterEngine.countReps(
      imuData: simulatedSquats,
      sampleRateHz: 10, // Mocked low sample rate for test
      minTimeBetweenRepsMs: 300, 
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // STRESS MVP CARD
        _buildCard(p, Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildCardHeader(p, Icons.bolt, "NEXT-GEN STRESS (MVP)", C.orange),
            const SizedBox(height: 12),
            Text(
              "Current Stress Score: ${stressResult.stressScore.toStringAsFixed(1)} / 3.0",
              style: TextStyle(color: p.ink, fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            Text(
              "Category: ${stressResult.category}",
              style: TextStyle(
                color: stressResult.stressScore >= 2.0 ? C.red : (stressResult.stressScore >= 1.0 ? C.orange : C.green),
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Live from HR ($currentHr bpm) vs RHR ($baselineRhr bpm)",
              style: TextStyle(color: p.ink2, fontSize: 12),
            ),
          ],
        )),

        // BIO AGE MVP CARD
        _buildCard(p, Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildCardHeader(p, Icons.favorite, "BIOLOGICAL AGE (MVP)", C.red),
            const SizedBox(height: 12),
            Text(
              "Bio Age: ${bioAgeResult.biologicalAge.toStringAsFixed(1)}",
              style: TextStyle(color: p.ink, fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            Text(
              "Chronological: $chronologicalAge",
              style: TextStyle(color: p.ink2, fontSize: 14),
            ),
            const SizedBox(height: 8),
            Text(
              "VO2 Mod: ${bioAgeResult.vo2Modifier.toStringAsFixed(1)} | HRV Mod: ${bioAgeResult.hrvModifier.toStringAsFixed(1)}",
              style: TextStyle(color: p.ink2, fontSize: 12),
            ),
          ],
        )),

        // SLEEP NEED MVP CARD
        _buildCard(p, Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildCardHeader(p, Icons.bedtime, "SLEEP PLANNER (MVP)", C.blue),
            const SizedBox(height: 12),
            Text(
              "Tonight's Need: ${sleepNeedResult.totalNeedMinutes.toStringAsFixed(0)} min",
              style: TextStyle(color: p.ink, fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            Text(
              "Base: ${sleepNeedResult.baselineMinutes} | Strain: +${sleepNeedResult.strainMinutes.toStringAsFixed(0)} | Debt: +${sleepNeedResult.debtMinutes.toStringAsFixed(0)}",
              style: TextStyle(color: p.ink2, fontSize: 12),
            ),
            if (sleepNeedResult.napCreditMinutes > 0)
              Text(
                "Nap Credit: -${sleepNeedResult.napCreditMinutes} min",
                style: TextStyle(color: C.green, fontSize: 12, fontWeight: FontWeight.w500),
              ),
          ],
        )),

        // JOURNAL INSIGHTS MVP CARD
        _buildCard(p, Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildCardHeader(p, Icons.book, "JOURNAL INSIGHTS (MVP)", C.purple),
            const SizedBox(height: 12),
            Text(
              journalImpact != null ? "${journalImpact.habitName} Impact: ${journalImpact.delta > 0 ? '+' : ''}${journalImpact.delta.toStringAsFixed(1)}%" : "Not enough data",
              style: TextStyle(color: p.ink, fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            if (journalImpact != null) ...[
              Text(
                journalImpact.isSignificant ? "Statistically Significant" : "Not Significant",
                style: TextStyle(color: journalImpact.isSignificant ? C.green : C.orange, fontSize: 14, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 4),
              Text(
                "p-value: ${journalImpact.pValue.toStringAsFixed(4)} (Welch's t-test)",
                style: TextStyle(color: p.ink2, fontSize: 12),
              ),
            ]
          ],
        )),

        // REP COUNTER MVP CARD
        _buildCard(p, Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildCardHeader(p, Icons.fitness_center, "REP COUNTER (MVP)", C.green),
            const SizedBox(height: 12),
            Text(
              "Detected Reps: ${repResult.reps}",
              style: TextStyle(color: p.ink, fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            Text(
              "Intensity: ${repResult.averageIntensity.toStringAsFixed(2)}g",
              style: TextStyle(color: p.ink2, fontSize: 14),
            ),
          ],
        )),
      ],
    );
  }
}
