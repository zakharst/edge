// Every pull put the three-step "On-Device Calculation" card over a Home that
// already showed the numbers, so each refresh looked like a wait. A one-day
// pass over numbers already on screen is one quiet line; the card stays for a
// multi-day backlog.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:openstrap_edge/data/day_label.dart';
import 'package:openstrap_edge/l10n/app_localizations.dart';
import 'package:openstrap_edge/models/metric.dart';
import 'package:openstrap_edge/state/app_state.dart';
import 'package:openstrap_edge/ui2/screens/home_screen.dart';

Future<void> _pump(WidgetTester t, DeriveProgress progress) async {
  final app = AppState.forTesting();
  addTearDown(app.dispose);
  app.deriveProgressNotifier.value = progress;
  await t.pumpWidget(MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: ChangeNotifierProvider<AppState>.value(
      value: app,
      child: Scaffold(
        body: HomeScreen(
          data: HomeData(
            dayId: todayLabel(),
            readiness: const Metric(value: 70.0, confidence: 0.8),
            sleepMin: const Metric(value: 450.0, confidence: 0.9),
            strain: const Metric(value: 4.2, confidence: 0.9),
          ),
        ),
      ),
    ),
  ));
  await t.pump();
}

void main() {
  testWidgets('a one-day pass over numbers on screen is one quiet line',
      (t) async {
    await _pump(
      t,
      const DeriveProgress(stage: 'analyzing', totalDays: 1, fraction: 0.5),
    );
    expect(find.text('Updating in the background'), findsOneWidget);
    expect(find.text('On-Device Calculation'), findsNothing);
    expect(find.textContaining('Step 2 of 3'), findsNothing);
  });

  testWidgets('a multi-day backlog keeps the progress card', (t) async {
    await _pump(
      t,
      const DeriveProgress(
          stage: 'analyzing', completedDays: 1, totalDays: 4, fraction: 0.5),
    );
    expect(find.text('On-Device Calculation'), findsOneWidget);
    expect(find.text('Updating in the background'), findsNothing);
  });
}
