// SPDX-FileCopyrightText: 2023 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_global_manager/act_global_manager.dart';
import 'package:act_halo_abstract/act_halo_abstract.dart';
import 'package:act_ocsigen_halo_manager/src/types/ocsigen_wifi_connect_status.dart';
import 'package:equatable/equatable.dart';

/// This represents the result of the WiFi connect method
class OcsigenWiFiConnectResult extends Equatable {
  /// The status of the OCSIGEN WiFi connect method
  final OcsigenWiFiConnectStatus status;

  /// Contains the real error value got from the device (useful when the error isn't known by the
  /// API)
  final int errorValue;

  /// The private constructor
  const OcsigenWiFiConnectResult._({
    required this.status,
    required this.errorValue,
  });

  /// Parse the packet received from Device to the [OcsigenWiFiConnectResult]
  ///
  /// If an error occurred in the parsing, the method returns null
  static OcsigenWiFiConnectResult? parseFromDevice(HaloPayloadPacket packet) {
    final length = packet.elementsNb;

    if (length != 1) {
      appLogger().w(
          "The result received after trying to connect to the WiFi isn't well formatted, "
          "we haven't received one element has expected");
      return null;
    }

    final tmpErrorResult = packet.getUInt(0);

    if (tmpErrorResult == null) {
      appLogger().w(
          "The first element isn't an unsigned integer, we can't parse the Ocsigen WiFi "
          "connect result");
      return null;
    }

    final tmpErrorValue = tmpErrorResult.$1;

    final tmpStatus = OcsigenWiFiConnectStatus.parseValue(tmpErrorValue);

    return OcsigenWiFiConnectResult._(
        status: tmpStatus, errorValue: tmpErrorValue);
  }

  @override
  List<Object?> get props => [status, errorValue];
}
