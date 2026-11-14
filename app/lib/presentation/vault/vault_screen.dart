import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/desktop/desktop_window.dart';
import '../../core/i18n.dart';
import '../../core/settings/app_settings.dart';
import '../../core/format.dart';
import '../../core/theme/layout.dart';
import '../../core/theme/typography.dart';
import '../../data/biometric.dart';
import '../../data/rpc/core_client.dart';
import '../../data/rpc/gen/cloudsync.pbgrpc.dart' as pb;
import '../common/hm.dart';
import '../core/core_cubit.dart';
import '../shell/app_shell.dart' show AppShell, BuildInfo, Section, StatusPills;

/// The vault and this device: the "profile" of the app (§ 4.6). On phones
/// it also carries the status block of the footer (App. D).
class VaultScreen extends StatefulWidget {
  const VaultScreen({super.key, required this.onLock});

  final VoidCallback onLock;

  @override
  State<VaultScreen> createState() => _VaultScreenState();
}

class _VaultScreenState extends State<VaultScreen> {
  final _old = TextEditingController();
  final _new = TextEditingController();
  final _repeat = TextEditingController();
  final _errors = <String, String>{};
  String? _formError;
  bool _changing = false, _exporting = false, _mounting = false;
  final _mount = TextEditingController();
  String? _mountShown; // last value from the core put into _mount
  String? _mountError;

  // Read once in initState: handlers use it after awaits, when the screen
  // may already be gone and context.read would throw.
  late final CoreCubit _core;

  @override
  void initState() {
    super.initState();
    _core = context.read<CoreCubit>();
    // A fingerprint may have been enrolled since the app started.
    Biometric.refresh().then((_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    for (final c in [_old, _new, _repeat, _mount]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _changePassword() async {
    _errors.clear();
    if (_old.text.isEmpty) _errors['old'] = tr('Enter the current password', 'Введите текущий пароль');
    if (_new.text.length < 8) _errors['new'] = tr('At least 8 characters', 'Не короче 8 символов');
    if (_repeat.text != _new.text) _errors['repeat'] = tr('Passwords do not match', 'Пароли не совпадают');
    setState(() => _formError = null);
    if (_errors.isNotEmpty) return;
    setState(() => _changing = true);
    try {
      await _core.api.changePassword(pb.ChangePasswordRequest(oldPassword: _old.text, newPassword: _new.text));
      // The fingerprint keeps the old password: seal the new one (or drop it).
      if (Biometric.enabled && await Biometric.enable(_new.text) != BioResult.ok) await Biometric.disable();
      if (mounted) setState(() {});
      for (final c in [_old, _new, _repeat]) {
        c.clear();
      }
      Toasts.success(
        tr('Password changed', 'Пароль изменён'),
        tr('other devices will ask for the new password', 'другие устройства попросят новый пароль'),
      );
    } catch (e) {
      setState(() => _formError = errorText(e));
    } finally {
      if (mounted) setState(() => _changing = false);
    }
  }

  Future<void> _setBiometric(bool on) async {
    if (!on) {
      await Biometric.disable();
      await AppSettings.instance.setBiometricDeclined(true);
      if (mounted) setState(() {});
      return;
    }
    final password = await _askPassword();
    if (password == null || !mounted) return;
    final r = await Biometric.enable(password);
    if (r == BioResult.ok) {
      await AppSettings.instance.setBiometricDeclined(false);
      Toasts.success(tr('Fingerprint unlock is on', 'Вход по отпечатку включён'));
    } else if (r == BioResult.failed) {
      Toasts.error(tr('Could not turn on fingerprint unlock', 'Не удалось включить вход по отпечатку'));
    }
    if (mounted) setState(() {});
  }

  /// The vault password, to be sealed for fingerprint unlock. It is checked
  /// against the vault file, so a typo is not saved.
  Future<String?> _askPassword() {
    final c = TextEditingController();
    String? error;
    return showHmModal<String>(
      context,
      title: tr('Unlock with fingerprint', 'Вход по отпечатку'),
      size: HmModalSize.sm,
      body: (ctx) => StatefulBuilder(
        builder: (ctx, set) {
          Future<void> submit() async {
            if (c.text.isEmpty) return set(() => error = tr('Enter the password', 'Введите пароль'));
            try {
              await _core.api.checkPassword(pb.CheckPasswordRequest(password: c.text));
              if (ctx.mounted) Navigator.pop(ctx, c.text);
            } catch (e) {
              set(() => error = errorText(e));
            }
          }

          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              HmTextField(
                label: tr('Vault password', 'Пароль vault'),
                required: true,
                password: true,
                autofocus: true,
                controller: c,
                error: error,
                onSubmitted: (_) => submit(),
              ),
              const SizedBox(height: 16),
              HmButton(tr('Continue', 'Продолжить'), variant: HmVariant.primary, onPressed: submit),
            ],
          );
        },
      ),
    ).whenComplete(c.dispose);
  }

  Future<void> _export() async {
    setState(() => _exporting = true);
    try {
      final f = await _core.api.exportVault(pb.Empty());
      final bytes = Uint8List.fromList(f.vault);
      final path = await FilePicker.platform.saveFile(dialogTitle: tr('Save vault', 'Сохранить vault'), fileName: 'vault.cs', bytes: bytes);
      if (path == null) return;
      if (!Platform.isAndroid) await File(path).writeAsBytes(bytes, flush: true);
      Toasts.success(tr('Vault saved', 'Vault сохранён'), path);
    } catch (e) {
      Toasts.error(tr('Export failed', 'Экспорт не удался'), errorText(e));
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  Future<void> _pickMount() async {
    final dir = await FilePicker.platform.getDirectoryPath(dialogTitle: tr('Folder for the vault', 'Папка для vault'));
    if (dir != null && mounted) setState(() => _mount.text = dir);
  }

  Future<void> _applyMount() async {
    final dir = _mount.text.trim();
    if (dir.isNotEmpty && !dir.startsWith('/') && !RegExp(r'^[A-Za-z]:[\\/]').hasMatch(dir)) {
      setState(() => _mountError = tr('An absolute path is needed', 'Нужен абсолютный путь'));
      return;
    }
    setState(() {
      _mountError = null;
      _mounting = true;
    });
    try {
      await _core.api.setMountPoint(pb.PathRequest(path: dir));
      await _core.refreshState();
      Toasts.success(
        tr('Folder changed', 'Папка изменена'),
        dir.isEmpty ? tr('the vault is not shown as a folder', 'vault не показывается папкой') : dir,
      );
    } catch (e) {
      setState(() => _mountError = errorText(e));
    } finally {
      if (mounted) setState(() => _mounting = false);
    }
  }

  Future<void> _stopService() async {
    final ok = await confirm(
      context,
      title: tr('Stop the background service?', 'Остановить фоновую службу?'),
      message: tr(
        'Sync stops, the vault locks and its folder is unmounted. Edits not uploaded yet stay queued and go out after the next start.',
        'Синхронизация остановится, vault заблокируется, папка отмонтируется. Ещё не загруженные правки останутся в очереди и уйдут после следующего запуска.',
      ),
      action: tr('Stop', 'Остановить'),
      destructive: true,
    );
    if (ok) await _core.stopService();
  }

  /// App preferences of this device and the vault folder (desktop).
  Widget _settings(pb.State s, Widget gap) {
    final hm = Hm.of(context);
    final settings = AppSettings.instance;
    if (s.canMount && _mountShown != s.mountDir) {
      _mountShown = s.mountDir;
      _mount.text = s.mountDir;
    }
    return ListenableBuilder(
      listenable: settings,
      builder: (context, _) => HmCard(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            HmSectionTitle(tr('Settings', 'Настройки')),
            gap,
            HmField(
              tr('Language', 'Язык'),
              Align(
                alignment: Alignment.centerLeft,
                child: HmSegmented<Lang>(
                  options: const {Lang.en: 'English', Lang.ru: 'Русский'},
                  value: settings.language,
                  onChanged: settings.setLanguage,
                ),
              ),
            ),
            if (Biometric.available) ...[
              gap,
              HmToggleRow(
                label: tr('Unlock with fingerprint', 'Вход по отпечатку'),
                hint: tr(
                  'The password is kept encrypted in the Android Keystore and opens only after a fingerprint check.',
                  'Пароль хранится зашифрованным в Android Keystore и открывается только после проверки отпечатка.',
                ),
                value: Biometric.enabled,
                onChanged: _setBiometric,
              ),
            ],
            if (DesktopWindow.supported) ...[
              gap,
              HmToggleRow(
                label: tr('Minimize to tray on close', 'Сворачивать в трей при закрытии'),
                hint: tr(
                  'The close button hides the window; quit from the tray icon menu. Sync runs in the background either way.',
                  'Кнопка закрытия прячет окно; выйти можно из меню значка в трее. Синхронизация в фоне идёт в любом случае.',
                ),
                value: settings.closeToTray,
                onChanged: settings.setCloseToTray,
              ),
            ],
            if (DesktopWindow.supported) ...[
              const SizedBox(height: 16),
              HmField(
                tr('Background service', 'Фоновая служба'),
                Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      tr('cloudsyncd: syncs and shows the folder', 'cloudsyncd: синхронизирует и показывает папку'),
                      style: HmText.small,
                    ),
                    HmButton(
                      tr('Stop', 'Остановить'),
                      small: true,
                      variant: HmVariant.red,
                      icon: Icons.stop_circle_outlined,
                      onPressed: _stopService,
                    ),
                  ],
                ),
              ),
            ],
            if (s.canMount) ...[
              const SizedBox(height: 16),
              HmTextField(
                label: tr('Vault folder on this device', 'Папка vault на этом устройстве'),
                controller: _mount,
                identifier: true,
                error: _mountError,
                placeholder: tr('empty: do not show as a folder', 'пусто: не показывать папкой'),
                hint: tr(
                  'Where your files appear. It must be empty (or not exist yet); the vault is remounted at once.',
                  'Где видны ваши файлы. Папка должна быть пустой (или ещё не существовать); vault перемонтируется сразу.',
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: hm.mobile ? WrapAlignment.start : WrapAlignment.end,
                children: [
                  HmButton(tr('Choose folder…', 'Выбрать папку…'), small: true, icon: Icons.folder_open_outlined, onPressed: _pickMount),
                  HmButton(tr('Apply', 'Применить'), small: true, variant: HmVariant.primary, loading: _mounting, onPressed: _applyMount),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hm = Hm.of(context);
    final core = context.watch<CoreCubit>().state;
    final s = core.state ?? pb.State();
    final st = core.status;
    final gap = SizedBox(height: hm.gapSm);
    return HmPage(
      children: [
        const HmPageTitle('Vault'),
        HmCard(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              HmSectionTitle(tr('This device', 'Это устройство')),
              gap,
              HmField(tr('Name', 'Имя'), Text(s.deviceName)),
              HmField('ID', SelectableText(s.deviceId.isEmpty ? '—' : s.deviceId)),
              HmField(tr('Platform', 'Платформа'), Text(platformName(s.platform))),
              if (s.mountPoint.isNotEmpty)
                HmField(
                  tr('Folder', 'Папка'),
                  Wrap(
                    spacing: 12,
                    runSpacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      SelectableText(s.mountPoint),
                      HmButton(
                        tr('Open', 'Открыть'),
                        small: true,
                        icon: Icons.folder_open_outlined,
                        onPressed: () => launchUrl(Uri.directory(s.mountPoint)),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 16),
              const HmSectionTitle('Vault'),
              gap,
              HmField('ID', SelectableText(s.vaultId)),
              HmField(tr('File', 'Файл'), SelectableText(s.vaultPath)),
              HmField(tr('Version', 'Версия'), Text('${st?.vaultVersion ?? '—'}')),
              HmField(tr('Scheme', 'Схема'), Text(st == null ? '—' : '${st.dataShards}+${st.parityShards}')),
            ],
          ),
        ),
        _settings(s, gap),
        HmCard(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              HmSectionTitle(tr('New device', 'Новое устройство')),
              gap,
              Text(
                tr(
                  'To connect another device, copy the vault file to it and enter the password. Without the password the file is useless.',
                  'Чтобы подключить другое устройство, перенесите на него файл vault и введите пароль. Без пароля файл бесполезен.',
                ),
                style: HmText.small.copyWith(height: 1.5),
              ),
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerRight,
                child: HmButton(
                  tr('Export vault', 'Экспортировать vault'),
                  icon: Icons.ios_share,
                  loading: _exporting,
                  expand: hm.mobile,
                  onPressed: _export,
                ),
              ),
            ],
          ),
        ),
        HmCard(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              HmSectionTitle(tr('Password', 'Пароль')),
              gap,
              if (_formError != null) ...[HmBanner(_formError!, tone: HmTone.error), gap],
              HmTextField(
                label: tr('Current password', 'Текущий пароль'),
                required: true,
                password: true,
                controller: _old,
                error: _errors['old'],
              ),
              gap,
              HmTextField(
                label: tr('New password', 'Новый пароль'),
                required: true,
                password: true,
                controller: _new,
                error: _errors['new'],
              ),
              gap,
              HmTextField(label: tr('Repeat', 'Повторите'), required: true, password: true, controller: _repeat, error: _errors['repeat']),
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerRight,
                child: HmButton(
                  tr('Change password', 'Сменить пароль'),
                  variant: HmVariant.primary,
                  loading: _changing,
                  expand: hm.mobile,
                  onPressed: _changePassword,
                ),
              ),
            ],
          ),
        ),
        if (hm.mobile) ...[
          // The footer's slots live here on phones (M6, App. D).
          HmCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                HmSectionTitle(tr('Status', 'Статус')),
                gap,
                DefaultTextStyle(
                  style: HmText.footer,
                  child: BuildInfo(core: core),
                ),
                const SizedBox(height: 12),
                StatusPills(core: core),
                const SizedBox(height: 12),
                HmButton(
                  tr('Log', 'Журнал'),
                  icon: Icons.receipt_long_outlined,
                  expand: true,
                  onPressed: () => AppShell.go(context, Section.log),
                ),
              ],
            ),
          ),
          HmButton(tr('Lock', 'Заблокировать'), variant: HmVariant.red, icon: Icons.lock_outline, expand: true, onPressed: widget.onLock),
        ],
      ],
    );
  }
}
