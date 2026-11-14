import 'package:flutter/material.dart';

import '../../core/theme/colors.dart';
import '../../core/theme/layout.dart';

/// The canvas of a page (§ 2.3): gutters and section gaps come from here,
/// pages add none of their own. On phones it pulls to refresh and tells
/// long lists when the end comes near (infinite scroll, App. D).
class HmPage extends StatefulWidget {
  const HmPage({super.key, required this.children, this.onRefresh});

  final List<Widget> children;
  final Future<void> Function()? onRefresh;

  @override
  State<HmPage> createState() => _HmPageState();
}

class _HmPageState extends State<HmPage> {
  final _scroll = ScrollController();
  final _end = ValueNotifier(0);

  @override
  void initState() {
    super.initState();
    _scroll.addListener(() {
      final p = _scroll.position;
      if (p.pixels > p.maxScrollExtent - 600) _end.value++;
    });
  }

  @override
  void dispose() {
    _scroll.dispose();
    _end.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hm = Hm.of(context);
    Widget view = SingleChildScrollView(
      controller: _scroll,
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.fromLTRB(hm.pageX, hm.pageY, hm.pageX, hm.pageBottom),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final (i, c) in widget.children.indexed) ...[if (i > 0) SizedBox(height: hm.gapLg), c],
        ],
      ),
    );
    if (hm.mobile && widget.onRefresh != null) {
      view = RefreshIndicator(onRefresh: widget.onRefresh!, color: HmColors.accent, backgroundColor: HmColors.surface, child: view);
    }
    return PageEnd(
      notifier: _end,
      child: Scrollbar(controller: _scroll, child: view),
    );
  }
}

/// Ticks when the page is scrolled near its end.
class PageEnd extends InheritedNotifier<ValueNotifier<int>> {
  const PageEnd({super.key, required super.notifier, required super.child});

  static ValueNotifier<int>? of(BuildContext context) => context.dependOnInheritedWidgetOfExactType<PageEnd>()?.notifier;
}
