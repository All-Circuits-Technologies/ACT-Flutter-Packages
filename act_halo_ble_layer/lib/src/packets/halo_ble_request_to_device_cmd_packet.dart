// SPDX-FileCopyrightText: 2023 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'dart:typed_data';

import 'package:act_halo_abstract/act_halo_abstract.dart';
import 'package:equatable/equatable.dart';

/// This is the command packet send to request the device
class HaloBleRequestToDeviceCmdPacket extends Equatable with InterfaceHaloPacketToSend {
  /// The command id
  final HaloCmdId cmdId;

  /// The packet to send
  final HaloRequestParamsPacket packetToSend;

  /// Default constructor, the cmd id is equals to [HaloCmdId.call], to get a reset command or
  /// readReady, see the other constructors
  const HaloBleRequestToDeviceCmdPacket({required this.packetToSend}) : cmdId = HaloCmdId.call;

  /// Private constructor
  const HaloBleRequestToDeviceCmdPacket._({required this.cmdId, required this.packetToSend});

  /// Helpful method to create a reset command
  factory HaloBleRequestToDeviceCmdPacket.reset({required MixinHaloRequestId requestId}) =>
      _createOtherCmd(cmdId: HaloCmdId.reset, requestId: requestId);

  /// Helpful method to create a read ready command
  factory HaloBleRequestToDeviceCmdPacket.readReady({required MixinHaloRequestId requestId}) =>
      _createOtherCmd(cmdId: HaloCmdId.readReady, requestId: requestId);

  /// Helpful static method to create other command which are not the call command
  static HaloBleRequestToDeviceCmdPacket _createOtherCmd({
    required HaloCmdId cmdId,
    required MixinHaloRequestId requestId,
  }) =>
      HaloBleRequestToDeviceCmdPacket._(
          cmdId: cmdId,
          packetToSend: HaloRequestParamsPacket(
            requestId: requestId,
            nbValues: const [],
            parameters: HaloPayloadPacket(),
          ));

  /// This method transforms the payload as a packet ready to be sent to the device.
  @override
  Uint8List getDataToSend() {
    final toSend = <int>[];

    // Add the CMD_ID
    toSend.add(cmdId.rawValue);
    // Add the REQUEST_ID : U1
    toSend.add(packetToSend.requestId.rawValue);
    // Add the REQUEST_TYPE : EU1
    toSend.add(packetToSend.requestId.type.rawValue);
    // Add the NB_PARAM : U1
    toSend.add(packetToSend.nbValues.length);

    for (final nbValue in packetToSend.nbValues) {
      // Add the NB_VALUES : U1 ; for each parameter
      toSend.add(nbValue);
    }

    return Uint8List.fromList(toSend);
  }

  @override
  List<Object?> get props => [cmdId, packetToSend];
}
