// SPDX-FileCopyrightText: 2023 Anthony Loiseau <anthony.loiseau@allcircuits.com>
// SPDX-FileCopyrightText: 2023 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_global_manager/act_global_manager.dart';
import 'package:act_permissions_manager/src/element/permission_element.dart';
import 'package:act_platform_manager/act_platform_manager.dart';
import 'package:permission_handler/permission_handler.dart' as permission_handler;

/// Extension of the [PermissionElement] Enum
extension PermissionElementExtension on PermissionElement {
  /// Maximum version of Android where location is required for BLE scan
  static const int androidBleWithLocationMaxVersion = 31;

  /// Return the library [permission_handler.Permission] attached to the
  /// [PermissionElement]
  List<permission_handler.Permission> get permissions =>
      PermissionElementHelper.getPermissions(this);
}

/// Helpful class which contains useful PermissionElement static methods
sealed class PermissionElementHelper {
  /// Maximum version of Android where location is required for BLE scan
  static const int androidBleWithLocationMaxVersion = 31;

  /// Return the library [permission_handler.Permission] attached to the
  /// [PermissionElement]
  static List<permission_handler.Permission> getPermissions(PermissionElement element) {
    final isAndroid = globalGetIt().get<PlatformManager>().isAndroid;
    final isIos = globalGetIt().get<PlatformManager>().isIos;
    final version = globalGetIt().get<PlatformManager>().version;

    switch (element) {
      case PermissionElement.background:
        return _getBackgroundPerms(isAndroid: isAndroid, isIos: isIos, version: version);

      case PermissionElement.ble:
        return _getBlePerms(isAndroid: isAndroid, isIos: isIos, version: version);

      case PermissionElement.locationAlways:
        return _getLocAlwaysPerms(isAndroid: isAndroid, isIos: isIos, version: version);

      case PermissionElement.locationWhenInUse:
        return _getLocWhenInUsePerms(isAndroid: isAndroid, isIos: isIos, version: version);

      case PermissionElement.trackingAuthorization:
        return _getTrackingPerms(isAndroid: isAndroid, isIos: isIos, version: version);

      case PermissionElement.wifi:
        return _getWifiPerms(isAndroid: isAndroid, isIos: isIos, version: version);
    }
  }

  /// Get the list of permissions linked to background
  static List<permission_handler.Permission> _getBackgroundPerms({
    required bool isAndroid,
    required bool isIos,
    required int? version,
  }) {
    if (!isAndroid) {
      return const [];
    }

    return [
      permission_handler.Permission.ignoreBatteryOptimizations,
    ];
  }

  /// Get the list of permissions linked to BLE
  static List<permission_handler.Permission> _getBlePerms({
    required bool isAndroid,
    required bool isIos,
    required int? version,
  }) {
    final permissions = <permission_handler.Permission>[];

    if (isAndroid) {
      // Is Android
      if ((version ?? androidBleWithLocationMaxVersion) < androidBleWithLocationMaxVersion) {
        // Older Android SDK
        permissions.add(permission_handler.Permission.locationWhenInUse);
        permissions.add(permission_handler.Permission.bluetooth);
      } else {
        // New Android SDK
        permissions.add(permission_handler.Permission.bluetoothScan);
        permissions.add(permission_handler.Permission.bluetoothConnect);
      }
    } else if (isIos) {
      // Is iOS
      permissions.add(permission_handler.Permission.bluetooth);
    }

    return permissions;
  }

  /// Get the list of permissions linked to the location always permission
  static List<permission_handler.Permission> _getLocAlwaysPerms({
    required bool isAndroid,
    required bool isIos,
    required int? version,
  }) =>
      [
        permission_handler.Permission.locationAlways,
      ];

  /// Get the list of permissions linked to location when in use
  static List<permission_handler.Permission> _getLocWhenInUsePerms({
    required bool isAndroid,
    required bool isIos,
    required int? version,
  }) =>
      [
        permission_handler.Permission.locationWhenInUse,
      ];

  /// Get the list of permissions linked to user tracking
  static List<permission_handler.Permission> _getTrackingPerms({
    required bool isAndroid,
    required bool isIos,
    required int? version,
  }) {
    if (!isIos) {
      return const [];
    }

    return [
      permission_handler.Permission.appTrackingTransparency,
    ];
  }

  /// Get the list of permissions linked to BLE
  static List<permission_handler.Permission> _getWifiPerms({
    required bool isAndroid,
    required bool isIos,
    required int? version,
  }) =>
      const [];
}
