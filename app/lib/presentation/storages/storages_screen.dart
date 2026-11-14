import 'package:flutter/material.dart';
import 'package:grpc/grpc.dart' show GrpcError, StatusCode;
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:fixnum/fixnum.dart';

import '../../core/format.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/layout.dart';
import '../../core/theme/typography.dart';
import '../../data/rpc/core_client.dart';
import '../../data/rpc/gen/cloudsync.pbgrpc.dart' as pb;
import '../common/hm.dart';
import '../../core/i18n.dart';
import '../core/core_cubit.dart';
import '../shell/app_shell.dart' show AppShell;
import 'add_storage.dart';
import 'reconnect_storage.dart';

class StoragesScreen extends StatefulWidget {
  const StoragesScreen({super.key});

  @override
  State<StoragesScreen> createState() => _StoragesScreenState();
}

class _StoragesScreenState extends State<StoragesScreen> {
  bool _repairing = false;

  // Read once in initState: handlers use it after awaits, when the screen
  // may already be gone and context.read would throw.
  late final CoreCubit _core;

  @override
  void initState() {
    super.initState();
    _core = context.read<CoreCubit>();
    _core.refreshStatus();
  }

  Future<void> _add() async {
    final added = await showAddStorage(context);
    if (added != null) {
      Toasts.success(tr('Storage added', 'Хранилище добавлено'), added.name);
      // It is listed at once as "preparing"; the core reopens with it.
      await _core.refreshStatus();
      await _untilPrepared();
      await _core.refreshState();
    }
  }

  /// Refreshes while some storage is still being opened (up to a minute).
  Future<void> _untilPrepared() async {
    for (var i = 0; i < 30 && mounted; i++) {
      final st = _core.state.status;
      if (st != null && !st.backends.any((b) => b.preparing)) return;
      await Future<void>.delayed(const Duration(seconds: 2));
      await _core.refreshStatus();
    }
  }

  Future<void> _rename(pb.Backend b) async {
    final name = TextEditingController(text: b.name);
    String? error;
    final next = await showHmModal<String>(
      context,
      title: tr('Rename storage', 'Переименовать хранилище'),
      body: (ctx) => StatefulBuilder(
        builder: (ctx, set) => HmTextField(
          label: tr('Name', 'Название'),
          required: true,
          autofocus: true,
          controller: name,
          error: error,
          hint: tr('Only for you: data and the storage ID stay the same.', 'Только для вас: данные и ID хранилища не меняются.'),
          onSubmitted: (v) => v.trim().isEmpty ? set(() => error = tr('Enter a name', 'Введите название')) : Navigator.pop(ctx, v.trim()),
        ),
      ),
      actions: (ctx) => [
        HmButton(tr('Cancel', 'Отмена'), variant: HmVariant.neutral, expand: Hm.of(ctx).mobile, onPressed: () => Navigator.pop(ctx)),
        HmButton(
          tr('Save', 'Сохранить'),
          variant: HmVariant.primary,
          expand: Hm.of(ctx).mobile,
          onPressed: () {
            if (name.text.trim().isNotEmpty) Navigator.pop(ctx, name.text.trim());
          },
        ),
      ],
    );
    name.dispose();
    if (next == null || next == b.name) return;
    try {
      await _core.api.renameBackend(pb.RenameBackendRequest(id: b.id, name: next));
      Toasts.success(tr('Storage renamed', 'Хранилище переименовано'), next);
      await _core.refreshStatus();
    } catch (e) {
      Toasts.error(tr('Could not rename', 'Не удалось переименовать'), errorText(e));
    }
  }

  Future<void> _toggle(pb.Backend b) async {
    if (b.enabled) {
      final ok = await confirm(
        context,
        title: tr('Disable “${b.name}”?', 'Отключить «${b.name}»?'),
        message: tr(
          'New data will not be written there. Run repair to move the parts already stored on it.',
          'Новые данные туда писаться не будут. Запустите восстановление, чтобы перенести с него уже записанные части.',
        ),
        action: tr('Disable', 'Отключить'),
        destructive: true,
      );
      if (!ok) return;
    }
    try {
      await _core.api.setBackendEnabled(pb.SetBackendEnabledRequest(id: b.id, enabled: !b.enabled));
      Toasts.success(b.enabled ? tr('Storage disabled', 'Хранилище отключено') : tr('Storage enabled', 'Хранилище включено'), b.name);
      await Future<void>.delayed(const Duration(seconds: 1));
      await _core.refreshState();
    } catch (e) {
      Toasts.error(tr('Failed', 'Не удалось'), errorText(e));
    }
  }

  Future<void> _remove(pb.Backend b) async {
    final ok = await confirm(
      context,
      title: tr('Remove “${b.name}” from the vault?', 'Удалить «${b.name}» из vault?'),
      message: tr(
        'The storage disappears from all devices. Data in the account itself is not deleted.',
        'Хранилище исчезнет с всех устройств. Данные в самом аккаунте не удаляются.',
      ),
      action: tr('Remove', 'Удалить'),
      destructive: true,
    );
    if (!ok) return;
    try {
      await _core.api.removeBackend(pb.RemoveBackendRequest(id: b.id));
    } on GrpcError catch (e) {
      if (e.code != StatusCode.failedPrecondition || !mounted) {
        Toasts.error(tr('Could not remove', 'Не удалось удалить'), errorText(e));
        return;
      }
      // Shards Repair could not move are still there: offer to drop them.
      final force = await confirm(
        context,
        title: tr('“${b.name}” still holds data', '«${b.name}» ещё хранит данные'),
        message: tr(
          '${e.message ?? ''}\n\nRemove it anyway only if this storage is gone for good: its pieces count as lost, '
              'repair then rebuilds every file that has enough pieces elsewhere. Files without them stay damaged.',
          '${e.message ?? ''}\n\nУдаляйте всё равно, только если хранилище потеряно навсегда: его части считаются утраченными, '
              'восстановление пересоберёт каждый файл, у которого хватает частей на других хранилищах. Остальные останутся повреждёнными.',
        ),
        action: tr('Remove anyway', 'Всё равно удалить'),
        destructive: true,
      );
      if (!force) return;
      try {
        await _core.api.removeBackend(pb.RemoveBackendRequest(id: b.id, force: true));
      } catch (e) {
        Toasts.error(tr('Could not remove', 'Не удалось удалить'), errorText(e));
        return;
      }
    } catch (e) {
      Toasts.error(tr('Could not remove', 'Не удалось удалить'), errorText(e));
      return;
    }
    Toasts.success(tr('Storage removed', 'Хранилище удалено'), b.name);
    await Future<void>.delayed(const Duration(seconds: 1));
    await _core.refreshState();
  }

  Future<void> _reconnect(pb.Backend b) async {
    final account = await showReconnectStorage(context, b);
    if (account == null) return;
    Toasts.success(tr('Storage reconnected', 'Хранилище переподключено'), account.isEmpty ? b.name : '${b.name}: $account');
    // The core reopens the storages with the new token.
    await Future<void>.delayed(const Duration(seconds: 2));
    await _core.refreshStatus();
    await _core.refreshState();
  }

  void _showLog(pb.Backend b) => AppShell.openLog(context, b.id);

  Future<void> _repair() async {
    setState(() => _repairing = true);
    try {
      final r = await _core.api.repair(pb.RepairRequest());
      if (r.failed > 0) {
        Toasts.error(
          tr('Repair finished with damaged files', 'Восстановление закончено, есть повреждённые файлы'),
          r.damaged.isEmpty
              ? tr('not repaired: ${r.failed}', 'не восстановлено: ${r.failed}')
              : r.damaged.take(5).join('\n') + (r.damaged.length > 5 ? '\n… +${r.damaged.length - 5}' : ''),
        );
      } else {
        Toasts.success(
          tr('Repair finished', 'Восстановление закончено'),
          tr('blocks fixed: ${r.repaired}, journal copies: ${r.journalCopies}', 'исправлено блоков: ${r.repaired}, копий журнала: ${r.journalCopies}'),
        );
      }
      await _core.refreshStatus();
    } catch (e) {
      Toasts.error(tr('Repair failed', 'Восстановление не удалось'), errorText(e));
    } finally {
      if (mounted) setState(() => _repairing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final core = context.watch<CoreCubit>().state;
    final st = core.status;
    final ready = core.state?.ready ?? false;
    final backends = st?.backends ?? <pb.Backend>[];
    final enabled = backends.where((b) => b.enabled).length;
    final online = backends.where((b) => b.enabled && b.online).length;
    final behind = backends.where((b) => b.behind).length;
    final k = st?.dataShards ?? 0, m = st?.parityShards ?? 0;
    final hm = Hm.of(context);
    final room = st != null && st.hasWritableBytes() ? st.writableBytes.toInt() : null;
    final unreported = backends.where((b) => b.enabled && !b.hasFreeBytes()).length;
    return HmPage(
      onRefresh: _core.refreshStatus,
      children: [
        HmPageTitle(
          tr('Storages', 'Хранилища'),
          trailing: hm.mobile ? null : HmButton(tr('Add storage', 'Добавить хранилище'), variant: HmVariant.primary, icon: Icons.add, onPressed: _add),
        ),
        if (!ready && core.unlocked)
          HmBanner(
            enabled < k + m
                ? tr(
                    'The vault is open but not working yet: it needs at least ${k + m} storages (k=$k + m=$m), there are $enabled.',
                    'Vault открыт, но ещё не работает: нужно хотя бы ${k + m} хранилищ (k=$k + m=$m), сейчас $enabled.',
                  )
                : tr('The vault is not ready: ', 'Vault не готов: ') + (core.state?.problem ?? ''),
            tone: HmTone.warning,
          ),
        if ((st?.domainRisk ?? false) && enabled >= k + m)
          HmBanner(
            tr(
              'More parts of one block land at a single provider than may be lost. If it fails, files become unreadable: add a storage at another provider.',
              'Части одного блока попадают к одному провайдеру чаще, чем можно потерять. Его отказ сделает файлы нечитаемыми: добавьте хранилище у другого провайдера.',
            ),
            tone: HmTone.warning,
          ),
        if (behind > 0)
          HmBanner(
            tr('Storages behind: $behind (new, or lost data).', 'Отстают хранилищ: $behind (новые или потерявшие данные).'),
            tone: HmTone.warning,
            action: HmButton(tr('Repair', 'Восстановить'), small: true, loading: _repairing, onPressed: ready ? _repair : null),
          ),
        if (st?.reloadNeeded ?? false)
          HmBanner(tr('The configuration changed on another device — applying…', 'Конфигурация изменилась на другом устройстве — применяется…')),
        HmStatCards(
          children: [
            HmStatCard(label: tr('Storages', 'Хранилищ'), value: '$enabled', accent: HmAccent.total),
            HmStatCard(label: tr('Online', 'В сети'), value: ready ? '$online' : '—', accent: online == enabled && ready ? HmAccent.ok : HmAccent.error),
            HmStatCard(
              label: tr('Room for files', 'Ещё поместится'),
              value: !ready || room == null ? '—' : formatSize(room) + (unreported > 0 ? '+' : ''),
              accent: room != null && room < (1 << 30) ? HmAccent.error : HmAccent.ok,
            ),
            HmStatCard(label: tr('Files', 'Файлы'), value: ready ? formatSize((st?.filesBytes ?? Int64.ZERO).toInt()) : '—', accent: HmAccent.total),
            HmStatCard(label: tr('Scheme k+m', 'Схема k+m'), value: '$k+$m', accent: HmAccent.active),
            HmStatCard(label: tr('May be lost', 'Можно потерять'), value: '$m', accent: HmAccent.uptime),
          ],
        ),
        if (ready && room != null && room < (1 << 30))
          HmBanner(
            tr(
              'Storages are almost full: about ${formatSize(room)} of files still fit with full protection. Free space in the fullest storage or add another one.',
              'Хранилища почти заполнены: с полной защитой поместится ещё около ${formatSize(room)} файлов. Освободите место в самом заполненном хранилище или добавьте ещё одно.',
            ),
            tone: HmTone.warning,
          ),
        if (hm.mobile) HmButton(tr('Add storage', 'Добавить хранилище'), variant: HmVariant.primary, icon: Icons.add, expand: true, onPressed: _add),
        HmTable<pb.Backend>(
          items: backends,
          loading: st == null,
          emptyText: tr('No storages yet', 'Хранилищ пока нет'),
          emptyIcon: Icons.cloud_off_outlined,
          emptyAction: HmButton(tr('Add storage', 'Добавить хранилище'), icon: Icons.add, onPressed: _add),
          onRefresh: _core.refreshStatus,
          rowStatus: (b) => !ready || !b.enabled || b.preparing ? null : (b.online ? HmStatus.ok : HmStatus.error),
          columns: [
            HmColumn(
              label: tr('Name', 'Название'),
              flex: 3,
              minWidth: 200,
              sortKey: (b) => b.name.toLowerCase(),
              cell: (b) => Row(
                children: [
                  if (ready && b.enabled && !b.preparing) ...[HmDot(ok: b.online), const SizedBox(width: 10)],
                  Flexible(child: Text(b.name, overflow: TextOverflow.ellipsis)),
                ],
              ),
            ),
            HmColumn(
              label: tr('Account', 'Аккаунт'),
              flex: 2,
              minWidth: 180,
              sortKey: (b) => b.account.toLowerCase(),
              cardIf: (b) => b.account.isNotEmpty,
              cell: (b) => Tooltip(
                message: b.root.isEmpty || b.type == 'local' ? '' : tr('folder: ', 'папка: ') + b.root,
                child: Text(b.account.isEmpty ? '—' : b.account, overflow: TextOverflow.ellipsis, style: b.account.isEmpty ? HmText.small : null),
              ),
            ),
            HmColumn(label: tr('Type', 'Тип'), minWidth: 90, sortKey: (b) => b.type, cell: (b) => Text(b.type)),
            HmColumn(label: tr('Failure zone', 'Зона отказа'), minWidth: 110, sortKey: (b) => b.domain, cell: (b) => Text(b.domain)),
            HmColumn(
              label: tr('Space', 'Место'),
              flex: 2,
              minWidth: 170,
              sortKey: (b) => b.hasFreeBytes() ? b.freeBytes.toInt() : -1,
              cell: (b) => _BackendSpace(b: b, ready: ready),
            ),
            HmColumn(
              label: tr('State', 'Состояние'),
              flex: 2,
              minWidth: 160,
              cell: (b) => _BackendState(b: b, ready: ready, sameAs: backends.where((o) => o.id == b.sameAs).firstOrNull?.name),
            ),
            HmColumn(
              label: tr('Response', 'Отклик'),
              minWidth: 120,
              sortKey: (b) => b.getMs > 0 ? b.getMs : b.listMs,
              cardIf: (b) => ready && (b.getMs > 0 || b.putMs > 0 || b.listMs > 0),
              cell: (b) => _BackendSpeed(b: b, ready: ready),
            ),
            HmColumn(
              label: 'ID',
              minWidth: 110,
              mobile: false,
              cell: (b) => Text(b.id, style: HmText.small),
            ),
          ],
          actions: (b) => [
            HmActionButton(icon: Icons.edit_outlined, label: tr('Rename', 'Переименовать'), onPressed: () => _rename(b)),
            HmActionButton(icon: Icons.receipt_long_outlined, label: tr('Log', 'Журнал'), onPressed: () => _showLog(b)),
            if (b.oauth)
              HmActionButton(
                icon: Icons.login,
                label: tr('Reconnect (sign in again)', 'Переподключить (войти заново)'),
                kind: ready && b.enabled && !b.online && !b.preparing ? HmAction.warning : HmAction.neutral,
                onPressed: () => _reconnect(b),
              ),
            HmActionButton(
              icon: b.enabled ? Icons.pause_circle_outline : Icons.play_circle_outline,
              label: b.enabled ? tr('Disable', 'Отключить') : tr('Enable', 'Включить'),
              kind: b.enabled ? HmAction.warning : HmAction.success,
              onPressed: () => _toggle(b),
            ),
            if (!b.enabled)
              HmActionButton(
                icon: Icons.delete_outline,
                label: tr('Remove from vault', 'Удалить из vault'),
                kind: HmAction.delete,
                onPressed: () => _remove(b),
              ),
          ],
        ),
        Text(
          tr(
            'A storage is identified by its ID, not its type: two Mega accounts are two independent storages, '
                'but one account (or folder) can hold only one storage. '
                'A failure zone is what can fail as a whole (one provider); parts of one block are spread over different zones. '
                'Every file takes (k+m)/k of its size across the storages; “Room for files” is how much more fits before '
                'the first storage that new data goes to is full (storages that do not report their space count as unlimited).',
            'Хранилище определяется своим ID, а не типом: два аккаунта Mega — два независимых хранилища, '
                'но в одном аккаунте (или папке) может быть только одно хранилище. '
                'Зона отказа — то, что может отказать целиком (один провайдер); части одного блока раскладываются по разным зонам. '
                'Каждый файл занимает (k+m)/k своего размера на всех хранилищах вместе; «Ещё поместится» — сколько можно записать, '
                'пока не заполнится первое хранилище, куда идут новые данные (хранилища, не сообщающие объём, считаются безлимитными).',
          ),
          style: HmText.small.copyWith(height: 1.5),
        ),
      ],
    );
  }
}

class _BackendState extends StatelessWidget {
  const _BackendState({required this.b, required this.ready, this.sameAs});

  final pb.Backend b;
  final bool ready;

  /// Name of another storage in the same account or folder.
  final String? sameAs;

  @override
  Widget build(BuildContext context) {
    final badges = <Widget>[
      if (b.preparing)
        HmBadge(tr('preparing…', 'подготовка…'), tone: HmTone.accent)
      else if (!b.enabled)
        HmBadge(tr('disabled', 'отключено'))
      else if (!ready)
        HmBadge(tr('not checked', 'не проверено'))
      else if (b.online)
        HmBadge(tr('online', 'в сети'), tone: HmTone.ok)
      else
        HmBadge(tr('unreachable', 'недоступно'), tone: HmTone.error),
      if (b.behind) HmBadge(tr('behind', 'отстаёт'), tone: HmTone.warning),
      if (b.sameAs.isNotEmpty) HmBadge(tr('duplicate', 'дубликат'), tone: HmTone.warning),
    ];
    final dup = b.sameAs.isEmpty
        ? null
        : tr(
            'Same account or folder as “${sameAs ?? b.sameAs}”: it adds no redundancy. Disable one and remove it from the vault.',
            'Тот же аккаунт или папка, что у «${sameAs ?? b.sameAs}»: защиты это не добавляет. Отключите одно и удалите из vault.',
          );
    final err = [if (ready && b.error.isNotEmpty && !b.online) b.error, ?dup].join('\n');
    return Tooltip(
      message: err,
      child: Wrap(
        spacing: 6,
        runSpacing: 4,
        children: [
          ...badges,
          if (err.isNotEmpty && Hm.of(context).mobile)
            Text(
              err,
              style: HmText.jb(11, color: HmColors.error),
              overflow: TextOverflow.ellipsis,
            ),
        ],
      ),
    );
  }
}

/// Recent response times of a storage: reads (or listings, before the
/// first read) and writes. Slow ones are shown in the warning colour.
class _BackendSpeed extends StatelessWidget {
  const _BackendSpeed({required this.b, required this.ready});

  final pb.Backend b;
  final bool ready;

  static const _slowMs = 3000;

  @override
  Widget build(BuildContext context) {
    final read = b.getMs > 0 ? b.getMs : b.listMs;
    if (!ready || b.preparing || (read == 0 && b.putMs == 0)) return Text('—', style: HmText.small);
    String ms(int v) => v == 0 ? '—' : (v < 1000 ? '$v ms' : '${(v / 1000).toStringAsFixed(1)} s');
    Text line(String label, int v) => Text('$label ${ms(v)}', style: v >= _slowMs ? HmText.small.copyWith(color: HmColors.warning) : HmText.small);
    return Tooltip(
      message: tr(
        'Typical time of one request lately. Reads go to the fastest storages first.',
        'Обычное время одного запроса за последнее время. Чтение идёт сначала с самых быстрых хранилищ.',
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [line(tr('read', 'чтение'), read), line(tr('write', 'запись'), b.putMs)],
      ),
    );
  }
}

/// Free / total space of a storage with a fill bar, and what the vault
/// keeps there.
class _BackendSpace extends StatelessWidget {
  const _BackendSpace({required this.b, required this.ready});

  final pb.Backend b;
  final bool ready;

  @override
  Widget build(BuildContext context) {
    if (!ready || b.preparing) return Text('—', style: HmText.small);
    final stored = tr('vault: ', 'vault: ') + formatSize(b.storedBytes.toInt());
    if (!b.hasFreeBytes()) {
      return Tooltip(
        message: b.online
            ? tr('The provider does not report its space', 'Провайдер не сообщает объём')
            : tr('Unknown while the storage is unreachable', 'Неизвестно, пока хранилище недоступно'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(tr('size unknown', 'объём неизвестен'), style: HmText.small),
            Text(stored, style: HmText.small),
          ],
        ),
      );
    }
    final free = b.freeBytes.toInt();
    final total = b.hasTotalBytes() ? b.totalBytes.toInt() : 0;
    final used = total > 0 ? (total - free) / total : null;
    final color = used == null
        ? HmColors.accent
        : used >= 0.95
        ? HmColors.error
        : used >= 0.8
        ? HmColors.warning
        : HmColors.accent;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          total > 0
              ? tr('${formatSize(free)} free of ${formatSize(total)}', '${formatSize(free)} свободно из ${formatSize(total)}')
              : tr('${formatSize(free)} free', '${formatSize(free)} свободно'),
          overflow: TextOverflow.ellipsis,
        ),
        if (used != null) ...[const SizedBox(height: 4), HmProgress(value: used, color: color), const SizedBox(height: 4)],
        Text(stored, style: HmText.small, overflow: TextOverflow.ellipsis),
      ],
    );
  }
}
