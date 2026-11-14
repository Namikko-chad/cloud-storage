import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;

/// GTK application id (linux/CMakeLists.txt APPLICATION_ID). GNOME on
/// Wayland matches windows to `<id>.desktop` for the taskbar icon.
const _appId = 'dev.cloudsync.cloudsync';

/// Registers the app with the Linux desktop (menu entry and taskbar icon):
/// writes `~/.local/share/applications/<id>.desktop` pointing at this build
/// and copies the icon next to it. Only release builds do it, so a debug
/// run does not take over the entry. Rewrites only when something changed.
Future<void> registerDesktopEntry() async {
  if (!Platform.isLinux || !kReleaseMode) return;
  try {
    final env = Platform.environment;
    final xdg = env['XDG_DATA_HOME'];
    final data = xdg != null && xdg.isNotEmpty ? xdg : p.join(env['HOME'] ?? '', '.local', 'share');
    final exe = Platform.resolvedExecutable;
    final src = File(p.join(p.dirname(exe), 'data', 'flutter_assets', 'assets', 'icon', 'cloudsync.png'));
    if (!await src.exists()) return;

    final icon = File(p.join(data, 'icons', 'hicolor', '256x256', 'apps', '$_appId.png'));
    final bytes = await src.readAsBytes();
    if (!await icon.exists() || !listEquals(await icon.readAsBytes(), bytes)) {
      await icon.parent.create(recursive: true);
      await icon.writeAsBytes(bytes, flush: true);
    }

    final entry = File(p.join(data, 'applications', '$_appId.desktop'));
    final text = [
      '[Desktop Entry]',
      'Type=Application',
      'Name=CloudSync',
      'Comment=Encrypted file sync over several cloud storages',
      'Exec="$exe"',
      'Icon=${icon.path}',
      'Terminal=false',
      'Categories=Network;FileTransfer;Utility;',
      'StartupWMClass=$_appId',
      'StartupNotify=true',
      '',
    ].join('\n');
    if (!await entry.exists() || await entry.readAsString() != text) {
      await entry.parent.create(recursive: true);
      await entry.writeAsString(text, flush: true);
    }
  } catch (_) {
    // Cosmetic only: the app works without it.
  }
}
