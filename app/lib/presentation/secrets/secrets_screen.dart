import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
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
import 'secret_card.dart';
import 'secret_editor.dart';
import 'secret_util.dart';
import 'totp.dart';

/// Group filter: every entry, or the entries without a (known) group.
const _all = '*all';
const _none = '*none';

/// The password safe: groups and entries. The list holds no secrets; an
/// entry is opened (decrypted by the core) only while its card is shown.
class SecretsScreen extends StatefulWidget {
  const SecretsScreen({super.key});

  @override
  State<SecretsScreen> createState() => _SecretsScreenState();
}

class _SecretsScreenState extends State<SecretsScreen> {
  List<pb.SecretGroup> _groups = [];
  List<pb.SecretEntry> _entries = [];
  int _broken = 0;
  bool _loading = true;
  String? _error;
  String _group = _all;
  bool _totp = false; // the 2FA list instead of passwords and keys
  TotpCodes? _codes; // while the 2FA list is shown
  final _query = TextEditingController();

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
    _codes?.dispose();
    super.dispose();
  }

  void _setMode(bool totp) {
    setState(() {
      _totp = totp;
      if (totp) {
        _codes ??= TotpCodes(_core.api);
      } else {
        _codes?.dispose();
        _codes = null;
      }
    });
  }

  /// Entries of the list shown: 2FA ones, or the others.
  List<pb.SecretEntry> get _listed => _entries.where((e) => (e.kind == pb.SecretKind.SECRET_TOTP) == _totp).toList();

  Future<void> _load({bool quiet = false}) async {
    if (!quiet) setState(() => _loading = true);
    try {
      final r = await _core.api.listSecrets(pb.Empty());
      if (!mounted) return;
      setState(() {
        _groups = r.groups;
        _entries = r.entries;
        _broken = r.broken;
        _error = null;
        _loading = false;
        _codes?.refresh();
        if (_group != _all && _group != _none && !_groups.any((g) => g.id == _group)) _group = _all;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = errorText(e);
        _loading = false;
      });
    }
  }

  Map<String, pb.SecretGroup> get _groupById => {for (final g in _groups) g.id: g};

  List<pb.SecretEntry> get _shown {
    final known = _groupById;
    final q = _query.text.trim().toLowerCase();
    return _listed.where((e) {
      final inGroup = switch (_group) {
        _all => true,
        _none => !known.containsKey(e.groupId),
        _ => e.groupId == _group,
      };
      if (!inGroup) return false;
      if (q.isEmpty) return true;
      return [e.title, e.username, e.url, e.address, e.comment].any((s) => s.toLowerCase().contains(q));
    }).toList();
  }

  int _count(String group) {
    final known = _groupById;
    final listed = _listed;
    return switch (group) {
      _all => listed.length,
      _none => listed.where((e) => !known.containsKey(e.groupId)).length,
      _ => listed.where((e) => e.groupId == group).length,
    };
  }

  Future<void> _add() async {
    final group = _group == _all || _group == _none ? '' : _group;
    final saved = await showSecretEditor(
      context,
      groups: _groups,
      initialGroup: group,
      kinds: _totp ? const [pb.SecretKind.SECRET_TOTP] : passwordKinds,
    );
    if (saved != null) await _load(quiet: true);
  }

  Future<void> _open(pb.SecretEntry e) async {
    await showSecretCard(context, entry: e, groups: _groups);
    if (mounted) await _load(quiet: true);
  }

  Future<void> _delete(pb.SecretEntry e) async {
    final ok = await confirm(
      context,
      title: tr('Delete entry?', 'Удалить запись?'),
      message: tr('“${e.title}” will be deleted on all devices.', '«${e.title}» будет удалена на всех устройствах.'),
      action: tr('Delete', 'Удалить'),
      destructive: true,
    );
    if (!ok) return;
    try {
      await _core.api.deleteSecret(pb.IdRequest(id: e.id));
      Toasts.success(tr('Deleted', 'Удалено'));
      await _load(quiet: true);
    } catch (err) {
      Toasts.error(tr('Could not delete', 'Не удалось удалить'), errorText(err));
    }
  }

  /// Copies what the row is for: the password (opened for this moment
  /// only), the SSH public key or the wallet address.
  Future<void> _quickCopy(pb.SecretEntry e) async {
    try {
      switch (e.kind) {
        case pb.SecretKind.SECRET_TOTP:
          if (_codes != null) await copyTotp(_codes!, e.id);
        case pb.SecretKind.SECRET_SSH:
          await SecretClipboard.copyPlain(e.publicKey, tr('Public key', 'Публичный ключ'));
        case pb.SecretKind.SECRET_WEB3:
          await SecretClipboard.copyPlain(e.address, tr('Address', 'Адрес'));
        default:
          final full = await _core.api.getSecret(pb.IdRequest(id: e.id));
          final pw = full.password;
          full.clear();
          await SecretClipboard.copy(pw, tr('Password', 'Пароль'));
      }
    } catch (err) {
      Toasts.error(tr('Could not copy', 'Не удалось скопировать'), errorText(err));
    }
  }

  Future<void> _editGroup([pb.SecretGroup? g]) async {
    final r = await showGroupEditor(context, group: g, entries: g == null ? 0 : _entries.where((e) => e.groupId == g.id).length);
    if (r == null) return;
    // A new group is selected; a deleted one falls back to all entries.
    setState(() => _group = g == null ? r.id : (r.id.isEmpty ? _all : _group));
    await _load(quiet: true);
  }

  @override
  Widget build(BuildContext context) {
    final hm = Hm.of(context);
    final groups = _groupById;
    final selected = groups[_group];
    final showNone = _groups.isNotEmpty && _count(_none) > 0;
    final groupList = _GroupList(
      groups: _groups,
      selected: _group,
      showNone: showNone,
      count: _count,
      onSelect: (id) => setState(() => _group = id),
      onAdd: () => _editGroup(),
      horizontal: hm.mobile,
    );
    final table = HmTable<pb.SecretEntry>(
      items: _shown,
      loading: _loading,
      error: _error,
      emptyText: _query.text.isNotEmpty
          ? tr('Nothing found', 'Ничего не найдено')
          : (_listed.isEmpty
                ? (_totp ? tr('No 2FA codes yet', '2FA-кодов пока нет') : tr('The safe is empty', 'Сейф пуст'))
                : tr('No entries in this group', 'В группе нет записей')),
      emptyIcon: _query.text.isNotEmpty ? Icons.search_off : (_totp ? Icons.pin_outlined : Icons.password_outlined),
      emptyAction: _query.text.isEmpty && !_loading
          ? HmButton(_totp ? tr('Add 2FA code', 'Добавить 2FA-код') : tr('Add entry', 'Добавить запись'), icon: Icons.add, onPressed: _add)
          : null,
      search: HmSearchField(controller: _query, placeholder: tr('Search…', 'Поиск…'), onChanged: (_) => setState(() {})),
      controls: [
        HmButton(tr('Add', 'Добавить'), variant: HmVariant.primary, icon: Icons.add, onPressed: _add),
        if (selected != null)
          HmButton(tr('Edit group', 'Изменить группу'), icon: Icons.edit_outlined, onPressed: () => _editGroup(selected)),
      ],
      onRefresh: () => _load(),
      onTap: _open,
      rowStatus: (e) => e.conflictOf.isNotEmpty ? HmStatus.error : null,
      columns: _totp ? _totpColumns(groups) : _passwordColumns(groups),
      actions: (e) => [
        if (_totp)
          HmActionButton(
            icon: Icons.copy_outlined,
            label: tr('Copy code', 'Копировать код'),
            kind: HmAction.neutral,
            onPressed: () => _quickCopy(e),
          ),
        if (!_totp) ..._passwordActions(e),
        HmActionButton(icon: Icons.delete_outline, label: tr('Delete', 'Удалить'), kind: HmAction.delete, onPressed: () => _delete(e)),
      ],
    );
    final modes = HmSegmented<bool>(
      options: {false: tr('Passwords and keys', 'Пароли и ключи'), true: tr('2FA codes', '2FA-коды')},
      value: _totp,
      onChanged: _setMode,
    );
    return BlocListener<CoreCubit, CoreState>(
      listenWhen: (a, b) => a.treeRev != b.treeRev || a.secretsRev != b.secretsRev,
      listener: (_, _) => _load(quiet: true),
      child: HmPage(
        onRefresh: () => _load(quiet: true),
        children: [
          HmPageTitle(tr('Passwords', 'Пароли')),
          modes,
          if (_broken > 0)
            HmBanner(
              tr(
                '$_broken records could not be opened with this vault’s key.',
                'Не удалось открыть записей: $_broken (не тот ключ vault).',
              ),
              tone: HmTone.error,
            ),
          if (hm.mobile) ...[
            groupList,
            table,
          ] else
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(width: 240, child: groupList),
                SizedBox(width: hm.gapMd),
                Expanded(child: table),
              ],
            ),
        ],
      ),
    );
  }

  List<HmColumn<pb.SecretEntry>> _totpColumns(Map<String, pb.SecretGroup> groups) => [
    HmColumn(
      label: tr('Title', 'Название'),
      flex: 3,
      minWidth: 200,
      sortKey: (e) => e.title.toLowerCase(),
      cell: (e) => _TitleCell(entry: e, group: _group == _all ? groups[e.groupId] : null),
    ),
    HmColumn(
      label: tr('Account', 'Аккаунт'),
      flex: 2,
      minWidth: 160,
      cardIf: (e) => e.username.isNotEmpty,
      sortKey: (e) => e.username.toLowerCase(),
      cell: (e) => Text(e.username, maxLines: 1, overflow: TextOverflow.ellipsis),
    ),
    HmColumn(
      label: tr('Code', 'Код'),
      width: 230,
      cell: (e) => Align(
        alignment: Alignment.centerLeft,
        child: TotpCodeView(codes: _codes!, id: e.id),
      ),
    ),
    HmColumn(
      label: tr('Recovery', 'Резервные'),
      width: 110,
      sortKey: (e) => e.recoveryLeft,
      cell: (e) => Align(
        alignment: Alignment.centerLeft,
        child: HmBadge(
          '${e.recoveryLeft}',
          tone: e.recoveryLeft == 0 ? HmTone.neutral : (e.recoveryLeft <= 2 ? HmTone.warning : HmTone.ok),
        ),
      ),
    ),
  ];

  List<Widget> _passwordActions(pb.SecretEntry e) => [
    if (e.kind != pb.SecretKind.SECRET_SSH && e.kind != pb.SecretKind.SECRET_WEB3 && e.username.isNotEmpty)
      HmActionButton(
        icon: Icons.person_outline,
        label: tr('Copy login', 'Копировать логин'),
        kind: HmAction.neutral,
        onPressed: () => SecretClipboard.copyPlain(e.username, tr('Login', 'Логин')),
      ),
    HmActionButton(
      icon: Icons.copy_outlined,
      label: switch (e.kind) {
        pb.SecretKind.SECRET_SSH => tr('Copy public key', 'Копировать публичный ключ'),
        pb.SecretKind.SECRET_WEB3 => tr('Copy address', 'Копировать адрес'),
        _ => tr('Copy password', 'Копировать пароль'),
      },
      kind: HmAction.neutral,
      onPressed: () => _quickCopy(e),
    ),
  ];

  List<HmColumn<pb.SecretEntry>> _passwordColumns(Map<String, pb.SecretGroup> groups) => [
    HmColumn(
      label: tr('Title', 'Название'),
      flex: 3,
      minWidth: 220,
      sortKey: (e) => e.title.toLowerCase(),
      cell: (e) => _TitleCell(entry: e, group: _group == _all ? groups[e.groupId] : null),
    ),
    HmColumn(
      label: tr('Login / key', 'Логин / ключ'),
      flex: 3,
      minWidth: 180,
      cardIf: (e) => _subtitle(e).isNotEmpty,
      sortKey: (e) => _subtitle(e).toLowerCase(),
      cell: (e) => Text(_subtitle(e), maxLines: 1, overflow: TextOverflow.ellipsis),
    ),
    HmColumn(
      label: tr('Type', 'Тип'),
      width: 120,
      sortKey: (e) => e.kind.value,
      cell: (e) => Align(
        alignment: Alignment.centerLeft,
        child: _KindBadge(entry: e),
      ),
    ),
    HmColumn(
      label: tr('Changed', 'Изменена'),
      width: 180,
      mobile: false,
      sortKey: (e) => e.updatedUnix.toInt(),
      cell: (e) => Text(formatTime(e.updatedUnix)),
    ),
  ];

  static String _subtitle(pb.SecretEntry e) => switch (e.kind) {
    pb.SecretKind.SECRET_SSH => e.fingerprint,
    pb.SecretKind.SECRET_WEB3 => e.address,
    _ => e.username.isNotEmpty ? e.username : e.url,
  };
}

class _TitleCell extends StatelessWidget {
  const _TitleCell({required this.entry, this.group});

  final pb.SecretEntry entry;
  final pb.SecretGroup? group;

  @override
  Widget build(BuildContext context) {
    final e = entry;
    return Row(
      children: [
        Icon(kindIcon(e.kind), size: 16, color: HmColors.accent),
        const SizedBox(width: 10),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(e.title, overflow: TextOverflow.ellipsis, maxLines: 1),
              if (group != null) Text(group!.name, style: HmText.small, overflow: TextOverflow.ellipsis, maxLines: 1),
            ],
          ),
        ),
        if (e.conflictOf.isNotEmpty) ...[const SizedBox(width: 8), HmBadge(tr('conflict', 'конфликт'), tone: HmTone.error)],
      ],
    );
  }
}

IconData kindIcon(pb.SecretKind k) => switch (k) {
  pb.SecretKind.SECRET_TOTP => Icons.pin_outlined,
  pb.SecretKind.SECRET_SSH => Icons.terminal,
  pb.SecretKind.SECRET_WEB3 => Icons.account_balance_wallet_outlined,
  _ => Icons.key_outlined,
};

class _KindBadge extends StatelessWidget {
  const _KindBadge({required this.entry});

  final pb.SecretEntry entry;

  @override
  Widget build(BuildContext context) => switch (entry.kind) {
    pb.SecretKind.SECRET_SSH => const HmBadge('SSH', tone: HmTone.info),
    pb.SecretKind.SECRET_WEB3 => HmBadge(entry.network == pb.Web3Network.WEB3_SOLANA ? 'SOLANA' : 'EVM', tone: HmTone.accent),
    pb.SecretKind.SECRET_TOTP => const HmBadge('2FA', tone: HmTone.ok),
    _ => HmBadge(tr('password', 'пароль')),
  };
}

/// Groups: a card on desktops, a strip of chips on phones.
class _GroupList extends StatelessWidget {
  const _GroupList({
    required this.groups,
    required this.selected,
    required this.showNone,
    required this.count,
    required this.onSelect,
    required this.onAdd,
    required this.horizontal,
  });

  final List<pb.SecretGroup> groups;
  final String selected;
  final bool showNone;
  final int Function(String) count;
  final ValueChanged<String> onSelect;
  final VoidCallback onAdd;
  final bool horizontal;

  @override
  Widget build(BuildContext context) {
    final items = <Widget>[
      _GroupTile(
        label: tr('All', 'Все'),
        count: count(_all),
        active: selected == _all,
        compact: horizontal,
        onTap: () => onSelect(_all),
        icon: Icons.apps,
      ),
      for (final g in groups)
        _GroupTile(label: g.name, count: count(g.id), active: selected == g.id, compact: horizontal, group: g, onTap: () => onSelect(g.id)),
      if (showNone)
        _GroupTile(
          label: tr('No group', 'Без группы'),
          count: count(_none),
          active: selected == _none,
          compact: horizontal,
          icon: Icons.inbox_outlined,
          onTap: () => onSelect(_none),
        ),
    ];
    if (horizontal) {
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            for (final w in items) Padding(padding: const EdgeInsets.only(right: 8), child: w),
            HmIconButton(icon: Icons.create_new_folder_outlined, label: tr('New group', 'Новая группа'), onPressed: onAdd),
          ],
        ),
      );
    }
    return HmCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(padding: const EdgeInsets.fromLTRB(4, 4, 4, 8), child: HmSectionTitle(tr('Groups', 'Группы'))),
          for (final w in items) Padding(padding: const EdgeInsets.only(bottom: 4), child: w),
          const SizedBox(height: 8),
          HmButton(tr('New group', 'Новая группа'), icon: Icons.create_new_folder_outlined, onPressed: onAdd),
        ],
      ),
    );
  }
}

class _GroupTile extends StatefulWidget {
  const _GroupTile({
    required this.label,
    required this.count,
    required this.active,
    required this.compact,
    required this.onTap,
    this.group,
    this.icon,
  });

  final String label;
  final int count;
  final bool active;
  final bool compact;
  final VoidCallback onTap;
  final pb.SecretGroup? group;
  final IconData? icon;

  @override
  State<_GroupTile> createState() => _GroupTileState();
}

class _GroupTileState extends State<_GroupTile> {
  bool _hot = false;

  @override
  Widget build(BuildContext context) {
    final hm = Hm.of(context);
    final alpha = (widget.active ? 0.08 : 0.0) + (_hot ? 0.10 : 0.0);
    final avatar = widget.group != null
        ? GroupAvatar(group: widget.group!, size: 24)
        : SizedBox.square(dimension: 24, child: Icon(widget.icon, size: 16, color: widget.active ? HmColors.accent : HmColors.muted));
    return Semantics(
      button: true,
      selected: widget.active,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hot = true),
        onExit: (_) => setState(() => _hot = false),
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            constraints: BoxConstraints(minHeight: hm.mobile ? 44 : 36),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: HmColors.tint(HmColors.accent, alpha),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: widget.active
                    ? HmColors.tint(HmColors.accent, HmColors.ring)
                    : (widget.compact ? HmColors.border : Colors.transparent),
              ),
            ),
            child: Row(
              mainAxisSize: widget.compact ? MainAxisSize.min : MainAxisSize.max,
              children: [
                avatar,
                const SizedBox(width: 10),
                if (widget.compact)
                  Text(widget.label, style: HmText.body.copyWith(color: widget.active ? HmColors.accent : HmColors.text))
                else
                  Expanded(
                    child: Text(
                      widget.label,
                      style: HmText.body.copyWith(color: widget.active ? HmColors.accent : HmColors.text),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                const SizedBox(width: 8),
                Text('${widget.count}', style: HmText.small),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A group's picture, or its first letter on a tinted square.
class GroupAvatar extends StatelessWidget {
  const GroupAvatar({super.key, required this.group, this.size = 24});

  final pb.SecretGroup group;
  final double size;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(size / 4);
    if (group.icon.isNotEmpty) {
      return ClipRRect(
        borderRadius: radius,
        child: Image.memory(
          Uint8List.fromList(group.icon),
          width: size,
          height: size,
          fit: BoxFit.cover,
          gaplessPlayback: true,
          errorBuilder: (_, _, _) => _letter(radius),
        ),
      );
    }
    return _letter(radius);
  }

  Widget _letter(BorderRadius radius) => Container(
    width: size,
    height: size,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      color: HmColors.tint(HmColors.purple, HmColors.badge),
      borderRadius: radius,
      border: Border.all(color: HmColors.tint(HmColors.purple, HmColors.ring)),
    ),
    child: Text(
      group.name.isEmpty ? '?' : group.name.characters.first.toUpperCase(),
      style: HmText.jb(size * 0.45, weight: 700, color: HmColors.purpleLight),
    ),
  );
}
