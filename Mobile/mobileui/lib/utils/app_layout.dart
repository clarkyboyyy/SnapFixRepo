import 'package:flutter/material.dart';

/// SnapFix is designed on a 393 x 873 Android canvas. Nothing locks these
/// numbers onto the screen: they only describe the reference the screens were
/// composed at, and every helper below derives its answer from the device's
/// real dimensions instead.
class AppLayout {
  AppLayout._();

  /// Phones use their full width. Windows wider than the reference (desktop
  /// demos, tablets) show the same fluid UI inside a phone-sized container so
  /// the 393 x 873 proportions are kept instead of stretching edge to edge.
  static const double maxAppWidth = 393;

  /// Reference Android phone used while designing the screens.
  static const Size referenceSize = Size(maxAppWidth, 873);

  /// Page gutter for cards and headings: the reference 20 on phones, tightened
  /// to 16 on 320dp-class devices so cards keep clear of the bezel.
  static double gutter(BuildContext context) =>
      MediaQuery.sizeOf(context).width < 360 ? 16 : 20;

  /// Utility for widget sizes (logos, illustration discs) that must never take
  /// more than [fraction] of the available width.
  static double fitWidth(
    BuildContext context,
    double preferred,
    double fraction,
  ) {
    final width = MediaQuery.sizeOf(context).width;
    final cap = width * fraction;
    return preferred < cap ? preferred : cap;
  }

  /// Android display-size settings can scale text well past 1.5x, which breaks
  /// fixed-height chrome (app bars, navigation bar, chips). Clamping keeps the
  /// layout readable and overflow-free.
  static const double minTextScale = .9;
  static const double maxTextScale = 1.3;
}
