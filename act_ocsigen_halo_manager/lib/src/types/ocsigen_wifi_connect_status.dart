// SPDX-FileCopyrightText: 2023 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

/// The OCSIGEN WiFi connect status
enum OcsigenWiFiConnectStatus {
  success(hexValue: 0x00, isError: false),
  timeoutError(hexValue: 0x01),
  wrongPasswordError(hexValue: 0x02),
  notFoundAccessPointError(hexValue: 0x03),
  wiFiConnexionFailedError(hexValue: 0x04),
  mqttConnexionFailedError(hexValue: 0x05),
  wiFiDataSavingError(hexValue: 0x06),
  unknownError(hexValue: 0xFF);

  /// True if the status is in error
  final bool isError;

  /// The hex value linked to the enum
  final int hexValue;

  /// Class constructor
  const OcsigenWiFiConnectStatus({required this.hexValue, this.isError = true});

  /// Parse the hex value given and returns the [OcsigenWiFiConnectStatus] enum linked, if the value
  /// isn't known, the method returns [OcsigenWiFiConnectStatus.unknownError]
  static OcsigenWiFiConnectStatus parseValue(int value) {
    for (final status in OcsigenWiFiConnectStatus.values) {
      if (value == status.hexValue) {
        return status;
      }
    }

    return OcsigenWiFiConnectStatus.unknownError;
  }
}
