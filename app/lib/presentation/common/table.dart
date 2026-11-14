import 'package:flutter/material.dart';

import '../../core/theme/colors.dart';
import '../../core/theme/layout.dart';
import '../../core/theme/typography.dart';
import 'buttons.dart';
import 'forms.dart';
import 'page.dart';
import 'surfaces.dart';
import '../../core/i18n.dart';

/// A column of [HmTable] (§ 9.5).
class HmColumn<T> {
  const HmColumn({
    required this.label,
    required this.cell,
    this.minWidth = 100,
    this.flex = 1,
    this.width,
    this.sortKey,
    this.mobile = true,
    this.cardIf,
  });

  final String label;
  final Widget Function(T) cell;
  final double minWidth;
  final int flex;
  final double? width; // fixed width
  final Comparable<Object?> Function(T)? sortKey;

  /// Shown as a field on phone cards (M8.2: hide what does not fit).
  final bool mobile;

  /// On phone cards, the field is left out for items where this is false
  /// (an empty cell would be a bare label).
  final bool Function(T)? cardIf;
}

/// The data table (§ 9): a container with a controls bar, a grid of rows
/// and pagination on desktops; row cards with a sort bar on phones (M9).
class HmTable<T> extends StatefulWidget {
  const HmTable({
    super.key,
    required this.items,
    required this.columns,
    this.loading = false,
    this.error,
    this.emptyText,
    this.emptyIcon,
    this.emptyAction,
    this.onTap,
    this.rowStatus,
    this.actions,
    this.search,
    this.controls = const [],
    this.onRefresh,
    this.header,
  });

  final List<T> items;
  final List<HmColumn<T>> columns;
  final bool loading;
  final String? error;
  final String? emptyText; // default: "Nothing found"
  final IconData? emptyIcon;
  final Widget? emptyAction;
  final void Function(T)? onTap;
  final HmStatus? Function(T)? rowStatus; // ok / error stripe only (§ 9.8)
  final List<Widget> Function(T)? actions;
  final Widget? search; // leftmost in the controls bar
  final List<Widget> controls; // page actions, left of refresh
  final VoidCallback? onRefresh;
  final Widget? header; // above the controls (e.g. a path bar)

  @override
  State<HmTable<T>> createState() => _HmTableState<T>();
}

class _HmTableState<T> extends State<HmTable<T>> {
  int? _sortCol;
  bool _asc = true;
  int _page = 0;
  int _perPage = 50;
  int _visible = 60; // phone cards rendered so far
  ValueNotifier<int>? _end;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final end = PageEnd.of(context);
    if (end != _end) {
      _end?.removeListener(_more);
      _end = end?..addListener(_more);
    }
  }

  @override
  void dispose() {
    _end?.removeListener(_more);
    super.dispose();
  }

  void _more() {
    if (_visible < widget.items.length) setState(() => _visible += 60);
  }

  @override
  void didUpdateWidget(HmTable<T> old) {
    super.didUpdateWidget(old);
    final pages = (widget.items.length / _perPage).ceil();
    if (_page >= pages) _page = (pages - 1).clamp(0, 1 << 30);
  }

  List<T> get _sorted {
    final list = [...widget.items];
    final key = _sortCol == null ? null : widget.columns[_sortCol!].sortKey;
    if (key != null) {
      list.sort((a, b) => _asc ? key(a).compareTo(key(b)) : key(b).compareTo(key(a)));
    }
    return list;
  }

  void _sort(int i) => setState(() {
    if (_sortCol == i) {
      _asc = !_asc;
    } else {
      _sortCol = i;
      _asc = true;
    }
  });

  @override
  Widget build(BuildContext context) {
    final hm = Hm.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (widget.error != null) ...[HmBanner(widget.error!, tone: HmTone.error), SizedBox(height: hm.gapSm)],
        Container(
          padding: EdgeInsets.all(hm.mobile ? 12 : 20),
          decoration: BoxDecoration(
            color: HmColors.surface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: HmColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (widget.header != null) ...[widget.header!, const SizedBox(height: 12)],
              _controls(hm),
              const SizedBox(height: 16),
              hm.mobile ? _cards() : _grid(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _controls(Hm hm) {
    final right = [
      ...widget.controls,
      if (widget.onRefresh != null) HmIconButton(icon: Icons.refresh, label: tr('Refresh', 'Обновить'), onPressed: widget.onRefresh),
    ];
    final sortable = [
      for (final (i, c) in widget.columns.indexed)
        if (c.sortKey != null) i,
    ];
    if (hm.mobile) {
      // Search row, sort row (with refresh), then the actions on their own row (M11).
      final refresh = widget.onRefresh == null
          ? null
          : HmIconButton(icon: Icons.refresh, label: tr('Refresh', 'Обновить'), onPressed: widget.onRefresh);
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (widget.search != null) ...[widget.search!, const SizedBox(height: 8)],
          if (sortable.isNotEmpty) ...[_sortBar(sortable, refresh), const SizedBox(height: 8)],
          if (widget.controls.isNotEmpty || (sortable.isEmpty && refresh != null))
            Wrap(spacing: 8, runSpacing: 8, children: [...widget.controls, if (sortable.isEmpty) ?refresh]),
        ],
      );
    }
    return Row(
      children: [
        ?widget.search,
        const Spacer(),
        for (final (i, w) in right.indexed) ...[if (i > 0) const SizedBox(width: 8), w],
      ],
    );
  }

  // Phones sort with a select and a direction toggle (M9.1).
  Widget _sortBar(List<int> sortable, Widget? refresh) => Row(
    children: [
      Expanded(
        child: HmSelect<int>(
          label: tr('Sort', 'Сортировка'),
          showLabel: false,
          options: {for (final i in sortable) i: tr('Sort: ', 'Сортировка: ') + widget.columns[i].label.toLowerCase()},
          value: _sortCol,
          placeholder: tr('Sort: as is', 'Сортировка: как есть'),
          onChanged: (i) => setState(() => _sortCol = i),
        ),
      ),
      const SizedBox(width: 8),
      SizedBox.square(
        dimension: 48,
        child: HmIconButton(
          icon: _asc ? Icons.arrow_upward : Icons.arrow_downward,
          label: _asc ? tr('Ascending', 'По возрастанию') : tr('Descending', 'По убыванию'),
          onPressed: () => setState(() => _asc = !_asc),
        ),
      ),
      if (refresh != null) ...[const SizedBox(width: 8), refresh],
    ],
  );

  Widget _state() {
    if (widget.loading) return const SizedBox(height: 200, child: HmLoading());
    return Center(
      child: HmEmptyState(widget.emptyText ?? tr('Nothing found', 'Ничего не найдено'), icon: widget.emptyIcon, action: widget.emptyAction),
    );
  }

  Widget _cell(HmColumn<T> c, Widget child) {
    final inner = Padding(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10), child: child);
    if (c.width != null) return SizedBox(width: c.width, child: inner);
    return Expanded(
      flex: c.flex,
      child: ConstrainedBox(
        constraints: BoxConstraints(minWidth: c.minWidth),
        child: inner,
      ),
    );
  }

  Widget _grid() {
    final all = _sorted;
    final pages = (all.length / _perPage).ceil();
    final rows = all.skip(_page * _perPage).take(_perPage).toList();
    final actionsWidth = widget.actions == null ? 0.0 : 150.0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: HmColors.border)),
          ),
          child: Row(
            children: [
              for (final (i, c) in widget.columns.indexed)
                _cell(c, _HeaderLabel(column: c, active: _sortCol == i, asc: _asc, onTap: c.sortKey == null ? null : () => _sort(i))),
              if (widget.actions != null) SizedBox(width: actionsWidth),
            ],
          ),
        ),
        if (widget.loading || rows.isEmpty)
          _state()
        else
          for (final (i, item) in rows.indexed)
            _GridRow(
              last: i == rows.length - 1,
              status: widget.rowStatus?.call(item),
              onTap: widget.onTap == null ? null : () => widget.onTap!(item),
              children: [
                for (final c in widget.columns)
                  _cell(c, DefaultTextStyle(style: HmText.body, overflow: TextOverflow.ellipsis, maxLines: 1, child: c.cell(item))),
                if (widget.actions != null)
                  SizedBox(
                    width: actionsWidth,
                    child: Padding(
                      padding: const EdgeInsets.only(right: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          for (final (j, a) in widget.actions!(item).indexed) ...[if (j > 0) const SizedBox(width: 6), a],
                        ],
                      ),
                    ),
                  ),
              ],
            ),
        if (all.length > _perPage) _pagination(all.length, pages),
      ],
    );
  }

  Widget _pagination(int total, int pages) {
    final from = _page * _perPage + 1;
    final to = ((_page + 1) * _perPage).clamp(0, total);
    final shown = <int>{0, pages - 1, _page - 1, _page, _page + 1}.where((p) => p >= 0 && p < pages).toList()..sort();
    return Container(
      margin: const EdgeInsets.only(top: 4),
      padding: const EdgeInsets.only(top: 12, bottom: 4),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: HmColors.border)),
      ),
      child: Row(
        children: [
          Text(tr('Rows per page', 'Строк на странице'), style: HmText.small),
          const SizedBox(width: 8),
          for (final n in const [10, 20, 50, 100])
            Padding(
              padding: const EdgeInsets.only(right: 4),
              child: _PageButton(
                label: '$n',
                active: n == _perPage,
                onTap: () => setState(() {
                  _perPage = n;
                  _page = 0;
                }),
              ),
            ),
          const SizedBox(width: 12),
          Text(tr('$from–$to of $total', '$from–$to из $total'), style: HmText.small),
          const Spacer(),
          _PageButton(label: '‹', onTap: _page == 0 ? null : () => setState(() => _page--)),
          for (final (i, p) in shown.indexed) ...[
            if (i > 0 && p - shown[i - 1] > 1)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Text('…', style: HmText.small),
              ),
            Padding(
              padding: const EdgeInsets.only(left: 4),
              child: _PageButton(label: '${p + 1}', active: p == _page, onTap: () => setState(() => _page = p)),
            ),
          ],
          const SizedBox(width: 4),
          _PageButton(label: '›', onTap: _page >= pages - 1 ? null : () => setState(() => _page++)),
        ],
      ),
    );
  }

  Widget _cards() {
    final all = _sorted;
    if (widget.loading || all.isEmpty) return _state();
    final shown = all.take(_visible).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final item in shown)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _Card<T>(
              item: item,
              columns: widget.columns,
              onTap: widget.onTap,
              actions: widget.actions,
              status: widget.rowStatus?.call(item),
            ),
          ),
        if (shown.length < all.length)
          Padding(
            padding: const EdgeInsets.all(12),
            child: Center(child: Text(tr('${shown.length} of ${all.length}', '${shown.length} из ${all.length}'), style: HmText.small)),
          ),
      ],
    );
  }
}

class _HeaderLabel<T> extends StatelessWidget {
  const _HeaderLabel({required this.column, required this.active, required this.asc, this.onTap});

  final HmColumn<T> column;
  final bool active;
  final bool asc;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final label = Text(column.label.toUpperCase(), style: HmText.th, maxLines: 1, overflow: TextOverflow.ellipsis);
    if (onTap == null) return label;
    // Dual arrows: the active direction at 1.0, the other at 0.4 (§ 9.5).
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Row(
          children: [
            Flexible(child: label),
            const SizedBox(width: 4),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Opacity(
                  opacity: active && asc ? 1 : 0.4,
                  child: const Icon(Icons.arrow_drop_up, size: 12, color: HmColors.muted),
                ),
                Opacity(
                  opacity: active && !asc ? 1 : 0.4,
                  child: const Icon(Icons.arrow_drop_down, size: 12, color: HmColors.muted),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _GridRow extends StatefulWidget {
  const _GridRow({required this.children, required this.last, this.onTap, this.status});

  final List<Widget> children;
  final bool last;
  final VoidCallback? onTap;
  final HmStatus? status;

  @override
  State<_GridRow> createState() => _GridRowState();
}

class _GridRowState extends State<_GridRow> {
  bool _hot = false;

  @override
  Widget build(BuildContext context) {
    final stripe = widget.status == null ? null : statusColor(widget.status!);
    return MouseRegion(
      cursor: widget.onTap == null ? MouseCursor.defer : SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hot = true),
      onExit: (_) => setState(() => _hot = false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          constraints: const BoxConstraints(minHeight: 52),
          decoration: BoxDecoration(
            color: _hot ? HmColors.tint(HmColors.accent, HmColors.subtle) : Colors.transparent,
            border: Border(
              left: stripe == null ? BorderSide.none : BorderSide(color: stripe, width: 3),
              bottom: widget.last ? BorderSide.none : BorderSide(color: HmColors.tint(HmColors.border, 0.5)),
            ),
          ),
          child: Row(children: widget.children),
        ),
      ),
    );
  }
}

class _Card<T> extends StatelessWidget {
  const _Card({required this.item, required this.columns, this.onTap, this.actions, this.status});

  final T item;
  final List<HmColumn<T>> columns;
  final void Function(T)? onTap;
  final List<Widget> Function(T)? actions;
  final HmStatus? status;

  @override
  Widget build(BuildContext context) {
    final fields = columns.skip(1).where((c) => c.mobile && (c.cardIf?.call(item) ?? true)).toList();
    final acts = actions?.call(item) ?? const <Widget>[];
    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        onTap: onTap == null ? null : () => onTap!(item),
        borderRadius: BorderRadius.circular(8),
        highlightColor: HmColors.tint(HmColors.accent, 0.08),
        child: Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: HmColors.bg,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: HmColors.border),
          ),
          // The status stripe is a separate edge: a rounded border must be one colour.
          foregroundDecoration: status == null
              ? null
              : BoxDecoration(
                  border: Border(left: BorderSide(color: statusColor(status!), width: 3)),
                ),
          constraints: const BoxConstraints(minHeight: 56),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DefaultTextStyle(style: HmText.bodyStrong, child: columns.first.cell(item)),
              for (final c in fields) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text(c.label.toUpperCase(), style: HmText.th),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: DefaultTextStyle(style: HmText.body, overflow: TextOverflow.ellipsis, maxLines: 1, child: c.cell(item)),
                      ),
                    ),
                  ],
                ),
              ],
              if (acts.isNotEmpty) ...[const SizedBox(height: 4), Wrap(alignment: WrapAlignment.end, spacing: 8, children: acts)],
            ],
          ),
        ),
      ),
    );
  }
}

class _PageButton extends StatelessWidget {
  const _PageButton({required this.label, this.active = false, this.onTap});

  final String label;
  final bool active;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => MouseRegion(
    cursor: onTap == null ? SystemMouseCursors.forbidden : SystemMouseCursors.click,
    child: GestureDetector(
      onTap: onTap,
      child: Opacity(
        opacity: onTap == null && !active ? 0.3 : 1,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: active ? HmColors.accent : HmColors.surface,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: active ? HmColors.accent : HmColors.border),
          ),
          child: Text(label, style: HmText.jb(12, color: active ? HmColors.onAccent : HmColors.text)),
        ),
      ),
    ),
  );
}
