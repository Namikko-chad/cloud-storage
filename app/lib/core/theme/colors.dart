import 'package:flutter/material.dart';

/// Design tokens (DESIGN_MANIFEST.md § 1). Widgets take colours from here
/// only; tints use [HmColors.tint] with the opacity scale of § 1.3.
abstract final class HmColors {
  static const Color bg = Color(0xFF080C10);
  static const Color surface = Color(0xFF0D1117);
  static const Color border = Color(0xFF1C2333);
  static const Color accent = Color(0xFF00D4FF);
  static const Color text = Color(0xFFE6EDF3);
  static const Color muted = Color(0xFF8B949E);

  static const Color ok = Color(0xFF10B981);
  static const Color error = Color(0xFFEF4444);
  static const Color active = Color(0xFF3B82F6);
  static const Color paused = Color(0xFF6B7280);
  static const Color warning = Color(0xFFF59E0B);
  static const Color purple = Color(0xFF7C3AED);
  static const Color purpleLight = Color(0xFFA78BFA);

  /// Text on the solid accent (primary button, active page).
  static const Color onAccent = Color(0xFF0A0E17);

  /// The viewport bezel (§ 5.3) — the one colour outside the token system.
  static const Color bezel = Color(0xFF000000);

  /// Opacity scale (§ 1.3).
  static const double subtle = 0.03;
  static const double resting = 0.10;
  static const double hover = 0.20; // resting + 0.10
  static const double badge = 0.15;
  static const double ring = 0.30;

  static Color tint(Color c, double alpha) => c.withValues(alpha: alpha);
}
