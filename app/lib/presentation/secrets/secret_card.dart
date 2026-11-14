import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/format.dart';
import '../../core/i18n.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/layout.dart';
import '../../core/theme/typography.dart';
import '../../data/rpc/core_client.dart';
import '../../data/rpc/gen/cloudsync.pbgrpc.dart' as pb;
import '../common/hm.dart';
import '../core/core_cubit.dart';
import 'secret_editor.dart';
import 'secret_util.dart';
import 'totp.dart';

/// Shows one entry. Its secret fields are asked from the core when the card
/// opens and dropped when it closes: they live only in memory, only while
/// the card is on screen.
Future<void> showSecretCard(BuildContext context, {required pb.SecretEntry entry, required List<pb.SecretGroup> groups}) {
  final card = GlobalKey<_SecretCardState>();
  return showHmModal<void>(
    context,
    title: entry.title,
    size: HmModalSize.lg,
    body: (_) => _SecretCard(key: card, entry: entry, groups: groups),
    actions: (ctx) => [
      HmButton(tr('Close', 'Закрыть'), variant: HmVariant.neutral, expand: Hm.of(ctx).mobile, onPressed: () => Navigator.pop(ctx)),
      HmButton(
        tr('Edit', 'Изменить'),
        variant: HmVariant.primary,
        icon: Icons.edit_outlined,
        expand: Hm.of(ctx).mobile,
        onPressed: () async {
          final opened = card.currentState?._opened;
          if (opened == null) return;
          // The editor gets its own copy; the card closes either way.
          final copy = opened.deepCopy();
          Navigator.pop(ctx);
          await showSecretEditor(context, groups: groups, entry: copy);
          copy.clear();
        },
      ),
    ],
  );
}

class _SecretCard extends StatefulWidget {
  const _SecretCard({super.key, required this.entry, required this.groups});

  final pb.SecretEntry entry;
  final List<pb.SecretGroup> groups;

  @override
  State<_SecretCard> createState() => _SecretCardState();
}

class _SecretCardState extends State<_SecretCard> {
  pb.SecretEntry? _opened;
  String? _error;
  TotpCodes? _codes;
  bool _showRecovery = false;

  late final CoreCubit _core;

  bool get _isTotp => widget.entry.kind == pb.SecretKind.SECRET_TOTP;

  @override
  void initState() {
    super.initState();
    _core = context.read<CoreCubit>();
    if (_isTotp) _codes = TotpCodes(_core.api);
    _open();
  }

  void _open() {
    _core.api.getSecret(pb.IdRequest(id: widget.entry.id)).then((e) {
      if (mounted) {
        setState(() {
          _opened?.clear();
          _opened = e;
        });
      } else {
        e.clear();
      }
    }, onError: (Object e) => mounted ? setState(() => _error = errorText(e)) : null);
  }

  @override
  void dispose() {
    _opened?.clear(); // drop the plaintext with the card
    _opened = null;
    _codes?.dispose();
    super.dispose();
  }

  void _toggleRecovery() => setState(() => _showRecovery = !_showRecovery);

  /// Removes a recovery code once it was used to log in.
  Future<void> _useCode(String code) async {
    final ok = await confirm(
      context,
      title: tr('Remove the used code?', 'Удалить использованный код?'),
      message: tr(
        '“$code” will be removed on all devices. A recovery code works only once.',
        '«$code» будет удалён на всех устройствах. Код восстановления действует один раз.',
      ),
      action: tr('Remove', 'Удалить'),
      destructive: true,
    );
    if (!ok) return;
    try {
      final saved = await _core.api.useRecoveryCode(pb.RecoveryCodeRequest(id: widget.entry.id, code: code));
      Toasts.success(tr('Code removed', 'Код удалён'), tr('${saved.recoveryLeft} left', 'Осталось: ${saved.recoveryLeft}'));
      if (mounted) _open();
    } catch (e) {
      Toasts.error(tr('Could not remove', 'Не удалось удалить'), errorText(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    final meta = widget.entry;
    final e = _opened;
    final group = widget.groups.where((g) => g.id == meta.groupId).firstOrNull;
    final devices = {for (final d in context.read<CoreCubit>().state.status?.devices ?? <pb.Device>[]) d.id: d.name};
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (meta.conflictOf.isNotEmpty) ...[
          HmBanner(
            tr(
              'Conflict copy: this entry was changed on two devices at the same time. Keep the right one, delete the other.',
              'Конфликтная копия: запись изменили на двух устройствах одновременно. Оставьте нужную, другую удалите.',
            ),
            tone: HmTone.warning,
          ),
          const SizedBox(height: 12),
        ],
        HmField(
          tr('Type', 'Тип'),
          Text(meta.kind == pb.SecretKind.SECRET_WEB3 ? '${meta.kind.label} · ${meta.network.label}' : meta.kind.label),
        ),
        if (group != null) HmField(tr('Group', 'Группа'), Text(group.name)),
        if (meta.username.isNotEmpty)
          HmField(
            _isTotp ? tr('Account', 'Аккаунт') : tr('Login', 'Логин'),
            _Copyable(meta.username, onCopy: () => SecretClipboard.copyPlain(meta.username, tr('Login', 'Логин'))),
          ),
        if (meta.url.isNotEmpty) HmField('URL', _Link(meta.url)),
        if (meta.kind == pb.SecretKind.SECRET_SSH) ...[
          HmField(tr('Key type', 'Тип ключа'), Text(meta.keyType)),
          HmField(
            tr('Fingerprint', 'Отпечаток'),
            _Copyable(meta.fingerprint, onCopy: () => SecretClipboard.copyPlain(meta.fingerprint, tr('Fingerprint', 'Отпечаток'))),
          ),
          HmField(
            tr('Public key', 'Публичный ключ'),
            _Copyable(meta.publicKey, onCopy: () => SecretClipboard.copyPlain(meta.publicKey, tr('Public key', 'Публичный ключ'))),
          ),
        ],
        if (meta.kind == pb.SecretKind.SECRET_WEB3) ...[
          HmField(
            tr('Address', 'Адрес'),
            _Copyable(meta.address, onCopy: () => SecretClipboard.copyPlain(meta.address, tr('Address', 'Адрес'))),
          ),
          if (meta.publicKey.isNotEmpty && meta.publicKey != meta.address)
            HmField(
              tr('Public key', 'Публичный ключ'),
              _Copyable(meta.publicKey, onCopy: () => SecretClipboard.copyPlain(meta.publicKey, tr('Public key', 'Публичный ключ'))),
            ),
        ],
        const SizedBox(height: 8),
        if (e == null)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: _error != null
                ? HmBanner(_error!, tone: HmTone.error)
                : Row(
                    children: [
                      const SizedBox.square(dimension: 14, child: HmSpinner()),
                      const SizedBox(width: 10),
                      Text(tr('Decrypting…', 'Расшифровка…'), style: HmText.small),
                    ],
                  ),
          )
        else ...[
          if (meta.kind == pb.SecretKind.SECRET_PASSWORD)
            HmField(tr('Password', 'Пароль'), _Secret(e.password, what: tr('Password', 'Пароль'))),
          if (_isTotp) ...[
            HmField(tr('Code', 'Код'), TotpCodeView(codes: _codes!, id: meta.id, large: true)),
            HmField(
              tr('Parameters', 'Параметры'),
              Text('${e.totpAlgorithm} · ${e.totpDigits} · ${tr('${e.totpPeriod} s', '${e.totpPeriod} с')}'),
            ),
            HmField(tr('Secret key', 'Секретный ключ'), _Secret(e.totpSecret, what: tr('Secret key', 'Секретный ключ'))),
            HmField(tr('Recovery codes', 'Коды восстановления'), _recoveryCodes(e)),
          ],
          if (meta.kind == pb.SecretKind.SECRET_SSH || meta.kind == pb.SecretKind.SECRET_WEB3)
            HmField(
              tr('Private key', 'Приватный ключ'),
              _Secret(e.privateKey, what: tr('Private key', 'Приватный ключ'), block: meta.kind == pb.SecretKind.SECRET_SSH),
            ),
          if (e.passphrase.isNotEmpty)
            HmField(tr('Passphrase', 'Пароль ключа'), _Secret(e.passphrase, what: tr('Passphrase', 'Пароль ключа'))),
          if (e.notes.isNotEmpty) HmField(tr('Notes', 'Описание'), SelectableText(e.notes)),
        ],
        HmField(tr('Changed', 'Изменена'), Text('${formatTime(meta.updatedUnix)} · ${devices[meta.device] ?? meta.device}')),
        if (meta.createdUnix != meta.updatedUnix) HmField(tr('Created', 'Создана'), Text(formatTime(meta.createdUnix))),
      ],
    );
  }
}

extension on _SecretCardState {
  Widget _recoveryCodes(pb.SecretEntry e) {
    final codes = e.recoveryCodes;
    if (codes.isEmpty) {
      return Text(tr('None saved', 'Не сохранены'), style: HmText.body.copyWith(color: HmColors.muted));
    }
    final low = codes.length <= 2;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                tr('${codes.length} left', 'Осталось: ${codes.length}'),
                style: HmText.body.copyWith(color: low ? HmColors.warning : HmColors.text),
              ),
            ),
            HmIconButton(
              icon: _showRecovery ? Icons.visibility_off_outlined : Icons.visibility_outlined,
              label: _showRecovery ? tr('Hide', 'Скрыть') : tr('Show', 'Показать'),
              onPressed: () => _toggleRecovery(),
            ),
          ],
        ),
        if (low) ...[
          const SizedBox(height: 6),
          Text(
            tr('Few codes left: make new ones on the site.', 'Кодов почти не осталось: создайте новые на сайте.'),
            style: HmText.small.copyWith(color: HmColors.warning),
          ),
        ],
        if (_showRecovery) ...[
          const SizedBox(height: 8),
          _Box(
            child: Column(
              children: [
                for (final c in codes)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Row(
                      children: [
                        Expanded(child: SelectableText(c, style: HmText.jb(13))),
                        HmIconButton(
                          icon: Icons.copy_outlined,
                          label: tr('Copy', 'Копировать'),
                          onPressed: () => SecretClipboard.copy(c, tr('Recovery code', 'Код восстановления')),
                        ),
                        const SizedBox(width: 6),
                        HmIconButton(
                          icon: Icons.task_alt,
                          label: tr('Used — remove', 'Использован — удалить'),
                          onPressed: () => _useCode(c),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

/// A secret value: hidden until shown, copied without showing.
class _Secret extends StatefulWidget {
  const _Secret(this.value, {required this.what, this.block = false});

  final String value;
  final String what;
  final bool block; // multi-line (an SSH key)

  @override
  State<_Secret> createState() => _SecretState();
}

class _SecretState extends State<_Secret> {
  bool _shown = false;

  @override
  Widget build(BuildContext context) {
    if (widget.value.isEmpty) return Text('—', style: HmText.body.copyWith(color: HmColors.muted));
    final text = _shown
        ? SelectableText(widget.value, style: HmText.jb(widget.block ? 11 : 13))
        : Text('•' * (widget.block ? 24 : widget.value.length.clamp(8, 24)), style: HmText.body.copyWith(color: HmColors.muted));
    final buttons = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        HmIconButton(
          icon: _shown ? Icons.visibility_off_outlined : Icons.visibility_outlined,
          label: _shown ? tr('Hide', 'Скрыть') : tr('Show', 'Показать'),
          onPressed: () => setState(() => _shown = !_shown),
        ),
        const SizedBox(width: 6),
        HmIconButton(
          icon: Icons.copy_outlined,
          label: tr('Copy', 'Копировать'),
          onPressed: () => SecretClipboard.copy(widget.value, widget.what),
        ),
      ],
    );
    if (widget.block && _shown) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          buttons,
          const SizedBox(height: 8),
          _Box(child: text),
        ],
      );
    }
    return Row(
      children: [
        Expanded(child: text),
        const SizedBox(width: 8),
        buttons,
      ],
    );
  }
}

class _Copyable extends StatelessWidget {
  const _Copyable(this.value, {required this.onCopy});

  final String value;
  final VoidCallback onCopy;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Expanded(child: SelectableText(value, style: HmText.jb(Hm.of(context).mobile ? 12 : 12))),
      const SizedBox(width: 8),
      HmIconButton(icon: Icons.copy_outlined, label: tr('Copy', 'Копировать'), onPressed: onCopy),
    ],
  );
}

class _Link extends StatelessWidget {
  const _Link(this.url);

  final String url;

  @override
  Widget build(BuildContext context) {
    final uri = Uri.tryParse(url.contains('://') ? url : 'https://$url');
    final web = uri != null && (uri.scheme == 'http' || uri.scheme == 'https');
    return Row(
      children: [
        Expanded(child: SelectableText(url)),
        if (web) ...[
          const SizedBox(width: 8),
          HmIconButton(
            icon: Icons.open_in_new,
            label: tr('Open', 'Открыть'),
            onPressed: () => launchUrl(uri, mode: LaunchMode.externalApplication),
          ),
        ],
      ],
    );
  }
}

class _Box extends StatelessWidget {
  const _Box({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: HmColors.bg,
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: HmColors.border),
    ),
    child: child,
  );
}
