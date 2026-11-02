// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

/// List the messages the barcode scanner displays, which the application translates.
enum BarcodeScannerText {
  /// Tell that the scanner can't run on the platform.
  unsupportedPlatform,

  /// Tell that the camera permission is being checked or asked for.
  waitingPermission,

  /// Tell that the camera permission isn't granted.
  permissionDenied,

  /// Label the button which asks the camera permission again.
  askPermissionButton,

  /// Tell that the camera failed.
  cameraError,
}
