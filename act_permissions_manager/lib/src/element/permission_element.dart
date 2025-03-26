// SPDX-FileCopyrightText: 2023 Anthony Loiseau <anthony.loiseau@allcircuits.com>
// SPDX-FileCopyrightText: 2023 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_permissions_manager/src/element/permission_element_extension.dart';
import 'package:permission_handler/permission_handler.dart' as permission_handler;

/// The permissions managed in the application
enum PermissionElement {
  /// This groups all the permissions linked to the background service
  background,

  /// This groups all the permissions linked to the Bluetooth service
  ble,

  /// This groups all the permissions linked to the location getting when we want to always get it
  locationAlways,

  /// This groups all the permissions linked to the location getting when the app is used
  locationWhenInUse,

  /// This groups all the permissions linked to the tracking authorization service
  trackingAuthorization,

  /// This groups all the permissions linked to the WiFi service
  wifi;

  /// This method returns true if the permission element needs a location permission
  bool get isAskingLocation {
    final permissionsList = PermissionElementHelper.getPermissions(this);

    return permissionsList.contains(permission_handler.Permission.locationWhenInUse) ||
        permissionsList.contains(permission_handler.Permission.locationAlways);
  }
}
