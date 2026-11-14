import 'package:flutter/widgets.dart';

/// Layout constants (DESIGN_MANIFEST.md § 2.5, MOBILITY M2.3). One
/// breakpoint: below 768 px of width the phone layout is used, whatever
/// the device (a narrow desktop window gets it too).
class Hm {
  const Hm._(this.mobile);
  final bool mobile;

  static const breakpoint = 768.0;

  static Hm of(BuildContext context) => Hm._(MediaQuery.sizeOf(context).width < breakpoint);

  double get pageX => mobile ? 16 : 40;
  double get pageY => mobile ? 12 : 32;
  double get pageBottom => mobile ? 24 : 60;
  double get gapLg => mobile ? 16 : 28;
  double get gapMd => mobile ? 12 : 20;
  double get gapSm => mobile ? 12 : 16;
  double get gapXs => mobile ? 8 : 12;
  static const double gapXxs = 8;

  double get control => mobile ? 48 : 36;
  double get button => mobile ? 44 : 30;
  double get buttonSm => mobile ? 36 : 24;
  double get toolbar => mobile ? 44 : 30;
  double get inputFont => mobile ? 16 : 12;
}
