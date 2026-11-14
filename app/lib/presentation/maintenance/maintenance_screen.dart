import 'package:fixnum/fixnum.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/format.dart';
import '../../core/i18n.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/layout.dart';
import '../../core/theme/typography.dart';
import '../../data/rpc/core_client.dart';
import '../../data/rpc/gen/cloudsync.pbgrpc.dart' as pb;
import '../common/hm.dart';
import '../core/core_cubit.dart';

class MaintenanceScreen extends StatefulWidget {
  const MaintenanceScreen({super.key});

  @override
  State<MaintenanceScreen> createState() => _MaintenanceScreenState();
}

class _MaintenanceScreenState extends State<MaintenanceScreen> {
  bool _syncing = false, _repairing = false, _cleaning = false, _pinning = false, _changing = false;
  bool _rebalance = false;
  pb.RepairReply? _repair;
  pb.GCReply? _gc;
  final _k = TextEditingController();
  final _m = TextEditingController();
  String? _kmError;
  bool _kmChanged = false;

  // Read once in initState: handlers use it after awaits, when the screen
  // may already be gone and context.read would throw.
  late final CoreCubit _core;

  @override
  void initState() {
    super.initState();
    _core = context.read<CoreCubit>();
    final st = _core.state.status;
    _k.text = '${st?.dataShards ?? 2}';
    _m.text = '${st?.parityShards ?? 1}';
    _core.refreshStatus();
  }

  @override
  void dispose() {
    _k.dispose();
    _m.dispose();
    super.dispose();
  }

  Future<void> _sync() async {
    setState(() => _syncing = true);
    try {
      await _core.api.sync(pb.Empty());
      await _core.refreshStatus();
    } catch (e) {
      Toasts.error(tr('Sync failed', 'Синхронизация не удалась'), errorText(e));
    } finally {
      if (mounted) setState(() => _syncing = false);
    }
  }

  Future<void> _keepAll(bool on) async {
    setState(() => _pinning = true);
    try {
      if (on) {
        await _core.api.pin(pb.PathRequest(path: '/'));
        Toasts.success(tr('All files downloaded and will be kept here', 'Все файлы скачаны и будут храниться здесь'));
      } else {
        await _core.api.unpin(pb.PathRequest(path: '/'));
      }
      await _core.refreshStatus();
    } catch (e) {
      Toasts.error(tr('Failed', 'Не удалось'), errorText(e));
    } finally {
      if (mounted) setState(() => _pinning = false);
    }
  }

  Future<void> _runRepair() async {
    setState(() => _repairing = true);
    try {
      final r = await _core.api.repair(pb.RepairRequest(rebalance: _rebalance));
      setState(() => _repair = r);
      final detail = [
        if (r.fromLocal > 0) tr('rebuilt from this device: ${r.fromLocal}', 'восстановлено с этого устройства: ${r.fromLocal}'),
        if (r.failed > 0) tr('not repaired: ${r.failed}', 'не восстановлено: ${r.failed}'),
      ].join('\n');
      Toasts.success(tr('Check finished', 'Проверка закончена'), detail.isEmpty ? null : detail);
      await _core.refreshStatus();
    } catch (e) {
      Toasts.error(tr('Repair failed', 'Восстановление не удалось'), errorText(e));
    } finally {
      if (mounted) setState(() => _repairing = false);
    }
  }

  Future<void> _runGC() async {
    final ok = await confirm(
      context,
      title: tr('Delete unused data?', 'Удалить неиспользуемые данные?'),
      message: tr(
        'Deletes pieces of deleted and overwritten files that no file has needed for more than 7 days. '
            'The first run only marks them.',
        'Удаляются части удалённых и перезаписанных файлов, которые не нужны ни одному файлу дольше 7 дней. '
            'Первый запуск только помечает их.',
      ),
      action: tr('Clean up', 'Очистить'),
      destructive: true,
    );
    if (!ok) return;
    setState(() => _cleaning = true);
    try {
      final r = await _core.api.gC(pb.GCRequest());
      setState(() => _gc = r);
      Toasts.success(tr('Cleanup finished', 'Очистка закончена'), tr('objects deleted: ${r.deleted}', 'удалено объектов: ${r.deleted}'));
    } catch (e) {
      Toasts.error(tr('Cleanup failed', 'Очистка не удалась'), errorText(e));
    } finally {
      if (mounted) setState(() => _cleaning = false);
    }
  }

  Future<void> _setKM() async {
    final k = int.tryParse(_k.text), m = int.tryParse(_m.text);
    if (k == null || m == null || k < 1 || m < 1) {
      setState(() => _kmError = tr('k and m must be whole numbers, 1 or more', 'k и m — целые числа от 1'));
      return;
    }
    setState(() {
      _changing = true;
      _kmError = null;
    });
    try {
      await _core.api.setRedundancy(pb.SetRedundancyRequest(dataShards: k, parityShards: m));
      setState(() => _kmChanged = true);
      Toasts.success(tr('Scheme changed: $k+$m', 'Схема изменена: $k+$m'));
      await Future<void>.delayed(const Duration(seconds: 1));
      await _core.refreshState();
    } catch (e) {
      setState(() => _kmError = errorText(e));
    } finally {
      if (mounted) setState(() => _changing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final hm = Hm.of(context);
    final core = context.watch<CoreCubit>().state;
    final st = core.status;
    final pins = st?.pins ?? <String>[];
    final keepAll = pins.contains('/');
    final enabled = st?.backends.where((b) => b.enabled).length ?? 0;
    final gap = SizedBox(height: hm.gapSm);
    return HmPage(
      onRefresh: _core.refreshStatus,
      children: [
        HmPageTitle(tr('Maintenance', 'Обслуживание')),
        HmStatCards(
          children: [
            HmStatCard(
              label: tr('Pending upload', 'Ждут отправки'),
              value: '${st?.pending ?? 0}',
              accent: (st?.pending ?? 0) > 0 ? HmAccent.error : HmAccent.ok,
            ),
            HmStatCard(label: tr('Cache', 'Кэш'), value: formatSize((st?.cacheBytes ?? Int64.ZERO).toInt()), accent: HmAccent.active),
            HmStatCard(label: tr('Pinned', 'Закреплено'), value: '${pins.length}', accent: HmAccent.total),
            HmStatCard(label: tr('Devices', 'Устройств'), value: '${st?.devices.length ?? 0}', accent: HmAccent.uptime),
          ],
        ),

        // Sync.
        HmCard(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              HmSectionTitle(tr('Sync', 'Синхронизация')),
              gap,
              if (!core.syncOk && core.syncError != null) ...[HmBanner(core.syncError!, tone: HmTone.error), gap],
              Row(
                children: [
                  Expanded(
                    child: Text(
                      core.lastSync == null
                          ? tr('Sync runs in the background every 30 seconds.', 'Синхронизация идёт в фоне каждые 30 секунд.')
                          : tr(
                              'Last: ${formatTime(Int64(core.lastSync!.millisecondsSinceEpoch ~/ 1000))}, ${core.syncOk ? 'succeeded' : 'failed'}.',
                              'Последняя: ${formatTime(Int64(core.lastSync!.millisecondsSinceEpoch ~/ 1000))}, ${core.syncOk ? 'успешно' : 'с ошибкой'}.',
                            ),
                      style: HmText.small.copyWith(height: 1.5),
                    ),
                  ),
                  const SizedBox(width: 12),
                  HmButton(tr('Sync now', 'Синхронизировать'), icon: Icons.sync, loading: _syncing, onPressed: _sync),
                ],
              ),
              const SizedBox(height: 16),
              HmToggleRow(
                label: tr('Keep all files on this device', 'Держать все файлы на этом устройстве'),
                hint: tr(
                  'Full copy: files are available offline. Otherwise they are downloaded when opened.',
                  'Полная копия: файлы доступны без сети. Иначе скачиваются при открытии.',
                ),
                value: keepAll,
                onChanged: _pinning ? null : _keepAll,
              ),
            ],
          ),
        ),

        if (pins.isNotEmpty && !(pins.length == 1 && keepAll))
          HmTable<String>(
            items: pins,
            columns: [
              HmColumn(
                label: tr('Pinned on this device', 'Закреплено на устройстве'),
                flex: 4,
                sortKey: (p) => p,
                cell: (p) => Text(p == '/' ? tr('/ (everything)', '/ (всё)') : p),
              ),
            ],
            actions: (p) => [
              HmActionButton(
                icon: Icons.push_pin,
                label: tr('Unpin', 'Открепить'),
                onPressed: () async {
                  await _core.api.unpin(pb.PathRequest(path: p));
                  _core.touched();
                  await _core.refreshStatus();
                },
              ),
            ],
          ),

        // Repair.
        HmCard(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              HmSectionTitle(tr('Check and repair', 'Проверка и восстановление')),
              gap,
              Text(
                tr(
                  'Reads every piece of every file and verifies checksums. Rewrites lost pieces, moves them off disabled '
                      'storages and re-encodes files after a k/m change.',
                  'Читает каждую часть каждого файла и сверяет контрольные суммы. Дописывает потерянные части, переносит их с отключённых '
                      'хранилищ и перекодирует файлы после смены k/m.',
                ),
                style: HmText.small.copyWith(height: 1.5),
              ),
              gap,
              HmCheckRow(
                label: tr('Rebalance data onto storages added later', 'Перераспределить данные по хранилищам, добавленным позже'),
                value: _rebalance,
                onChanged: (v) => setState(() => _rebalance = v),
              ),
              if (_repair != null) ...[
                gap,
                HmStatCards(
                  children: [
                    HmStatCard(label: tr('Checked', 'Проверено'), value: '${_repair!.blobs}'),
                    HmStatCard(label: tr('Fixed', 'Исправлено'), value: '${_repair!.repaired + _repair!.reencoded}', accent: HmAccent.ok),
                    HmStatCard(label: tr('Moved', 'Перенесено'), value: '${_repair!.moved}', accent: HmAccent.active),
                    HmStatCard(label: tr('Failed', 'Не удалось'), value: '${_repair!.failed}', accent: _repair!.failed > 0 ? HmAccent.error : HmAccent.ok),
                  ],
                ),
                if (_repair!.damaged.isNotEmpty) ...[
                  gap,
                  HmBanner(
                    tr(
                      'Not enough intact pieces left for these files: parts of them cannot be read now. '
                          'If a storage is only temporarily unreachable, run the check again later; the log has details.',
                      'Для этих файлов не хватает целых частей: часть их содержимого сейчас не читается. '
                          'Если какое-то хранилище недоступно временно, повторите проверку позже; подробности в журнале.',
                    ),
                    tone: HmTone.error,
                  ),
                  gap,
                  SelectableText(_repair!.damaged.join('\n'), style: HmText.jb(12, color: HmColors.error)),
                ],
              ],
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerRight,
                child: HmButton(
                  tr('Check and repair', 'Проверить и восстановить'),
                  variant: HmVariant.primary,
                  icon: Icons.health_and_safety_outlined,
                  loading: _repairing,
                  expand: hm.mobile,
                  onPressed: _runRepair,
                ),
              ),
            ],
          ),
        ),

        // Redundancy.
        HmCard(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              HmSectionTitle(tr('Redundancy', 'Избыточность')),
              gap,
              Text(
                tr(
                  'Currently ${st?.dataShards ?? '?'}+${st?.parityShards ?? '?'}: each block is split into k data pieces and m parity pieces, '
                      'so any m storages can be lost. Needs k+m enabled storages, currently $enabled.',
                  'Сейчас ${st?.dataShards ?? '?'}+${st?.parityShards ?? '?'}: каждый блок делится на k частей данных и m частей чётности, '
                      'можно потерять любые m хранилищ. Нужно k+m включённых хранилищ, сейчас $enabled.',
                ),
                style: HmText.small.copyWith(height: 1.5),
              ),
              if (_kmChanged) ...[
                gap,
                HmBanner(
                  tr(
                    'New files are written with the new scheme. Run check and repair to re-encode existing ones.',
                    'Новые файлы пишутся по новой схеме. Запустите проверку и восстановление, чтобы перекодировать старые.',
                  ),
                ),
              ],
              gap,
              HmTextField(
                label: tr('Data pieces (k)', 'Частей данных (k)'),
                controller: _k,
                keyboard: TextInputType.number,
                formatters: [FilteringTextInputFormatter.digitsOnly],
              ),
              gap,
              HmTextField(
                label: tr('Parity pieces (m)', 'Частей чётности (m)'),
                controller: _m,
                keyboard: TextInputType.number,
                formatters: [FilteringTextInputFormatter.digitsOnly],
                error: _kmError,
              ),
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerRight,
                child: HmButton(tr('Apply', 'Применить'), loading: _changing, expand: hm.mobile, onPressed: _setKM),
              ),
            ],
          ),
        ),

        // GC.
        HmCard(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              HmSectionTitle(tr('Cleanup', 'Очистка')),
              gap,
              Text(
                tr(
                  'Pieces of deleted files and old versions stay in the storages for 7 days (they can still be recovered during that time), then are deleted.',
                  'Части удалённых и старых версий файлов остаются в хранилищах 7 дней (за это время их ещё можно восстановить), потом удаляются.',
                ),
                style: HmText.small.copyWith(height: 1.5),
              ),
              if (_gc != null) ...[
                gap,
                HmBanner(
                  tr(
                    'Objects: ${_gc!.objects}, unused: ${_gc!.unused}, deleted: ${_gc!.deleted}'
                        '${_gc!.skipped.isEmpty ? '' : '. Unavailable: ${_gc!.skipped.join(', ')}'}',
                    'Объектов: ${_gc!.objects}, не нужны: ${_gc!.unused}, удалено: ${_gc!.deleted}'
                        '${_gc!.skipped.isEmpty ? '' : '. Недоступны: ${_gc!.skipped.join(', ')}'}',
                  ),
                  tone: _gc!.skipped.isEmpty ? HmTone.ok : HmTone.warning,
                ),
              ],
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerRight,
                child: HmButton(
                  tr('Delete unused', 'Удалить неиспользуемое'),
                  variant: HmVariant.red,
                  icon: Icons.cleaning_services_outlined,
                  loading: _cleaning,
                  expand: hm.mobile,
                  onPressed: _runGC,
                ),
              ),
            ],
          ),
        ),

        // Devices.
        HmTable<pb.Device>(
          items: st?.devices ?? [],
          loading: st == null,
          columns: [
            HmColumn(
              label: tr('Device', 'Устройство'),
              flex: 3,
              sortKey: (d) => d.name.toLowerCase(),
              cell: (d) => Row(
                children: [
                  Flexible(child: Text(d.name, overflow: TextOverflow.ellipsis)),
                  if (d.id == st?.deviceId) ...[const SizedBox(width: 8), HmBadge(tr('this device', 'это устройство'), tone: HmTone.accent)],
                ],
              ),
            ),
            HmColumn(label: tr('Platform', 'Платформа'), sortKey: (d) => d.platform, cell: (d) => Text(platformName(d.platform))),
            HmColumn(label: tr('Added', 'Подключено'), flex: 2, sortKey: (d) => d.addedUnix.toInt(), cell: (d) => Text(formatDate(d.addedUnix))),
            HmColumn(
              label: 'ID',
              mobile: false,
              cell: (d) => Text(d.id, style: HmText.small),
            ),
          ],
        ),
      ],
    );
  }
}
