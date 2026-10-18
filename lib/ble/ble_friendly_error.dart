import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import '../l10n/app_localizations.dart';

/// Humanizes low-level BLE and transport exceptions into clear, actionable,
/// human-readable explanations, hiding raw technical jargon (like "GATT 133")
/// while keeping technical details accessible for diagnostics.
String friendlyBleError(Object error, [AppLocalizations? l]) {
  final s = error.toString().toLowerCase();

  // Android GATT 133 / 0x85 (classic connection congestion or link drop)
  if (s.contains('133') || s.contains('0x85') || s.contains('gatt_error')) {
    return 'Connection to WHOOP was interrupted. Please bring the band closer and try again.';
  }

  // Peer disconnected / connection terminated by peripheral (0x13 / 19)
  if (s.contains('19') ||
      s.contains('0x13') ||
      s.contains('peer removed') ||
      s.contains('connection terminated by peer') ||
      s.contains('remote user terminated')) {
    return 'The device disconnected unexpectedly. Ensure it is awake and nearby.';
  }

  // Timeout / Link supervision timeout (0x08 / 8)
  if (s.contains('timeout') ||
      s.contains('timed out') ||
      s.contains('0x08') ||
      s.contains('link_supervision_timeout') ||
      s.contains('gatt_connection_timeout')) {
    return 'Connection attempt timed out. Ensure your WHOOP is awake, charged, and nearby.';
  }

  // Link loss / connection dropped
  if (s.contains('137') || s.contains('0x89') || s.contains('link loss')) {
    return 'The Bluetooth link was interrupted by the phone. Please reconnect.';
  }

  // Permission issues
  if (s.contains('unauthorized') ||
      s.contains('permission') ||
      s.contains('not authorized') ||
      s.contains('denied')) {
    return 'Bluetooth permission is needed to communicate with your WHOOP. Please enable Bluetooth permission in Settings.';
  }

  // Radio switched off
  if (s.contains('adapter is off') ||
      s.contains('powered off') ||
      s.contains('bluetooth must be turned on') ||
      s.contains('poweredoff')) {
    return 'Bluetooth is turned off on your phone. Turn on Bluetooth to connect.';
  }

  // Encryption / pairing key rejection
  if (s.contains('bond') ||
      s.contains('encrypt') ||
      s.contains('pin') ||
      s.contains('key refused')) {
    return 'Pairing was rejected. Forget the device in your phone’s Bluetooth settings, then pair again.';
  }

  // Unsupported hardware
  if (s.contains('unsupported') || s.contains('not supported')) {
    return 'Bluetooth Low Energy is not supported on this phone.';
  }

  // User cancelled
  if (s.contains('cancel') || s.contains('dismiss')) {
    return 'Pairing was cancelled.';
  }

  // General clean-up of raw Flutter / PlatformException wrappers
  var clean = error.toString().trim();
  if (clean.startsWith('PlatformException(')) {
    final match =
        RegExp(r'PlatformException\([^,]+,\s*([^,]+),').firstMatch(clean);
    if (match != null && match.group(1) != null && match.group(1) != 'null') {
      clean = match.group(1)!.trim();
    }
  } else if (clean.startsWith('Exception: ')) {
    clean = clean.substring('Exception: '.length).trim();
  }
  return clean;
}

/// Dispatches an immediate high-priority accessibility announcement for screen
/// readers (VoiceOver / TalkBack).
void announceAccessibility(BuildContext context, String message) {
  try {
    SemanticsService.sendAnnouncement(
      View.of(context),
      message,
      Directionality.of(context),
    );
  } catch (_) {
    // No-op if semantics or view binding is uninitialized in headless test
  }
}
