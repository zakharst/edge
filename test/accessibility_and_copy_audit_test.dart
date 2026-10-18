import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openstrap_edge/ble/ble_friendly_error.dart';
import 'package:openstrap_edge/ble/ble_state.dart';
import 'package:openstrap_edge/ui2/grammar.dart';
import 'package:openstrap_edge/ui2/theme.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

void main() {
  group('BLE Copy & Human-Readable Error Sanitization', () {
    test('replaces GATT error 133 with human-readable connection interrupted copy', () {
      final err = PlatformException(
        code: '133',
        message: 'GATT_ERROR',
        details: 'android.bluetooth.BluetoothGatt.connectGatt',
      );
      final humanized = friendlyBleError(err);
      expect(humanized.toLowerCase(), contains('connection to whoop was interrupted'));
      expect(humanized, isNot(contains('133')));
      expect(humanized, isNot(contains('GATT_ERROR')));
    });

    test('replaces link supervision timeout with actionable charged & nearby copy', () {
      final err = Exception('GATT_CONNECTION_TIMEOUT: link supervision timed out');
      final humanized = friendlyBleError(err);
      expect(humanized.toLowerCase(), contains('timed out'));
      expect(humanized.toLowerCase(), contains('awake'));
      expect(humanized, isNot(contains('GATT_CONNECTION_TIMEOUT')));
    });

    test('replaces peer disconnected (code 19 / 0x13) with human copy', () {
      final err = 'PlatformException(19, connection terminated by peer, null)';
      final humanized = friendlyBleError(err);
      expect(humanized.toLowerCase(), contains('disconnected unexpectedly'));
      expect(humanized, isNot(contains('19')));
    });

    test('replaces permission denial with actionable Settings instruction', () {
      final err = PlatformException(code: 'denied', message: 'Bluetooth permission denied');
      final humanized = friendlyBleError(err);
      expect(humanized.toLowerCase(), contains('permission'));
      expect(humanized.toLowerCase(), contains('settings'));
    });

    test('replaces adapter off with turn on Bluetooth instruction', () {
      final err = Exception('adapter is off');
      final humanized = friendlyBleError(err);
      expect(humanized.toLowerCase(), contains('turn on bluetooth'));
    });

    test('replaces bond / encryption refusal with clear re-pair instruction', () {
      final err = 'BluetoothException(bonding rejected / auth failed)';
      final humanized = friendlyBleError(err);
      expect(humanized.toLowerCase(), contains('forget the device'));
    });

    test('strips raw PlatformException and Exception prefixes from generic errors', () {
      final err1 = PlatformException(code: 'custom', message: 'Sensor clock lost');
      expect(friendlyBleError(err1), 'Sensor clock lost');

      final err2 = Exception('Device memory full');
      expect(friendlyBleError(err2), 'Device memory full');
    });

    test('BandStatus permission denied copy references Edge MOD, not legacy OpenStrap', () {
      final status = bandStatusFor(
        connection: 'disconnected',
        blocker: BleBlocker.permissionDenied,
      );
      expect(status.reason, contains('Edge MOD'));
      expect(status.reason, isNot(contains('OpenStrap')));
      expect(status.fix, contains('Edge MOD'));
      expect(status.fix, isNot(contains('OpenStrap')));
    });
  });

  group('Accessibility & Dynamic Type Verification', () {
    testWidgets('SignalCard includes secondary sub context in semanticLabel', (t) async {
      await t.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SignalCard(
              LucideIcons.footprints,
              C.green,
              'Steps',
              '8,412',
              unit: '',
              sub: '84% of goal · WHOOP 4.0',
            ),
          ),
        ),
      );

      final semantics = t.getSemantics(find.byType(SignalCard));
      expect(semantics.label, contains('Steps, 8,412'));
      expect(semantics.label, contains('84% of goal · WHOOP 4.0'));
    });

    testWidgets('Pressable enforces minimum 44x44 touch target', (t) async {
      await t.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: Pressable(
                onTap: () {},
                semanticLabel: 'Tap me',
                child: const SizedBox(width: 10, height: 10),
              ),
            ),
          ),
        ),
      );

      final renderBox = t.renderObject<RenderBox>(find.byType(Pressable));
      expect(renderBox.size.width, greaterThanOrEqualTo(44.0));
      expect(renderBox.size.height, greaterThanOrEqualTo(44.0));
    });

    testWidgets('ChartFrame produces accessible spoken summary of data shape', (t) async {
      await t.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChartFrame(
              title: 'Heart rate',
              unit: 'bpm',
              series: const [58.0, 60.0, 62.0, 65.0],
              child: const SizedBox(height: 120),
            ),
          ),
        ),
      );

      final semantics = t.getSemantics(find.byType(ChartFrame));
      expect(semantics.label, contains('Latest 65'));
      expect(semantics.label, contains('ranging 58 to 65'));
      expect(semantics.label, contains('up'));
    });

    testWidgets('Large font scaling (2.0x Dynamic Type) renders without overflow', (t) async {
      await t.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(
            textScaler: TextScaler.linear(2.0),
            size: Size(375, 812),
          ),
          child: MaterialApp(
            home: Scaffold(
              body: ListView(
                children: [
                  SignalCard(
                    LucideIcons.activity,
                    C.blue,
                    'Resting HR',
                    '54',
                    unit: 'bpm',
                    sub: 'Typical range 50–58',
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      expect(t.takeException(), isNull);
    });
  });
}
