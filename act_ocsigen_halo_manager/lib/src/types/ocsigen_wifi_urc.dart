// SPDX-FileCopyrightText: 2023 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_dart_utility/act_dart_utility.dart';
import 'package:act_halo_abstract/act_halo_abstract.dart';

/// The ocsigen WiFi URC
enum OcsigenWiFiUrc with MixinHaloType {
  ok(rawValue: 0x00),
  connecting(rawValue: 0x01),
  disconnected(rawValue: 0x02),
  failedAttempt(rawValue: 0x03),
  lostConnection(rawValue: 0x04),
  unknown(rawValue: ByteUtility.maxInt64);

  /// The raw value linked to the enum
  @override
  final int rawValue;

  /// Class constructor
  const OcsigenWiFiUrc({required this.rawValue});

  /// Parse the raw value given and returns the [OcsigenWiFiUrc] enum linked, if the value
  /// isn't known, the method returns [OcsigenWiFiUrc.unknown]
  static OcsigenWiFiUrc parseValue(int value) {
    for (final tmpAuthMode in OcsigenWiFiUrc.values) {
      if (value == tmpAuthMode.rawValue) {
        return tmpAuthMode;
      }
    }

    return OcsigenWiFiUrc.unknown;
  }
}
