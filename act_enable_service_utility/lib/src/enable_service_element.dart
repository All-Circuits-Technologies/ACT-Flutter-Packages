// SPDX-FileCopyrightText: 2023 Anthony Loiseau <anthony.loiseau@allcircuits.com>
// SPDX-FileCopyrightText: 2023 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

/// This represents the different kind of system service which may be enabled
enum EnableServiceElement {
  /// This is the background service for using the application in background
  background,

  /// This is the Bluetooth Low Energy service
  ble,

  /// This is the Bluetooth Low Energy service with location (this is needed for older Android
  /// version)
  bleLocation,

  /// This is the location service
  location,

  /// This is the WiFi service
  wifi;
}
