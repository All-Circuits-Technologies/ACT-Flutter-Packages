// SPDX-FileCopyrightText: 2023 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'dart:typed_data';

import 'package:act_global_manager/act_global_manager.dart';
import 'package:act_halo_abstract/act_halo_abstract.dart';

/// The HALO BLE request result
class HaloBleRequestResult extends HaloRequestResult {
  /// Fixed number of bytes in data received
  static const fixedNumberOfBytesInDataReceived = 4;

  /// The index of cmd id
  static const cmdIdIdx = 0;

  /// The index of error enum
  static const errorEnumIdx = 1;

  /// The index of value number
  static const valueNbIdx = 2;

  /// The index of request id
  static const requestIdIdx = 3;

  /// The command id received with the result
  final HaloCmdId cmdId;

  /// Class constructor
  const HaloBleRequestResult({
    required this.cmdId,
    required super.requestId,
    required super.result,
    required super.error,
    super.nbValues,
  });

  /// Helpful constructor to manage success request result
  const HaloBleRequestResult.success({
    required super.requestId,
    required super.result,
  })  : cmdId = HaloCmdId.ack,
        super(error: HaloErrorType.noError, nbValues: 0);

  /// Helpful constructor to manager error in the request result
  const HaloBleRequestResult.error({
    required super.error,
    required super.requestId,
  })  : cmdId = HaloCmdId.unknown,
        super.error();

  /// Parse the result received from device and create [HaloBleRequestResult] from it
  static HaloBleRequestResult? parseResultFromDevice({
    required HaloRequestId requestId,
    required Uint8List deviceResult,
  }) {
    if (deviceResult.length != fixedNumberOfBytesInDataReceived) {
      appLogger().w("The size of the response received (after an HALO request) isn't equal of what "
          "we expect: $fixedNumberOfBytesInDataReceived");
      return null;
    }

    final cmdId = HaloCmdIdHelper.parseValue(deviceResult[cmdIdIdx]);
    if (cmdId == HaloCmdId.unknown) {
      appLogger().w("The command id received is unknown: $cmdId");
    }

    final error = HaloErrorTypeHelper.parseValue(deviceResult[errorEnumIdx]);
    if (error == HaloErrorType.unknown) {
      appLogger().w("An error occurred in the device but its unknown: $error");
    }

    if (requestId.id != deviceResult[requestIdIdx]) {
      appLogger().w("We expect an answer to the request: $requestId, but we received a result for "
          "the request: ${deviceResult[requestIdIdx]}, can't proceed");
      return null;
    }

    return HaloBleRequestResult(
      error: error,
      requestId: requestId,
      cmdId: cmdId,
      result: null,
      nbValues: deviceResult[valueNbIdx],
    );
  }

  @override
  List<Object?> get props => [...super.props, cmdId];
}
