import 'package:flutter/material.dart';

import '../../core/theme/colors.dart';
import '../../core/theme/layout.dart';
import '../../core/theme/typography.dart';

/// Button variants (§ 7.3). One `primary` per view; destructive is `red`;
/// cancel is `neutral`.
enum HmVariant { primary, cyan, green, purple, red, neutral }

/// The one button of the app (§ 7). Heights are fixed: 30/24 px on
/// desktops, 44/36 on phones (M7). Hover (desktop) or press (touch) adds
/// +0.10 alpha.
class HmButton extends StatefulWidget {
  const HmButton(
    this.label, {
    super.key,
    this.onPressed,
    this.variant = HmVariant.cyan,
    this.small = false,
    this.icon,
    this.loading = false,
    this.expand = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final HmVariant variant;
  final bool small;
  final IconData? icon;
  final bool loading;

  /// Full width: only for form and sheet footers on phones (M7).
  final bool expand;

  @override
  State<HmButton> createState() => _HmButtonState();
}

class _HmButtonState extends State<HmButton> {
  bool _hot = false;

  (Color fg, Color bg, Color? border) _colors() {
    final hot = _hot && widget.onPressed != null && !widget.loading;
    double a(double rest) => hot ? rest + 0.10 : rest;
    Color tinted(Color c) => HmColors.tint(c, a(HmColors.resting));
    return switch (widget.variant) {
      HmVariant.primary => (HmColors.onAccent, hot ? HmColors.tint(HmColors.accent, 0.9) : HmColors.accent, null),
      HmVariant.cyan => (HmColors.accent, tinted(HmColors.accent), HmColors.tint(HmColors.accent, HmColors.ring)),
      HmVariant.green => (HmColors.ok, tinted(HmColors.ok), HmColors.tint(HmColors.ok, HmColors.ring)),
      HmVariant.purple => (HmColors.purpleLight, tinted(HmColors.purple), HmColors.tint(HmColors.purple, HmColors.ring)),
      HmVariant.red => (HmColors.error, tinted(HmColors.error), HmColors.tint(HmColors.error, HmColors.ring)),
      HmVariant.neutral => (
        hot ? HmColors.text : HmColors.muted,
        hot ? HmColors.tint(HmColors.text, 0.05) : Colors.transparent,
        HmColors.border,
      ),
    };
  }

  @override
  Widget build(BuildContext context) {
    final hm = Hm.of(context);
    final (fg, bg, border) = _colors();
    final disabled = widget.onPressed == null || widget.loading;
    final style = HmText.button.copyWith(color: fg, fontSize: hm.mobile ? 12 : 11);
    final content = Row(
      mainAxisSize: widget.expand ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (widget.icon != null) ...[Icon(widget.icon, size: hm.mobile ? 16 : 12, color: fg), const SizedBox(width: 6)],
        Text(widget.label, style: style, maxLines: 1, overflow: TextOverflow.ellipsis),
      ],
    );
    return Semantics(
      button: true,
      enabled: !disabled,
      label: widget.label,
      child: MouseRegion(
        cursor: disabled ? SystemMouseCursors.forbidden : SystemMouseCursors.click,
        onEnter: hm.mobile ? null : (_) => setState(() => _hot = true),
        onExit: hm.mobile ? null : (_) => setState(() => _hot = false),
        child: GestureDetector(
          onTapDown: hm.mobile ? (_) => setState(() => _hot = true) : null,
          onTapUp: hm.mobile ? (_) => setState(() => _hot = false) : null,
          onTapCancel: hm.mobile ? () => setState(() => _hot = false) : null,
          onTap: disabled ? null : widget.onPressed,
          child: Opacity(
            opacity: widget.onPressed == null ? 0.5 : 1,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              height: widget.small ? hm.buttonSm : hm.button,
              padding: EdgeInsets.symmetric(horizontal: hm.mobile ? 16 : 14),
              decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: border ?? Colors.transparent),
              ),
              child: widget.loading
                  // The label keeps the width; the spinner sits over it (§ 7.4).
                  ? Stack(
                      alignment: Alignment.center,
                      children: [
                        Opacity(opacity: 0, child: content),
                        SizedBox.square(
                          dimension: style.fontSize! + 2,
                          child: HmSpinner(color: fg),
                        ),
                      ],
                    )
                  : Center(widthFactor: 1, child: content),
            ),
          ),
        ),
      ),
    );
  }
}

/// Square icon button for toolbars (§ 9.3): 30 px, 44 px on phones (M7).
/// [label] is both the tooltip and the screen reader name.
class HmIconButton extends StatefulWidget {
  const HmIconButton({super.key, required this.icon, required this.label, this.onPressed, this.color});

  final IconData icon;
  final String label;
  final VoidCallback? onPressed;
  final Color? color;

  @override
  State<HmIconButton> createState() => _HmIconButtonState();
}

class _HmIconButtonState extends State<HmIconButton> {
  bool _hot = false;

  @override
  Widget build(BuildContext context) {
    final hm = Hm.of(context);
    final size = hm.toolbar;
    final btn = MouseRegion(
      cursor: widget.onPressed == null ? SystemMouseCursors.forbidden : SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hot = true),
      onExit: (_) => setState(() => _hot = false),
      child: GestureDetector(
        onTap: widget.onPressed,
        child: Opacity(
          opacity: widget.onPressed == null ? 0.5 : 1,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: _hot ? HmColors.tint(HmColors.accent, 0.08) : Colors.transparent,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: _hot ? HmColors.tint(HmColors.accent, HmColors.ring) : HmColors.border),
            ),
            child: Icon(widget.icon, size: hm.mobile ? 16 : 14, color: widget.color ?? HmColors.muted),
          ),
        ),
      ),
    );
    return Semantics(
      button: true,
      label: widget.label,
      child: hm.mobile ? btn : Tooltip(message: widget.label, child: btn),
    );
  }
}

/// Row action kinds (§ 7.6).
enum HmAction { edit, success, warning, delete, neutral }

/// Dense bordered icon button inside table rows (§ 7.6); 44 px target on
/// phones (M7).
class HmActionButton extends StatefulWidget {
  const HmActionButton({super.key, required this.icon, required this.label, required this.onPressed, this.kind = HmAction.edit});

  final IconData icon;
  final String label;
  final VoidCallback? onPressed;
  final HmAction kind;

  @override
  State<HmActionButton> createState() => _HmActionButtonState();
}

class _HmActionButtonState extends State<HmActionButton> {
  bool _hot = false;

  @override
  Widget build(BuildContext context) {
    final hm = Hm.of(context);
    final (fg, ring) = switch (widget.kind) {
      HmAction.edit => (HmColors.accent, HmColors.tint(HmColors.accent, HmColors.ring)),
      HmAction.success => (HmColors.ok, HmColors.tint(HmColors.ok, HmColors.ring)),
      HmAction.warning => (HmColors.warning, HmColors.tint(HmColors.warning, HmColors.ring)),
      HmAction.delete => (HmColors.error, HmColors.tint(HmColors.error, HmColors.ring)),
      HmAction.neutral => (HmColors.muted, HmColors.tint(HmColors.text, 0.15)),
    };
    final box = AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: _hot ? HmColors.tint(fg, HmColors.resting) : Colors.transparent,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: ring),
      ),
      child: Icon(widget.icon, size: 14, color: fg),
    );
    final btn = MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hot = true),
      onExit: (_) => setState(() => _hot = false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onPressed,
        child: Opacity(
          opacity: widget.onPressed == null ? 0.5 : 1,
          child: hm.mobile ? SizedBox.square(dimension: 44, child: Center(child: box)) : box,
        ),
      ),
    );
    return Semantics(
      button: true,
      label: widget.label,
      child: hm.mobile ? btn : Tooltip(message: widget.label, child: btn),
    );
  }
}

/// The spinner (§ 17.1). Sized by its parent; colour from the caller.
class HmSpinner extends StatelessWidget {
  const HmSpinner({super.key, this.color = HmColors.accent});

  final Color color;

  @override
  Widget build(BuildContext context) => CircularProgressIndicator(strokeWidth: 2, color: color, strokeCap: StrokeCap.butt);
}
