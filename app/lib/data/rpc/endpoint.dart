import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;

/// Where the core listens and the token it wants.
class Endpoint {
  const Endpoint({required this.address, this.port = 0, required this.token});

  final InternetAddress address;
  final int port;
  final String token;
}

/// Finds or starts the core for this platform.
abstract class CoreLauncher {
  Future<Endpoint> endpoint({bool start = true});

  static CoreLauncher forPlatform() => Platform.isAndroid ? AndroidLauncher() : DesktopLauncher();
}

/// Android: the core runs inside the app (gomobile AAR) in a foreground
/// service; Kotlin starts it and hands over the socket path and token.
class AndroidLauncher implements CoreLauncher {
  static const _ch = MethodChannel('dev.cloudsync/core');

  @override
  Future<Endpoint> endpoint({bool start = true}) async {
    final r = await _ch.invokeMapMethod<String, String>('start');
    if (r == null) throw StateError('core did not start');
    return Endpoint(
      address: InternetAddress(r['socket']!, type: InternetAddressType.unix),
      token: r['token']!,
    );
  }
}

/// Desktop: the core is the cloudsyncd daemon. It writes its address and
/// token to `<config dir>/cloudsync/endpoint.json`; when it is not running
/// the app starts it (from next to the app binary, $CLOUDSYNCD or PATH).
class DesktopLauncher implements CoreLauncher {
  static String get configDir {
    if (Platform.isWindows) return p.join(Platform.environment['APPDATA'] ?? '.', 'cloudsync');
    final xdg = Platform.environment['XDG_CONFIG_HOME'];
    final home = Platform.environment['HOME'] ?? '.';
    return p.join(xdg != null && xdg.isNotEmpty ? xdg : p.join(home, '.config'), 'cloudsync');
  }

  File get _file => File(p.join(configDir, 'endpoint.json'));

  @override
  Future<Endpoint> endpoint({bool start = true}) async {
    final e = await _read();
    if (e != null && await _reachable(e)) return e;
    if (!start) throw const SocketException('cloudsyncd is not running');
    final before = await _modified();
    await _spawn();
    final deadline = DateTime.now().add(const Duration(seconds: 15));
    while (DateTime.now().isBefore(deadline)) {
      await Future<void>.delayed(const Duration(milliseconds: 300));
      final m = await _modified();
      if (m == null || m == before) continue;
      final e = await _read();
      if (e != null && await _reachable(e)) return e;
    }
    throw const SocketException('cloudsyncd did not start (see its log)');
  }

  Future<DateTime?> _modified() async => await _file.exists() ? (await _file.stat()).modified : null;

  Future<Endpoint?> _read() async {
    try {
      final j = jsonDecode(await _file.readAsString()) as Map<String, dynamic>;
      final addr = j['address'] as String;
      final token = j['token'] as String;
      if (addr.startsWith('unix://')) {
        return Endpoint(
          address: InternetAddress(addr.substring('unix://'.length), type: InternetAddressType.unix),
          token: token,
        );
      }
      final i = addr.lastIndexOf(':');
      return Endpoint(address: InternetAddress(addr.substring(0, i)), port: int.parse(addr.substring(i + 1)), token: token);
    } catch (_) {
      return null;
    }
  }

  Future<bool> _reachable(Endpoint e) async {
    try {
      final s = await Socket.connect(e.address, e.port, timeout: const Duration(seconds: 2));
      s.destroy();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> _spawn() async {
    final name = Platform.isWindows ? 'cloudsyncd.exe' : 'cloudsyncd';
    final candidates = [
      Platform.environment['CLOUDSYNCD'],
      p.join(p.dirname(Platform.resolvedExecutable), name),
      p.join(p.dirname(Platform.resolvedExecutable), 'lib', name),
    ];
    var exe = name; // PATH
    for (final c in candidates) {
      if (c != null && c.isNotEmpty && await File(c).exists()) {
        exe = c;
        break;
      }
    }
    await Process.start(exe, const [], mode: ProcessStartMode.detached);
  }
}
