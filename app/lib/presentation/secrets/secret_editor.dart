import 'dart:async';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/i18n.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/layout.dart';
import '../../core/theme/typography.dart';
import '../../data/rpc/core_client.dart';
import '../../data/rpc/gen/cloudsync.pbgrpc.dart' as pb;
import '../common/hm.dart';
import '../core/core_cubit.dart';
import 'group_icons.dart';
import 'secret_util.dart';
import 'secrets_screen.dart' show GroupAvatar;
import 'totp.dart' show formatTotp;

/// Kinds of the password list; the 2FA list has only [pb.SecretKind.SECRET_TOTP].
const passwordKinds = [pb.SecretKind.SECRET_PASSWORD, pb.SecretKind.SECRET_SSH, pb.SecretKind.SECRET_WEB3];

/// Creates an entry, or edits an opened one ([entry] with its secrets).
/// Returns the saved entry (without secrets), or null.
Future<pb.SecretEntry?> showSecretEditor(
  BuildContext context, {
  required List<pb.SecretGroup> groups,
  pb.SecretEntry? entry,
  String initialGroup = '',
  List<pb.SecretKind> kinds = passwordKinds,
}) {
  final form = GlobalKey<_EditorState>();
  final saving = ValueNotifier(false);
  return showHmModal<pb.SecretEntry>(
    context,
    title: entry == null ? tr('New entry', 'Новая запись') : tr('Edit entry', 'Изменить запись'),
    size: HmModalSize.lg,
    dismissible: false,
    body: (_) => _Editor(key: form, groups: groups, entry: entry, initialGroup: initialGroup, kinds: kinds, saving: saving),
    actions: (ctx) => [
      HmButton(tr('Cancel', 'Отмена'), variant: HmVariant.neutral, expand: Hm.of(ctx).mobile, onPressed: () => Navigator.pop(ctx)),
      ValueListenableBuilder(
        valueListenable: saving,
        builder: (_, busy, _) => HmButton(
          tr('Save', 'Сохранить'),
          variant: HmVariant.primary,
          loading: busy,
          expand: Hm.of(ctx).mobile,
          onPressed: () async {
            final saved = await form.currentState?.save();
            if (saved != null && ctx.mounted) Navigator.pop(ctx, saved);
          },
        ),
      ),
    ],
  );
}

class _Editor extends StatefulWidget {
  const _Editor({
    super.key,
    required this.groups,
    required this.entry,
    required this.initialGroup,
    required this.kinds,
    required this.saving,
  });

  final List<pb.SecretGroup> groups;
  final pb.SecretEntry? entry;
  final String initialGroup;
  final List<pb.SecretKind> kinds;
  final ValueNotifier<bool> saving;

  @override
  State<_Editor> createState() => _EditorState();
}

class _EditorState extends State<_Editor> {
  late pb.SecretKind _kind;
  late pb.Web3Network _network;
  late String _group;
  final _title = TextEditingController();
  final _username = TextEditingController();
  final _password = TextEditingController();
  final _url = TextEditingController();
  final _notes = TextEditingController();
  final _privateKey = TextEditingController();
  final _passphrase = TextEditingController();
  final _comment = TextEditingController();
  final _totpSecret = TextEditingController();
  final _recovery = TextEditingController();
  String _algorithm = 'SHA1';
  int _digits = 6;
  int _period = 30;
  pb.TotpPreview? _preview;
  String? _totpError;
  Timer? _checkTimer;
  int _checkSeq = 0;

  String? _titleError;
  String? _keyError;
  String? _saveError;
  pb.DerivedKey? _derived;
  Timer? _deriveTimer;
  int _deriveSeq = 0;

  late final CoreCubit _core;

  bool get _isKey => _kind == pb.SecretKind.SECRET_SSH || _kind == pb.SecretKind.SECRET_WEB3;
  bool get _isTotp => _kind == pb.SecretKind.SECRET_TOTP;
  bool get _isUri => _totpSecret.text.trim().toLowerCase().startsWith('otpauth:');

  @override
  void initState() {
    super.initState();
    _core = context.read<CoreCubit>();
    final e = widget.entry;
    _kind = e?.kind ?? widget.kinds.first;
    if (_kind == pb.SecretKind.SECRET_KIND_UNSPECIFIED) _kind = pb.SecretKind.SECRET_PASSWORD;
    _network = e?.network == pb.Web3Network.WEB3_SOLANA ? pb.Web3Network.WEB3_SOLANA : pb.Web3Network.WEB3_EVM;
    _group = e?.groupId ?? widget.initialGroup;
    if (!widget.groups.any((g) => g.id == _group)) _group = '';
    if (e != null) {
      _title.text = e.title;
      _username.text = e.username;
      _password.text = e.password;
      _url.text = e.url;
      _notes.text = e.notes;
      _privateKey.text = e.privateKey;
      _passphrase.text = e.passphrase;
      _comment.text = e.comment;
      _totpSecret.text = e.totpSecret;
      _recovery.text = e.recoveryCodes.join('\n');
      if (e.totpAlgorithm.isNotEmpty) _algorithm = e.totpAlgorithm;
      if (e.totpDigits > 0) _digits = e.totpDigits;
      if (e.totpPeriod > 0) _period = e.totpPeriod;
      if (_isKey) _derive();
      if (_isTotp) _check();
    }
  }

  @override
  void dispose() {
    _deriveTimer?.cancel();
    _checkTimer?.cancel();
    for (final c in [_title, _username, _password, _url, _notes, _privateKey, _passphrase, _comment, _totpSecret, _recovery]) {
      c.clear();
      c.dispose();
    }
    super.dispose();
  }

  void _deriveSoon() {
    _deriveTimer?.cancel();
    _deriveTimer = Timer(const Duration(milliseconds: 350), _derive);
  }

  /// Asks the core for the public half of the key being typed.
  Future<void> _derive() async {
    final seq = ++_deriveSeq;
    if (_privateKey.text.trim().isEmpty) {
      setState(() {
        _derived = null;
        _keyError = null;
      });
      return;
    }
    try {
      final d = await _core.api.deriveKey(
        pb.DeriveKeyRequest(
          kind: _kind,
          network: _network,
          privateKey: _privateKey.text,
          passphrase: _passphrase.text,
          comment: _comment.text,
        ),
      );
      if (!mounted || seq != _deriveSeq) return;
      setState(() {
        _derived = d;
        _keyError = null;
      });
    } catch (e) {
      if (!mounted || seq != _deriveSeq) return;
      setState(() {
        _derived = null;
        _keyError = errorText(e);
      });
    }
  }

  void _checkSoon() {
    _checkTimer?.cancel();
    _checkTimer = Timer(const Duration(milliseconds: 300), _check);
  }

  /// Asks the core to read the TOTP secret (or otpauth:// URI) and the
  /// pasted recovery codes: shows the current code to compare with the
  /// site and the codes as they will be saved.
  Future<void> _check() async {
    final seq = ++_checkSeq;
    try {
      final p = await _core.api.checkTotp(
        pb.CheckTotpRequest(
          secret: _totpSecret.text,
          algorithm: _algorithm,
          digits: _digits,
          period: _period,
          recoveryText: _recovery.text,
        ),
      );
      if (!mounted || seq != _checkSeq) return;
      setState(() {
        _preview = p;
        _totpError = p.error.isEmpty ? null : p.error;
        if (p.error.isEmpty && p.code.isNotEmpty && _isUri) {
          _algorithm = p.algorithm;
          _digits = p.digits;
          _period = p.period;
          if (_title.text.trim().isEmpty) _title.text = p.issuer.isNotEmpty ? p.issuer : p.account;
          if (_username.text.trim().isEmpty) _username.text = p.account;
        }
      });
    } catch (e) {
      if (!mounted || seq != _checkSeq) return;
      setState(() => _totpError = errorText(e));
    }
  }

  Future<pb.SecretEntry?> save() async {
    setState(() {
      _titleError = _title.text.trim().isEmpty ? tr('Enter a title', 'Введите название') : null;
      _saveError = null;
    });
    if (_isTotp && _totpSecret.text.trim().isEmpty) {
      setState(() => _totpError = tr('Paste the secret key or the otpauth:// link', 'Вставьте секретный ключ или ссылку otpauth://'));
      return null;
    }
    if (_titleError != null) return null;
    if (_isKey && _privateKey.text.trim().isEmpty) {
      setState(() => _keyError = tr('Paste the private key', 'Вставьте приватный ключ'));
      return null;
    }
    final req = pb.SecretEntry(
      id: widget.entry?.id,
      version: widget.entry?.version,
      kind: _kind,
      title: _title.text.trim(),
      groupId: _group,
      username: _kind == pb.SecretKind.SECRET_PASSWORD || _isTotp ? _username.text.trim() : '',
      url: _url.text.trim(),
      notes: _notes.text,
      password: _kind == pb.SecretKind.SECRET_PASSWORD ? _password.text : '',
      privateKey: _isKey ? _privateKey.text.trim() : '',
      passphrase: _kind == pb.SecretKind.SECRET_SSH ? _passphrase.text : '',
      comment: _kind == pb.SecretKind.SECRET_SSH ? _comment.text.trim() : '',
      network: _kind == pb.SecretKind.SECRET_WEB3 ? _network : null,
      totpSecret: _isTotp ? _totpSecret.text.trim() : null,
      totpAlgorithm: _isTotp ? _algorithm : null,
      totpDigits: _isTotp ? _digits : null,
      totpPeriod: _isTotp ? _period : null,
      recoveryCodes: _isTotp && _recovery.text.trim().isNotEmpty ? [_recovery.text] : null,
    );
    widget.saving.value = true;
    try {
      final saved = await _core.api.putSecret(req);
      Toasts.success(tr('Saved', 'Сохранено'), saved.title);
      return saved;
    } catch (e) {
      if (mounted) setState(() => _saveError = errorText(e));
      return null;
    } finally {
      req.clear();
      widget.saving.value = false;
    }
  }

  List<Widget> _totpFields(Widget gap) {
    final p = _preview;
    final codes = p?.recoveryCodes ?? const <String>[];
    void param(VoidCallback f) {
      setState(f);
      _checkSoon();
    }

    return [
      HmTextField(label: tr('Account', 'Аккаунт'), controller: _username, identifier: true, placeholder: 'user@example.com'),
      gap,
      HmTextField(
        label: tr('Secret key', 'Секретный ключ'),
        required: true,
        controller: _totpSecret,
        password: true,
        identifier: true,
        error: _totpError,
        hint: tr(
          'The key shown next to the QR code (base32), or the otpauth:// link',
          'Ключ, который показывают рядом с QR-кодом (base32), или ссылка otpauth://',
        ),
        onChanged: (_) {
          setState(() {});
          _checkSoon();
        },
      ),
      gap,
      if (!_isUri) ...[
        Wrap(
          spacing: 12,
          runSpacing: 8,
          children: [
            SizedBox(
              width: 150,
              child: HmSelect<String>(
                label: tr('Algorithm', 'Алгоритм'),
                options: const {'SHA1': 'SHA1', 'SHA256': 'SHA256', 'SHA512': 'SHA512'},
                value: _algorithm,
                onChanged: (v) => param(() => _algorithm = v),
              ),
            ),
            SizedBox(
              width: 120,
              child: HmSelect<int>(
                label: tr('Digits', 'Цифр'),
                options: const {6: '6', 7: '7', 8: '8'},
                value: _digits,
                onChanged: (v) => param(() => _digits = v),
              ),
            ),
            SizedBox(
              width: 120,
              child: HmSelect<int>(
                label: tr('Period', 'Период'),
                options: {
                  for (final s in {30, 60, _period}) s: tr('$s s', '$s с'),
                },
                value: _period,
                onChanged: (v) => param(() => _period = v),
              ),
            ),
          ],
        ),
        gap,
      ],
      if (p != null && p.code.isNotEmpty) ...[
        HmCard(
          recessed: true,
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              HmField(tr('Code now', 'Код сейчас'), Text(formatTotp(p.code), style: HmText.jb(15, weight: 700))),
              HmField(tr('Parameters', 'Параметры'), Text('${p.algorithm} · ${p.digits} · ${tr('${p.period} s', '${p.period} с')}')),
              Text(
                tr('It should match the code the site asks for.', 'Он должен совпасть с кодом, который ждёт сайт.'),
                style: HmText.small.copyWith(color: HmColors.muted),
              ),
            ],
          ),
        ),
        gap,
      ],
      HmTextField(label: 'URL', controller: _url, identifier: true, keyboard: TextInputType.url),
      gap,
      HmTextField(
        label: tr('Recovery codes', 'Коды восстановления'),
        controller: _recovery,
        identifier: true,
        lines: 6,
        hint: tr(
          'Paste the list as the site gives it: the codes are picked out of it. A used code is removed from the card.',
          'Вставьте список как есть, коды будут выделены из него. Использованный код удаляется в карточке.',
        ),
        onChanged: (_) => _checkSoon(),
      ),
      if (codes.isNotEmpty) ...[
        const SizedBox(height: 8),
        Text(tr('Recognized: ${codes.length}', 'Распознано: ${codes.length}'), style: HmText.small),
        const SizedBox(height: 6),
        Wrap(spacing: 16, runSpacing: 4, children: [for (final c in codes) Text(c, style: HmText.jb(12))]),
      ],
      gap,
    ];
  }

  @override
  Widget build(BuildContext context) {
    final hm = Hm.of(context);
    final gap = SizedBox(height: hm.gapSm);
    final d = _derived;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (widget.entry == null && widget.kinds.length > 1) ...[
          HmSegmented<pb.SecretKind>(
            options: {for (final k in widget.kinds) k: k.label},
            value: _kind,
            onChanged: (k) {
              setState(() {
                _kind = k;
                _derived = null;
                _keyError = null;
              });
              if (_isKey) _derive();
            },
          ),
          gap,
        ],
        HmTextField(
          label: tr('Title', 'Название'),
          required: true,
          autofocus: widget.entry == null,
          controller: _title,
          error: _titleError,
        ),
        gap,
        HmSelect<String>(
          label: tr('Group', 'Группа'),
          options: {'': tr('No group', 'Без группы'), for (final g in widget.groups) g.id: g.name},
          value: _group,
          onChanged: (v) => setState(() => _group = v),
        ),
        gap,
        if (_kind == pb.SecretKind.SECRET_PASSWORD) ...[
          HmTextField(label: tr('Login', 'Логин'), controller: _username, identifier: true),
          gap,
          HmTextField(label: tr('Password', 'Пароль'), controller: _password, password: true),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: HmButton(
              tr('Generate', 'Сгенерировать'),
              small: true,
              icon: Icons.casino_outlined,
              onPressed: () => setState(() => _password.text = generatePassword()),
            ),
          ),
          gap,
          HmTextField(label: 'URL', controller: _url, identifier: true, keyboard: TextInputType.url),
          gap,
        ],
        if (_kind == pb.SecretKind.SECRET_WEB3) ...[
          HmSegmented<pb.Web3Network>(
            options: {
              for (final n in [pb.Web3Network.WEB3_EVM, pb.Web3Network.WEB3_SOLANA]) n: n.label,
            },
            value: _network,
            onChanged: (n) {
              setState(() => _network = n);
              _derive();
            },
          ),
          gap,
          HmTextField(
            label: tr('Private key', 'Приватный ключ'),
            required: true,
            controller: _privateKey,
            password: true,
            identifier: true,
            error: _keyError,
            hint: _network == pb.Web3Network.WEB3_SOLANA
                ? tr('Base58 keypair, keypair JSON array or 32-byte seed', 'Base58-пара ключей, JSON-массив keypair или 32-байтный seed')
                : tr('64 hex digits, with or without 0x', '64 hex-символа, с 0x или без'),
            onChanged: (_) => _deriveSoon(),
          ),
          gap,
        ],
        if (_kind == pb.SecretKind.SECRET_SSH) ...[
          HmTextField(
            label: tr('Private key', 'Приватный ключ'),
            required: true,
            controller: _privateKey,
            identifier: true,
            lines: 6,
            error: _keyError,
            placeholder: '-----BEGIN OPENSSH PRIVATE KEY-----',
            hint: tr('OpenSSH or PEM; the public key is computed from it', 'OpenSSH или PEM; публичный ключ вычисляется из него'),
            onChanged: (_) => _deriveSoon(),
          ),
          gap,
          HmTextField(
            label: tr('Passphrase', 'Пароль ключа'),
            controller: _passphrase,
            password: true,
            hint: tr('Only if the key is encrypted', 'Только если ключ зашифрован'),
            onChanged: (_) => _deriveSoon(),
          ),
          gap,
          HmTextField(
            label: tr('Comment', 'Комментарий'),
            controller: _comment,
            identifier: true,
            placeholder: 'user@host',
            onChanged: (_) => _deriveSoon(),
          ),
          gap,
          HmTextField(label: tr('Host / URL', 'Хост / URL'), controller: _url, identifier: true),
          gap,
        ],
        if (_isTotp) ..._totpFields(gap),
        if (_isKey && d != null) ...[_Derived(kind: _kind, key: ValueKey(d.publicKey), derived: d), gap],
        HmTextField(
          label: tr('Notes', 'Описание'),
          controller: _notes,
          lines: 4,
          hint: tr('Encrypted like the password', 'Шифруется, как и пароль'),
        ),
        if (_saveError != null) ...[gap, HmBanner(_saveError!, tone: HmTone.error)],
      ],
    );
  }
}

/// The public half the core computed, shown while the key is typed.
class _Derived extends StatelessWidget {
  const _Derived({super.key, required this.kind, required this.derived});

  final pb.SecretKind kind;
  final pb.DerivedKey derived;

  @override
  Widget build(BuildContext context) => HmCard(
    recessed: true,
    padding: const EdgeInsets.all(12),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        HmField(tr('Key type', 'Тип ключа'), Text(derived.keyType)),
        if (kind == pb.SecretKind.SECRET_SSH) ...[
          HmField(tr('Fingerprint', 'Отпечаток'), SelectableText(derived.fingerprint)),
          HmField(tr('Public key', 'Публичный ключ'), SelectableText(derived.publicKey, style: HmText.jb(11))),
        ] else ...[
          HmField(tr('Address', 'Адрес'), SelectableText(derived.address)),
          if (derived.publicKey != derived.address)
            HmField(tr('Public key', 'Публичный ключ'), SelectableText(derived.publicKey, style: HmText.jb(11))),
        ],
      ],
    ),
  );
}

/// Creates or edits a group. Returns the saved group, a group with an
/// empty id when it was deleted, or null.
Future<pb.SecretGroup?> showGroupEditor(BuildContext context, {pb.SecretGroup? group, int entries = 0}) {
  final form = GlobalKey<_GroupFormState>();
  final saving = ValueNotifier(false);
  return showHmModal<pb.SecretGroup>(
    context,
    title: group == null ? tr('New group', 'Новая группа') : tr('Edit group', 'Изменить группу'),
    size: HmModalSize.sm,
    body: (_) => _GroupForm(key: form, group: group, entries: entries, saving: saving),
    actions: (ctx) => [
      HmButton(tr('Cancel', 'Отмена'), variant: HmVariant.neutral, expand: Hm.of(ctx).mobile, onPressed: () => Navigator.pop(ctx)),
      ValueListenableBuilder(
        valueListenable: saving,
        builder: (_, busy, _) => HmButton(
          group == null ? tr('Create', 'Создать') : tr('Save', 'Сохранить'),
          variant: HmVariant.primary,
          loading: busy,
          expand: Hm.of(ctx).mobile,
          onPressed: () async {
            final saved = await form.currentState?.save();
            if (saved != null && ctx.mounted) Navigator.pop(ctx, saved);
          },
        ),
      ),
    ],
  );
}

class _GroupForm extends StatefulWidget {
  const _GroupForm({super.key, required this.group, required this.entries, required this.saving});

  final pb.SecretGroup? group;
  final int entries;
  final ValueNotifier<bool> saving;

  @override
  State<_GroupForm> createState() => _GroupFormState();
}

class _GroupFormState extends State<_GroupForm> {
  late final _name = TextEditingController(text: widget.group?.name ?? '');
  late Uint8List _icon = Uint8List.fromList(widget.group?.icon ?? const []);
  String? _error;
  bool _picking = false;

  late final CoreCubit _core;

  @override
  void initState() {
    super.initState();
    _core = context.read<CoreCubit>();
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _choose() async {
    final c = await pickGroupIcon(context);
    if (c == null) return;
    try {
      final icon = await renderGroupIcon(c.preset.icon, c.color);
      if (!mounted) return;
      setState(() {
        _icon = icon;
        if (_name.text.trim().isEmpty) _name.text = c.preset.label;
      });
    } catch (e) {
      Toasts.error(tr('Could not use this picture', 'Не удалось взять картинку'), '$e');
    }
  }

  Future<void> _pick() async {
    setState(() => _picking = true);
    try {
      final r = await FilePicker.platform.pickFiles(
        type: FileType.image,
        withData: true,
        dialogTitle: tr('Group picture', 'Картинка группы'),
      );
      final bytes = r?.files.firstOrNull?.bytes;
      if (bytes == null) return;
      final icon = await groupIcon(bytes);
      if (mounted) setState(() => _icon = icon);
    } catch (e) {
      Toasts.error(tr('Could not use this picture', 'Не удалось взять картинку'), '$e');
    } finally {
      if (mounted) setState(() => _picking = false);
    }
  }

  Future<pb.SecretGroup?> save() async {
    if (_name.text.trim().isEmpty) {
      setState(() => _error = tr('Enter a name', 'Введите имя'));
      return null;
    }
    widget.saving.value = true;
    try {
      final g = await _core.api.putSecretGroup(pb.SecretGroup(id: widget.group?.id, name: _name.text.trim(), icon: _icon));
      Toasts.success(tr('Group saved', 'Группа сохранена'), g.name);
      return g;
    } catch (e) {
      if (mounted) setState(() => _error = errorText(e));
      return null;
    } finally {
      widget.saving.value = false;
    }
  }

  Future<void> _delete() async {
    final g = widget.group!;
    final ok = await confirm(
      context,
      title: tr('Delete group?', 'Удалить группу?'),
      message: widget.entries == 0
          ? tr('“${g.name}” will be deleted on all devices.', '«${g.name}» будет удалена на всех устройствах.')
          : tr(
              '“${g.name}” will be deleted on all devices. Its ${widget.entries} entries stay, without a group.',
              '«${g.name}» будет удалена на всех устройствах. Записи (${widget.entries}) останутся, без группы.',
            ),
      action: tr('Delete', 'Удалить'),
      destructive: true,
    );
    if (!ok) return;
    try {
      await _core.api.deleteSecretGroup(pb.IdRequest(id: g.id));
      Toasts.success(tr('Group deleted', 'Группа удалена'));
      if (mounted) Navigator.pop(context, pb.SecretGroup());
    } catch (e) {
      Toasts.error(tr('Could not delete', 'Не удалось удалить'), errorText(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    final hm = Hm.of(context);
    final preview = pb.SecretGroup(name: _name.text, icon: _icon);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        HmTextField(
          label: tr('Name', 'Имя'),
          required: true,
          autofocus: widget.group == null,
          controller: _name,
          error: _error,
          onChanged: (_) => setState(() {}),
          onSubmitted: (_) async {
            final saved = await save();
            if (saved != null && context.mounted) Navigator.pop(context, saved);
          },
        ),
        SizedBox(height: hm.gapSm),
        HmFormField(
          label: tr('Picture', 'Картинка'),
          hint: tr('From the gallery, or a file scaled down to 128 px', 'Из галереи или файл, уменьшается до 128 px'),
          child: Row(
            children: [
              GroupAvatar(group: preview, size: 48),
              const SizedBox(width: 12),
              Expanded(
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    HmButton(tr('Choose…', 'Выбрать…'), small: true, icon: Icons.apps, onPressed: _choose),
                    HmButton(
                      tr('From file…', 'С диска…'),
                      small: true,
                      variant: HmVariant.neutral,
                      icon: Icons.upload_file_outlined,
                      loading: _picking,
                      onPressed: _pick,
                    ),
                    if (_icon.isNotEmpty)
                      HmButton(
                        tr('Remove', 'Убрать'),
                        small: true,
                        variant: HmVariant.neutral,
                        onPressed: () => setState(() => _icon = Uint8List(0)),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (widget.group != null) ...[
          SizedBox(height: hm.gapMd),
          Align(
            alignment: Alignment.centerLeft,
            child: HmButton(
              tr('Delete group', 'Удалить группу'),
              small: true,
              variant: HmVariant.red,
              icon: Icons.delete_outline,
              onPressed: _delete,
            ),
          ),
        ],
        if (_picking) Text(tr('Reading the picture…', 'Чтение картинки…'), style: HmText.small.copyWith(color: HmColors.muted)),
      ],
    );
  }
}
