// SPDX-FileCopyrightText: 2023 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_global_manager/act_global_manager.dart';
import 'package:act_halo_abstract/act_halo_abstract.dart';
import 'package:act_ocsigen_halo_manager/src/types/ocsigen_wifi_auth_mode.dart';
import 'package:equatable/equatable.dart';

/// Represents the result of the WiFi complete scan got from Device
class OcsigenWiFiCompleteScanResult extends Equatable {
  /// The number of elements contained in the result received from device
  static const elementsNb = 4;

  /// The index of the SSID in the result received from device
  static const ssidIdx = 0;

  /// The index of the RSSI in the result received from device
  static const rssiIdx = 1;

  /// The index of the channel number in the result received from device
  static const channelNbIdx = 2;

  /// The index of the auth mode in the result received from device
  static const authModeIdx = 3;

  /// The ssid contained in the WiFi complete scan
  final String ssid;

  /// The rssi contained in the WiFi complete scan
  final int rssi;

  /// The channel nb contained in the WiFi complete scan
  final int channelNb;

  /// The auth mode contained in the WiFi complete scan
  final OcsigenWiFiAuthMode authMode;

  /// The private constructor
  const OcsigenWiFiCompleteScanResult._({
    required this.ssid,
    required this.rssi,
    required this.channelNb,
    required this.authMode,
  });

  /// Parse the packet received from Device to the [OcsigenWiFiCompleteScanResult]
  ///
  /// If an error occurred in the parsing, the method returns null
  static List<OcsigenWiFiCompleteScanResult>? parseFromDevice(HaloPayloadPacket packet) {
    final length = packet.elementsNb;

    if ((length % elementsNb) != 0) {
      appLogger().w("The list of WiFi complete info isn't well formatted, the number of elements "
          "is not a modulo of $elementsNb");
      return null;
    }

    final elements = <OcsigenWiFiCompleteScanResult>[];
    for (var idx = 0; idx < length; idx = idx + elementsNb) {
      final ssidResult = packet.getString(idx + ssidIdx);

      if (ssidResult == null) {
        appLogger().w("The element at the idx: ${idx + ssidIdx} isn't a string ssid, we can't "
            "parse the Ocsigen WiFi complete scan result");
        return null;
      }

      final rssiResult = packet.getInt(idx + rssiIdx);

      if (rssiResult == null) {
        appLogger().w("The element at the idx: ${idx + rssiIdx} isn't an int rssi, we can't "
            "parse the Ocsigen WiFi complete scan result");
        return null;
      }

      final channelNbResult = packet.getUInt(idx + channelNbIdx);

      if (channelNbResult == null) {
        appLogger().w("The element at the idx: ${idx + channelNbIdx} isn't an uint channel nb, we "
            "can't parse the Ocsigen WiFi complete scan result");
        return null;
      }

      final tmpAuthMode = packet.getUInt(idx + authModeIdx);

      if (tmpAuthMode == null) {
        appLogger().w("The element at the idx: ${idx + authModeIdx} isn't an uint auth mode, we "
            "can't parse the Ocsigen WiFi complete scan result");
        return null;
      }

      final authMode = OcsigenWiFiAuthMode.parseValue(tmpAuthMode.$1);

      if (authMode == OcsigenWiFiAuthMode.wiFiAuthUnknown) {
        appLogger().w("The ocsigen WiFi auth mode isn't known: ${tmpAuthMode.$1}, we continue");
      }

      elements.add(OcsigenWiFiCompleteScanResult._(
        ssid: ssidResult.$1,
        rssi: rssiResult.$1,
        channelNb: channelNbResult.$1,
        authMode: authMode,
      ));
    }

    return elements;
  }

  @override
  List<Object?> get props => [ssid, rssi, channelNb, authMode];
}
