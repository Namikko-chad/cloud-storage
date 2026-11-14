import 'dart:async';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/i18n.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/layout.dart';
import '../../core/theme/typography.dart';
import '../../data/rpc/core_client.dart';
import '../../data/rpc/gen/cloudsync.pbgrpc.dart' as pb;
import '../common/hm.dart';
import '../core/core_cubit.dart';

/// Types shown first: what most people use.
const _popular = ['drive', 'mega', 's3', 'onedrive', 'dropbox', 'yandex', 'pcloud', 'webdav', 'b2', 'box', 'sftp', 'local'];

Future<pb.Backend?> showAddStorage(BuildContext context) {
  final key = GlobalKey<_AddStorageState>();
  return showHmModal<pb.Backend>(
    context,
    title: tr('New storage', 'Новое хранилище'),
    size: HmModalSize.lg,
    dismissible: false,
    body: (_) => _AddStorage(key: key),
    actions: (ctx) => [
      HmButton(tr('Cancel', 'Отмена'), variant: HmVariant.neutral, expand: Hm.of(ctx).mobile, onPressed: () => Navigator.pop(ctx)),
      _SubmitButton(form: key),
    ],
  );
}

class _SubmitButton extends StatefulWidget {
  const _SubmitButton({required this.form});

  final GlobalKey<_AddStorageState> form;

  @override
  State<_SubmitButton> createState() => _SubmitButtonState();
}

class _SubmitButtonState extends State<_SubmitButton> {
  bool _busy = false;

  @override
  Widget build(BuildContext context) => HmButton(
    tr('Check and add', 'Проверить и добавить'),
    variant: HmVariant.primary,
    loading: _busy,
    expand: Hm.of(context).mobile,
    onPressed: () async {
      setState(() => _busy = true);
      final b = await widget.form.currentState?.submit();
      if (!context.mounted) return;
      setState(() => _busy = false);
      if (b != null) Navigator.pop(context, b);
    },
  );
}

class _AddStorage extends StatefulWidget {
  const _AddStorage({super.key});

  @override
  State<_AddStorage> createState() => _AddStorageState();
}

class _AddStorageState extends State<_AddStorage> {
  List<pb.BackendType>? _types;
  pb.BackendType? _type;
  final _name = TextEditingController();
  final _domain = TextEditingController();
  final _root = TextEditingController();
  final _params = <String, TextEditingController>{};
  final _choices = <String, String>{};
  bool _advanced = false;
  String? _error;
  final _errors = <String, String>{};

  String? _token;
  String _account = ''; // who the browser sign-in was for
  StreamSubscription<pb.AuthorizeReply>? _auth;
  bool _signingIn = false;
  String? _authUrl;

  // Read once in initState: handlers use it after awaits, when the screen
  // may already be gone and context.read would throw.
  late final CoreCubit _core;

  @override
  void initState() {
    super.initState();
    _core = context.read<CoreCubit>();
    _core.api
        .backendTypes(pb.Empty())
        .then(
          (r) {
            final list = [...r.types];
            int rank(pb.BackendType t) {
              final i = _popular.indexOf(t.name);
              return i < 0 ? 1000 : i;
            }

            list.sort((a, b) => rank(a) != rank(b) ? rank(a) - rank(b) : a.name.compareTo(b.name));
            if (mounted) setState(() => _types = list);
          },
          onError: (Object e) {
            if (mounted) setState(() => _error = errorText(e));
          },
        );
  }

  @override
  void dispose() {
    _auth?.cancel();
    for (final c in [_name, _domain, _root, ..._params.values]) {
      c.dispose();
    }
    super.dispose();
  }

  void _select(String name) {
    final t = _types!.firstWhere((t) => t.name == name);
    _auth?.cancel();
    setState(() {
      _type = t;
      _token = null;
      _account = '';
      _signingIn = false;
      _authUrl = null;
      _errors.clear();
      _choices.clear();
      for (final c in _params.values) {
        c.dispose();
      }
      _params.clear();
      for (final o in t.options) {
        if (o.name == 'token') continue;
        _params[o.name] = TextEditingController();
      }
      final taken = (_core.state.status?.backends ?? []).where((b) => b.type == t.name).length;
      _name.text = taken == 0 ? _label(t) : '${_label(t)} ${taken + 1}';
    });
  }

  static String _label(pb.BackendType t) => switch (t.name) {
    'drive' => 'Google Drive',
    'mega' => 'Mega',
    's3' => 'S3',
    'onedrive' => 'OneDrive',
    'dropbox' => 'Dropbox',
    'yandex' => tr('Yandex Disk', 'Яндекс Диск'),
    'pcloud' => 'pCloud',
    'webdav' => 'WebDAV',
    'b2' => 'Backblaze B2',
    'box' => 'Box',
    'sftp' => 'SFTP',
    'local' => tr('Local folder', 'Локальная папка'),
    _ => t.name,
  };

  Future<void> _signIn() async {
    final t = _type!;
    await _auth?.cancel();
    setState(() {
      _signingIn = true;
      _error = null;
      _authUrl = null;
    });
    final params = <String, String>{
      for (final n in const ['client_id', 'client_secret'])
        if ((_params[n]?.text ?? '').isNotEmpty) n: _params[n]!.text,
    };
    _auth = _core.api
        .authorize(pb.AuthorizeRequest(type: t.name, params: params.entries))
        .listen(
          (r) async {
            if (r.url.isNotEmpty) {
              setState(() => _authUrl = r.url);
              await launchUrl(Uri.parse(r.url), mode: LaunchMode.externalApplication);
            }
            if (r.token.isNotEmpty && mounted) {
              setState(() {
                _token = r.token;
                _account = r.account;
                _signingIn = false;
              });
            }
          },
          onError: (Object e) {
            if (mounted) {
              setState(() {
                _signingIn = false;
                _error = tr('Sign-in failed: ', 'Вход не удался: ') + errorText(e);
              });
            }
          },
          onDone: () {
            if (mounted) setState(() => _signingIn = false);
          },
        );
  }

  /// Validates, then asks the core to open the storage and add it.
  Future<pb.Backend?> submit() async {
    final t = _type;
    _errors.clear();
    if (t == null) {
      setState(() => _error = tr('Choose a storage type', 'Выберите тип хранилища'));
      return null;
    }
    if (_name.text.trim().isEmpty) _errors['name'] = tr('Enter a name', 'Введите название');
    if (t.name == 'local' && !_root.text.trim().startsWith('/') && !RegExp(r'^[A-Za-z]:[\\/]').hasMatch(_root.text.trim())) {
      _errors['root'] = tr('An absolute path is needed', 'Нужен абсолютный путь');
    }
    for (final o in t.options) {
      if (o.name == 'token') continue;
      if (o.required && _value(o).isEmpty) _errors[o.name] = tr('Required', 'Обязательное поле');
    }
    if (t.oauth && _token == null && (_params['token']?.text ?? '').isEmpty) {
      _error = tr('Sign in to the account in the browser', 'Войдите в аккаунт через браузер');
    } else {
      _error = null;
    }
    setState(() {});
    if (_errors.isNotEmpty || _error != null) return null;
    final params = <String, String>{
      for (final o in t.options)
        if (o.name != 'token' && _value(o).isNotEmpty) o.name: _value(o),
      'token': ?_token,
    };
    try {
      return await _core.api.addBackend(
        pb.AddBackendRequest(
          name: _name.text.trim(),
          type: t.name,
          domain: _domain.text.trim(),
          root: _root.text.trim(),
          params: params.entries,
          account: _account,
        ),
      );
    } catch (e) {
      if (mounted) setState(() => _error = errorText(e));
      return null;
    }
  }

  Future<void> _pickRoot() async {
    final dir = await FilePicker.platform.getDirectoryPath(dialogTitle: tr('Folder for the storage', 'Папка для хранилища'));
    if (dir != null && mounted) setState(() => _root.text = dir);
  }

  String _value(pb.BackendOption o) => (_choices[o.name] ?? _params[o.name]?.text ?? '').trim();

  @override
  Widget build(BuildContext context) {
    final hm = Hm.of(context);
    final types = _types;
    if (types == null) return SizedBox(height: 200, child: _error == null ? const HmLoading() : HmBanner(_error!, tone: HmTone.error));
    final t = _type;
    final gap = SizedBox(height: hm.gapSm);
    final options = t == null ? <pb.BackendOption>[] : t.options.where((o) => o.name != 'token').toList();
    final basic = options.where((o) => !o.advanced || o.required).toList();
    final extra = options.where((o) => o.advanced && !o.required).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_error != null) ...[HmBanner(_error!, tone: HmTone.error), gap],
        HmSelect<String>(
          label: tr('Type', 'Тип'),
          required: true,
          options: {for (final x in types) x.name: _label(x)},
          describe: (n) => types.firstWhere((x) => x.name == n).description,
          value: t?.name,
          onChanged: _select,
        ),
        if (t != null) ...[
          gap,
          HmTextField(
            label: tr('Name', 'Название'),
            required: true,
            controller: _name,
            error: _errors['name'],
            hint: tr('For example “Mega work”: only you see it', 'Например «Mega рабочий»: видно только вам'),
          ),
          gap,
          HmTextField(
            label: tr('Failure zone', 'Зона отказа'),
            controller: _domain,
            identifier: true,
            placeholder: t.name,
            hint: tr(
              'What fails together: the type by default. Two accounts of one provider are one zone.',
              'Что откажет вместе: по умолчанию — тип. Два аккаунта одного провайдера — одна зона.',
            ),
          ),
          gap,
          if (t.name == 'local') ...[
            HmTextField(
              label: tr('Folder on this device', 'Папка на этом устройстве'),
              required: true,
              controller: _root,
              identifier: true,
              error: _errors['root'],
              placeholder: '/mnt/disk/cloudsync',
              hint: tr(
                'Absolute path. Better another disk: a copy on the same disk does not survive its failure.',
                'Абсолютный путь. Лучше другой диск: копия на том же диске не защищает от его отказа.',
              ),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: HmButton(tr('Choose folder…', 'Выбрать папку…'), small: true, icon: Icons.folder_open_outlined, onPressed: _pickRoot),
            ),
          ] else
            HmTextField(
              label: tr('Folder in the account', 'Папка в аккаунте'),
              controller: _root,
              identifier: true,
              placeholder: 'cloudsync',
            ),
          if (t.oauth) ...[
            const SizedBox(height: 24),
            HmSectionTitle(tr('Account sign-in', 'Вход в аккаунт')),
            gap,
            if (_token != null)
              HmBanner(
                _account.isEmpty
                    ? tr('Signed in, access granted.', 'Вход выполнен, доступ получен.')
                    : tr('Signed in as $_account, access granted.', 'Вход выполнен как $_account, доступ получен.'),
                tone: HmTone.ok,
              )
            else ...[
              Text(
                tr(
                  'A browser opens on this device. After you sign in, the provider gives the app access.',
                  'Откроется браузер на этом устройстве. После входа провайдер вернёт доступ в приложение.',
                ),
                style: HmText.small.copyWith(height: 1.5),
              ),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerLeft,
                child: HmButton(
                  _signingIn ? tr('Waiting for sign-in…', 'Ожидание входа…') : tr('Sign in with browser', 'Войти через браузер'),
                  icon: Icons.login,
                  loading: _signingIn,
                  onPressed: _signIn,
                ),
              ),
              if (_authUrl != null) ...[
                const SizedBox(height: 8),
                SelectableText(
                  tr('If the browser did not open: ', 'Если браузер не открылся: ') + _authUrl!,
                  style: HmText.jb(11, color: HmColors.muted),
                ),
              ],
            ],
          ],
          if (basic.isNotEmpty) ...[
            const SizedBox(height: 24),
            HmSectionTitle(tr('Options', 'Параметры')),
            for (final o in basic) ...[gap, _option(o)],
          ],
          if (extra.isNotEmpty) ...[
            const SizedBox(height: 16),
            HmToggleRow(
              label: tr('Advanced options', 'Дополнительные параметры'),
              hint: tr('${extra.length}; usually not needed', '${extra.length} шт.; обычно не нужны'),
              value: _advanced,
              onChanged: (v) => setState(() => _advanced = v),
            ),
            if (_advanced)
              for (final o in extra) ...[gap, _option(o)],
          ],
        ],
      ],
    );
  }

  Widget _option(pb.BackendOption o) {
    final help = o.help.split('\n').first;
    if (o.examples.isNotEmpty && !o.password) {
      return HmSelect<String>(
        label: o.name,
        required: o.required,
        hint: help,
        options: {for (final e in o.examples) e: e.isEmpty ? tr('(empty)', '(пусто)') : e},
        value: _choices[o.name] ?? (o.default_3.isEmpty ? null : o.default_3),
        placeholder: o.default_3.isEmpty ? null : o.default_3,
        onChanged: (v) => setState(() => _choices[o.name] = v),
      );
    }
    return HmTextField(
      label: o.name,
      required: o.required,
      password: o.password,
      identifier: true,
      controller: _params[o.name],
      placeholder: o.default_3.isEmpty ? null : o.default_3,
      error: _errors[o.name],
      hint: help,
    );
  }
}
