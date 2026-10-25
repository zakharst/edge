import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openstrap_edge/models/metric.dart';
import 'package:openstrap_edge/state/app_state.dart';
import 'package:openstrap_edge/ui2/profile/profile.dart' show ProfileAvatar;
import 'package:openstrap_edge/ui2/screens/screens.dart';
import 'package:openstrap_edge/ui2/ui2.dart';
import 'package:provider/provider.dart';

void main() {
  testWidgets('visual inspection of redesigned Home screen with rich data', (tester) async {
    tester.view.physicalSize = const Size(393 * 3, 852 * 3); // iPhone 16 / 15 Pro
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);

    final app = AppState.forTesting();
    addTearDown(app.dispose);

    const data = HomeData(
      name: 'Zakhar',
      dayId: '2026-10-17',
      readiness: Metric(value: 84.0, confidence: 0.95, tier: MetricTier.high),
      strain: Metric(value: 12.4, confidence: 0.9, tier: MetricTier.high),
      strainTarget: {'value': 13.0, 'low': 11.5, 'high': 14.5},
      sleepMin: Metric(value: 462.0, confidence: 0.95, tier: MetricTier.high), // 7h 42m
      sleepNeedMin: Metric(value: 420.0, confidence: 1.0, tier: MetricTier.estimate), // 7h
      // Last night's 7h 42m over the 7 h adult minimum: 462 / 420 = 110 %.
      sleepPerfPct: Metric(value: 110.0, confidence: 0.7, tier: MetricTier.estimate),
      rhr: Metric(value: 52.0, confidence: 0.95, tier: MetricTier.high),
      steps: Metric(value: 8420.0, confidence: 0.9, tier: MetricTier.high, inputsUsed: ['band_step_counter']),
      stepGoal: 10000,
      calories: Metric(value: 540.0, confidence: 0.85, tier: MetricTier.high),
      caloriesTotal: Metric(value: 2180.0, confidence: 0.85, tier: MetricTier.high),
      drivers: [
        {'label': 'HRV', 'direction': 'up', 'weight': 0.6},
        {'label': 'RHR', 'direction': 'down', 'weight': 0.3},
        {'label': 'Sleep', 'direction': 'up', 'weight': 0.1},
      ],
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

    // Verify Executive Header
    expect(find.textContaining('ZAKHAR'), findsNothing); // Name is in greeting title
    expect(find.textContaining('Zakhar'), findsOneWidget); // "Good morning, Zakhar"
    expect(find.byType(ProfileAvatar), findsOneWidget);

    // Verify Ambient Hardware Status Bar
    expect(find.byType(Semantics), findsWidgets);
    expect(find.text('No band paired · Pair your WHOOP band to start tracking'), findsOneWidget);

    // Verify Level 1 Daily Hero & Verdict
    expect(find.text('OPTIMAL RECOVERY'), findsOneWidget);
    expect(find.text('Autonomic balance restored · Primed for high strain'), findsOneWidget);
    expect(find.text('84'), findsOneWidget);
    expect(find.text('RECOVERY'), findsOneWidget);
    expect(find.text('STRAIN'), findsOneWidget);
    expect(find.text('SLEEP'), findsOneWidget);
    expect(find.text('110%'), findsOneWidget);
    expect(find.textContaining('7h 42m · of 7h'), findsOneWidget);

    // Verify Level 2 Vitals (At a glance)
    expect(find.text('At a glance'), findsOneWidget);
    expect(find.text('52'), findsOneWidget); // RHR
    expect(find.text('8,420'), findsOneWidget); // Steps
    expect(find.text('540'), findsOneWidget); // Active Energy

    // Scroll to see Level 3 & Level 4
    await tester.scrollUntilVisible(find.text("Today's plan"), 300);

    // Verify Level 3 Guidance (Today's plan)
    expect(find.text("Today's plan"), findsOneWidget);
    expect(find.textContaining('steps left'), findsOneWidget);
    expect(find.textContaining('Aim for 13.0 strain'), findsOneWidget);

    // Scroll to see Level 4 Progressive Disclosure
    await tester.scrollUntilVisible(find.text('Breakdown of your day'), 300);
    expect(find.text('Breakdown of your day'), findsOneWidget);
    expect(find.text('Hour by hour'), findsOneWidget);

    await tester.scrollUntilVisible(find.text('Longevity & Biomarkers'), 300);
    expect(find.text('Longevity & Biomarkers'), findsOneWidget);
  });

  testWidgets('Home screen renders without overflow on 375px mobile viewport (iPhone SE)', (tester) async {
    tester.view.physicalSize = const Size(375 * 2, 667 * 2);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.reset);

    const data = HomeData(
      name: 'Zakhar',
      dayId: '2026-10-17',
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

    await tester.pumpWidget(
      MaterialApp(
        theme: buildTheme(Brightness.dark),
        home: const Scaffold(
          body: HomeScreen(data: data, hour: 9),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Zero overflow errors
    expect(tester.takeException(), isNull);
    expect(find.text('OPTIMAL RECOVERY'), findsOneWidget);
  });

  testWidgets('Home screen handles dynamic font scaling (1.5x) gracefully', (tester) async {
    tester.view.physicalSize = const Size(393 * 3, 852 * 3);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);

    const data = HomeData(
      name: 'Zakhar',
      dayId: '2026-10-17',
      readiness: Metric(value: 84.0, confidence: 0.95, tier: MetricTier.high),
      strain: Metric(value: 12.4, confidence: 0.9, tier: MetricTier.high),
      sleepMin: Metric(value: 462.0, confidence: 0.95, tier: MetricTier.high),
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: buildTheme(Brightness.dark),
        home: const MediaQuery(
          data: MediaQueryData(textScaler: TextScaler.linear(1.5)),
          child: Scaffold(
            body: HomeScreen(data: data, hour: 9),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('OPTIMAL RECOVERY'), findsOneWidget);
  });
}
