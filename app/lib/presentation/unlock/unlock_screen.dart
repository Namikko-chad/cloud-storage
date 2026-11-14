import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:grpc/grpc.dart';

import '../../core/i18n.dart';
import '../../core/settings/app_settings.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/layout.dart';
import '../../core/theme/typography.dart';
import '../../data/biometric.dart';
import '../../data/rpc/core_client.dart';
import '../../data/rpc/gen/cloudsync.pbgrpc.dart' as pb;
import '../common/hm.dart';
import '../core/core_cubit.dart';

String defaultDeviceName() {
  if (Platform.isAndroid) return 'Android';
  try {
    return Platform.localHostname;
  } catch (_) {
    return Platform.operatingSystem;
  }
}

/// After the password was entered once: offers to unlock by fingerprint
/// next time (Android, a fingerprint is enrolled, not declined before).
Future<void> offerBiometric(BuildContext context, String password) async {
  await Biometric.refresh();
  if (!Biometric.available || Biometric.enabled || AppSettings.instance.biometricDeclined) return;
  if (!context.mounted) return;
  final yes = await confirm(
    context,
    title: tr('Unlock with fingerprint?', 'Входить по отпечатку?'),
    message: tr(
      'Next time the vault opens with your fingerprint. The password is kept encrypted on this phone, in the Android Keystore; it opens only after a fingerprint check.',
      'В следующий раз vault откроется по отпечатку пальца. Пароль хранится на этом телефоне в зашифрованном виде (Android Keystore) и открывается только после проверки отпечатка.',
    ),
    action: tr('Turn on', 'Включить'),
  );
  if (!yes) {
    await AppSettings.instance.setBiometricDeclined(true);
    return;
  }
  final r = await Biometric.enable(password);
  if (r == BioResult.ok) {
    Toasts.success(tr('Fingerprint unlock is on', 'Вход по отпечатку включён'));
  } else if (r == BioResult.failed) {
    Toasts.error(tr('Could not turn on fingerprint unlock', 'Не удалось включить вход по отпечатку'));
  }
}

/// Shown while the vault is locked, missing, or the core is unreachable.
class UnlockScreen extends StatelessWidget {
  const UnlockScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final core = context.watch<CoreCubit>().state;
    final hm = Hm.of(context);
    final Widget card = switch (core.conn) {
      Conn.failed => const _NoCore(),
      Conn.connecting => const SizedBox(height: 240, child: HmLoading()),
      Conn.ready when core.state?.vaultExists ?? false => const _Unlock(),
      Conn.ready => const _Setup(),
    };
    return HmPage(
      children: [
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(height: hm.mobile ? 8 : 40),
                card,
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _NoCore extends StatelessWidget {
  const _NoCore();

  @override
  Widget build(BuildContext context) {
    final core = context.watch<CoreCubit>().state;
    final hint = Platform.isAndroid
        ? tr('The core runs inside the app; try again.', 'Ядро работает внутри приложения; попробуйте ещё раз.')
        : tr(
            'The app starts cloudsyncd itself. It must be next to the app, in PATH or in \$CLOUDSYNCD.',
            'Приложение запускает cloudsyncd само. Он должен лежать рядом с приложением, в PATH или в \$CLOUDSYNCD.',
          );
    return HmCard(
      accent: core.stopped ? HmAccent.active : HmAccent.error,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          HmPageTitle(
            core.stopped
                ? tr('Background service stopped', 'Фоновая служба остановлена')
                : tr('No connection to the core', 'Нет связи с ядром'),
          ),
          const SizedBox(height: 16),
          if (core.stopped)
            Text(
              tr(
                'Sync is off and the vault is locked. Start the service to continue.',
                'Синхронизация выключена, vault заблокирован. Запустите службу, чтобы продолжить.',
              ),
              style: HmText.small.copyWith(height: 1.5),
            )
          else ...[
            HmBanner(core.error ?? tr('The core is not responding', 'Ядро не отвечает'), tone: HmTone.error),
            const SizedBox(height: 12),
            Text(hint, style: HmText.small.copyWith(height: 1.5)),
          ],
          const SizedBox(height: 20),
          Align(
            alignment: Alignment.centerRight,
            child: HmButton(
              core.stopped ? tr('Start service', 'Запустить службу') : tr('Retry', 'Повторить'),
              variant: HmVariant.primary,
              icon: core.stopped ? Icons.play_arrow : Icons.refresh,
              onPressed: () => context.read<CoreCubit>().connect(),
            ),
          ),
        ],
      ),
    );
  }
}

class _Unlock extends StatefulWidget {
  const _Unlock();

  @override
  State<_Unlock> createState() => _UnlockState();
}

class _UnlockState extends State<_Unlock> {
  final _password = TextEditingController();
  final _device = TextEditingController(text: defaultDeviceName());
  bool _busy = false;
  String? _error;

  bool get _bio => Biometric.available && Biometric.enabled;

  @override
  void initState() {
    super.initState();
    // Saved for fingerprint unlock: ask for the finger right away.
    if (_bio) WidgetsBinding.instance.addPostFrameCallback((_) => _fingerprint());
  }

  @override
  void dispose() {
    _password.dispose();
    _device.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_password.text.isEmpty) {
      setState(() => _error = tr('Enter the password', 'Введите пароль'));
      return;
    }
    await _unlock(_password.text, byFingerprint: false);
  }

  Future<void> _fingerprint() async {
    if (_busy) return;
    setState(() => _error = null);
    final (password, r) = await Biometric.unlock();
    if (!mounted) return;
    switch (r) {
      case BioResult.ok:
        await _unlock(password!, byFingerprint: true);
      case BioResult.canceled:
        setState(() {});
      case BioResult.invalidated:
        setState(
          () => _error = tr(
            'Fingerprints on this phone have changed. Enter the password to turn fingerprint unlock on again.',
            'Отпечатки на телефоне изменились. Введите пароль, чтобы снова включить вход по отпечатку.',
          ),
        );
      case BioResult.failed:
        await Biometric.refresh();
        if (mounted) setState(() => _error = tr('Fingerprint check failed', 'Не удалось проверить отпечаток'));
    }
  }

  Future<void> _unlock(String password, {required bool byFingerprint}) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    final core = context.read<CoreCubit>();
    try {
      final st = await core.api.unlock(pb.UnlockRequest(password: password, deviceName: _device.text.trim()));
      if (!byFingerprint && mounted) await offerBiometric(context, password);
      core.adopt(st);
    } catch (e) {
      // The saved password no longer opens the vault (changed on another device).
      final stale = byFingerprint && e is GrpcError && e.code == StatusCode.permissionDenied;
      if (stale) await Biometric.disable();
      if (mounted) {
        setState(
          () => _error = stale
              ? tr(
                  'The vault password has changed. Enter the new one.',
                  'Пароль vault изменился. Введите новый.',
                )
              : errorText(e),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final hm = Hm.of(context);
    final path = context.watch<CoreCubit>().state.state?.vaultPath ?? '';
    return HmCard(
      accent: HmAccent.total,
      padding: EdgeInsets.all(hm.mobile ? 16 : 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          HmPageTitle(tr('Unlock vault', 'Разблокировать vault')),
          const SizedBox(height: 8),
          Text(path, style: HmText.small, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 20),
          HmTextField(
            label: tr('Password', 'Пароль'),
            required: true,
            password: true,
            autofocus: !_bio,
            controller: _password,
            error: _error,
            onSubmitted: (_) => _submit(),
          ),
          SizedBox(height: hm.gapSm),
          HmTextField(
            label: tr('Device name', 'Имя устройства'),
            controller: _device,
            hint: tr('Shown to other devices in locks and conflict copies', 'Видно другим устройствам в блокировках и конфликтных копиях'),
          ),
          const SizedBox(height: 24),
          _Actions(
            children: [
              if (_bio)
                HmButton(
                  tr('Fingerprint', 'Отпечаток'),
                  icon: Icons.fingerprint,
                  expand: hm.mobile,
                  onPressed: _busy ? null : _fingerprint,
                ),
              HmButton(tr('Unlock', 'Разблокировать'), variant: HmVariant.primary, loading: _busy, expand: hm.mobile, onPressed: _submit),
            ],
          ),
        ],
      ),
    );
  }
}

enum _Mode { create, import }

class _Setup extends StatefulWidget {
  const _Setup();

  @override
  State<_Setup> createState() => _SetupState();
}

class _SetupState extends State<_Setup> {
  _Mode _mode = _Mode.create;
  final _password = TextEditingController();
  final _repeat = TextEditingController();
  final _device = TextEditingController(text: defaultDeviceName());
  final _k = TextEditingController(text: '2');
  final _m = TextEditingController(text: '1');
  Uint8List? _file;
  String? _fileName;
  bool _busy = false;
  String? _error;
  final _errors = <String, String>{};

  @override
  void dispose() {
    for (final c in [_password, _repeat, _device, _k, _m]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _pick() async {
    final r = await FilePicker.platform.pickFiles(dialogTitle: tr('Vault file', 'Файл vault'), withData: true);
    final f = r?.files.single;
    if (f?.bytes != null) {
      setState(() {
        _file = f!.bytes;
        _fileName = f.name;
      });
    }
  }

  bool _validate() {
    _errors.clear();
    if (_password.text.length < 8) _errors['password'] = tr('At least 8 characters', 'Не короче 8 символов');
    if (_mode == _Mode.create) {
      if (_repeat.text != _password.text) _errors['repeat'] = tr('Passwords don’t match', 'Пароли не совпадают');
      final k = int.tryParse(_k.text), m = int.tryParse(_m.text);
      if (k == null || k < 1) _errors['k'] = tr('A whole number, 1 or more', 'Целое число от 1');
      if (m == null || m < 1) _errors['m'] = tr('A whole number, 1 or more', 'Целое число от 1');
    } else if (_file == null) {
      _errors['file'] = tr('Choose a vault file', 'Выберите файл vault');
    }
    setState(() {});
    return _errors.isEmpty;
  }

  Future<void> _submit() async {
    if (!_validate()) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    final core = context.read<CoreCubit>();
    try {
      final st = _mode == _Mode.create
          ? await core.api.createVault(
              pb.CreateVaultRequest(
                password: _password.text,
                dataShards: int.parse(_k.text),
                parityShards: int.parse(_m.text),
                deviceName: _device.text.trim(),
              ),
            )
          : await core.api.importVault(pb.ImportVaultRequest(vault: _file, password: _password.text, deviceName: _device.text.trim()));
      if (mounted) await offerBiometric(context, _password.text);
      core.adopt(st);
    } catch (e) {
      if (mounted) setState(() => _error = errorText(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final hm = Hm.of(context);
    final digits = [FilteringTextInputFormatter.digitsOnly];
    final k = int.tryParse(_k.text) ?? 0, m = int.tryParse(_m.text) ?? 0;
    return HmCard(
      accent: HmAccent.total,
      padding: EdgeInsets.all(hm.mobile ? 16 : 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          HmPageTitle(tr('Setup', 'Настройка')),
          const SizedBox(height: 8),
          Text(
            tr(
              'The vault is the only configuration file: the encryption key, storages and devices. It is protected by a password.',
              'Vault — единственный файл конфигурации: ключ шифрования, хранилища и устройства. Он защищён паролем.',
            ),
            style: HmText.small.copyWith(height: 1.5),
          ),
          const SizedBox(height: 20),
          HmSegmented<_Mode>(
            options: {_Mode.create: tr('New vault', 'Новый vault'), _Mode.import: tr('Existing', 'Существующий')},
            value: _mode,
            onChanged: (v) => setState(() {
              _mode = v;
              _errors.clear();
              _error = null;
            }),
          ),
          const SizedBox(height: 20),
          if (_error != null) ...[HmBanner(_error!, tone: HmTone.error), SizedBox(height: hm.gapSm)],
          if (_mode == _Mode.import) ...[
            HmFormField(
              label: tr('Vault file', 'Файл vault'),
              required: true,
              error: _errors['file'],
              hint: tr('Copy vault.cs from another device (Vault → Export)', 'Скопируйте vault.cs с другого устройства (Vault → Экспорт)'),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      _fileName ?? tr('Not selected', 'Не выбран'),
                      style: HmText.body.copyWith(color: _fileName == null ? HmColors.muted : HmColors.text),
                    ),
                  ),
                  HmButton(tr('Choose', 'Выбрать'), icon: Icons.file_open_outlined, onPressed: _pick),
                ],
              ),
            ),
            SizedBox(height: hm.gapSm),
          ],
          HmTextField(label: tr('Password', 'Пароль'), required: true, password: true, controller: _password, error: _errors['password']),
          if (_mode == _Mode.create) ...[
            SizedBox(height: hm.gapSm),
            HmTextField(
              label: tr('Repeat password', 'Повторите пароль'),
              required: true,
              password: true,
              controller: _repeat,
              error: _errors['repeat'],
            ),
            const SizedBox(height: 24),
            HmSectionTitle(tr('Redundancy', 'Избыточность')),
            SizedBox(height: hm.gapSm),
            HmTextField(
              label: tr('Data pieces (k)', 'Частей данных (k)'),
              required: true,
              controller: _k,
              keyboard: TextInputType.number,
              formatters: digits,
              error: _errors['k'],
              onChanged: (_) => setState(() {}),
            ),
            SizedBox(height: hm.gapSm),
            HmTextField(
              label: tr('Parity pieces (m)', 'Частей чётности (m)'),
              required: true,
              controller: _m,
              keyboard: TextInputType.number,
              formatters: digits,
              error: _errors['m'],
              onChanged: (_) => setState(() {}),
              hint: k > 0 && m > 0
                  ? tr(
                      'Storages needed: ${k + m}. Any $m can be lost. Takes ${((k + m) / k).toStringAsFixed(2)}× the space.',
                      'Нужно хранилищ: ${k + m}. Можно потерять любые $m. Занимает ${((k + m) / k).toStringAsFixed(2)}× объёма.',
                    )
                  : tr('m = 1 is like RAID 5', 'm = 1 — как RAID 5'),
            ),
          ],
          SizedBox(height: hm.gapSm),
          HmTextField(label: tr('Device name', 'Имя устройства'), controller: _device),
          const SizedBox(height: 24),
          _Actions(
            children: [
              HmButton(
                _mode == _Mode.create ? tr('Create vault', 'Создать vault') : tr('Connect', 'Подключить'),
                variant: HmVariant.primary,
                loading: _busy,
                expand: hm.mobile,
                onPressed: _submit,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Actions extends StatelessWidget {
  const _Actions({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    if (Hm.of(context).mobile) return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: children.reversed.toList());
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        for (final (i, c) in children.indexed) ...[if (i > 0) const SizedBox(width: 12), c],
      ],
    );
  }
}
