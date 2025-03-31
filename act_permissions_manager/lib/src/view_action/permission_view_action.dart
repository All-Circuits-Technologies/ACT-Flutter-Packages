// SPDX-FileCopyrightText: 2023 Anthony Loiseau <anthony.loiseau@allcircuits.com>
// SPDX-FileCopyrightText: 2023 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

/// Represents the action linked to the permission request
enum PermissionViewAction {
  /// This is used when we request the permission
  askPermission,

  /// This is used when the permission is permanently denied
  informPermanentlyDenied,
}
