// SPDX-FileCopyrightText: 2023 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_dart_utility/act_dart_utility.dart';

/// The ocsigen auth mode
enum OcsigenWiFiAuthMode {
  wiFiAuthOpen(hexValue: 0x00),
  wiFiAuthWep(hexValue: 0x01),
  wiFiAuthWpaPsk(hexValue: 0x02),
  wiFiAuthWpa2Psk(hexValue: 0x03),
  wiFiAuthWpaWpa2Psk(hexValue: 0x04),
  wiFiAuthWpa2Enterprise(hexValue: 0x05),
  wiFiAuthWpa3Psk(hexValue: 0x06),
  unknown(hexValue: ByteUtility.maxInt64);

  /// The hex value linked to the enum
  final int hexValue;

  /// Class constructor
  const OcsigenWiFiAuthMode({required this.hexValue});

  /// Parse the hex value given and returns the [OcsigenWiFiAuthMode] enum linked, if the value
  /// isn't known, the method returns [OcsigenWiFiAuthMode.unknown]
  static OcsigenWiFiAuthMode parseValue(int value) {
    for (final tmpAuthMode in OcsigenWiFiAuthMode.values) {
      if (value == tmpAuthMode.hexValue) {
        return tmpAuthMode;
      }
    }

    return OcsigenWiFiAuthMode.unknown;
  }
}
