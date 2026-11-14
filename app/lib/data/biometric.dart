import 'dart:io';

import 'package:flutter/services.dart';

import '../core/i18n.dart';

enum BioResult { ok, canceled, invalidated, failed }

/// Unlock by fingerprint (Android only, `Biometric.kt`): the vault password
/// is sealed in the Android Keystore with a key that opens only after a
/// strong biometric check.
class Biometric {
  static const _ch = MethodChannel('dev.cloudsync/biometric');

  /// The phone has a fingerprint enrolled.
  static bool available = false;

  /// A password is saved for fingerprint unlock.
  static bool enabled = false;

  static Future<void> refresh() async {
    if (!Platform.isAndroid) return;
    try {
      final r = await _ch.invokeMapMethod<String, bool>('status');
      available = r?['available'] ?? false;
      enabled = r?['enabled'] ?? false;
    } catch (_) {
      available = enabled = false;
    }
  }

  /// Saves [password] after a fingerprint check.
  static Future<BioResult> enable(String password) async {
    try {
      await _ch.invokeMethod('enable', {
        'password': password,
        'title': tr('Unlock with fingerprint', 'Вход по отпечатку'),
        'cancel': tr('Cancel', 'Отмена'),
      });
      enabled = true;
      return BioResult.ok;
    } on PlatformException catch (e) {
      return _result(e);
    }
  }

  /// Returns the saved password after a fingerprint check, or the reason it failed.
  static Future<(String?, BioResult)> unlock() async {
    try {
      final p = await _ch.invokeMethod<String>('unlock', {
        'title': tr('Unlock vault', 'Разблокировать vault'),
        'cancel': tr('Use password', 'Ввести пароль'),
      });
      return (p, p == null ? BioResult.failed : BioResult.ok);
    } on PlatformException catch (e) {
      final r = _result(e);
      if (r == BioResult.invalidated || e.code == 'disabled') enabled = false;
      return (null, r);
    }
  }

  static Future<void> disable() async {
    enabled = false;
    try {
      await _ch.invokeMethod('disable');
    } catch (_) {}
  }

  static BioResult _result(PlatformException e) => switch (e.code) {
    'canceled' => BioResult.canceled,
    'invalidated' => BioResult.invalidated,
    _ => BioResult.failed,
  };
}
