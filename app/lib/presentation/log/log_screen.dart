import 'dart:async';

import 'package:fixnum/fixnum.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/i18n.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/typography.dart';
import '../../data/rpc/core_client.dart';
import '../../data/rpc/gen/cloudsync.pbgrpc.dart' as pb;
import '../common/hm.dart';
import '../core/core_cubit.dart';

/// Recent core events: why storages fail, sync and mount errors. The core
/// keeps the last 1000 (repeats folded); the daemon also writes them to
/// cloudsyncd.log next to the vault.
class LogScreen extends StatefulWidget {
  const LogScreen({super.key, this.backendId});

  /// Show only this storage at first.
  final String? backendId;

  @override
  State<LogScreen> createState() => _LogScreenState();
}

const _all = '';

class _LogScreenState extends State<LogScreen> {
  List<pb.LogEntry> _entries = [];
  bool _loading = true;
  String? _error;
  late String _backend = widget.backendId ?? _all;
  bool _errorsOnly = false;
  Timer? _timer;

  // Read once in initState: handlers use it after awaits, when the screen
  // may already be gone and context.read would throw.
  late final CoreCubit _core;

  @override
  void initState() {
    super.initState();
    _core = context.read<CoreCubit>();
    _load();
    _core.refreshStatus();
    _timer = Timer.periodic(const Duration(seconds: 5), (_) => _load(quiet: true));
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _load({bool quiet = false}) async {
    if (!quiet) setState(() => _loading = true);
    try {
      final r = await _core.api.logs(pb.LogsRequest(backendId: _backend));
      if (!mounted) return;
      setState(() {
        _entries = r.entries.reversed.toList(); // newest first
        _error = null;
        _loading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = errorText(e);
          _loading = false;
        });
      }
    }
  }

  Future<void> _clear() async {
    final ok = await confirm(
      context,
      title: tr('Clear the log?', 'Очистить журнал?'),
      message: tr(
        'Events are removed from the app; the log file of the daemon stays.',
        'События пропадут из приложения; файл журнала демона останется.',
      ),
      action: tr('Clear', 'Очистить'),
      destructive: true,
    );
    if (!ok) return;
    try {
      await _core.api.clearLogs(pb.Empty());
      await _load();
    } catch (e) {
      Toasts.error(tr('Could not clear', 'Не удалось очистить'), errorText(e));
    }
  }

  static String _time(Int64 ms) {
    final t = DateTime.fromMillisecondsSinceEpoch(ms.toInt()).toLocal();
    String two(int v) => v.toString().padLeft(2, '0');
    return '${t.year}-${two(t.month)}-${two(t.day)} ${two(t.hour)}:${two(t.minute)}:${two(t.second)}';
  }

  static HmTone _tone(String level) => switch (level) {
    'error' => HmTone.error,
    'warn' => HmTone.warning,
    _ => HmTone.neutral,
  };

  static String _level(String level) => switch (level) {
    'error' => tr('error', 'ошибка'),
    'warn' => tr('warning', 'внимание'),
    _ => tr('info', 'инфо'),
  };

  static String _source(String s) => switch (s) {
    'storage' => tr('storage', 'хранилище'),
    'sync' => tr('sync', 'синхронизация'),
    'mount' => tr('folder', 'папка'),
    'vault' => 'vault',
    _ => s,
  };

  @override
  Widget build(BuildContext context) {
    final backends = context.watch<CoreCubit>().state.status?.backends ?? <pb.Backend>[];
    final names = {for (final b in backends) b.id: b.name};
    final shown = _errorsOnly ? _entries.where((e) => e.level != 'info').toList() : _entries;
    final errors = _entries.where((e) => e.level == 'error').length;
    return HmPage(
      onRefresh: _load,
      children: [
        HmPageTitle(tr('Log', 'Журнал')),
        Text(
          tr(
            'What the core did and what failed: a storage that drops out shows its errors here. Repeats are folded into one line (×N). '
                'The daemon also writes cloudsyncd.log in its config folder.',
            'Что делало ядро и что не удалось: здесь видно, почему отваливается хранилище. Повторы сворачиваются в одну строку (×N). '
                'Демон также пишет cloudsyncd.log в своей папке настроек.',
          ),
          style: HmText.small.copyWith(height: 1.5),
        ),
        HmStatCards(
          children: [
            HmStatCard(label: tr('Events', 'Событий'), value: '${_entries.length}', accent: HmAccent.total),
            HmStatCard(label: tr('Errors', 'Ошибок'), value: '$errors', accent: errors == 0 ? HmAccent.ok : HmAccent.error),
          ],
        ),
        HmTable<pb.LogEntry>(
          items: shown,
          loading: _loading,
          error: _error,
          emptyText: tr('No events yet', 'Событий пока нет'),
          emptyIcon: Icons.receipt_long_outlined,
          onRefresh: _load,
          rowStatus: (e) => e.level == 'error' ? HmStatus.error : null,
          search: SizedBox(
            width: 240,
            child: HmSelect<String>(
              label: tr('Storage', 'Хранилище'),
              showLabel: false,
              options: {_all: tr('All events', 'Все события'), for (final b in backends) b.id: b.name},
              value: _backend,
              onChanged: (v) {
                setState(() => _backend = v);
                _load();
              },
            ),
          ),
          controls: [
            HmButton(
              _errorsOnly ? tr('Show all', 'Показать все') : tr('Problems only', 'Только проблемы'),
              small: true,
              icon: Icons.filter_list,
              onPressed: () => setState(() => _errorsOnly = !_errorsOnly),
            ),
            HmButton(tr('Clear', 'Очистить'), small: true, icon: Icons.delete_sweep_outlined, onPressed: _entries.isEmpty ? null : _clear),
          ],
          columns: [
            HmColumn(
              label: tr('Time', 'Время'),
              minWidth: 170,
              sortKey: (e) => e.timeUnixMs.toInt(),
              cell: (e) => Text(_time(e.timeUnixMs), style: HmText.small),
            ),
            HmColumn(
              label: tr('Level', 'Уровень'),
              minWidth: 110,
              sortKey: (e) => e.level,
              cell: (e) => Align(
                alignment: Alignment.centerLeft,
                child: HmBadge(_level(e.level), tone: _tone(e.level)),
              ),
            ),
            HmColumn(
              label: tr('Source', 'Источник'),
              minWidth: 150,
              sortKey: (e) => '${e.source}${names[e.backendId] ?? ''}',
              cell: (e) =>
                  Text(e.backendId.isEmpty ? _source(e.source) : (names[e.backendId] ?? e.backendId), overflow: TextOverflow.ellipsis),
            ),
            HmColumn(
              label: tr('Message', 'Сообщение'),
              flex: 5,
              minWidth: 320,
              cell: (e) => Tooltip(
                message: e.count > 1 ? tr('first: ', 'впервые: ') + _time(e.firstUnixMs) : '',
                child: Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(text: e.message),
                      if (e.count > 1)
                        TextSpan(
                          text: '  ×${e.count}',
                          style: HmText.small.copyWith(color: HmColors.warning),
                        ),
                    ],
                  ),
                  style: HmText.jb(12, color: e.level == 'error' ? HmColors.error : HmColors.text),
                ),
              ),
            ),
          ],
          actions: (e) => [
            HmActionButton(
              icon: Icons.copy_outlined,
              label: tr('Copy', 'Копировать'),
              onPressed: () {
                Clipboard.setData(ClipboardData(text: '${_time(e.timeUnixMs)} ${e.level} ${names[e.backendId] ?? e.source}: ${e.message}'));
                Toasts.success(tr('Copied', 'Скопировано'), '');
              },
            ),
          ],
        ),
      ],
    );
  }
}
