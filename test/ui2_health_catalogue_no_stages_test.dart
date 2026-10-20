// Sleep stages are a 1 Hz movement-and-pulse estimate with low accuracy, so
// they live only on the detailed sleep screen, under a caption that says so.
// The Health catalogue lists measures; it must not offer deep or REM minutes
// as metrics of their own, even on a device that has a long series of them.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openstrap_edge/ui2/screens/screens.dart'
    show ExploreData, HealthData, HealthScreen;
import 'package:openstrap_edge/ui2/ui2.dart' show buildTheme;

void main() {
  testWidgets('the Health catalogue has no deep or REM rows', (tester) async {
    tester.view.physicalSize = const Size(390 * 3, 4000 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(MaterialApp(
      theme: buildTheme(Brightness.light),
      home: const Scaffold(
        body: HealthScreen(
            data: HealthData(daysWithData: 9),
            explore: ExploreData(counts: {
              'tst_min': 9,
              'efficiency': 9,
              'deep_min': 9,
              'rem_min': 9,
            }),
            tab: 1),
      ),
    ));
    await tester.pumpAndSettle();
    // The neighbouring sleep rows are there, so the family did build.
    expect(find.text('Asleep as a share of time in bed'), findsOneWidget);
    expect(find.text('Heart-rate flatness inside NREM'), findsNothing);
    expect(find.text('Staged from beat variability and movement'), findsNothing);
  });
}
