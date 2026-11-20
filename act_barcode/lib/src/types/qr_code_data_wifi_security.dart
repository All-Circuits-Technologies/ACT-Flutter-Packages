// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_dart_utility/act_dart_utility.dart';

/// Enum representing Wi-Fi security types for QR code data.
enum QrCodeDataWifiSecurity with MixinStringValueType {
  /// WPA for WPA/WPA2/WPA3 protocols
  wpa(stringValueOverride: "WPA"),

  /// WEP for WEP protocol
  wep(stringValueOverride: "WEP"),

  /// No security for open networks
  none(stringValueOverride: "nopass");

  /// {@macro act_dart_utility.MixinStringValueType.stringValueOverride}
  @override
  final String? stringValueOverride;

  /// Enum constructor
  const QrCodeDataWifiSecurity({this.stringValueOverride});
}
