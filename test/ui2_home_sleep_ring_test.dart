// The Home sleep ring is sleep performance: last night's total sleep over last
// night's own reference, in percent. It used to show a 0-100 composite with
// invented weights (0.35/0.20/0.20/0.15/0.10) and a deep + REM term from a
// stager that agrees with PSG at kappa 0.128. Both are gone.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:openstrap_edge/data/day_label.dart';
import 'package:openstrap_edge/l10n/app_localizations.dart';
import 'package:openstrap_edge/models/metric.dart';
import 'package:openstrap_edge/ui2/screens/home_screen.dart';

Future<void> _pump(WidgetTester t, HomeData d) async {
  await t.pumpWidget(MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(body: HomeScreen(data: d)),
  ));
  await t.pumpAndSettle();
}

HomeData _day({Metric perf = Metric.empty, Metric ref = Metric.empty}) =>
    HomeData(
      dayId: todayLabel(),
      readiness: const Metric(value: 70.0, confidence: 0.8),
      sleepMin: const Metric(value: 420.0, confidence: 0.9),
      sleepNeedMin: const Metric(value: 480.0, confidence: 0.6),
      strain: const Metric(value: 4.2, confidence: 0.9),
      sleepPerfPct: perf,
      sleepRefLastNightMin: ref,
    );

void main() {
  testWidgets('the ring is last night over its own reference, in percent',
      (t) async {
    await _pump(
        t,
        _day(
          perf: const Metric(value: 93.0, confidence: 0.7),
          ref: const Metric(value: 450.0, confidence: 0.6),
        ));
    expect(find.text('93%'), findsOneWidget);
    expect(find.textContaining('of 7h 30m'), findsOneWidget,
        reason: "measured against last night's reference, not tonight's");
  });

  testWidgets('no composite score anywhere on the ring', (t) async {
    await _pump(
        t,
        _day(
          perf: const Metric(value: 100.0, confidence: 0.7),
          ref: const Metric(value: 420.0, confidence: 0.6),
        ));
    expect(find.text('100%'), findsOneWidget);
    expect(find.text('72'), findsNothing);
  });

  testWidgets('without a performance the ring shows the hours it has',
      (t) async {
    await _pump(t, _day());
    expect(find.text('7h 00m'), findsWidgets);
  });
}
