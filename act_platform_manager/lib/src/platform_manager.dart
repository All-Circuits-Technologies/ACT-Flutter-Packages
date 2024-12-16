// SPDX-FileCopyrightText: 2020 - 2023 Sami Kouatli <sami.kouatli@allcircuits.com>
// SPDX-FileCopyrightText: 2023 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'dart:io';

import 'package:act_abstract_manager/act_abstract_manager.dart';
import 'package:device_info_plus/device_info_plus.dart';

/// Builder for creating the PlatformManager
class PlatformBuilder extends ManagerBuilder<PlatformManager> {
  /// Class constructor with the class construction
  PlatformBuilder() : super(() => PlatformManager());

  /// List of manager dependencies
  @override
  Iterable<Type> dependsOn() => [];
}

/// Retrieve phone platform OS.
/// This class can only be called from a UI build.
class PlatformManager extends AbstractManager {
  PlatformManager() : super();

  /// Sdk version for Android
  /// OS version for iOS
  int? _sdkVersion;

  @override
  Future<void> initManager() async {
    // Set SDK/OS version
    if (isAndroid) {
      final androidInfo = await DeviceInfoPlugin().androidInfo;
      _sdkVersion = androidInfo.version.sdkInt;
    } else if (isIos) {
      final iOSInfo = await DeviceInfoPlugin().iosInfo;
      _sdkVersion = int.tryParse(iOSInfo.systemVersion);
    }
  }

  /// Getters of [Platform]
  bool get isAndroid => Platform.isAndroid;

  bool get isIos => Platform.isIOS;

  /// Getter of Platform version
  int? get version => _sdkVersion;
}
