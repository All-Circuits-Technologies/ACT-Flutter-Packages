// SPDX-FileCopyrightText: 2023 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_halo_abstract/act_halo_abstract.dart';

/// The ocsigen auth mode
enum OcsigenWiFiAuthMode with MixinHaloType {
  wiFiAuthOpen(rawValue: 0x00),
  wiFiAuthWep(rawValue: 0x01),
  wiFiAuthWpaPsk(rawValue: 0x02),
  wiFiAuthWpa2Psk(rawValue: 0x03),
  wiFiAuthWpaWpa2Psk(rawValue: 0x04),
  wiFiAuthWpa2Enterprise(rawValue: 0x05),
  wiFiAuthWpa3Psk(rawValue: 0x06),
  wiFiAuthAuto(rawValue: 0xFE),
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
