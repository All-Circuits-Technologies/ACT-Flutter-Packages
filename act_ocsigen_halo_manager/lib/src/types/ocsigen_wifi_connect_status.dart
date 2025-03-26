// SPDX-FileCopyrightText: 2023 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_halo_abstract/act_halo_abstract.dart';

/// The OCSIGEN WiFi connect status
enum OcsigenWiFiConnectStatus with MixinHaloType {
  /// The connection was successful
  success(rawValue: 0x00, isError: false),

  /// The waiting time has been exceeded for the wifi connection
  timeoutError(rawValue: 0x01),

  /// Wrong WiFi password error
  wrongPasswordError(rawValue: 0x02),

  /// The WiFi access point is not found
  notFoundAccessPointError(rawValue: 0x03),

  /// The WiFi connection failed
  wiFiConnectionFailedError(rawValue: 0x04),

  /// The MQTT connection failed
  mqttConnexionFailedError(rawValue: 0x05),

  /// The WiFi data backup failed
  wiFiDataSavingError(rawValue: 0x06),

  /// The error is unknown
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
