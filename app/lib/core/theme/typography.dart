import 'package:flutter/widgets.dart';

import 'colors.dart';

/// Type scale (DESIGN_MANIFEST.md § 3.2). Both families are bundled
/// variable fonts; the weight goes to the `wght` axis. Syne has no
/// Cyrillic, so Cyrillic display text falls back to JetBrains Mono (§ 3.1).
abstract final class HmText {
  static const mono = 'JetBrains Mono';
  static const display = 'Syne';

  static TextStyle jb(double size, {int weight = 400, Color color = HmColors.text, double spacing = 0, double? height}) => TextStyle(
    fontFamily: mono,
    fontSize: size,
    fontWeight: _weight(weight),
    fontVariations: [FontVariation('wght', weight.toDouble())],
    color: color,
    letterSpacing: spacing,
    height: height,
  );

  static TextStyle syne(double size, {int weight = 700, Color color = HmColors.text, double spacing = 0}) => TextStyle(
    fontFamily: display,
    fontFamilyFallback: const [mono],
    fontSize: size,
    fontWeight: _weight(weight),
    fontVariations: [FontVariation('wght', weight.toDouble())],
    color: color,
    letterSpacing: spacing,
  );

  static FontWeight _weight(int w) => FontWeight.values[((w ~/ 100) - 1).clamp(0, 8)];

  // Rows of § 3.2.
  static TextStyle get pageTitle => syne(22, weight: 800, spacing: -0.5);
  static TextStyle get logo => syne(22, weight: 800, spacing: -0.5);
  static TextStyle get statValue => syne(20, weight: 800);
  static TextStyle get dialogHeading => jb(18, weight: 700);
  static TextStyle get modalTitle => syne(15, weight: 700);
  static TextStyle get input => jb(14);
  static TextStyle get body => jb(13);
  static TextStyle get bodyStrong => jb(13, weight: 600);
  static TextStyle get small => jb(12, color: HmColors.muted);
  static TextStyle get label => jb(12, weight: 600, color: HmColors.muted, spacing: 0.5);
  static TextStyle get button => jb(11, weight: 600, spacing: 0.5);
  static TextStyle get sectionTitle => syne(11, weight: 700, color: HmColors.muted, spacing: 1.5);
  static TextStyle get nav => jb(11, weight: 600, color: HmColors.muted, spacing: 0.5);
  static TextStyle get badge => jb(10, weight: 600, spacing: 0.5);
  static TextStyle get th => syne(10, weight: 700, color: HmColors.muted, spacing: 1);
  static TextStyle get footer => jb(10, color: HmColors.muted, spacing: 0.5);
}
