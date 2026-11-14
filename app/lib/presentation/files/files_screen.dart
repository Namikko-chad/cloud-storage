import 'dart:async';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
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

class FilesScreen extends StatefulWidget {
  const FilesScreen({super.key});

  @override
  State<FilesScreen> createState() => _FilesScreenState();
}

class _FilesScreenState extends State<FilesScreen> {
  String _dir = '/';
  List<pb.Entry> _entries = [];
  Map<String, pb.LockInfo> _locks = {};
  bool _loading = true;
  String? _error;
  final _query = TextEditingController();
  List<pb.Entry>? _found; // global search results
  bool _uploading = false;

  // Read once in initState: handlers use it after awaits, when the screen
  // may already be gone and context.read would throw.
  late final CoreCubit _core;

  @override
  void initState() {
    super.initState();
    _core = context.read<CoreCubit>();
    _load();
  }

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  Future<void> _load({bool quiet = false}) async {
    if (!quiet) setState(() => _loading = true);
    try {
      final r = await _core.api.list(pb.PathRequest(path: _dir));
      if (!mounted) return;
      setState(() {
        _entries = r.entries;
        _error = null;
        _loading = false;
      });
      unawaited(_loadLocks());
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = errorText(e);
        _loading = false;
        if (!quiet) _entries = [];
      });
    }
  }

  Future<void> _loadLocks() async {
    final files = _entries.where((e) => !e.dir).map((e) => e.path).toList();
    if (files.isEmpty) return;
    try {
      final r = await _core.api.locks(pb.PathsRequest(paths: files));
      if (mounted) setState(() => _locks = {for (final l in r.locks) l.path: l});
    } catch (_) {}
  }

  void _open(String dir) {
    _query.clear();
    setState(() {
      _dir = dir;
      _found = null;
      _locks = {};
    });
    _load();
  }

  Future<void> _search(String q) async {
    if (q.trim().isEmpty) {
      setState(() => _found = null);
      return;
    }
    try {
      final r = await _core.api.search(pb.SearchRequest(query: q));
      if (mounted) setState(() => _found = r.entries);
    } catch (e) {
      Toasts.error(tr('Search failed', 'Поиск не удался'), errorText(e));
    }
  }

  Future<void> _run(String done, Future<void> Function() op, {bool reload = true}) async {
    try {
      await op();
      if (done.isNotEmpty) Toasts.success(done);
      if (reload) {
        _core.touched();
        await _load(quiet: true);
      }
    } catch (e) {
      Toasts.error(tr('Error', 'Ошибка'), errorText(e));
    }
  }

  Future<void> _upload({bool folder = false}) async {
    List<String> paths;
    if (folder) {
      final d = await FilePicker.platform.getDirectoryPath(dialogTitle: tr('Folder to upload', 'Папка для загрузки'));
      if (d == null) return;
      paths = [d];
    } else {
      final r = await FilePicker.platform.pickFiles(allowMultiple: true, dialogTitle: tr('Files to upload', 'Файлы для загрузки'));
      paths = [for (final f in r?.files ?? <PlatformFile>[]) ?f.path];
    }
    if (paths.isEmpty) return;
    setState(() => _uploading = true);
    try {
      final r = await _core.api.upload(pb.UploadRequest(localPaths: paths, remoteDir: _dir));
      Toasts.success(tr('Uploaded: ${r.files}', 'Загружено: ${r.files}'), tr('to $_dir', 'в $_dir'));
      _core.touched();
      await _load(quiet: true);
    } catch (e) {
      Toasts.error(tr('Upload failed', 'Загрузка не удалась'), errorText(e));
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Future<void> _mkdir() async {
    final name = await _askName(context, title: tr('New folder', 'Новая папка'), action: tr('Create', 'Создать'));
    if (name == null) return;
    await _run(tr('Folder created', 'Папка создана'), () => _core.api.mkdir(pb.PathRequest(path: p.posix.join(_dir, name))));
  }

  Future<void> _rename(pb.Entry e) async {
    final name = await _askName(context, title: tr('Rename', 'Переименовать'), action: tr('Save', 'Сохранить'), initial: e.name);
    if (name == null || name == e.name) return;
    await _run(
      tr('Renamed', 'Переименовано'),
      () => _core.api.rename(pb.RenameRequest(from: e.path, to: p.posix.join(p.posix.dirname(e.path), name))),
    );
  }

  Future<void> _remove(pb.Entry e) async {
    final ok = await confirm(
      context,
      title: e.dir ? tr('Delete folder?', 'Удалить папку?') : tr('Delete file?', 'Удалить файл?'),
      message: e.dir
          ? tr(
              '“${e.name}” and everything in it will be deleted on all devices.',
              '«${e.name}» и всё внутри будут удалены на всех устройствах.',
            )
          : tr('“${e.name}” will be deleted on all devices.', '«${e.name}» будет удалён на всех устройствах.'),
      action: tr('Delete', 'Удалить'),
      destructive: true,
    );
    if (!ok) return;
    await _run(tr('Deleted', 'Удалено'), () => _core.api.remove(pb.RemoveRequest(path: e.path, recursive: e.dir)));
  }

  Future<void> _pin(pb.Entry e) => _run(
    e.pinned
        ? tr('No longer kept on this device', 'Больше не хранится на устройстве')
        : tr('Downloaded and pinned', 'Скачано и закреплено'),
    () => e.pinned ? _core.api.unpin(pb.PathRequest(path: e.path)) : _core.api.pin(pb.PathRequest(path: e.path)),
  );

  /// Keeps a conflict copy: it replaces the file it collided with.
  Future<void> _keep(pb.Entry e) async {
    final ok = await confirm(
      context,
      title: tr('Keep this version?', 'Оставить эту версию?'),
      message: tr(
        '“${p.posix.basename(e.conflictOf)}” will be replaced with this copy.',
        '«${p.posix.basename(e.conflictOf)}» будет заменён этой копией.',
      ),
      action: tr('Keep', 'Оставить'),
    );
    if (!ok) return;
    await _run(tr('Conflict resolved', 'Конфликт разрешён'), () async {
      try {
        await _core.api.remove(pb.RemoveRequest(path: e.conflictOf));
      } catch (_) {} // the original may be gone already
      await _core.api.rename(pb.RenameRequest(from: e.path, to: e.conflictOf));
    });
  }

  Future<void> _saveAs(pb.Entry e) async {
    final dst = e.dir
        ? await FilePicker.platform.getDirectoryPath(dialogTitle: tr('Save to', 'Куда сохранить'))
        : await FilePicker.platform.saveFile(dialogTitle: tr('Save as', 'Сохранить как'), fileName: e.name);
    if (dst == null) return;
    await _run(tr('Saved', 'Сохранено'), () => _core.api.download(pb.DownloadRequest(path: e.path, localPath: dst)), reload: false);
  }

  /// Opens a file in its app. On desktops with a mounted folder the file is
  /// opened there, so edits are saved back and the file is locked while
  /// open; otherwise a copy is downloaded.
  Future<void> _openFile(pb.Entry e) async {
    final mount = _core.state.state?.mountPoint ?? '';
    try {
      if (mount.isNotEmpty && !Platform.isAndroid) {
        final local = p.joinAll([mount, ...p.posix.split(e.path).skip(1)]);
        if (!await launchUrl(Uri.file(local))) throw tr('no app for this file', 'нет приложения для этого файла');
        return;
      }
      final tmp = Directory(p.join((await getTemporaryDirectory()).path, 'cloudsync-open'));
      await tmp.create(recursive: true);
      final local = p.join(tmp.path, e.name);
      Toasts.show(tr('Downloading…', 'Скачивание…'), detail: e.name);
      await _core.api.download(pb.DownloadRequest(path: e.path, localPath: local));
      final r = await OpenFilex.open(local);
      if (r.type != ResultType.done) throw r.message;
    } catch (err) {
      Toasts.error(tr('Could not open', 'Не удалось открыть'), errorText(err));
    }
  }

  void _details(pb.Entry e) {
    if (e.dir) {
      _open(e.path);
      return;
    }
    final devices = _deviceNames();
    showHmModal<void>(
      context,
      title: e.name,
      body: (_) => _Details(entry: e, device: devices[e.device] ?? e.device),
      actions: (ctx) => [
        HmButton(tr('Close', 'Закрыть'), variant: HmVariant.neutral, expand: Hm.of(ctx).mobile, onPressed: () => Navigator.pop(ctx)),
        HmButton(
          tr('Open', 'Открыть'),
          variant: HmVariant.primary,
          icon: Icons.open_in_new,
          expand: Hm.of(ctx).mobile,
          onPressed: () {
            Navigator.pop(ctx);
            _openFile(e);
          },
        ),
      ],
    );
  }

  Map<String, String> _deviceNames() => {for (final d in _core.state.status?.devices ?? <pb.Device>[]) d.id: d.name};

  @override
  Widget build(BuildContext context) {
    final hm = Hm.of(context);
    final devices = _deviceNames();
    final q = _query.text.toLowerCase();
    final items = _found ?? (q.isEmpty ? _entries : _entries.where((e) => e.name.toLowerCase().contains(q)).toList());
    return BlocListener<CoreCubit, CoreState>(
      listenWhen: (a, b) => a.treeRev != b.treeRev,
      listener: (_, _) => _load(quiet: true),
      child: HmPage(
        onRefresh: () => _load(quiet: true),
        children: [
          HmPageTitle(tr('Files', 'Файлы')),
          HmTable<pb.Entry>(
            items: items,
            loading: _loading,
            error: _error,
            emptyText: _found != null
                ? tr('Nothing found', 'Ничего не найдено')
                : (q.isEmpty ? tr('Folder is empty', 'Папка пуста') : tr('No matches in this folder', 'Нет совпадений в этой папке')),
            emptyIcon: _found != null || q.isNotEmpty ? Icons.search_off : Icons.folder_open_outlined,
            emptyAction: _found == null && q.isEmpty && !_loading
                ? HmButton(tr('Upload files', 'Загрузить файлы'), icon: Icons.upload_outlined, onPressed: _upload)
                : null,
            header: _PathBar(dir: _dir, searching: _found != null, onOpen: _open),
            search: HmSearchField(
              controller: _query,
              placeholder: tr('Search… (Enter for everywhere)', 'Поиск… (Enter — везде)'),
              onChanged: (v) => setState(() {
                if (v.isEmpty) _found = null;
              }),
              onSubmitted: _search,
            ),
            controls: [
              HmButton(
                tr('Upload', 'Загрузить'),
                variant: HmVariant.primary,
                icon: Icons.upload_outlined,
                loading: _uploading,
                onPressed: _upload,
              ),
              if (!Platform.isAndroid)
                HmButton(
                  tr('Folder', 'Папку'),
                  icon: Icons.drive_folder_upload_outlined,
                  onPressed: _uploading ? null : () => _upload(folder: true),
                ),
              HmButton(tr('New folder', 'Новая папка'), icon: Icons.create_new_folder_outlined, onPressed: _mkdir),
            ],
            onRefresh: () => _load(),
            onTap: _details,
            rowStatus: (e) => e.conflictOf.isNotEmpty ? HmStatus.error : null,
            columns: [
              HmColumn(
                label: tr('Name', 'Имя'),
                flex: 4,
                minWidth: 220,
                sortKey: (e) => '${e.dir ? 0 : 1}${e.name.toLowerCase()}',
                cell: (e) => _NameCell(entry: e, showPath: _found != null),
              ),
              HmColumn(
                label: tr('Size', 'Размер'),
                minWidth: 90,
                cardIf: (e) => !e.dir,
                sortKey: (e) => e.size.toInt(),
                cell: (e) => Text(e.dir ? '—' : formatSize(e.size.toInt())),
              ),
              HmColumn(
                label: tr('Modified', 'Изменён'),
                flex: 2,
                minWidth: 170,
                sortKey: (e) => e.mtimeUnix.toInt(),
                cell: (e) => Text(formatTime(e.mtimeUnix)),
              ),
              HmColumn(
                label: tr('Device', 'Устройство'),
                flex: 2,
                minWidth: 110,
                mobile: false,
                cell: (e) => Text(devices[e.device] ?? '—'),
              ),
              HmColumn(
                label: tr('Status', 'Состояние'),
                flex: 3,
                minWidth: 180,
                cardIf: (e) => !e.dir || e.pinned,
                cell: (e) => _StateCell(entry: e, lock: _locks[e.path]),
              ),
            ],
            actions: (e) => [
              if (e.conflictOf.isNotEmpty)
                HmActionButton(
                  icon: Icons.check,
                  label: tr('Keep this version', 'Оставить эту версию'),
                  kind: HmAction.success,
                  onPressed: () => _keep(e),
                ),
              HmActionButton(
                icon: e.pinned ? Icons.push_pin : Icons.push_pin_outlined,
                label: e.pinned
                    ? tr('Don’t keep on this device', 'Не хранить на устройстве')
                    : tr('Keep on this device', 'Хранить на устройстве'),
                kind: e.pinned ? HmAction.edit : HmAction.neutral,
                onPressed: () => _pin(e),
              ),
              if (!Platform.isAndroid)
                HmActionButton(
                  icon: Icons.download_outlined,
                  label: tr('Save as…', 'Сохранить как…'),
                  kind: HmAction.neutral,
                  onPressed: () => _saveAs(e),
                ),
              HmActionButton(icon: Icons.edit_outlined, label: tr('Rename', 'Переименовать'), onPressed: () => _rename(e)),
              HmActionButton(
                icon: Icons.delete_outline,
                label: tr('Delete', 'Удалить'),
                kind: HmAction.delete,
                onPressed: () => _remove(e),
              ),
            ],
          ),
          if (hm.mobile) const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _PathBar extends StatelessWidget {
  const _PathBar({required this.dir, required this.searching, required this.onOpen});

  final String dir;
  final bool searching;
  final ValueChanged<String> onOpen;

  @override
  Widget build(BuildContext context) {
    final parts = dir == '/' ? <String>[] : dir.substring(1).split('/');
    final crumbs = <(String, String)>[('/', tr('All files', 'Все файлы'))];
    for (var i = 0; i < parts.length; i++) {
      crumbs.add(('/${parts.sublist(0, i + 1).join('/')}', parts[i]));
    }
    return Align(
      alignment: Alignment.centerLeft,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        reverse: true,
        child: Row(
          children: [
            if (dir != '/' && !searching) ...[
              HmIconButton(icon: Icons.arrow_upward, label: tr('Up', 'Наверх'), onPressed: () => onOpen(p.posix.dirname(dir))),
              const SizedBox(width: 12),
            ],
            for (final (i, c) in crumbs.indexed) ...[
              if (i > 0)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: Text('/', style: HmText.small),
                ),
              _Crumb(label: c.$2, last: i == crumbs.length - 1 && !searching, onTap: () => onOpen(c.$1)),
            ],
            if (searching) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Text('/', style: HmText.small),
              ),
              Text(tr('search results', 'результаты поиска'), style: HmText.bodyStrong),
            ],
          ],
        ),
      ),
    );
  }
}

class _Crumb extends StatelessWidget {
  const _Crumb({required this.label, required this.last, required this.onTap});

  final String label;
  final bool last;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => MouseRegion(
    cursor: last ? MouseCursor.defer : SystemMouseCursors.click,
    child: GestureDetector(
      onTap: last ? null : onTap,
      child: ConstrainedBox(
        constraints: BoxConstraints(minHeight: Hm.of(context).mobile ? 44 : 0),
        child: Center(
          widthFactor: 1,
          child: Text(label, style: last ? HmText.bodyStrong : HmText.body.copyWith(color: HmColors.accent)),
        ),
      ),
    ),
  );
}

class _NameCell extends StatelessWidget {
  const _NameCell({required this.entry, required this.showPath});

  final pb.Entry entry;
  final bool showPath;

  @override
  Widget build(BuildContext context) {
    final e = entry;
    return Row(
      children: [
        Icon(e.dir ? Icons.folder_outlined : _icon(e.name), size: 16, color: e.dir ? HmColors.accent : HmColors.muted),
        const SizedBox(width: 10),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(e.name, overflow: TextOverflow.ellipsis, maxLines: 1),
              if (showPath) Text(p.posix.dirname(e.path), style: HmText.small, overflow: TextOverflow.ellipsis, maxLines: 1),
            ],
          ),
        ),
        if (e.conflictOf.isNotEmpty) ...[const SizedBox(width: 8), HmBadge(tr('conflict', 'конфликт'), tone: HmTone.error)],
      ],
    );
  }

  static IconData _icon(String name) => switch (p.extension(name).toLowerCase()) {
    '.jpg' || '.jpeg' || '.png' || '.gif' || '.webp' || '.heic' => Icons.image_outlined,
    '.mp4' || '.mkv' || '.mov' || '.avi' || '.webm' => Icons.movie_outlined,
    '.mp3' || '.flac' || '.ogg' || '.wav' || '.m4a' => Icons.audiotrack_outlined,
    '.pdf' => Icons.picture_as_pdf_outlined,
    '.zip' || '.tar' || '.gz' || '.7z' || '.rar' => Icons.inventory_2_outlined,
    '.txt' || '.md' || '.doc' || '.docx' || '.odt' || '.rtf' => Icons.description_outlined,
    _ => Icons.insert_drive_file_outlined,
  };
}

class _StateCell extends StatelessWidget {
  const _StateCell({required this.entry, this.lock});

  final pb.Entry entry;
  final pb.LockInfo? lock;

  @override
  Widget build(BuildContext context) {
    final e = entry;
    final badges = <Widget>[
      if (lock != null && lock!.locked)
        HmBadge(
          lock!.mine ? tr('open here', 'открыт здесь') : tr('open: ${lock!.deviceName}', 'открыт: ${lock!.deviceName}'),
          tone: HmTone.warning,
          icon: Icons.lock_outline,
        ),
      if (!e.dir)
        HmBadge(e.local ? tr('on device', 'на устройстве') : tr('in cloud', 'в облаке'), tone: e.local ? HmTone.ok : HmTone.neutral),
      if (e.pinned) HmBadge(tr('pinned', 'закреплён'), tone: HmTone.accent),
    ];
    if (badges.isEmpty) return const SizedBox.shrink();
    return Wrap(spacing: 6, runSpacing: 4, alignment: WrapAlignment.end, children: badges);
  }
}

class _Details extends StatefulWidget {
  const _Details({required this.entry, required this.device});

  final pb.Entry entry;
  final String device;

  @override
  State<_Details> createState() => _DetailsState();
}

class _DetailsState extends State<_Details> {
  pb.LockInfo? _lock;
  String? _lockError;

  @override
  void initState() {
    super.initState();
    context
        .read<CoreCubit>()
        .api
        .lockHolder(pb.PathRequest(path: widget.entry.path))
        .then(
          (l) => mounted ? setState(() => _lock = l) : null,
          onError: (Object e) => mounted ? setState(() => _lockError = errorText(e)) : null,
        );
  }

  @override
  Widget build(BuildContext context) {
    final e = widget.entry;
    final lock = _lock;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (e.conflictOf.isNotEmpty) ...[
          HmBanner(
            tr(
              'Conflict copy: “${p.posix.basename(e.conflictOf)}” was changed on two devices at the same time.',
              'Конфликтная копия: «${p.posix.basename(e.conflictOf)}» изменили на двух устройствах одновременно.',
            ),
            tone: HmTone.warning,
          ),
          const SizedBox(height: 12),
        ],
        HmField(tr('Path', 'Путь'), SelectableText(e.path)),
        HmField(tr('Size', 'Размер'), Text(formatSize(e.size.toInt()))),
        HmField(tr('Modified', 'Изменён'), Text(formatTime(e.mtimeUnix))),
        HmField(tr('Device', 'Устройство'), Text(widget.device)),
        HmField(
          tr('Storage', 'Хранение'),
          Text(
            e.local
                ? tr('fully on this device', 'целиком на этом устройстве')
                : tr('in the cloud, downloaded on open', 'в облаке, скачивается при открытии'),
          ),
        ),
        HmField(tr('Pinned', 'Закреплён'), Text(e.pinned ? tr('yes', 'да') : tr('no', 'нет'))),
        HmField(
          tr('Lock', 'Блокировка'),
          lock == null
              ? Text(_lockError ?? tr('checking…', 'проверка…'), style: HmText.body.copyWith(color: HmColors.muted))
              : lock.locked
              ? Row(
                  children: [
                    HmBadge(
                      lock.mine ? tr('open here', 'открыт здесь') : tr('open', 'открыт'),
                      tone: HmTone.warning,
                      icon: Icons.lock_outline,
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        tr('${lock.deviceName} since ${formatTime(lock.sinceUnix)}', '${lock.deviceName} с ${formatTime(lock.sinceUnix)}'),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                )
              : Text(tr('free', 'свободен')),
        ),
      ],
    );
  }
}

Future<String?> _askName(BuildContext context, {required String title, required String action, String initial = ''}) {
  final c = TextEditingController(text: initial);
  String? error;
  return showHmModal<String>(
    context,
    title: title,
    size: HmModalSize.sm,
    body: (ctx) => StatefulBuilder(
      builder: (ctx, set) => HmTextField(
        label: tr('Name', 'Имя'),
        required: true,
        autofocus: true,
        controller: c,
        error: error,
        onSubmitted: (v) {
          final n = v.trim();
          if (n.isEmpty || n.contains('/')) {
            set(() => error = tr('Name can’t contain “/”', 'Имя без «/»'));
            return;
          }
          Navigator.pop(ctx, n);
        },
      ),
    ),
    actions: (ctx) => [
      HmButton(tr('Cancel', 'Отмена'), variant: HmVariant.neutral, expand: Hm.of(ctx).mobile, onPressed: () => Navigator.pop(ctx)),
      HmButton(
        action,
        variant: HmVariant.primary,
        expand: Hm.of(ctx).mobile,
        onPressed: () {
          final n = c.text.trim();
          if (n.isNotEmpty && !n.contains('/')) Navigator.pop(ctx, n);
        },
      ),
    ],
  );
}
