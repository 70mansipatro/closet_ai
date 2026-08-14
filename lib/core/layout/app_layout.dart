import 'package:flutter/material.dart';

/// Shared layout constants and helpers so every screen hosted inside
/// [AppShell] (the bottom-nav / nav-rail shell) reserves consistent,
/// device-aware space above the persistent navigation chrome instead of
/// each screen inventing its own hardcoded padding.
class AppLayout {
  AppLayout._();

  /// Height of the [NavigationBar] itself (see navigationBarTheme in app_theme.dart).
  static const double navBarHeight = 66;

  /// Height of the gradient divider drawn above the [NavigationBar] in [AppShell].
  static const double navBarDividerHeight = 2;

  /// Width breakpoint at which [AppShell] switches from a bottom nav bar
  /// (phone/tablet) to a side [NavigationRail] (web/desktop).
  static const double desktopBreakpoint = 900;

  /// Whether the current window width should use the desktop rail layout.
  static bool isDesktop(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= desktopBreakpoint;

  /// Extra bottom clearance (beyond the device's own safe-area inset) that
  /// scrollable content should reserve so its last item never sits flush
  /// against the bottom nav bar or screen edge.
  static const double scrollBottomBuffer = 24;

  /// Extra bottom clearance for floating action buttons.
  static const double fabBottomBuffer = 16;

  /// Bottom padding for a screen's scrollable content (ListView/CustomScrollView/
  /// SingleChildScrollView). Content in [AppShell]'s body is already laid out
  /// above the bottom nav bar by Scaffold itself, so this only adds breathing
  /// room plus the device's own bottom safe-area inset (home indicator, etc.)
  /// for screens rendered without an enclosing [SafeArea].
  static double scrollBottomPadding(
    BuildContext context, {
    double buffer = scrollBottomBuffer,
  }) {
    return buffer + MediaQuery.paddingOf(context).bottom;
  }

  /// Bottom padding for scrollable content on a screen that also has a
  /// [FloatingActionButton], so the last list item never sits underneath it.
  static double scrollBottomPaddingWithFab(BuildContext context) {
    return scrollBottomPadding(context, buffer: 80);
  }

  /// Wraps a [FloatingActionButton] (or any floating widget) with enough
  /// bottom margin to clear the device safe area, so it never crowds the
  /// bottom nav bar or the home indicator.
  static Widget liftedFab(BuildContext context, Widget fab) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.paddingOf(context).bottom),
      child: fab,
    );
  }
}
