// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

/// Tell what the barcode scanner is doing, from the camera permission to the camera.
enum BarcodeScannerStatus {
  /// Mean that the platform is Linux, Windows or Fuchsia, where the camera can't be read.
  unsupported,

  /// Mean that the camera permission is being checked or asked for.
  waitingPermission,

  /// Mean that the camera permission isn't granted.
  permissionDenied,

  /// Mean that the permission is granted and that the camera is starting.
  starting,

  /// Mean that the camera is running and looks for barcodes.
  scanning,

  /// Mean that the camera ran, then was stopped or paused by the controller.
  stopped,

  /// Mean that the camera failed.
  error,
}
