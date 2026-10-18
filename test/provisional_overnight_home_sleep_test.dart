import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openstrap_edge/compute/derivation_engine.dart';
import 'package:openstrap_edge/data/day_label.dart';
import 'package:openstrap_edge/data/db.dart';
import 'package:openstrap_edge/data/local_repository_impl.dart';
import 'package:openstrap_edge/l10n/app_localizations.dart';
import 'package:openstrap_edge/models/metric.dart';
import 'package:openstrap_edge/models/payloads.dart' show todayHeadlineOf;
import 'package:openstrap_edge/ui2/screens/home_screen.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  late Database db;
  late String dir;
  final nowSec = DateTime.now().millisecondsSinceEpoch ~/ 1000;

  setUp(() async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    LocalDb.dbName = 'openstrap_provisional_home_sleep_test.db';
    dir = await databaseFactory.getDatabasesPath();
    await LocalDb.close();
    await databaseFactory.deleteDatabase(p.join(dir, LocalDb.dbName));
    db = await LocalDb.instance;
  });

  tearDown(() async {
    await LocalDb.close();
    await databaseFactory.deleteDatabase(p.join(dir, LocalDb.dbName));
  });

  test('today with confirmed wake (provisional) shows today sleep on Home, not yesterday or No sleep',
      () async {
    final y = DateTime.now().subtract(const Duration(days: 1));
    final yesterday = '${y.year.toString().padLeft(4, '0')}-'
        '${y.month.toString().padLeft(2, '0')}-'
        '${y.day.toString().padLeft(2, '0')}';

    // 1. Seed yesterday in DB with 7h sleep
    await db.insert('day_result', {
      'day_id': yesterday,
      'algo_version': kAlgoVersion,
      'payload_json': jsonEncode({
        'scalars': {'rmssd': 65, 'readiness': 80.0, 'rhr': 55.0},
        'sleep': {
          'window': {'value': {'offset_ms': (nowSec - 24 * 3600) * 1000}},
          'accounting': {'value': {'tst_sec': 7 * 3600, 'duration_min': 420}},
        },
      }),
      'window_json': jsonEncode({'offset_ms': (nowSec - 24 * 3600) * 1000}),
      'computed_at': 1,
      'finalized': 1,
    });

    // 2. Seed today in DB with 8h 01m sleep (wake 45 min ago, edge 45 min past wake)
    // 45 min > 30 min (kWakeConfirmMarginSec), but < 60 min (_headlineFreezeMarginSec)
    final wakeSec = nowSec - 45 * 60;
    final edgeSec = nowSec; // 45 min past wake
    await db.insert('day_result', {
      'day_id': todayLabel(),
      'algo_version': kAlgoVersion,
      'payload_json': jsonEncode({
        'scalars': {'rmssd': 75, 'readiness': 84.0, 'rhr': 51.0},
        'data_edge_sec': edgeSec,
        'sleep': {
          'window': {
            'value': {
              'onset_ms': (wakeSec - 8 * 3600 - 60) * 1000,
              'offset_ms': wakeSec * 1000,
            },
          },
          'accounting': {
            'value': {
              'tst_sec': 8 * 3600 + 60,
              'duration_min': 481,
            },
          },
        },
      }),
      'window_json': jsonEncode({'offset_ms': wakeSec * 1000}),
      'computed_at': 2,
      'finalized': 0,
    });

    // Insert decoded_onehz frame so bandEdgeSec matches edgeSec
    await db.insert('decoded_onehz', {
      'ts_ms': edgeSec * 1000,
      'rec_ts': edgeSec,
      'counter': edgeSec,
      'hr': 60,
    });

    // Refresh freshness
    await LocalDb.refreshComputeFreshness();

    // Verify freshness payload
    final freshnessRow = await LocalDb.computeFreshness('today');
    final fresh = jsonDecode(freshnessRow!['payload_json'] as String) as Map<String, dynamic>;
    expect(fresh['overnight_day'], todayLabel(), reason: 'today must be overnight_day');
    expect(fresh['showing_prior_overnight'], isFalse, reason: 'must not show prior overnight');
    expect(fresh['recovery_state'], 'provisional');

    // Verify getToday()
    final repo = LocalRepositoryImpl(getProfileMap: () => const {});
    final today = await repo.getToday();

    expect(today['status']['overnight_day'], todayLabel());
    expect(today['status']['showing_prior_overnight'], isFalse);
    expect(today['status']['recovery_state'], 'provisional');

    // Sleep block must have today's 481 minutes (8h 01m)
    final sleep = today['sleep'] as Map<String, dynamic>;
    final dur = sleep['duration_min'];
    final durMin = dur is Map ? dur['value'] : dur;
    expect(durMin, 481);

    // Headline must report today's sleep and provisional recovery
    final headline = todayHeadlineOf(today);
    expect(headline['recovery_state'], 'provisional');
    expect(headline['recovery'], 84.0);
    expect(headline['sleep_min'], 481);

    // Load HomeData for UI
    final homeData = await HomeData.load(repo);
    expect(homeData.sleepMin.value, 481.0, reason: 'Home sleep must show 8h 01m (481m)');
    expect(homeData.sleepMin.note, isNull, reason: 'Home sleep must not have stale overnight note');
    expect(homeData.readiness.value, 84.0, reason: 'Provisional recovery must be shown');
    expect(homeData.recoveryState, 'provisional');
  });

  testWidgets('provisional morning sleep shows I\'m awake card on Home screen', (tester) async {
    final homeData = HomeData(
      dayId: todayLabel(),
      recoveryState: 'provisional',
      readiness: const Metric(value: 84.0, confidence: 0.8),
      sleepMin: const Metric(value: 481.0, confidence: 0.9),
      sleepNeedMin: const Metric(value: 480.0, confidence: 0.9),
      strain: const Metric(value: 4.2, confidence: 0.9),
    );

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: HomeScreen(data: homeData),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text("I'm awake"), findsOneWidget);
    expect(find.textContaining('Logged 8h 01m of sleep'), findsOneWidget);
  });

  test('sleep confirmed via sleep_source settles today immediately as final', () async {
    final wakeSec = nowSec - 10 * 60; // only 10 min ago
    final edgeSec = nowSec; // only 10 min past wake (normally < 30m / 60m margin)
    await db.insert('day_result', {
      'day_id': todayLabel(),
      'algo_version': kAlgoVersion,
      'payload_json': jsonEncode({
        'scalars': {'readiness': 82.0, 'rhr': 52.0},
        'sleep_source': 'confirmed',
        'data_edge_sec': edgeSec,
        'sleep': {
          'window': {
            'value': {
              'onset_ms': (wakeSec - 8 * 3600) * 1000,
              'offset_ms': wakeSec * 1000,
            },
          },
          'accounting': {
            'value': {
              'tst_sec': 8 * 3600,
              'duration_min': 480,
            },
          },
        },
      }),
      'window_json': jsonEncode({'offset_ms': wakeSec * 1000}),
      'computed_at': 3,
      'finalized': 0,
    });

    await db.insert('decoded_onehz', {
      'ts_ms': edgeSec * 1000,
      'rec_ts': edgeSec,
      'counter': edgeSec,
      'hr': 60,
    });

    await LocalDb.refreshComputeFreshness();
    final freshnessRow = await LocalDb.computeFreshness('today');
    final fresh = jsonDecode(freshnessRow!['payload_json'] as String) as Map<String, dynamic>;

    expect(fresh['overnight_day'], todayLabel());
    expect(fresh['recovery_state'], 'final', reason: 'confirmed sleep must promote recovery to final');
    expect(fresh['overnight_state'], 'ready', reason: 'confirmed sleep must mark overnight ready');
  });
}
