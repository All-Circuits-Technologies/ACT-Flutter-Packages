// SPDX-FileCopyrightText: 2023 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_global_manager/act_global_manager.dart';
import 'package:act_halo_abstract/act_halo_abstract.dart';
import 'package:act_ocsigen_halo_manager/src/types/ocsigen_wifi_urc.dart';
import 'package:equatable/equatable.dart';

/// Represents the result of the WiFi status retrieved from Device
class OcsigenWiFiStatusResult extends Equatable {
  /// The number of elements contained in the result received from device
  static const elementsNb = 5;

  /// The index of the SSID in the result received from device
  static const ssidIdx = 0;

  /// The index of the ip in the result received from device
  static const ipIdx = 1;

  /// The index of the netmask in the result received from device
  static const netmaskIdx = 2;

  /// The index of the gateway in the result received from device
  static const gatewayIdx = 3;

  /// The index of the urc in the result received from device
  static const urcIdx = 4;

  /// The ssid contained in the WiFi status
  final String ssid;

  /// The ip contained in the WiFi status
  final String ip;

  /// The netmask contained in the WiFi status
  final String netmask;

  /// The gateway contained in the WiFi status
  final String gateway;

  /// The urc contained in the WiFi status
  final OcsigenWiFiUrc urc;

  /// Private constructor
  const OcsigenWiFiStatusResult._({
    required this.ssid,
    required this.ip,
    required this.netmask,
    required this.gateway,
    required this.urc,
  });

  /// Parse the packet received from Device to the [OcsigenWiFiStatusResult]
  ///
  /// If an error occurred in the parsing, the method returns null
  static List<OcsigenWiFiStatusResult>? parseFromDevice(HaloPayloadPacket packet) {
    final length = packet.elementsNb;

    if ((length % elementsNb) != 0) {
      appLogger().w("The list of WiFi status isn't well formatted, the number of elements "
          "is not a modulo of $elementsNb");
      return null;
    }

    final elements = <OcsigenWiFiStatusResult>[];
    for (var idx = 0; idx < length; idx = idx + elementsNb) {
      final ssidResult = packet.getString(idx + ssidIdx);

      if (ssidResult == null) {
        appLogger().w("The element at the idx: ${idx + ssidIdx} isn't a string ssid, we can't "
            "parse the Ocsigen WiFi status result");
        return null;
      }

      final ipResult = packet.getString(idx + ipIdx);

      if (ipResult == null) {
        appLogger().w("The element at the idx: ${idx + ipIdx} isn't a string ip, we can't "
            "parse the Ocsigen WiFi status result");
        return null;
      }

      final netmaskResult = packet.getString(idx + netmaskIdx);

      if (netmaskResult == null) {
        appLogger().w("The element at the idx: ${idx + netmaskIdx} isn't a string netmask, we "
            "can't parse the Ocsigen WiFi status result");
        return null;
      }

      final gatewayResult = packet.getString(idx + gatewayIdx);

      if (gatewayResult == null) {
        appLogger().w("The element at the idx: ${idx + gatewayIdx} isn't a string gateway, we "
            "can't parse the Ocsigen WiFi status result");
        return null;
      }

      final urcResult = packet.getUInt(idx + urcIdx);

      if (urcResult == null) {
        appLogger().w("The element at the idx: ${idx + gatewayIdx} isn't a uint8 urc, we "
            "can't parse the Ocsigen WiFi status result");
        return null;
      }

      final urc = OcsigenWiFiUrc.parseValue(urcResult.$1);

      if (urc == OcsigenWiFiUrc.unknown) {
        appLogger().w("The ocsigen WiFi urc isn't known, we continue");
      }

      elements.add(OcsigenWiFiStatusResult._(
          ssid: ssidResult.$1,
          ip: ipResult.$1,
          netmask: netmaskResult.$1,
          gateway: gatewayResult.$1,
          urc: urc));
    }

    return elements;
  }

  @override
  List<Object?> get props => [ssid, ip, netmask, gateway, urc];
}
