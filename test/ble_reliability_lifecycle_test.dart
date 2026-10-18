import 'package:flutter_test/flutter_test.dart';
import 'package:openstrap_edge/ble/ble_engine.dart';
import 'package:openstrap_edge/ble/ble_state.dart';
import 'package:openstrap_edge/sync/sync_policy.dart';

void main() {
  group('BLE Reliability & Lifecycle: Bluetooth State & Permissions', () {
    test('classifyBleBlocker maps adapter states correctly', () {
      expect(
        classifyBleBlocker(adapterState: 'unauthorized'),
        BleBlocker.permissionDenied,
      );
      expect(
        classifyBleBlocker(adapterState: 'unavailable'),
        BleBlocker.unsupported,
      );
      expect(
        classifyBleBlocker(adapterState: 'off'),
        BleBlocker.adapterOff,
      );
      expect(
        classifyBleBlocker(adapterState: 'turningOff'),
        BleBlocker.adapterOff,
      );
      expect(
        classifyBleBlocker(adapterState: 'on'),
        isNull,
      );
    });

    test('classifyBleBlocker maps thrown transport errors correctly', () {
      expect(
        classifyBleBlocker(error: 'PlatformException(permission denied)'),
        BleBlocker.permissionDenied,
      );
      expect(
        classifyBleBlocker(error: 'User has not authorized Bluetooth'),
        BleBlocker.permissionDenied,
      );
      expect(
        classifyBleBlocker(error: 'bluetooth must be turned on'),
        BleBlocker.adapterOff,
      );
      expect(
        classifyBleBlocker(error: 'Bluetooth adapter is off'),
        BleBlocker.adapterOff,
      );
      expect(
        classifyBleBlocker(error: 'BLE unsupported on hardware'),
        BleBlocker.unsupported,
      );
      expect(
        classifyBleBlocker(error: 'Device disconnected unexpectedly'),
        isNull,
      );
      expect(
        classifyBleBlocker(adapterState: null, error: null),
        isNull,
      );
    });

    test('isTimeoutDisconnect distinguishes link timeouts from clean disconnects', () {
      // Android GATT timeout indicators
      expect(isTimeoutDisconnect('GATT_CONNECTION_TIMEOUT'), isTrue);
      expect(isTimeoutDisconnect('status=8 (LINK_SUPERVISION_TIMEOUT)'), isTrue);
      expect(isTimeoutDisconnect('Operation timed out after 30000ms'), isTrue);

      // iOS CBError timeout indicators
      expect(
        isTimeoutDisconnect('The connection has timed out unexpectedly.'),
        isTrue,
      );

      // Clean or peer-closed disconnects
      expect(isTimeoutDisconnect('Connection terminated by peer user'), isFalse);
      expect(isTimeoutDisconnect('Local app disconnected'), isFalse);
      expect(isTimeoutDisconnect(null), isFalse);
    });

    test('bandStatusFor enforces linear blocker priority hierarchy', () {
      // 1. System permissions outrank every band flag
      final permDenied = bandStatusFor(
        connection: 'disconnected',
        blocker: BleBlocker.permissionDenied,
        needsRepairGuide: true,
      );
      expect(permDenied.condition, BandCondition.bluetoothDenied);
      expect(permDenied.isFault, isTrue);

      // 2. Radio off outranks band flags
      final radioOff = bandStatusFor(
        connection: 'disconnected',
        blocker: BleBlocker.adapterOff,
        syncChunkQuarantined: true,
      );
      expect(radioOff.condition, BandCondition.bluetoothOff);
      expect(radioOff.isFault, isTrue);

      // 3. Hardware unsupported outranks band flags
      final unsupported = bandStatusFor(
        connection: 'disconnected',
        blocker: BleBlocker.unsupported,
      );
      expect(unsupported.condition, BandCondition.bluetoothUnsupported);
      expect(unsupported.isFault, isTrue);

      // 4. Auto-reconnect paused outranks plain disconnect
      final paused = bandStatusFor(
        connection: 'connecting',
        autoReconnectPaused: true,
        bondRefusals: 3,
      );
      expect(paused.condition, BandCondition.reconnectPaused);
      expect(paused.bondRefusals, 3);
      expect(paused.isFault, isTrue);

      // 5. Repair needed outranks ordinary sync
      final repair = bandStatusFor(
        connection: 'connected',
        needsRepairGuide: true,
      );
      expect(repair.condition, BandCondition.repairNeeded);
      expect(repair.fix, contains('Forget the band'));

      // 6. Sync chunk quarantined
      final syncStuck = bandStatusFor(
        connection: 'connected',
        syncChunkQuarantined: true,
      );
      expect(syncStuck.condition, BandCondition.syncStuck);

      // 7. Normal states
      final normalConn = bandStatusFor(connection: 'connected');
      expect(normalConn.condition, BandCondition.connected);
      expect(normalConn.isFault, isFalse);

      final normalDisc = bandStatusFor(connection: 'disconnected');
      expect(normalDisc.condition, BandCondition.disconnected);
      expect(normalDisc.isFault, isFalse);
    });
  });

  group('BLE Reliability & Lifecycle: Packet Pipeline (Malformed, Duplicate, Missing, Delayed)', () {
    test('exact packet count matches without loss', () {
      expect(
        burstPacketCountMatches(
          expectedPacketCount: 100,
          receivedTrafficCount: 100,
          droppedThisBurst: 0,
        ),
        isTrue,
      );
      expect(
        burstPacketShortfall(
          expectedPacketCount: 100,
          receivedTrafficCount: 100,
          droppedThisBurst: 0,
        ),
        0,
      );
    });

    test('missing packets report positive shortfall and fail match', () {
      // Band promised 100 packets, phone only received 85
      expect(
        burstPacketCountMatches(
          expectedPacketCount: 100,
          receivedTrafficCount: 85,
          droppedThisBurst: 0,
        ),
        isFalse,
      );
      expect(
        burstPacketShortfall(
          expectedPacketCount: 100,
          receivedTrafficCount: 85,
          droppedThisBurst: 0,
        ),
        15,
      );
    });

    test('duplicate packets and surplus traffic pass validation', () {
      // Re-transmissions and duplicate packets cause received > expected
      expect(
        burstPacketCountMatches(
          expectedPacketCount: 50,
          receivedTrafficCount: 55,
          droppedThisBurst: 0,
        ),
        isTrue,
      );
      // Shortfall is negative for surplus
      expect(
        burstPacketShortfall(
          expectedPacketCount: 50,
          receivedTrafficCount: 55,
          droppedThisBurst: 0,
        ),
        lessThanOrEqualTo(0),
      );
    });

    test('malformed/corrupted packets carve-out accounts for dropped records', () {
      // 50 expected: 30 valid received, 20 malformed/stale records dropped by RecordGate
      expect(
        burstPacketCountMatches(
          expectedPacketCount: 50,
          receivedTrafficCount: 30,
          droppedThisBurst: 20,
        ),
        isTrue,
      );
      expect(
        burstPacketShortfall(
          expectedPacketCount: 50,
          receivedTrafficCount: 30,
          droppedThisBurst: 20,
        ),
        0,
      );

      // If dropped count does NOT fully explain the gap, match must fail
      expect(
        burstPacketCountMatches(
          expectedPacketCount: 50,
          receivedTrafficCount: 30,
          droppedThisBurst: 10, // 10 unexplained missing packets
        ),
        isFalse,
      );
      expect(
        burstPacketShortfall(
          expectedPacketCount: 50,
          receivedTrafficCount: 30,
          droppedThisBurst: 10,
        ),
        10,
      );
    });

    test('adaptive slack widens only on persistent retry attempts', () {
      // First 3 attempts enforce 0 slack
      expect(
        burstPacketCountMatches(
          expectedPacketCount: 40,
          receivedTrafficCount: 39,
          droppedThisBurst: 0,
          consecutiveFailedValidations: 0,
        ),
        isFalse,
      );
      expect(
        burstPacketCountMatches(
          expectedPacketCount: 40,
          receivedTrafficCount: 39,
          droppedThisBurst: 0,
          consecutiveFailedValidations: 2,
        ),
        isFalse,
      );

      // Attempt 4+ (consecutiveFailedValidations >= 3) grants 2-packet slack for edge conditions
      expect(
        burstPacketCountMatches(
          expectedPacketCount: 40,
          receivedTrafficCount: 38,
          droppedThisBurst: 0,
          consecutiveFailedValidations: 3,
        ),
        isTrue,
      );
      expect(
        burstPacketCountMatches(
          expectedPacketCount: 40,
          receivedTrafficCount: 37,
          droppedThisBurst: 0,
          consecutiveFailedValidations: 3,
        ),
        isFalse, // 3 missing exceeds 2 slack
      );
    });
  });

  group('BLE Reliability & Lifecycle: Reconnect Supervisor Lifecycle', () {
    test('supervisor initiates start when link is down and loop is inactive', () {
      final action = superviseReconnect(
        paired: true,
        keepAlive: true,
        connected: false,
        loopRunning: false,
        autoReconnectPaused: false,
        attemptRunningFor: null,
      );
      expect(action, ReconnectSupervisorAction.start);
    });

    test('supervisor does not interfere when connected or un-configured', () {
      expect(
        superviseReconnect(
          paired: true,
          keepAlive: true,
          connected: true,
          loopRunning: false,
          autoReconnectPaused: false,
          attemptRunningFor: null,
        ),
        ReconnectSupervisorAction.none,
      );
      expect(
        superviseReconnect(
          paired: false,
          keepAlive: true,
          connected: false,
          loopRunning: false,
          autoReconnectPaused: false,
          attemptRunningFor: null,
        ),
        ReconnectSupervisorAction.none,
      );
      expect(
        superviseReconnect(
          paired: true,
          keepAlive: false,
          connected: false,
          loopRunning: false,
          autoReconnectPaused: false,
          attemptRunningFor: null,
        ),
        ReconnectSupervisorAction.none,
      );
    });

    test('supervisor resets wedged attempt exceeding autoConnect window', () {
      // An attempt running for 25 minutes has wedged past Android autoConnect limit (15-20 min)
      final action = superviseReconnect(
        paired: true,
        keepAlive: true,
        connected: false,
        loopRunning: true,
        autoReconnectPaused: false,
        attemptRunningFor: const Duration(minutes: 25),
      );
      expect(action, ReconnectSupervisorAction.restartStale);
    });

    test('supervisor respects in-flight user connection', () {
      final action = superviseReconnect(
        paired: true,
        keepAlive: true,
        connected: false,
        loopRunning: false,
        autoReconnectPaused: false,
        attemptRunningFor: null,
        connectInFlight: true,
      );
      expect(action, ReconnectSupervisorAction.none);
    });
  });
}
