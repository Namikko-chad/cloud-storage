import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/i18n.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/typography.dart';
import '../../data/rpc/gen/cloudsync.pbgrpc.dart' as pb;
import '../common/hm.dart';
import 'secret_util.dart';

/// Live two-factor codes. The core computes them (the secrets never leave
/// it); this asks again when a code expires and ticks every second for the
/// countdown.
class TotpCodes extends ChangeNotifier {
  TotpCodes(this._api) {
    _fetch();
    _tick = Timer.periodic(const Duration(seconds: 1), (_) => _onTick());
  }

  final pb.CloudSyncClient _api;
  Map<String, pb.TotpCode> _codes = {};
  late final Timer _tick;
  int _skew = 0; // core clock − local clock, s
  bool _fetching = false;
  bool _disposed = false;

  /// The core's clock now, in unix seconds.
  int get now => DateTime.now().millisecondsSinceEpoch ~/ 1000 + _skew;

  pb.TotpCode? operator [](String id) => _codes[id];

  /// Asks for fresh codes (after an entry was added or changed).
  void refresh() => _fetch();

  void _onTick() {
    if (_codes.values.any((c) => c.expiresUnix.toInt() <= now)) _fetch();
    if (_codes.isNotEmpty) notifyListeners();
  }

  Future<void> _fetch() async {
    if (_fetching) return;
    _fetching = true;
    try {
      final r = await _api.totpCodes(pb.Empty());
      if (_disposed) return;
      _skew = r.nowUnix.toInt() - DateTime.now().millisecondsSinceEpoch ~/ 1000;
      _codes = {for (final c in r.codes) c.id: c};
      notifyListeners();
    } catch (_) {
      // The vault may be closing; the next tick tries again.
    } finally {
      _fetching = false;
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _tick.cancel();
    _codes = {};
    super.dispose();
  }
}

/// "123456" → "123 456", "12345678" → "1234 5678".
String formatTotp(String code) => switch (code.length) {
  6 => '${code.substring(0, 3)} ${code.substring(3)}',
  8 => '${code.substring(0, 4)} ${code.substring(4)}',
  _ => code,
};

/// The current code of one entry with its countdown and a copy button.
class TotpCodeView extends StatelessWidget {
  const TotpCodeView({super.key, required this.codes, required this.id, this.large = false});

  final TotpCodes codes;
  final String id;
  final bool large;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: codes,
    builder: (context, _) {
      final c = codes[id];
      if (c == null) return Text('— — —', style: HmText.body.copyWith(color: HmColors.muted));
      final left = (c.expiresUnix.toInt() - codes.now).clamp(0, c.period);
      final ending = left <= 5;
      final color = ending ? HmColors.error : HmColors.accent;
      final code = Text(formatTotp(c.code), style: HmText.jb(large ? 26 : 15, weight: 700, color: ending ? HmColors.error : HmColors.text));
      final timer = SizedBox(
        width: large ? 120 : 64,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(tr('$left s', '$left с'), style: HmText.small.copyWith(color: ending ? HmColors.error : HmColors.muted)),
            const SizedBox(height: 3),
            HmProgress(value: c.period == 0 ? 0 : left / c.period, color: color),
          ],
        ),
      );
      return Row(
        mainAxisSize: large ? MainAxisSize.max : MainAxisSize.min,
        children: [
          Flexible(child: code),
          const SizedBox(width: 12),
          timer,
          const SizedBox(width: 8),
          HmIconButton(
            icon: Icons.copy_outlined,
            label: ending && c.next.isNotEmpty ? tr('Copy (ends soon)', 'Копировать (скоро сменится)') : tr('Copy', 'Копировать'),
            onPressed: () => copyTotp(codes, id),
          ),
        ],
      );
    },
  );
}

/// Copies the current code; at the last seconds of a period, the next one
/// (it is valid by the time it is typed).
Future<void> copyTotp(TotpCodes codes, String id) async {
  final c = codes[id];
  if (c == null) {
    Toasts.error(tr('No code yet', 'Кода пока нет'));
    return;
  }
  final left = c.expiresUnix.toInt() - codes.now;
  final value = left <= 3 && c.next.isNotEmpty ? c.next : c.code;
  await SecretClipboard.copy(value, tr('Code', 'Код'));
}
