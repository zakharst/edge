import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openstrap_edge/data/local_repository.dart';
import 'package:openstrap_edge/models/metric.dart';
import 'package:openstrap_edge/ui2/screens/next_gen_mvp.dart';
import 'package:openstrap_edge/ui2/theme.dart';

class _Repo extends LocalRepository {
  @override
  Future<Map<String, dynamic>> getDayStress(String date) async => const {
    'score': 37.0,
    'level': 'Balanced',
  };

  @override
  Future<Map<String, dynamic>> getProfile() async => const {'age': 32};

  @override
  Future<Map<String, dynamic>> getZones() async => const {
    'ceiling': {'bpm': 191},
  };

  @override
  Future<Map<String, dynamic>> getInsights() async => const {
    'regularity': {
      'value': {'sri': 82.0},
    },
  };

  @override
  Future<Map<String, dynamic>> getJournalInsights({
    String range = '90d',
  }) async => const {
    'insights': [
      {
        'tag': 'late meal',
        'outcome_label': 'HRV',
        'delta_pct': -8.4,
        'n_with': 8,
        'n_without': 12,
      },
    ],
  };

  @override
  Future<Map<String, dynamic>> getDayNaps(String date) async => const {
    'nap_min': 20,
  };

  @override
  Future<Map<String, dynamic>> getChart(
    String metric, {
    int? from,
    int? to,
    Set<String> signals = const {},
  }) async => {
    'points': [
      for (var i = 0; i < 14; i++)
        {
          't': i,
          'v': switch (metric) {
            'resting_hr' => 52 + (i % 2),
            'hrv' => 61 + (i % 3),
            'steps' => 8500 + i * 100,
            _ => 0,
          },
        },
    ],
  };
}

Future<void> _pump(WidgetTester tester, Widget child) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: buildTheme(Brightness.light),
      home: Scaffold(body: SingleChildScrollView(child: child)),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('MOD Next Gen renders measured inputs end to end', (
    tester,
  ) async {
    await _pump(
      tester,
      NextGenMvpCard(
        repo: _Repo(),
        dayId: '2026-10-11',
        strain: const Metric(value: 12, confidence: 1),
        sleepMinutes: const Metric(value: 430, confidence: 1),
        sleepNeedMinutes: const Metric(value: 480, confidence: 1),
      ),
    );

    expect(find.text('37'), findsOneWidget);
    expect(find.textContaining('Balanced'), findsOneWidget);
    expect(find.text('late meal'), findsOneWidget);
    expect(find.textContaining('HRV: -8.4%'), findsOneWidget);
    expect(find.text('BIOLOGICAL AGE · EXPERIMENTAL'), findsOneWidget);
    expect(find.text('SLEEP PLANNER · EXPERIMENTAL'), findsOneWidget);
    expect(
      find.text('—'),
      findsOneWidget,
      reason: 'only the live rep counter abstains',
    );
  });

  testWidgets('Next Gen stays hidden without a real day and repository', (
    tester,
  ) async {
    await _pump(tester, const NextGenMvpCard(repo: null, dayId: null));

    expect(find.byType(Card), findsNothing);
    expect(find.text('—'), findsNothing);
  });
}
