// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_platform_manager/act_platform_manager.dart';

/// Say which platform the application runs on, for the tests.
class FakePlatformManager extends PlatformManager {
  /// {@macro act_platform_manager.MixinActPlatforms.isAndroid}
  @override
  final bool isAndroid;

  /// {@macro act_platform_manager.MixinActPlatforms.isIos}
  @override
  final bool isIos;

  /// {@macro act_platform_manager.MixinActPlatforms.isLinux}
  @override
  final bool isLinux;

  /// {@macro act_platform_manager.MixinActPlatforms.isWindows}
  @override
  final bool isWindows;

  /// {@macro act_platform_manager.MixinActPlatforms.isMacOS}
  @override
  final bool isMacOS;

  /// {@macro act_platform_manager.MixinActPlatforms.isWeb}
  @override
  final bool isWeb;

  /// {@macro act_platform_manager.MixinActPlatforms.isFuchsia}
  @override
  final bool isFuchsia;

  /// Give the version of the system the application runs on.
  @override
  final int? version;

  /// Create the platform, which is none of the supported ones unless the test says so.
  FakePlatformManager({
    this.isAndroid = false,
    this.isIos = false,
    this.isLinux = false,
    this.isWindows = false,
    this.isMacOS = false,
    this.isWeb = false,
    this.isFuchsia = false,
    this.version,
  });

  /// Create the platform of an Android device running the given [version] of the system.
  factory FakePlatformManager.android({int? version}) =>
      FakePlatformManager(isAndroid: true, version: version);

  /// Create the platform of an iOS device.
  factory FakePlatformManager.ios() => FakePlatformManager(isIos: true, version: 17);
}
