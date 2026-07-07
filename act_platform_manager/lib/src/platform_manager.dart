// SPDX-FileCopyrightText: 2020 - 2023 Sami Kouatli <sami.kouatli@allcircuits.com>
// SPDX-FileCopyrightText: 2023 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_life_cycle/act_life_cycle.dart';
import 'package:act_platform_manager/src/models/mixin_act_platforms.dart';
import 'package:act_platform_manager/src/platforms_deps/act_platform.dart';
import 'package:device_info_plus/device_info_plus.dart';

/// Builder for creating the PlatformManager
class PlatformBuilder extends AbsLifeCycleFactory<PlatformManager> {
  /// Class constructor with the class construction
  const PlatformBuilder() : super(PlatformManager.new);

  /// List of manager dependencies
  @override
  Iterable<Type> dependsOn() => [];
}

/// Retrieve phone platform OS.
/// This class can only be called from a UI build.
class PlatformManager extends AbsWithLifeCycle with MixinActPlatforms {
  /// Contains the platform information
  final ActPlatform _platform;

  /// Sdk version for Android
  /// OS version for iOS
  int? _sdkVersion;

  /// Getter of Platform version
  int? get version => _sdkVersion;

  /// {@macro act_platform_manager.MixinActPlatforms.environment}
  @override
  Map<String, String> get environment => _platform.environment;

  /// {@macro act_platform_manager.MixinActPlatforms.isAndroid}
  @override
  bool get isAndroid => _platform.isAndroid;

  /// {@macro act_platform_manager.MixinActPlatforms.isIos}
  @override
  bool get isIos => _platform.isIos;

  /// {@macro act_platform_manager.MixinActPlatforms.isFuchsia}
  @override
  bool get isFuchsia => _platform.isFuchsia;

  /// {@macro act_platform_manager.MixinActPlatforms.isLinux}
  @override
  bool get isLinux => _platform.isLinux;

  /// {@macro act_platform_manager.MixinActPlatforms.isMacOS}
  @override
  bool get isMacOS => _platform.isMacOS;

  /// {@macro act_platform_manager.MixinActPlatforms.isWindows}
  @override
  bool get isWindows => _platform.isWindows;

  /// {@macro act_platform_manager.MixinActPlatforms.isWeb}
  @override
  bool get isWeb => _platform.isWeb;

  /// Tells if the current platform is a mobile platform (Android or iOS)
  bool get isMobile => isAndroid || isIos;

  /// Tells if the current platform is a desktop platform (Linux, MacOS or Windows)
  bool get isDesktop => isLinux || isMacOS || isWindows;

  /// Class constructor
  PlatformManager() : _platform = ActPlatform.instance;

  /// {@macro act_life_cycle.MixinWithLifeCycle.initLifeCycle}
  @override
  Future<void> initLifeCycle() async {
    await super.initLifeCycle();
    // Set SDK/OS version
    if (isAndroid) {
      final androidInfo = await DeviceInfoPlugin().androidInfo;
      _sdkVersion = androidInfo.version.sdkInt;
    } else if (isIos) {
      final iOSInfo = await DeviceInfoPlugin().iosInfo;
      _sdkVersion = int.tryParse(iOSInfo.systemVersion);
    }
  }
}
