import 'package:flutter/material.dart';

import 'colors.dart';
import 'typography.dart';

/// Material defaults with every elevation zeroed (MOBILITY App. D). Dark
/// only: there is no light palette.
abstract final class AppTheme {
  static ThemeData get dark {
    final base = ThemeData(
      brightness: Brightness.dark,
      useMaterial3: true,
      fontFamily: HmText.mono,
      scaffoldBackgroundColor: HmColors.bg,
      canvasColor: HmColors.bg,
      splashFactory: NoSplash.splashFactory,
      colorScheme: const ColorScheme.dark(
        primary: HmColors.accent,
        onPrimary: HmColors.onAccent,
        secondary: HmColors.accent,
        surface: HmColors.surface,
        onSurface: HmColors.text,
        error: HmColors.error,
        onError: HmColors.text,
        outline: HmColors.border,
        surfaceTint: Colors.transparent,
      ),
    );
    return base.copyWith(
      textTheme: base.textTheme.apply(fontFamily: HmText.mono, bodyColor: HmColors.text, displayColor: HmColors.text),
      dividerTheme: const DividerThemeData(color: HmColors.border, thickness: 1, space: 1),
      dialogTheme: const DialogThemeData(elevation: 0, backgroundColor: HmColors.surface),
      bottomSheetTheme: const BottomSheetThemeData(elevation: 0, backgroundColor: HmColors.surface, modalElevation: 0),
      popupMenuTheme: PopupMenuThemeData(
        elevation: 0,
        color: HmColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(color: HmColors.border),
        ),
        textStyle: HmText.jb(12),
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: HmColors.surface,
          border: Border.all(color: HmColors.border),
          borderRadius: BorderRadius.circular(6),
        ),
        textStyle: HmText.jb(11),
        waitDuration: const Duration(milliseconds: 400),
      ),
      navigationBarTheme: NavigationBarThemeData(
        elevation: 0,
        height: 56,
        backgroundColor: HmColors.surface,
        indicatorColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        labelTextStyle: WidgetStateProperty.resolveWith(
          (s) => HmText.jb(11, weight: 600, color: s.contains(WidgetState.selected) ? HmColors.accent : HmColors.muted),
        ),
        iconTheme: WidgetStateProperty.resolveWith(
          (s) => IconThemeData(size: 20, color: s.contains(WidgetState.selected) ? HmColors.accent : HmColors.muted),
        ),
      ),
      scrollbarTheme: ScrollbarThemeData(
        thumbColor: WidgetStatePropertyAll(HmColors.tint(HmColors.muted, 0.4)),
        thickness: const WidgetStatePropertyAll(6),
        radius: const Radius.circular(3),
      ),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: HmColors.accent,
        selectionColor: HmColors.tint(HmColors.accent, 0.3),
        selectionHandleColor: HmColors.accent,
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(color: HmColors.accent, linearTrackColor: HmColors.border),
    );
  }
}
