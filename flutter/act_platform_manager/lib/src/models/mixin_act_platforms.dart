// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

/// This mixin is used to get the platform information of the application, such as the current
/// platform and the environment variables of the platform.
mixin MixinActPlatforms {
  /// {@template act_platform_manager.MixinActPlatforms.environment}
  /// This is the platform environment
  /// {@endtemplate}
  Map<String, String> get environment;

  /// {@template act_platform_manager.MixinActPlatforms.isAndroid}
  /// Tells if the current platform is Android
  /// {@endtemplate}
  bool get isAndroid;

  /// {@template act_platform_manager.MixinActPlatforms.isIos}
  /// Tells if the current platform is iOS
  /// {@endtemplate}
  bool get isIos;

  /// {@template act_platform_manager.MixinActPlatforms.isFuchsia}
  /// Tells if the current platform is Fuchsia
  /// {@endtemplate}
  bool get isFuchsia;

  /// {@template act_platform_manager.MixinActPlatforms.isLinux}
  /// Tells if the current platform is Linux
  /// {@endtemplate}
  bool get isLinux;

  /// {@template act_platform_manager.MixinActPlatforms.isMacOS}
  /// Tells if the current platform is MacOS
  /// {@endtemplate}
  bool get isMacOS;

  /// {@template act_platform_manager.MixinActPlatforms.isWindows}
  /// Tells if the current platform is Windows
  /// {@endtemplate}
  bool get isWindows;

  /// {@template act_platform_manager.MixinActPlatforms.isWeb}
  /// Tells if the current platform is Web
  /// {@endtemplate}
  bool get isWeb;
}
