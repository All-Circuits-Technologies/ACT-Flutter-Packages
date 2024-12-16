// SPDX-FileCopyrightText: 2023 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_halo_abstract/act_halo_abstract.dart';

/// The OCSIGEN WiFi connect status
enum OcsigenWiFiConnectStatus with MixinHaloType {
  success(rawValue: 0x00, isError: false),
  timeoutError(rawValue: 0x01),
  wrongPasswordError(rawValue: 0x02),
  notFoundAccessPointError(rawValue: 0x03),
  wiFiConnectionFailedError(rawValue: 0x04),
  mqttConnexionFailedError(rawValue: 0x05),
  wiFiDataSavingError(rawValue: 0x06),
  unknownError(rawValue: 0xFF);

  /// True if the status is in error
  final bool isError;

  /// The raw value linked to the enum
  @override
  final int rawValue;

  /// Class constructor
  const OcsigenWiFiConnectStatus({required this.rawValue, this.isError = true});

  /// Parse the raw value given and returns the [OcsigenWiFiConnectStatus] enum linked, if the value
  /// isn't known, the method returns [OcsigenWiFiConnectStatus.unknownError]
  static OcsigenWiFiConnectStatus parseValue(int value) {
    for (final status in OcsigenWiFiConnectStatus.values) {
      if (value == status.rawValue) {
        return status;
      }
    }

    return OcsigenWiFiConnectStatus.unknownError;
  }
}
