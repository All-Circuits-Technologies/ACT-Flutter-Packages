// SPDX-FileCopyrightText: 2025 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_platform_manager/src/models/mixin_act_platforms.dart';
import 'package:act_platform_manager/src/platforms_deps/platform_dummy.dart'
    if (dart.library.io) "package:act_platform_manager/src/platforms_deps/platform_io.dart"
    if (dart.library.js_interop) "package:act_platform_manager/src/platforms_deps/platform_js.dart"
    as private_platform;

/// Exports information which depends on the platform
class ActPlatform with MixinActPlatforms {
  /// {@macro act_platform_manager.MixinActPlatforms.environment}
  @override
  Map<String, String> get environment => private_platform.environment;

  /// {@macro act_platform_manager.MixinActPlatforms.isAndroid}
  @override
  bool get isAndroid => private_platform.isAndroid;

  /// {@macro act_platform_manager.MixinActPlatforms.isIos}
  @override
  bool get isIos => private_platform.isIos;

  /// {@macro act_platform_manager.MixinActPlatforms.isFuchsia}
  @override
  bool get isFuchsia => private_platform.isFuchsia;

  /// {@macro act_platform_manager.MixinActPlatforms.isLinux}
  @override
  bool get isLinux => private_platform.isLinux;

  /// {@macro act_platform_manager.MixinActPlatforms.isMacOS}
  @override
  bool get isMacOS => private_platform.isMacOS;

  /// {@macro act_platform_manager.MixinActPlatforms.isWindows}
  @override
  bool get isWindows => private_platform.isWindows;

  /// {@macro act_platform_manager.MixinActPlatforms.isWeb}
  @override
  bool get isWeb => private_platform.isWeb;

  /// Singleton instance of the platform
  static final ActPlatform _instance = const ActPlatform._();

  /// Getter of the singleton instance of the platform
  static ActPlatform get instance => _instance;

  /// Class constructor
  const ActPlatform._();
}
