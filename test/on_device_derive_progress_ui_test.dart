import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:openstrap_edge/models/metric.dart';
import 'package:openstrap_edge/state/app_state.dart';
import 'package:openstrap_edge/ui2/screens/screens.dart';
import 'package:openstrap_edge/ui2/ui2.dart';
import 'package:provider/provider.dart';

import 'support/app_state_derive_harness.dart';

const _db = 'openstrap_derive_progress_ui_test.db';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() => deriveDbSetUp(_db));
  tearDownAll(() => deriveDbTearDown(_db));
  setUp(deriveDbReset);
  const data = HomeData(
    name: 'Zakhar',
    dayId: '2026-10-18',
    readiness: Metric(value: 84.0, confidence: 0.95, tier: MetricTier.high),
    strain: Metric(value: 12.4, confidence: 0.9, tier: MetricTier.high),
    strainTarget: {'value': 13.0, 'low': 11.5, 'high': 14.5},
    sleepMin: Metric(value: 462.0, confidence: 0.95, tier: MetricTier.high),
    sleepNeedMin: Metric(value: 480.0, confidence: 0.9, tier: MetricTier.high),
    rhr: Metric(value: 52.0, confidence: 0.95, tier: MetricTier.high),
    steps: Metric(value: 8420.0, confidence: 0.9, tier: MetricTier.high),
    stepGoal: 10000,
    calories: Metric(value: 540.0, confidence: 0.85, tier: MetricTier.high),
    caloriesTotal: Metric(value: 2180.0, confidence: 0.85, tier: MetricTier.high),
  );

  testWidgets('displays on-device calculation card with progress, stages and privacy badge when deriving',
      (tester) async {
    tester.view.physicalSize = const Size(393 * 3, 852 * 3);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);

    final app = AppState.forTesting();
    addTearDown(app.dispose);

    // Simulate active derivation pass via DeriveProgress notifier
    app.deriveProgressNotifier.value = const DeriveProgress(
      stage: 'analyzing',
      completedDays: 1,
      totalDays: 2,
      fraction: 0.65,
      stageDescription: 'Calculating sleep stages (Deep/REM), HRV & resting heart rate…',
    );

    await tester.pumpWidget(
      ChangeNotifierProvider<AppState>.value(
        value: app,
        child: MaterialApp(
          theme: buildTheme(Brightness.dark),
          home: const Scaffold(
            body: HomeScreen(data: data, hour: 9),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verify On-Device Calculation header and privacy badge
    expect(find.text('On-Device Calculation'), findsOneWidget);
    expect(find.text('100% PRIVATE'), findsOneWidget);
    expect(find.byIcon(LucideIcons.cpu), findsOneWidget);
    expect(find.byIcon(LucideIcons.shieldCheck), findsOneWidget);

    // Verify multi-stage indicator and percentage
    expect(find.text('Step 2 of 3: Analyzing History (1/2 days)'), findsOneWidget);
    expect(find.text('65%'), findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsOneWidget);

    // Verify stage detail
    expect(
      find.text('Calculating sleep stages (Deep/REM), HRV & resting heart rate…'),
      findsOneWidget,
    );

    // Verify clear reassurance copy for privacy and completed sync
    expect(
      find.textContaining('Band sync complete. Processed on your iPhone CPU — health data never leaves this device.'),
      findsOneWidget,
    );
  });
}
