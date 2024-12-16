// SPDX-FileCopyrightText: 2023 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_global_manager/act_global_manager.dart';
import 'package:act_halo_abstract/act_halo_abstract.dart';
import 'package:act_halo_ble_layer/src/characteristics/abstract_halo_characteristic.dart';
import 'package:act_halo_ble_layer/src/characteristics/mix_char_notification.dart';
import 'package:act_halo_ble_layer/src/halo_ble_companion.dart';
import 'package:act_halo_ble_layer/src/packets/halo_ble_request_result.dart';
import 'package:act_halo_ble_layer/src/packets/halo_ble_request_to_device_cmd_packet.dart';
import 'package:flutter/foundation.dart';

/// This is the BLE material layer for managing request to device
class HaloBleRequestToDeviceMaterial
    extends AbstractHaloRequestToDeviceMaterial {
  /// The ble companion to use in order to exchange
  final HaloBleCompanion _bleCompanion;

  /// Class constructor
  HaloBleRequestToDeviceMaterial({
    required HaloBleCompanion bleCompanion,
  }) : _bleCompanion = bleCompanion;

  /// This is the method to override in order to define the implementation of the calling function
  /// feature.
  /// When this method is called, we have verified if the request id given is a function
  @override
  Future<HaloRequestResult> implCallFunction(
          {required HaloRequestParamsPacket request}) =>
      _callRequest(
          cmdPacket: HaloBleRequestToDeviceCmdPacket(packetToSend: request));

  /// This is the method to override in order to define the implementation of the calling order
  /// feature.
  /// When this method is called, we have verified if the request id given is an order
  @override
  Future<HaloErrorType> implCallOrder(
      {required HaloRequestParamsPacket request}) async {
    final result = await _callRequest(
        cmdPacket: HaloBleRequestToDeviceCmdPacket(
      packetToSend: request,
    ));

    return result.error;
  }

  /// This is the method to override in order to define the implementation of the calling procedure
  /// feature.
  /// When this method is called, we have verified if the request id given is a procedure
  @override
  Future<HaloErrorType> implCallProcedure(
      {required HaloRequestParamsPacket request}) async {
    final result = await _callRequest(
        cmdPacket: HaloBleRequestToDeviceCmdPacket(
      packetToSend: request,
    ));

    return result.error;
  }

  /// Call request from device and manages the all process
  Future<HaloBleRequestResult> _callRequest({
    required HaloBleRequestToDeviceCmdPacket cmdPacket,
  }) async {
    final requestId = cmdPacket.packetToSend.requestId;

    // Before all: send a RESET procedure, to clean all the previous exchange
    var result = await _writeRequestPacket(
      requestId: requestId,
      dataToSend: HaloBleRequestToDeviceCmdPacket.reset(requestId: requestId)
          .getDataToSend(),
      expectAResultAtTheEnd: true,
      writeInCmdChar: true,
    );

    if (result.error != HaloErrorType.noError) {
      appLogger().w(
          "A problem occurred when trying to reset the request channel to device, before "
          "executing the request: $requestId in the device");
      return result;
    }

    final parametersPackets = cmdPacket.packetToSend.parameters.getDataToSend(
      maxPacketSize: _bleCompanion.haloBleConfig.maxCharacteristicByteSize,
    );

    final requestType = requestId.type;

    // First step: we write the command and we wait for the acknowledgment
    var tmpExpectAResponseAtTheEnd = requestType != HaloRequestType.order ||
        cmdPacket.packetToSend.nbValues.isNotEmpty;
    result = await _writeRequestPacket(
      requestId: requestId,
      dataToSend: cmdPacket.getDataToSend(),
      expectAResultAtTheEnd: tmpExpectAResponseAtTheEnd,
      writeInCmdChar: true,
    );

    if (result.error != HaloErrorType.noError) {
      appLogger().w(
          "A problem occurred when calling the request: $requestId in the device");
      return result;
    }

    if (!tmpExpectAResponseAtTheEnd) {
      // There is no parameters to send; therefore, we don't expect an answer, we can stop here
      return result;
    }

    // Second step: we send the parameters
    for (var idx = 0; idx < parametersPackets.length; ++idx) {
      tmpExpectAResponseAtTheEnd = requestType != HaloRequestType.order ||
          (idx != (parametersPackets.length - 1));

      result = await _writeRequestPacket(
        requestId: requestId,
        dataToSend: parametersPackets[idx],
        expectAResultAtTheEnd: tmpExpectAResponseAtTheEnd,
        writeInCmdChar: false,
      );

      if (result.error != HaloErrorType.noError) {
        appLogger()
            .w("A problem occurred when sending the parameters to the request: "
                "$requestId in the device");
        return result;
      }
    }

    if (requestType == HaloRequestType.procedure ||
        requestType == HaloRequestType.order) {
      // The order and procedure aren't expecting results, we can stop here
      return result;
    }

    // Third step: if we are it means that we have to inspect the result and ask for the result
    final (packetResult, packet) =
        await _readClientRequestFromExchangeZone(requestId: requestId);

    if (packetResult != HaloErrorType.noError) {
      return HaloBleRequestResult.error(
          error: packetResult, requestId: requestId);
    }

    return HaloBleRequestResult.success(requestId: requestId, result: packet!);
  }

  /// Write request packet, with the [requestId] given and the [dataToSend].
  ///
  /// If [expectAResultAtTheEnd] is equals to true, we wait for a notification in the command
  /// characteristic
  /// If [writeInCmdChar] is equals to true, we write in the command characteristic, if false we
  /// write in the temporary exchange characteristic
  Future<HaloBleRequestResult> _writeRequestPacket({
    required HaloRequestId requestId,
    required Uint8List dataToSend,
    required bool expectAResultAtTheEnd,
    required bool writeInCmdChar,
  }) async {
    if (!expectAResultAtTheEnd) {
      return _writeRequestPacketWithoutResult(
        requestId: requestId,
        dataToSend: dataToSend,
        writeInCmdChar: writeInCmdChar,
      );
    }

    return _writeRequestPacketWithResult(
      requestId: requestId,
      dataToSend: dataToSend,
      writeInCmdChar: writeInCmdChar,
    );
  }

  /// Write request packet, with the [requestId] given and the [dataToSend]. Without waiting for a
  /// notification result
  ///
  /// If [writeInCmdChar] is equals to true, we write in the command characteristic, if false we
  /// write in the temporary exchange characteristic
  Future<HaloBleRequestResult> _writeRequestPacketWithoutResult({
    required HaloRequestId requestId,
    required Uint8List dataToSend,
    required bool writeInCmdChar,
  }) async {
    final result = await _bleCompanion.onlyWrite(
      toWriteInto: writeInCmdChar
          ? _bleCompanion.haloBleConfig.charJRequestToDeviceCmd
          : _bleCompanion.haloBleConfig.charKRequestToDeviceTmp,
      dataToWrite: dataToSend,
    );

    if (result != HaloErrorType.noError) {
      appLogger().w(
          "A problem occurred when tried to write a command without response, for "
          "the request: $requestId to the device");
      return HaloBleRequestResult.error(
        requestId: requestId,
        error: result,
      );
    }

    return HaloBleRequestResult(
      requestId: requestId,
      cmdId: HaloCmdId.ack,
      result: null,
      error: HaloErrorType.noError,
    );
  }

  /// Write request packet, with the [requestId] given and the [dataToSend].
  ///
  /// We wait for a notification in the command characteristic after writing.
  /// If [writeInCmdChar] is equals to true, we write in the command characteristic, if false we
  /// write in the temporary exchange characteristic
  Future<HaloBleRequestResult> _writeRequestPacketWithResult({
    required HaloRequestId requestId,
    required Uint8List dataToSend,
    required bool writeInCmdChar,
  }) async {
    final (result, data) = await _bleCompanion.writeAndWaitNotifResult(
      toWriteInto: writeInCmdChar
          ? _bleCompanion.haloBleConfig.charJRequestToDeviceCmd
          : _bleCompanion.haloBleConfig.charKRequestToDeviceTmp,
      dataToWrite: dataToSend,
      toWaitNotifyFrom: _bleCompanion.haloBleConfig.charJRequestToDeviceCmd,
    );

    if (result != HaloErrorType.noError) {
      appLogger().w(
          "A problem occurred when tried to write a command, for the request: $requestId "
          "to the device");
      return HaloBleRequestResult.error(
        requestId: requestId,
        error: result,
      );
    }

    final requestResult = HaloBleRequestResult.parseResultFromDevice(
      requestId: requestId,
      deviceResult: data!,
    );

    if (requestResult == null) {
      appLogger().w(
          "A problem occurred when tried to parse the result of the request: "
          "$requestId, received from the device");
      return HaloBleRequestResult.error(
        requestId: requestId,
        error: HaloErrorType.genericError,
      );
    }

    if (requestResult.error != HaloErrorType.noError) {
      appLogger().w(
          "An error occurred on the device, when waiting for the result of the request: "
          "$requestId");
      return requestResult;
    }

    return requestResult;
  }

  /// Read a client request from exchange zone, do the same thing as [_readPacketFromDevice] but
  /// prefill the characteristics
  Future<(HaloErrorType, HaloPayloadPacket?)>
      _readClientRequestFromExchangeZone({
    required HaloRequestId requestId,
  }) async =>
          _readPacketFromDevice(
            toWriteInto: _bleCompanion.haloBleConfig.charJRequestToDeviceCmd,
            requestId: requestId,
            toWaitNotifyFrom:
                _bleCompanion.haloBleConfig.charKRequestToDeviceTmp,
          );

  /// Read packet from device, after having sent the request [requestId]
  ///
  /// We write in the [toWriteInto] characteristic for asking the sending of packets
  /// We wait and read the [toWaitNotifyFrom] characteristic
  Future<(HaloErrorType, HaloPayloadPacket?)> _readPacketFromDevice({
    required AbstractHaloCharacteristic toWriteInto,
    required HaloRequestId requestId,
    required MixCharNotification toWaitNotifyFrom,
  }) async {
    bool? allHasBeenReceived = false;
    final allPackets = <Uint8List>[];

    while (allHasBeenReceived == false) {
      final (result, data) = await _bleCompanion.writeAndWaitNotifResult(
        toWriteInto: toWriteInto,
        dataToWrite:
            HaloBleRequestToDeviceCmdPacket.readReady(requestId: requestId)
                .getDataToSend(),
        toWaitNotifyFrom: toWaitNotifyFrom,
      );

      if (result != HaloErrorType.noError) {
        appLogger().w(
            "A problem occurred when tried to read a result from the exchange zone"
            "from the device");
        return (result, null);
      }

      allHasBeenReceived = HaloPayloadPacket.isLastElementPacket(data!);

      if (allHasBeenReceived == null) {
        appLogger().w("A problem occurred in the packet received");
        return const (HaloErrorType.formatError, null);
      }

      allPackets.add(data);
    }

    final packet = HaloPayloadPacket.fromDevice(allPackets);

    if (packet == null) {
      appLogger()
          .w("A problem occurred in the packet received, we can't parse it");
      return const (HaloErrorType.formatError, null);
    }

    return (HaloErrorType.noError, HaloPayloadPacket.fromDevice(allPackets));
  }

  /// Manage the close of all the resources at the end of the class
  /// Need to be called by the owner of the class
  @override
  Future<void> close() async {
    // Nothing to do
  }
}
