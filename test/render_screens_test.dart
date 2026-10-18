import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openstrap_edge/models/metric.dart';
import 'package:openstrap_edge/state/app_state.dart';
import 'package:openstrap_edge/sync/paired_device.dart';
import 'package:openstrap_edge/ui2/screens/home_screen.dart';
import 'package:openstrap_edge/ui2/theme.dart';
import 'package:provider/provider.dart';

Future<void> _loadFonts() async {
  final files = Directory('assets/fonts/Manrope')
      .listSync()
      .whereType<File>()
      .where((f) => f.path.endsWith('.ttf'));
  for (final family in const ['Manrope', '.SF Pro Text', 'Menlo', 'Roboto']) {
    final loader = FontLoader(family);
    for (final f in files) {
      loader.addFont(f.readAsBytes().then((b) => ByteData.sublistView(Uint8List.fromList(b))));
    }
    await loader.load();
  }

  final lucideFile = File('/Users/zstarovoit/.pub-cache/hosted/pub.dev/lucide_icons_flutter-3.1.17/assets/lucide.ttf');
  if (lucideFile.existsSync()) {
    for (final family in const ['packages/lucide_icons_flutter/Lucide', 'Lucide']) {
      final loader = FontLoader(family);
      loader.addFont(lucideFile.readAsBytes().then((b) => ByteData.sublistView(Uint8List.fromList(b))));
      await loader.load();
    }
  }
}

Future<void> _capture(WidgetTester tester, GlobalKey key, String path) async {
  await tester.runAsync(() async {
    final boundary = key.currentContext!.findRenderObject() as RenderRepaintBoundary;
    final image = await boundary.toImage(pixelRatio: 2.0);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    final bytes = byteData!.buffer.asUint8List();
    final file = File(path);
    file.parent.createSync(recursive: true);
    file.writeAsBytesSync(bytes);
  });
}

const outDir = '/Users/zstarovoit/.gemini/antigravity-cli/brain/6a056783-a0f7-4251-baa5-807a9dc42c47';

const mockTodayData = HomeData(
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
  drivers: [
    {'label': 'HRV', 'direction': 'up', 'weight': 0.6},
    {'label': 'RHR', 'direction': 'down', 'weight': 0.3},
    {'label': 'Sleep', 'direction': 'up', 'weight': 0.1},
  ],
);

const mockPastDayData = HomeData(
  name: 'Zakhar',
  dayId: '2026-10-16',
  readiness: Metric(value: 62.0, confidence: 0.95, tier: MetricTier.high),
  strain: Metric(value: 14.8, confidence: 0.9, tier: MetricTier.high),
  strainTarget: {'value': 14.0, 'low': 12.5, 'high': 15.5},
  sleepMin: Metric(value: 410.0, confidence: 0.95, tier: MetricTier.high),
  sleepNeedMin: Metric(value: 480.0, confidence: 0.9, tier: MetricTier.high),
  rhr: Metric(value: 55.0, confidence: 0.95, tier: MetricTier.high),
  steps: Metric(value: 11200.0, confidence: 0.9, tier: MetricTier.high),
  stepGoal: 10000,
  calories: Metric(value: 720.0, confidence: 0.85, tier: MetricTier.high),
  caloriesTotal: Metric(value: 2450.0, confidence: 0.85, tier: MetricTier.high),
  drivers: [
    {'label': 'HRV', 'direction': 'down', 'weight': 0.5},
    {'label': 'Sleep', 'direction': 'down', 'weight': 0.5},
  ],
);

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await _loadFonts();
  });

  testWidgets('1. iPhone 15/16 Pro size (393x852 pt)', (tester) async {
    tester.view.physicalSize = const Size(393 * 3, 852 * 3);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);

    final app = AppState.forTesting();
    addTearDown(app.dispose);
    app.paired = PairedDevice('C0:EE:FB:01:02:03', 'WHOOP4012345');
    app.device.connection = 'connected';
    app.device.strapName = 'WHOOP 4.0';
    app.device.batteryPct = 84.0;
    app.device.charging = false;
    app.device.liveHr = 72;

    final key = GlobalKey();
    await tester.pumpWidget(
      ChangeNotifierProvider<AppState>.value(
        value: app,
        child: MaterialApp(
          theme: buildTheme(Brightness.dark),
          home: Scaffold(
            body: RepaintBoundary(
              key: key,
              child: const HomeScreen(data: mockTodayData, hour: 9),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await _capture(tester, key, '$outDir/screen_1_iphone_pro.png');
  });

  testWidgets('2. iPhone SE / compact size (375x667 pt)', (tester) async {
    tester.view.physicalSize = const Size(375 * 2, 667 * 2);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.reset);

    final app = AppState.forTesting();
    addTearDown(app.dispose);
    app.paired = PairedDevice('C0:EE:FB:01:02:03', 'WHOOP4012345');
    app.device.connection = 'connected';
    app.device.strapName = 'WHOOP 4.0';
    app.device.batteryPct = 84.0;
    app.device.charging = false;
    app.device.liveHr = 72;

    final key = GlobalKey();
    await tester.pumpWidget(
      ChangeNotifierProvider<AppState>.value(
        value: app,
        child: MaterialApp(
          theme: buildTheme(Brightness.dark),
          home: Scaffold(
            body: RepaintBoundary(
              key: key,
              child: const HomeScreen(data: mockTodayData, hour: 9),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await _capture(tester, key, '$outDir/screen_2_iphone_se.png');
  });

  testWidgets('3. Normal connected / live state', (tester) async {
    tester.view.physicalSize = const Size(393 * 3, 852 * 3);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);

    final app = AppState.forTesting();
    addTearDown(app.dispose);
    app.paired = PairedDevice('C0:EE:FB:01:02:03', 'WHOOP4012345');
    app.device.connection = 'connected';
    app.device.strapName = 'WHOOP 4.0';
    app.device.batteryPct = 92.0;
    app.device.charging = true;
    app.device.batteryPackPct = 78.0;
    app.device.liveHr = 68;

    final key = GlobalKey();
    await tester.pumpWidget(
      ChangeNotifierProvider<AppState>.value(
        value: app,
        child: MaterialApp(
          theme: buildTheme(Brightness.dark),
          home: Scaffold(
            body: RepaintBoundary(
              key: key,
              child: const HomeScreen(data: mockTodayData, hour: 9),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await _capture(tester, key, '$outDir/screen_3_connected_live.png');
  });

  testWidgets('4. Disconnected / reconnecting state', (tester) async {
    tester.view.physicalSize = const Size(393 * 3, 852 * 3);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);

    final app = AppState.forTesting();
    addTearDown(app.dispose);
    app.paired = PairedDevice('C0:EE:FB:01:02:03', 'WHOOP4012345');
    app.device.connection = 'connecting';
    app.device.strapName = 'WHOOP 4.0';
    app.device.batteryPct = 45.0;

    final key = GlobalKey();
    await tester.pumpWidget(
      ChangeNotifierProvider<AppState>.value(
        value: app,
        child: MaterialApp(
          theme: buildTheme(Brightness.dark),
          home: Scaffold(
            body: RepaintBoundary(
              key: key,
              child: const HomeScreen(data: mockTodayData, hour: 9),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    await _capture(tester, key, '$outDir/screen_4_disconnected_reconnecting.png');
  });

  testWidgets('5. Past-day / historical state', (tester) async {
    tester.view.physicalSize = const Size(393 * 3, 852 * 3);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);

    final app = AppState.forTesting();
    addTearDown(app.dispose);
    app.paired = PairedDevice('C0:EE:FB:01:02:03', 'WHOOP4012345');
    app.device.connection = 'disconnected';
    app.device.strapName = 'WHOOP 4.0';

    final key = GlobalKey();
    await tester.pumpWidget(
      ChangeNotifierProvider<AppState>.value(
        value: app,
        child: MaterialApp(
          theme: buildTheme(Brightness.dark),
          home: Scaffold(
            body: RepaintBoundary(
              key: key,
              child: const HomeScreen(data: mockPastDayData, hour: 9),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await _capture(tester, key, '$outDir/screen_5_past_day.png');
  });

  testWidgets('7. On-device derivation progress card', (tester) async {
    tester.view.physicalSize = const Size(393 * 3, 852 * 3);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);

    final app = AppState.forTesting();
    addTearDown(app.dispose);
    app.paired = PairedDevice('C0:EE:FB:01:02:03', 'WHOOP4012345');
    app.device.connection = 'connected';
    app.device.strapName = 'WHOOP 4.0';
    app.deriveProgressNotifier.value = const DeriveProgress(
      stage: 'analyzing',
      completedDays: 1,
      totalDays: 2,
      fraction: 0.65,
      stageDescription: 'Calculating sleep stages (Deep/REM), HRV & resting heart rate…',
    );

    final key = GlobalKey();
    await tester.pumpWidget(
      ChangeNotifierProvider<AppState>.value(
        value: app,
        child: MaterialApp(
          theme: buildTheme(Brightness.light),
          home: RepaintBoundary(
            key: key,
            child: const Scaffold(
              body: HomeScreen(data: mockTodayData, hour: 9),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await _capture(tester, key, '$outDir/screen_7_on_device_calculation.png');
  });
}

