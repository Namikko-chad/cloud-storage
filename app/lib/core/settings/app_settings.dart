import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../data/rpc/endpoint.dart';
import '../i18n.dart';

/// App preferences of this device (not part of the vault): kept in
/// `<config dir>/cloudsync/app.json` on desktops, in app support on Android.
class AppSettings extends ChangeNotifier {
  AppSettings._(this._file);

  final File? _file;
  bool _closeToTray = false;
  bool _biometricDeclined = false;

  static late AppSettings instance;

  /// Closing the window hides it to the tray instead of quitting (desktop).
  bool get closeToTray => _closeToTray;

  Lang get language => lang.value;

  /// The user said no to unlocking by fingerprint: don't offer it again
  /// after each password unlock (Android; can be turned on in Settings).
  bool get biometricDeclined => _biometricDeclined;

  static Future<AppSettings> load() async {
    File? file;
    try {
      final dir = Platform.isAndroid ? (await getApplicationSupportDirectory()).path : DesktopLauncher.configDir;
      file = File(p.join(dir, 'app.json'));
    } catch (_) {}
    final s = AppSettings._(file);
    try {
      if (file != null && await file.exists()) {
        final j = jsonDecode(await file.readAsString()) as Map<String, dynamic>;
        s._closeToTray = j['close_to_tray'] == true;
        s._biometricDeclined = j['biometric_declined'] == true;
        lang.value = Lang.values.firstWhere((l) => l.name == j['language'], orElse: () => Lang.en);
      }
    } catch (_) {
      // A broken file means defaults.
    }
    return instance = s;
  }

  Future<void> setLanguage(Lang l) async {
    lang.value = l;
    notifyListeners();
    await _save();
  }

  Future<void> setCloseToTray(bool v) async {
    _closeToTray = v;
    notifyListeners();
    await _save();
  }

  Future<void> setBiometricDeclined(bool v) async {
    _biometricDeclined = v;
    notifyListeners();
    await _save();
  }

  Future<void> _save() async {
    final f = _file;
    if (f == null) return;
    try {
      await f.parent.create(recursive: true);
      await f.writeAsString(jsonEncode({
          'language': lang.value.name,
          'close_to_tray': _closeToTray,
          'biometric_declined': _biometricDeclined,
        }));
    } catch (_) {}
  }
}
