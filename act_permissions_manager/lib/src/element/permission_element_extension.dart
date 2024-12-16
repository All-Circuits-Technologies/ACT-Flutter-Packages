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
    final permissions = <permission_handler.Permission>[];

    switch (element) {
      case PermissionElement.locationWhenInUse:
        permissions.add(permission_handler.Permission.locationWhenInUse);
        break;

      case PermissionElement.locationAlways:
        permissions.add(permission_handler.Permission.locationAlways);
        break;

      case PermissionElement.ble:
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
        break;

      case PermissionElement.background:
        if (isAndroid) {
          permissions.add(permission_handler.Permission.ignoreBatteryOptimizations);
        }
        break;

      case PermissionElement.trackingAuthorization:
        if (isIos) {
          permissions.add(permission_handler.Permission.appTrackingTransparency);
        }
        break;
    }

    return permissions;
  }
}
