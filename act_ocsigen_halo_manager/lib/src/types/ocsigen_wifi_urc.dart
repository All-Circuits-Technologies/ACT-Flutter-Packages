// SPDX-FileCopyrightText: 2023 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_dart_utility/act_dart_utility.dart';

/// The ocsigen WiFi URC
enum OcsigenWiFiUrc {
  ok(hexValue: 0x00),
  connecting(hexValue: 0x01),
  disconnected(hexValue: 0x02),
  failedAttempt(hexValue: 0x03),
  lostConnection(hexValue: 0x04),
  unknown(hexValue: ByteUtility.maxInt64);

  /// The hex value linked to the enum
  final int hexValue;

  /// Class constructor
  const OcsigenWiFiUrc({required this.hexValue});

  /// Parse the hex value given and returns the [OcsigenWiFiUrc] enum linked, if the value
  /// isn't known, the method returns [OcsigenWiFiUrc.unknown]
  static OcsigenWiFiUrc parseValue(int value) {
    for (final tmpAuthMode in OcsigenWiFiUrc.values) {
      if (value == tmpAuthMode.hexValue) {
        return tmpAuthMode;
      }
    }

    return OcsigenWiFiUrc.unknown;
  }
}
