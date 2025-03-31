// SPDX-FileCopyrightText: 2023 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_halo_abstract/act_halo_abstract.dart';

/// The ocsigen auth mode
enum OcsigenWiFiAuthMode with MixinHaloType {
  /// Means no need to authenticate to connect to WiFi
  wiFiAuthOpen(rawValue: 0x00),

  /// Means the authentication mode is by WEP key
  wiFiAuthWep(rawValue: 0x01),

  /// Means the authentication mode is by WPA_PSK key
  wiFiAuthWpaPsk(rawValue: 0x02),

  /// Means the authentication mode is by WPA2_PSK key
  wiFiAuthWpa2Psk(rawValue: 0x03),

  /// Means the authentication mode is by key WPA_WPA2_PSK
  wiFiAuthWpaWpa2Psk(rawValue: 0x04),

  /// Means that the authentication mode is by key WPA2_ENTERPRISE
  wiFiAuthWpa2Enterprise(rawValue: 0x05),

  /// Means that the authentication mode is by key WPA3_PSK
  wiFiAuthWpa3Psk(rawValue: 0x06),

  /// Means that we let the device use the right authentication
  wiFiAuthAuto(rawValue: 0xFE),

  /// Means that we don't know the authentication
  wiFiAuthUnknown(rawValue: 0xFF);

  /// The raw value linked to the enum
  @override
  final int rawValue;

  /// Class constructor
  const OcsigenWiFiAuthMode({required this.rawValue});

  /// Parse the raw value given and returns the [OcsigenWiFiAuthMode] enum linked, if the value
  /// isn't known, the method returns [OcsigenWiFiAuthMode.wiFiAuthUnknown]
  static OcsigenWiFiAuthMode parseValue(int value) {
    for (final tmpAuthMode in OcsigenWiFiAuthMode.values) {
      if (value == tmpAuthMode.rawValue) {
        return tmpAuthMode;
      }
    }

    return OcsigenWiFiAuthMode.wiFiAuthUnknown;
  }
}
