// SPDX-FileCopyrightText: 2023 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_dart_result/act_dart_result.dart';
import 'package:act_halo_abstract/act_halo_abstract.dart';

/// The OCSIGEN WiFi connect status
enum OcsigenWiFiConnectStatus with MixinHaloType, MixinResultStatus {
  /// The connection was successful
  success(rawValue: 0x00, isSuccess: true, canBeRetried: true),

  /// The waiting time has been exceeded for the wifi connection
  timeoutError(rawValue: 0x01, canBeRetried: true),

  /// Wrong WiFi password error
  wrongPasswordError(rawValue: 0x02, canBeRetried: false),

  /// The WiFi access point is not found
  notFoundAccessPointError(rawValue: 0x03, canBeRetried: true),

  /// The WiFi connection failed
  wiFiConnectionFailedError(rawValue: 0x04, canBeRetried: true),

  /// The MQTT connection failed
  mqttConnexionFailedError(rawValue: 0x05, canBeRetried: true),

  /// The WiFi data backup failed
  wiFiDataSavingError(rawValue: 0x06, canBeRetried: true),

  /// The error is unknown
  unknownError(rawValue: 0xFF, canBeRetried: false);

  /// {@macro act_dart_result.MixinResultStatus.isSuccess}
  ///
  /// This is true only for [OcsigenWiFiConnectStatus.success]
  @override
  final bool isSuccess;

  /// {@macro act_dart_result.MixinResultStatus.canBeRetried}
  ///
  /// A wrong password or an unknown status can't be fixed by trying again
  @override
  final bool canBeRetried;

  /// The raw value linked to the enum
  @override
  final int rawValue;

  /// Class constructor
  const OcsigenWiFiConnectStatus({
    required this.rawValue,
    required this.canBeRetried,
    this.isSuccess = false,
  });

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
