// "I'm awake" fired confirmSleep without awaiting it and swallowed every
// error, so a tap that waited behind a running derive, or found no wake time
// to confirm, looked exactly like a dead button. The card has to show it is
// working, take one tap at a time, and say when nothing was confirmed.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:openstrap_edge/data/day_label.dart';
import 'package:openstrap_edge/l10n/app_localizations.dart';
import 'package:openstrap_edge/models/metric.dart';
import 'package:openstrap_edge/state/app_state.dart';
import 'package:openstrap_edge/ui2/screens/home_screen.dart';

class _Spy extends AppState {
  _Spy() : super.forTesting();
  int calls = 0;
  Completer<bool> result = Completer<bool>();

  @override
  Future<bool> confirmSleep(String date) {
    calls++;
    return result.future;
  }
}

Future<void> _pump(WidgetTester t, AppState app) async {
  final homeData = HomeData(
    dayId: todayLabel(),
    recoveryState: 'provisional',
    readiness: const Metric(value: 84.0, confidence: 0.8),
    sleepMin: const Metric(value: 481.0, confidence: 0.9),
    sleepNeedMin: const Metric(value: 480.0, confidence: 0.9),
    strain: const Metric(value: 4.2, confidence: 0.9),
  );
  await t.pumpWidget(
    MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: ChangeNotifierProvider<AppState>.value(
        value: app,
        child: Scaffold(body: HomeScreen(data: homeData)),
      ),
    ),
  );
  await t.pump();
}

void main() {
  testWidgets('tap shows a spinner and ignores repeat taps while confirming', (
    t,
  ) async {
    final app = _Spy();
    await _pump(t, app);

    await t.tap(find.text("I'm awake"));
    await t.pump();
    expect(app.calls, 1);
    expect(
      find.text("I'm awake"),
      findsNothing,
      reason: 'the label gives way to a spinner while confirming',
    );

    await t.tap(find.textContaining('Logged 8h 01m'));
    await t.pump();
    expect(app.calls, 1, reason: 'a second tap must not queue another derive');

    app.result.complete(true);
    await t.pump();
    await t.pump();
    expect(find.byType(SnackBar), findsNothing);
  });

  testWidgets('nothing to confirm is said out loud, and the card re-arms', (
    t,
  ) async {
    final app = _Spy();
    await _pump(t, app);

    await t.tap(find.text("I'm awake"));
    await t.pump();
    app.result.complete(false);
    await t.pump();
    await t.pump();

    expect(find.byType(SnackBar), findsOneWidget);
    expect(find.text("I'm awake"), findsOneWidget);
  });

  testWidgets('a failing confirm shows an error instead of silence', (t) async {
    final app = _Spy();
    await _pump(t, app);

    await t.tap(find.text("I'm awake"));
    await t.pump();
    app.result.completeError(StateError('db locked'));
    await t.pump();
    await t.pump();

    expect(find.byType(SnackBar), findsOneWidget);
    expect(find.text("I'm awake"), findsOneWidget);
  });
}
