import 'package:flutter/material.dart';

import '../../core/theme/colors.dart';
import '../../core/theme/layout.dart';
import '../../core/theme/typography.dart';

/// Accent stripes (§ 8.2).
enum HmAccent { ok, error, total, active, paused, uptime }

List<Color> _gradient(HmAccent a) => switch (a) {
  HmAccent.ok => const [HmColors.ok, HmColors.accent],
  HmAccent.error => const [HmColors.error, HmColors.warning],
  HmAccent.total => const [HmColors.accent, HmColors.purple],
  HmAccent.active => const [HmColors.active, HmColors.accent],
  HmAccent.paused => const [HmColors.paused, HmColors.muted],
  HmAccent.uptime => const [HmColors.purple, HmColors.accent],
};

/// Left status bar colours (§ 8.3).
enum HmStatus { ok, error, paused, warning }

Color statusColor(HmStatus s) => switch (s) {
  HmStatus.ok => HmColors.ok,
  HmStatus.error => HmColors.error,
  HmStatus.paused => HmColors.paused,
  HmStatus.warning => HmColors.warning,
};

/// Card (§ 8.1): surface, 12 px radius, no shadow, padding by the caller.
/// [recessed] steps it down to bg when it sits inside another surface.
class HmCard extends StatelessWidget {
  const HmCard({super.key, required this.child, this.padding, this.accent, this.status, this.recessed = false});

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final HmAccent? accent;
  final HmStatus? status;
  final bool recessed;

  @override
  Widget build(BuildContext context) {
    assert(accent == null || status == null, 'pick one channel (§ 8.6)');
    Widget body = Padding(padding: padding ?? EdgeInsets.zero, child: child);
    if (status != null) {
      body = Stack(
        children: [
          Padding(padding: const EdgeInsets.only(left: 8), child: body),
          Positioned(left: 0, top: 0, bottom: 0, child: Container(width: 2, color: statusColor(status!))),
        ],
      );
    }
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: recessed ? HmColors.bg : HmColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: HmColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (accent != null)
            Container(
              height: 2,
              decoration: BoxDecoration(gradient: LinearGradient(colors: _gradient(accent!))),
            ),
          body,
        ],
      ),
    );
  }
}

/// KPI card (§ 8.4): label above a single-token value.
class HmStatCard extends StatelessWidget {
  const HmStatCard({super.key, required this.label, required this.value, this.accent, this.valueColor});

  final String label;
  final String value;
  final HmAccent? accent;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    final hm = Hm.of(context);
    return HmCard(
      accent: accent,
      padding: hm.mobile ? const EdgeInsets.symmetric(horizontal: 16, vertical: 12) : const EdgeInsets.fromLTRB(20, 16, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label.toUpperCase(), style: HmText.th, maxLines: 1, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 8),
          Text(
            value,
            style: HmText.statValue.copyWith(color: valueColor),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

/// Row of stat cards: equal-flex on desktops (§ 8.4), a horizontally
/// scrolling strip on phones (M8.1).
class HmStatCards extends StatelessWidget {
  const HmStatCards({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final hm = Hm.of(context);
    if (hm.mobile) {
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        clipBehavior: Clip.none,
        child: Row(
          children: [
            for (final c in children) ...[
              IntrinsicWidth(
                child: ConstrainedBox(constraints: const BoxConstraints(minWidth: 128), child: c),
              ),
              const SizedBox(width: 8),
            ],
          ],
        ),
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < children.length; i++) ...[if (i > 0) const SizedBox(width: 16), Expanded(child: children[i])],
      ],
    );
  }
}

/// Section title with the trailing rule (§ 18.1).
class HmSectionTitle extends StatelessWidget {
  const HmSectionTitle(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) => Semantics(
    header: true,
    child: Row(
      children: [
        Text(text.toUpperCase(), style: HmText.sectionTitle),
        const SizedBox(width: 12),
        const Expanded(child: Divider()),
      ],
    ),
  );
}

/// The one page title (§ 3.3).
class HmPageTitle extends StatelessWidget {
  const HmPageTitle(this.text, {super.key, this.trailing});

  final String text;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: Semantics(header: true, child: Text(text, style: HmText.pageTitle)),
      ),
      ?trailing,
    ],
  );
}

enum HmTone { ok, error, warning, info, neutral, accent }

(Color, Color, Color) _tone(HmTone t, double bgAlpha) {
  Color c(Color x) => HmColors.tint(x, bgAlpha);
  Color r(Color x) => HmColors.tint(x, HmColors.ring);
  return switch (t) {
    HmTone.ok => (HmColors.ok, c(HmColors.ok), r(HmColors.ok)),
    HmTone.error => (HmColors.error, c(HmColors.error), r(HmColors.error)),
    HmTone.warning => (HmColors.warning, c(HmColors.warning), r(HmColors.warning)),
    HmTone.info || HmTone.accent => (HmColors.accent, c(HmColors.accent), r(HmColors.accent)),
    HmTone.neutral => (HmColors.paused, HmColors.tint(HmColors.paused, 0.15), Colors.transparent),
  };
}

/// One-word state (§ 12.1): alpha 0.15, the neutral one has no border.
class HmBadge extends StatelessWidget {
  const HmBadge(this.text, {super.key, this.tone = HmTone.neutral, this.icon});

  final String text;
  final HmTone tone;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final (fg, bg, ring) = _tone(tone, HmColors.badge);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: ring),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[Icon(icon, size: 10, color: fg), const SizedBox(width: 4)],
          Text(text.toUpperCase(), style: HmText.badge.copyWith(color: fg)),
        ],
      ),
    );
  }
}

/// `key: value` chip (§ 12.4).
class HmPill extends StatelessWidget {
  const HmPill({super.key, required this.child, this.tone});

  final Widget child;
  final HmTone? tone;

  @override
  Widget build(BuildContext context) {
    var (fg, bg, ring) = (HmColors.muted, HmColors.tint(HmColors.text, HmColors.subtle), HmColors.border);
    if (tone != null) (fg, bg, ring) = _tone(tone!, 0.08);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: ring),
      ),
      child: DefaultTextStyle(
        style: HmText.footer.copyWith(color: fg),
        child: child,
      ),
    );
  }
}

/// Live/dead dot (§ 12.2): the only glowing element; pulses, error faster.
class HmDot extends StatefulWidget {
  const HmDot({super.key, required this.ok, this.label});

  final bool ok;
  final String? label;

  @override
  State<HmDot> createState() => _HmDotState();
}

class _HmDotState extends State<HmDot> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: _period)..repeat(reverse: true);

  Duration get _period => Duration(milliseconds: widget.ok ? 1000 : 750);

  @override
  void didUpdateWidget(HmDot old) {
    super.didUpdateWidget(old);
    if (old.ok != widget.ok) {
      _c.duration = _period;
      _c.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.ok ? HmColors.ok : HmColors.error;
    final still = MediaQuery.disableAnimationsOf(context);
    final dot = AnimatedBuilder(
      animation: _c,
      builder: (_, _) => Opacity(
        opacity: still ? 1 : 1 - _c.value * 0.5,
        child: Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color,
            boxShadow: [BoxShadow(color: color, blurRadius: 8)],
          ),
        ),
      ),
    );
    return Semantics(label: widget.label ?? (widget.ok ? 'online' : 'offline'), child: dot);
  }
}

/// Page-level message (§ 19.2).
class HmBanner extends StatelessWidget {
  const HmBanner(this.text, {super.key, this.tone = HmTone.info, this.action});

  final String text;
  final HmTone tone;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final (fg, bg, ring) = _tone(tone, 0.08);
    final icon = switch (tone) {
      HmTone.error => Icons.error_outline,
      HmTone.warning => Icons.warning_amber_rounded,
      HmTone.ok => Icons.check_circle_outline,
      _ => Icons.info_outline,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: ring),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(icon, size: 16, color: fg),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text, style: HmText.jb(12, color: fg)),
          ),
          if (action != null) ...[const SizedBox(width: 12), action!],
        ],
      ),
    );
  }
}

/// "Nothing here" (§ 19.1): one line, optional icon and one CTA.
class HmEmptyState extends StatelessWidget {
  const HmEmptyState(this.text, {super.key, this.icon, this.action});

  final String text;
  final IconData? icon;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final hm = Hm.of(context);
    return Padding(
      padding: EdgeInsets.symmetric(vertical: hm.mobile ? 32 : 40, horizontal: hm.mobile ? 16 : 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[Icon(icon, size: 32, color: HmColors.muted), const SizedBox(height: 12)],
          Text(
            text,
            style: HmText.body.copyWith(color: HmColors.muted),
            textAlign: TextAlign.center,
          ),
          if (action != null) ...[const SizedBox(height: 16), action!],
        ],
      ),
    );
  }
}

/// Known-percent progress (§ 17.3): 3 px, track is the border colour.
class HmProgress extends StatelessWidget {
  const HmProgress({super.key, required this.value, this.color = HmColors.accent});

  final double value;
  final Color color;

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(2),
    child: LinearProgressIndicator(value: value.clamp(0, 1), minHeight: 3, color: color, backgroundColor: HmColors.border),
  );
}

/// A centred spinner for a loading surface (§ 9.6).
class HmLoading extends StatelessWidget {
  const HmLoading({super.key});

  @override
  Widget build(BuildContext context) {
    final s = Hm.of(context).mobile ? 32.0 : 48.0;
    return Center(
      child: SizedBox.square(dimension: s, child: const CircularProgressIndicator(strokeWidth: 2)),
    );
  }
}

/// Label: value line for details (sub-label style, § 18.3 h4).
class HmField extends StatelessWidget {
  const HmField(this.label, this.value, {super.key, this.mono = true});

  final String label;
  final Widget value;
  final bool mono;

  @override
  Widget build(BuildContext context) {
    final v = DefaultTextStyle(style: HmText.body, child: value);
    if (Hm.of(context).mobile) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label.toUpperCase(), style: HmText.th),
            const SizedBox(height: 4),
            v,
          ],
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 140, child: Text(label.toUpperCase(), style: HmText.th)),
          const SizedBox(width: 12),
          Expanded(child: v),
        ],
      ),
    );
  }
}
