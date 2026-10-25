// The Home sleep ring is sleep performance: last night's total sleep over the
// AASM/SRS 7 h adult minimum (Watson et al. 2015), in percent. It used to show
// a 0-100 composite with invented weights (0.35/0.20/0.20/0.15/0.10) and a
// deep + REM term from a stager that agrees with PSG at kappa 0.128, and later
// a personal p75-of-free-nights reference with a nap credit. All are gone.

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

HomeData _day({Metric perf = Metric.empty, double sleepMin = 420.0}) =>
    HomeData(
      dayId: todayLabel(),
      readiness: const Metric(value: 70.0, confidence: 0.8),
      sleepMin: Metric(value: sleepMin, confidence: 0.9),
      sleepNeedMin: const Metric(value: 420.0, confidence: 1.0),
      strain: const Metric(value: 4.2, confidence: 0.9),
      sleepPerfPct: perf,
    );

void main() {
  testWidgets('the ring is last night over the 7 h adult minimum, in percent',
      (t) async {
    // 6 h 30 m over 7 h = 92.857 %.
    await _pump(
        t,
        _day(
          sleepMin: 390.0,
          perf: const Metric(value: 650 / 7, confidence: 0.7),
        ));
    expect(find.text('93%'), findsOneWidget);
    expect(find.textContaining('6h 30m · of 7h'), findsOneWidget);
  });

  testWidgets('a night past 7 h reads over 100 %, not capped', (t) async {
    // 8 h over 7 h = 114.29 %.
    await _pump(
        t,
        _day(
          sleepMin: 480.0,
          perf: const Metric(value: 800 / 7, confidence: 0.7),
        ));
    expect(find.text('114%'), findsOneWidget);
    expect(t.takeException(), isNull);
  });

  testWidgets('the plan row names 7 h as the adult minimum, not a need',
      (t) async {
    // Tall enough that the plan section is laid out, not left offstage.
    t.view.physicalSize = const Size(800, 4000);
    t.view.devicePixelRatio = 1.0;
    addTearDown(t.view.reset);
    await _pump(t, _day());
    expect(find.text('Adult minimum'), findsOneWidget);
    expect(find.text('Need'), findsNothing);
  });

  testWidgets('no composite score anywhere on the ring', (t) async {
    await _pump(
        t,
        _day(
          perf: const Metric(value: 100.0, confidence: 0.7),
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
