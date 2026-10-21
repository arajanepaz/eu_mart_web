import 'package:flutter/foundation.dart';

/// Device-aware responsive helpers.
///
/// Some in-app browsers can report an unusual web viewport. On Flutter Web,
/// defaultTargetPlatform still reflects the underlying Android/iOS device, so
/// we use both device type and width when deciding whether to use mobile UI.
class ResponsiveDevice {
  const ResponsiveDevice._();

  static bool get isMobilePlatform {
    if (!kIsWeb) {
      return defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS;
    }

    return defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS;
  }

  static bool useMobileLayout(double width, {double breakpoint = 900}) {
    return isMobilePlatform || width < breakpoint;
  }
}
