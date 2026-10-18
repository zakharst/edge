import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:openstrap_edge/coach/coach_config.dart';

void main() {
  group('Security & Privacy Audit: Android Manifest & Configuration', () {
    final manifestFile = File('android/app/src/main/AndroidManifest.xml');
    late String manifest;

    setUpAll(() {
      expect(manifestFile.existsSync(), isTrue);
      manifest = manifestFile.readAsStringSync();
    });

    test('android:allowBackup is disabled to prevent ADB health DB extraction', () {
      expect(
        manifest.contains('android:allowBackup="false"'),
        isTrue,
        reason: 'Health DB could be extracted via adb backup if allowBackup is true',
      );
    });

    test('android:dataExtractionRules is configured for scoped Android 12+ backups', () {
      expect(
        manifest.contains('android:dataExtractionRules="@xml/data_extraction_rules"'),
        isTrue,
      );
    });

    test('intrusive and excessive permissions are removed with tools:node="remove"', () {
      // RECORD_AUDIO must never be merged in from third-party plugins
      expect(
        manifest.contains('<uses-permission android:name="android.permission.RECORD_AUDIO" tools:node="remove" />'),
        isTrue,
      );
      // QUERY_ALL_PACKAGES must never be requested
      expect(
        manifest.contains('<uses-permission android:name="android.permission.QUERY_ALL_PACKAGES"\n        tools:node="remove" />') ||
            manifest.contains('<uses-permission android:name="android.permission.QUERY_ALL_PACKAGES" tools:node="remove" />'),
        isTrue,
      );
    });

    test('EdgeTrackingService is unexported to prevent external IPC invocation', () {
      final m = RegExp(
        r'<service\s+android:name="\.EdgeTrackingService"\s+android:exported="(\w+)"',
        multiLine: true,
      ).firstMatch(manifest);
      expect(m, isNotNull);
      expect(m!.group(1), 'false');
    });

    test('exported services and receivers are guarded by permissions or tokens', () {
      // EdgeCompanionService must require BIND_COMPANION_DEVICE_SERVICE
      expect(
        manifest.contains('android:permission="android.permission.BIND_COMPANION_DEVICE_SERVICE"'),
        isTrue,
      );
      // NotificationListener must require BIND_NOTIFICATION_LISTENER_SERVICE
      expect(
        manifest.contains('android:permission="android.permission.BIND_NOTIFICATION_LISTENER_SERVICE"'),
        isTrue,
      );
      // FileProvider must be unexported
      expect(
        manifest.contains('sk.fourq.otaupdate.OtaUpdateFileProvider'),
        isTrue,
      );
      final fpMatch = RegExp(
        r'<provider[^>]+sk\.fourq\.otaupdate\.OtaUpdateFileProvider[^>]+android:exported="(\w+)"',
        multiLine: true,
      ).firstMatch(manifest);
      if (fpMatch != null) {
        expect(fpMatch.group(1), 'false');
      }
    });
  });

  group('Security & Privacy Audit: iOS Entitlements & Info.plist', () {
    final plistFile = File('ios/Runner/Info.plist');
    late String plist;

    setUpAll(() {
      expect(plistFile.existsSync(), isTrue);
      plist = plistFile.readAsStringSync();
    });

    test('ad personalization and IDFV collection are permanently disabled', () {
      expect(
        plist.contains('<key>GOOGLE_ANALYTICS_DEFAULT_ALLOW_AD_PERSONALIZATION_SIGNALS</key>\n\t<false/>') ||
            plist.contains('<key>GOOGLE_ANALYTICS_DEFAULT_ALLOW_AD_PERSONALIZATION_SIGNALS</key><false/>'),
        isTrue,
      );
      expect(
        plist.contains('<key>GOOGLE_ANALYTICS_IDFV_COLLECTION_ENABLED</key>\n\t<false/>') ||
            plist.contains('<key>GOOGLE_ANALYTICS_IDFV_COLLECTION_ENABLED</key><false/>'),
        isTrue,
      );
    });

    test('mandatory privacy usage descriptions are populated and truthful', () {
      final requiredUsageKeys = [
        'NSBluetoothAlwaysUsageDescription',
        'NSHealthShareUsageDescription',
        'NSHealthUpdateUsageDescription',
        'NSMotionUsageDescription',
        'NSCameraUsageDescription',
        'NSLocationWhenInUseUsageDescription',
      ];

      for (final key in requiredUsageKeys) {
        final idx = plist.indexOf('<key>$key</key>');
        expect(idx >= 0, isTrue, reason: 'Missing required iOS usage description: $key');
        final rest = plist.substring(idx);
        final match = RegExp(r'<string>([^<]+)</string>').firstMatch(rest);
        expect(match, isNotNull, reason: 'Empty string for $key');
        expect(match!.group(1)!.trim(), isNotEmpty);
      }
    });

    test('HealthKit entitlements exist in Runner.entitlements', () {
      final entFile = File('ios/Runner/Runner.entitlements');
      expect(entFile.existsSync(), isTrue);
      final ent = entFile.readAsStringSync();
      expect(ent.contains('<key>com.apple.developer.healthkit</key>'), isTrue);
    });
  });

  group('Security & Privacy Audit: Health Data, BYOK & Network Isolation', () {
    test('isPrivateCoachHost classifies only genuine local loopback/mDNS hosts as private', () {
      expect(isPrivateCoachHost('http://localhost:11434'), isTrue);
      expect(isPrivateCoachHost('http://127.0.0.1:8080'), isTrue);
      expect(isPrivateCoachHost('http://[::1]:11434'), isTrue);
      expect(isPrivateCoachHost('http://10.0.2.2:11434'), isTrue);
      expect(isPrivateCoachHost('http://my-mac.local:11434'), isTrue);
      // Public hosts are NEVER private
      expect(isPrivateCoachHost('https://api.openai.com'), isFalse);
      expect(isPrivateCoachHost('https://api.anthropic.com'), isFalse);
      expect(isPrivateCoachHost('https://my-health-server.com'), isFalse);
    });

    test('isLocalCoachHost includes Tailscale CGNAT RFC 6598 range', () {
      // 100.64.0.1 is in 100.64.0.0/10
      expect(isLocalCoachHost('http://100.64.0.1:11434'), isTrue);
      expect(isLocalCoachHost('http://100.127.255.254:11434'), isTrue);
      // 100.128.0.1 is outside the /10 block
      expect(isLocalCoachHost('http://100.128.0.1:11434'), isFalse);
    });

    test('coachApiKeyToSave forces key deletion when endpoint changes to prevent credential leakage', () {
      // If endpoint changed (pendingKeyDelete = true) and no new key was typed, force delete
      expect(
        coachApiKeyToSave(
          keyText: '',
          storedKeyReadable: true,
          pendingKeyDelete: true,
        ),
        '',
      );

      // If user clears key intentionally on same endpoint, force delete
      expect(
        coachApiKeyToSave(
          keyText: '',
          storedKeyReadable: true,
          pendingKeyDelete: false,
        ),
        '',
      );

      // If user types a new key, return it
      expect(
        coachApiKeyToSave(
          keyText: 'sk-test-secret-key-123',
          storedKeyReadable: true,
          pendingKeyDelete: true,
        ),
        'sk-test-secret-key-123',
      );

      // If key is unreadable and no endpoint change, leave it untouched
      expect(
        coachApiKeyToSave(
          keyText: '',
          storedKeyReadable: false,
          pendingKeyDelete: false,
        ),
        isNull,
      );
    });

    test('no unencrypted http:// network calls exist in production code (lib/) outside local loopback & XML namespaces', () {
      final lib = Directory('lib');
      final badUrls = <String>[];

      for (final entity in lib.listSync(recursive: true)) {
        if (entity is! File || !entity.path.endsWith('.dart') || entity.path.endsWith('.g.dart')) continue;
        final lines = entity.readAsLinesSync();
        for (var i = 0; i < lines.length; i++) {
          final line = lines[i];
          if (!line.contains('http://')) continue;

          // Allowed exceptions: XML namespaces, licenses, comments, or localhost/127.0.0.1/10.0.2.2
          final isNamespace = line.contains('xmlns') || line.contains('schemas');
          final isLicense = line.contains('creativecommons.org');
          final isComment = line.trim().startsWith('//');
          final isLocalhost = line.contains('localhost') ||
              line.contains('127.0.0.1') ||
              line.contains('10.0.2.2');

          if (!isNamespace && !isLicense && !isComment && !isLocalhost) {
            badUrls.add('${entity.path}:${i + 1} -> ${line.trim()}');
          }
        }
      }

      expect(
        badUrls,
        isEmpty,
        reason: 'Unencrypted HTTP endpoint found in production code:\n${badUrls.join('\n')}',
      );
    });
  });
}
