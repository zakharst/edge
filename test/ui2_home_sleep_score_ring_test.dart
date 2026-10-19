// The Home sleep ring read min(sleep / need, 100%), so any night that met the
// need showed 100% every morning. With a score in the rollup it shows that.

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

HomeData _day({Map<String, dynamic>? score}) => HomeData(
      dayId: todayLabel(),
      readiness: const Metric(value: 70.0, confidence: 0.8),
      sleepMin: const Metric(value: 481.0, confidence: 0.9),
      sleepNeedMin: const Metric(value: 450.0, confidence: 0.9),
      strain: const Metric(value: 4.2, confidence: 0.9),
      sleepScore: score,
    );

void main() {
  testWidgets('a scored night shows its score, not hours over need', (t) async {
    await _pump(t, _day(score: {'value': 72, 'need_min': 470}));
    expect(find.text('72'), findsOneWidget);
    expect(find.textContaining('100%'), findsNothing);
    expect(find.textContaining('of 7h 50m'), findsOneWidget,
        reason: "measured against last night's need, not tonight's");
  });

  testWidgets('without a score the ring keeps the hours-over-need read',
      (t) async {
    await _pump(t, _day());
    expect(find.textContaining('100%'), findsWidgets);
  });
}
