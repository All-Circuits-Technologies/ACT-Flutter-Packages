// SPDX-FileCopyrightText: 2025 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_platform_manager/src/platforms_deps/platform_dummy.dart'
    if (dart.library.io) "package:act_platform_manager/src/platforms_deps/platform_io.dart"
    if (dart.library.js_interop) "package:act_platform_manager/src/platforms_deps/platform_js.dart"
    as private_platform;

/// Exports information which depends on the platform
sealed class ActPlatform {
  /// This is the platform environment
  static Map<String, String> get environment => private_platform.environment;

  /// Tells if the current platform is Android
  static bool get isAndroid => private_platform.isAndroid;

  /// Tells if the current platform is iOS
  static bool get isIos => private_platform.isIos;

  /// Tells if the current platform is Fuchsia
  static bool get isFuchsia => private_platform.isFuchsia;

  /// Tells if the current platform is Linux
  static bool get isLinux => private_platform.isLinux;

  /// Tells if the current platform is MacOS
  static bool get isMacOS => private_platform.isMacOS;

  /// Tells if the current platform is Windows
  static bool get isWindows => private_platform.isWindows;

  /// Tells if the current platform is Web
  static bool get isWeb => private_platform.isWeb;
}
