import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/colors.dart';
import '../../core/theme/layout.dart';
import '../../core/theme/typography.dart';
import 'buttons.dart';
import '../../core/i18n.dart';

/// Modal widths (§ 14.2).
enum HmModalSize { sm, md, lg }

const _scrim = Color(0x99000000); // rgba(0,0,0,0.6) (§ 14.1)

/// Opens a modal: a centred dialog on desktops (§ 14), a bottom sheet with
/// a handle on phones (M14). [actions] is `[Cancel, Primary]` in that
/// order; on phones it is stacked with the primary on top (M7).
Future<T?> showHmModal<T>(
  BuildContext context, {
  required String title,
  required WidgetBuilder body,
  List<Widget> Function(BuildContext)? actions,
  HmModalSize size = HmModalSize.md,
  bool dismissible = true,
}) {
  final hm = Hm.of(context);
  if (hm.mobile) {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      isDismissible: dismissible,
      enableDrag: dismissible,
      useSafeArea: true,
      barrierColor: _scrim,
      backgroundColor: Colors.transparent,
      constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.92),
      // dismissible: false also blocks the back button (M14).
      builder: (ctx) => PopScope(
        canPop: dismissible,
        child: _Sheet(title: title, body: body, actions: actions),
      ),
    );
  }
  return showGeneralDialog<T>(
    context: context,
    barrierDismissible: dismissible,
    barrierLabel: title,
    barrierColor: _scrim,
    transitionDuration: const Duration(milliseconds: 150),
    pageBuilder: (ctx, _, _) => PopScope(
      canPop: dismissible,
      child: _Dialog(title: title, body: body, actions: actions, size: size, dismissible: dismissible),
    ),
    transitionBuilder: (ctx, a, _, child) => BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 4 * a.value, sigmaY: 4 * a.value),
      child: FadeTransition(opacity: a, child: child),
    ),
  );
}

class _Dialog extends StatelessWidget {
  const _Dialog({required this.title, required this.body, required this.actions, required this.size, required this.dismissible});

  final String title;
  final WidgetBuilder body;
  final List<Widget> Function(BuildContext)? actions;
  final HmModalSize size;
  final bool dismissible;

  @override
  Widget build(BuildContext context) {
    final width = switch (size) {
      HmModalSize.sm => 380.0,
      HmModalSize.md => 520.0,
      HmModalSize.lg => 720.0,
    };
    final screen = MediaQuery.sizeOf(context);
    return CallbackShortcuts(
      bindings: {if (dismissible) const SingleActivator(LogicalKeyboardKey.escape): () => Navigator.of(context).maybePop()},
      child: Center(
        child: Material(
          type: MaterialType.transparency,
          child: FocusScope(
            autofocus: true,
            child: Container(
              width: width,
              constraints: BoxConstraints(maxWidth: screen.width * 0.9, maxHeight: screen.height * 0.9),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: HmColors.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: HmColors.border),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Semantics(header: true, child: Text(title, style: HmText.modalTitle)),
                  const SizedBox(height: 20),
                  Flexible(
                    child: SingleChildScrollView(child: Builder(builder: body)),
                  ),
                  if (actions != null) ...[
                    const SizedBox(height: 24),
                    const Divider(),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        for (final (i, a) in actions!(context).indexed) ...[if (i > 0) const SizedBox(width: 12), a],
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Sheet extends StatelessWidget {
  const _Sheet({required this.title, required this.body, required this.actions});

  final String title;
  final WidgetBuilder body;
  final List<Widget> Function(BuildContext)? actions;

  @override
  Widget build(BuildContext context) {
    final inset = MediaQuery.viewInsetsOf(context).bottom;
    final safe = MediaQuery.paddingOf(context).bottom;
    final acts = actions?.call(context) ?? const [];
    return Padding(
      padding: EdgeInsets.only(bottom: inset),
      child: Container(
        padding: EdgeInsets.fromLTRB(16, 12, 16, 20 + safe),
        decoration: const BoxDecoration(
          color: HmColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          border: Border.fromBorderSide(BorderSide(color: HmColors.border)), // bottom edge is off screen
          boxShadow: [BoxShadow(color: Color(0x66000000), offset: Offset(0, -8), blurRadius: 24)],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(color: HmColors.border, borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 16),
            Semantics(header: true, child: Text(title, style: HmText.modalTitle)),
            const SizedBox(height: 16),
            Flexible(
              child: SingleChildScrollView(child: Builder(builder: body)),
            ),
            if (acts.isNotEmpty) ...[
              const SizedBox(height: 20),
              // DOM order [Cancel, Primary] renders primary on top (M7).
              for (final a in acts.reversed) ...[Padding(padding: const EdgeInsets.only(bottom: 8), child: a)],
            ],
          ],
        ),
      ),
    );
  }
}

/// A centred confirmation dialog on every platform (App. D: confirms stay
/// centred). Destructive confirms use a red primary (§ 14.4).
Future<bool> confirm(
  BuildContext context, {
  required String title,
  required String message,
  required String action,
  bool destructive = false,
}) async {
  final hm = Hm.of(context);
  final ok = await showGeneralDialog<bool>(
    context: context,
    barrierDismissible: true,
    barrierLabel: title,
    barrierColor: _scrim,
    pageBuilder: (ctx, _, _) {
      final buttons = [
        HmButton(tr('Cancel', 'Отмена'), variant: HmVariant.neutral, expand: hm.mobile, onPressed: () => Navigator.pop(ctx, false)),
        HmButton(
          action,
          variant: destructive ? HmVariant.red : HmVariant.primary,
          expand: hm.mobile,
          onPressed: () {
            if (destructive) HapticFeedback.mediumImpact();
            Navigator.pop(ctx, true);
          },
        ),
      ];
      return _Dialog(
        title: title,
        size: HmModalSize.sm,
        dismissible: true,
        body: (_) => Text(message, style: HmText.body.copyWith(height: 1.5)),
        actions: (_) => hm.mobile
            ? [
                Expanded(child: Column(children: [buttons[1], const SizedBox(height: 8), buttons[0]])),
              ]
            : buttons,
      );
    },
    transitionBuilder: (ctx, a, _, child) => BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 4 * a.value, sigmaY: 4 * a.value),
      child: FadeTransition(opacity: a, child: child),
    ),
  );
  return ok ?? false;
}

/// Picks one option: a dropdown panel under the trigger on desktops
/// (§ 16), a picker sheet on phones (App. D). From 8 options on, a search
/// field sits on top (§ 16.4).
Future<T?> pickOption<T>(
  BuildContext context, {
  required String title,
  required Map<T, String> options,
  T? value,
  String Function(T)? describe,
}) {
  final hm = Hm.of(context);
  final list = _OptionList<T>(options: options, value: value, describe: describe);
  if (hm.mobile) {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      barrierColor: _scrim,
      backgroundColor: Colors.transparent,
      constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.8),
      builder: (_) => _Sheet(title: title, body: (_) => list, actions: null),
    );
  }
  final box = context.findRenderObject() as RenderBox?;
  final origin = box?.localToGlobal(Offset.zero) ?? Offset.zero;
  final size = box?.size ?? Size.zero;
  return showGeneralDialog<T>(
    context: context,
    barrierDismissible: true,
    barrierLabel: title,
    barrierColor: Colors.transparent,
    transitionDuration: Duration.zero,
    pageBuilder: (ctx, _, _) {
      final screen = MediaQuery.sizeOf(ctx);
      final below = screen.height - origin.dy - size.height - 8;
      final up = below < 240 && origin.dy > below;
      final width = size.width.clamp(180.0, 320.0);
      return CallbackShortcuts(
        bindings: {const SingleActivator(LogicalKeyboardKey.escape): () => Navigator.pop(ctx)},
        child: Stack(
          children: [
            Positioned(
              left: origin.dx.clamp(8, screen.width - width - 8),
              top: up ? null : origin.dy + size.height + 8,
              bottom: up ? screen.height - origin.dy + 8 : null,
              width: width,
              child: Material(
                type: MaterialType.transparency,
                child: Container(
                  constraints: BoxConstraints(maxHeight: screen.height * 0.6),
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: HmColors.surface,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: HmColors.border),
                    boxShadow: const [BoxShadow(color: Color(0x66000000), offset: Offset(0, 8), blurRadius: 24)],
                  ),
                  child: list,
                ),
              ),
            ),
          ],
        ),
      );
    },
  );
}

class _OptionList<T> extends StatefulWidget {
  const _OptionList({required this.options, required this.value, this.describe});

  final Map<T, String> options;
  final T? value;
  final String Function(T)? describe;

  @override
  State<_OptionList<T>> createState() => _OptionListState<T>();
}

class _OptionListState<T> extends State<_OptionList<T>> {
  final _q = TextEditingController();

  @override
  void dispose() {
    _q.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hm = Hm.of(context);
    final q = _q.text.toLowerCase();
    final items = widget.options.entries
        .where((e) => q.isEmpty || e.value.toLowerCase().contains(q) || (widget.describe?.call(e.key).toLowerCase().contains(q) ?? false))
        .toList();
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (widget.options.length >= 8)
          Padding(
            padding: const EdgeInsets.all(4),
            child: TextField(
              controller: _q,
              autofocus: !hm.mobile,
              autocorrect: false,
              onChanged: (_) => setState(() {}),
              style: HmText.jb(hm.inputFont),
              decoration: InputDecoration(
                isDense: true,
                filled: true,
                fillColor: HmColors.bg,
                hintText: tr('Search…', 'Поиск…'),
                hintStyle: HmText.jb(hm.inputFont, color: HmColors.muted),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: hm.mobile ? 12 : 8),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: HmColors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: HmColors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: HmColors.accent),
                ),
              ),
            ),
          ),
        if (items.isEmpty)
          Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              tr('Nothing found', 'Ничего не найдено'),
              textAlign: TextAlign.center,
              style: HmText.body.copyWith(color: HmColors.muted),
            ),
          )
        else
          Flexible(
            child: ListView(
              shrinkWrap: true,
              padding: EdgeInsets.zero,
              children: [
                for (final e in items)
                  _OptionItem(
                    label: e.value,
                    detail: widget.describe?.call(e.key),
                    active: e.key == widget.value,
                    onTap: () => Navigator.pop(context, e.key),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}

class _OptionItem extends StatefulWidget {
  const _OptionItem({required this.label, required this.active, required this.onTap, this.detail});

  final String label;
  final String? detail;
  final bool active;
  final VoidCallback onTap;

  @override
  State<_OptionItem> createState() => _OptionItemState();
}

class _OptionItemState extends State<_OptionItem> {
  bool _hot = false;

  @override
  Widget build(BuildContext context) {
    final hm = Hm.of(context);
    final bg = widget.active
        ? HmColors.tint(HmColors.accent, HmColors.resting)
        : _hot
        ? HmColors.tint(HmColors.accent, 0.08)
        : Colors.transparent;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hot = true),
      onExit: (_) => setState(() => _hot = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          constraints: BoxConstraints(minHeight: hm.mobile ? 48 : 0),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(6)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(widget.label, style: HmText.jb(hm.mobile ? 13 : 12, color: widget.active ? HmColors.accent : HmColors.text)),
              if (widget.detail != null && widget.detail!.isNotEmpty)
                Text(
                  widget.detail!,
                  style: HmText.jb(11, color: HmColors.muted),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Toast types (§ 15.3).
enum ToastKind { success, error, info, warning }

class _Toast {
  _Toast(this.kind, this.title, this.detail);

  final ToastKind kind;
  final String title;
  final String? detail;
  final key = UniqueKey();
}

/// Toast stack: bottom-right on desktops (§ 15.3), full width above the
/// tab bar on phones (M15). Newest on top; errors stay until closed.
class Toasts {
  static final _items = ValueNotifier<List<_Toast>>([]);

  static void show(String title, {ToastKind kind = ToastKind.info, String? detail}) {
    final t = _Toast(kind, title, detail);
    _items.value = [t, ..._items.value];
    final life = switch (kind) {
      ToastKind.error => null,
      ToastKind.warning => const Duration(seconds: 6),
      _ => const Duration(seconds: 4),
    };
    if (life != null) Timer(life, () => _remove(t));
  }

  static void success(String title, [String? detail]) => show(title, kind: ToastKind.success, detail: detail);
  static void error(String title, [String? detail]) => show(title, kind: ToastKind.error, detail: detail);

  static void _remove(_Toast t) => _items.value = _items.value.where((x) => x != t).toList();
}

/// Renders the toasts above everything; mount it last in the app root.
class ToastHost extends StatelessWidget {
  const ToastHost({super.key, required this.bottomOffset});

  /// Space kept free at the bottom (the tab bar on phones).
  final double bottomOffset;

  @override
  Widget build(BuildContext context) {
    final hm = Hm.of(context);
    return ValueListenableBuilder(
      valueListenable: Toasts._items,
      builder: (context, items, _) => Positioned(
        right: hm.mobile ? 16 : 24,
        left: hm.mobile ? 16 : null,
        bottom: (hm.mobile ? 8 : 24) + bottomOffset + MediaQuery.paddingOf(context).bottom,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            for (final t in items.take(4))
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: _ToastView(key: t.key, toast: t),
              ),
          ],
        ),
      ),
    );
  }
}

class _ToastView extends StatelessWidget {
  const _ToastView({super.key, required this.toast});

  final _Toast toast;

  @override
  Widget build(BuildContext context) {
    final hm = Hm.of(context);
    final (color, icon) = switch (toast.kind) {
      ToastKind.success => (HmColors.ok, Icons.check_circle_outline),
      ToastKind.error => (HmColors.error, Icons.error_outline),
      ToastKind.warning => (HmColors.warning, Icons.warning_amber_rounded),
      ToastKind.info => (HmColors.accent, Icons.info_outline),
    };
    return Semantics(
      liveRegion: true,
      child: Material(
        type: MaterialType.transparency,
        child: Container(
          constraints: BoxConstraints(minWidth: hm.mobile ? double.infinity : 280, maxWidth: hm.mobile ? double.infinity : 420),
          padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: HmColors.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: HmColors.border),
            boxShadow: const [BoxShadow(color: Color(0x66000000), offset: Offset(0, 8), blurRadius: 24)],
          ),
          // The 3 px type stripe (§ 15.3); a rounded border must be one colour.
          foregroundDecoration: BoxDecoration(
            border: Border(left: BorderSide(color: color, width: 3)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 10),
              Flexible(
                fit: hm.mobile ? FlexFit.tight : FlexFit.loose,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(toast.title, style: HmText.jb(12, weight: 600), maxLines: 1, overflow: TextOverflow.ellipsis),
                    if (toast.detail != null)
                      Text(
                        toast.detail!,
                        style: HmText.jb(12, color: HmColors.muted),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 4),
              Semantics(
                button: true,
                label: tr('Close', 'Закрыть'),
                child: InkResponse(
                  radius: 16,
                  onTap: () => Toasts._remove(toast),
                  child: const Padding(
                    padding: EdgeInsets.all(4),
                    child: Icon(Icons.close, size: 14, color: HmColors.muted),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
