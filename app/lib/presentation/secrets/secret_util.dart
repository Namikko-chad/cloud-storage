import 'dart:async';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/services.dart';

import '../../core/i18n.dart';
import '../../data/rpc/gen/cloudsync.pbgrpc.dart' as pb;
import '../common/hm.dart';

/// Copies a secret and clears the clipboard after [clearAfter], unless
/// something else was copied meanwhile.
class SecretClipboard {
  SecretClipboard._();

  static const clearAfter = Duration(seconds: 30);
  static Timer? _timer;

  static Future<void> copy(String value, String what) async {
    await Clipboard.setData(ClipboardData(text: value));
    _timer?.cancel();
    _timer = Timer(clearAfter, () async {
      final now = await Clipboard.getData(Clipboard.kTextPlain);
      if (now?.text == value) await Clipboard.setData(const ClipboardData(text: ''));
    });
    Toasts.success(tr('$what copied', '$what: скопировано'), tr('The clipboard is cleared in 30 s', 'Буфер обмена очистится через 30 с'));
  }

  /// Copies a value that is not secret (public key, address, login).
  static Future<void> copyPlain(String value, String what) async {
    await Clipboard.setData(ClipboardData(text: value));
    Toasts.success(tr('$what copied', '$what: скопировано'));
  }
}

/// A random password: letters, digits and symbols, at least one of each.
String generatePassword({int length = 20}) {
  const lower = 'abcdefghijkmnopqrstuvwxyz';
  const upper = 'ABCDEFGHJKLMNPQRSTUVWXYZ';
  const digits = '23456789';
  const symbols = r'!#$%&*+-=?@^_~';
  const all = lower + upper + digits + symbols;
  final r = Random.secure();
  String pick(String set) => set[r.nextInt(set.length)];
  final chars = [pick(lower), pick(upper), pick(digits), pick(symbols), for (var i = 4; i < length; i++) pick(all)];
  chars.shuffle(r);
  return chars.join();
}

/// The largest picture the core accepts for a group.
const maxIconBytes = 64 << 10;

/// Scales a picture down to a square PNG that fits [maxIconBytes].
Future<Uint8List> groupIcon(Uint8List source) async {
  for (final side in const [128, 96, 64, 48]) {
    final codec = await ui.instantiateImageCodec(source);
    final frame = await codec.getNextFrame();
    final img = frame.image;
    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder);
    // Centre crop to a square, then scale.
    final s = min(img.width, img.height).toDouble();
    final src = ui.Rect.fromLTWH((img.width - s) / 2, (img.height - s) / 2, s, s);
    final dst = ui.Rect.fromLTWH(0, 0, side.toDouble(), side.toDouble());
    canvas.drawImageRect(img, src, dst, ui.Paint()..filterQuality = ui.FilterQuality.high);
    final out = await recorder.endRecording().toImage(side, side);
    final png = await out.toByteData(format: ui.ImageByteFormat.png);
    img.dispose();
    out.dispose();
    codec.dispose();
    if (png != null && png.lengthInBytes <= maxIconBytes) return png.buffer.asUint8List();
  }
  throw tr('The picture is too detailed to fit 64 KiB', 'Картинка не помещается в 64 КиБ');
}

extension SecretKindText on pb.SecretKind {
  String get label => switch (this) {
    pb.SecretKind.SECRET_SSH => tr('SSH key', 'SSH-ключ'),
    pb.SecretKind.SECRET_WEB3 => tr('Web3 key', 'Web3-ключ'),
    pb.SecretKind.SECRET_TOTP => tr('2FA code', '2FA-код'),
    _ => tr('Password', 'Пароль'),
  };
}

extension Web3NetworkText on pb.Web3Network {
  String get label => switch (this) {
    pb.Web3Network.WEB3_SOLANA => 'Solana',
    _ => 'Ethereum / EVM',
  };
}
