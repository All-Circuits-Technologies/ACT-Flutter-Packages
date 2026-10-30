// SPDX-FileCopyrightText: 2023 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'dart:async';

import 'package:act_dart_result/act_dart_result.dart';
import 'package:act_halo_abstract/act_halo_abstract.dart';
import 'package:act_halo_ble_layer/src/halo_ble_companion.dart';
import 'package:act_halo_ble_layer/src/hardware_layer/halo_ble_data_exchange.dart';

/// This is the BLE hardware layer for managing attributes
///
/// The commands go through the characteristic B, the values through the characteristic C and the
/// characteristic A notifies the flags of the attributes which changed (see [HaloBleDataExchange]).
class HaloBleAttributeHardware extends AbstractHaloAttributeHardware {
  /// The exchanges of the attribute service
  late final HaloBleDataExchange _exchange;

  /// Class constructor
  HaloBleAttributeHardware({required HaloBleCompanion bleCompanion}) {
    final config = bleCompanion.haloBleConfig;
    _exchange = HaloBleDataExchange(
      bleCompanion: bleCompanion,
      label: "attribute",
      cmdChar: config.charBAttrCmd,
      tmpChar: config.charCAttrTmp,
      flags: (
        char: config.charAAttrNotify,
        onNewValue: (packet) {
          if (!attributeNewValueCtrl.isClosed) {
            attributeNewValueCtrl.add(packet);
          }
        },
      ),
    );
  }

  /// This method allows to write a specific attribute value to the device
  @override
  Future<HaloErrorType> writeAttribute({required HaloPacket packet}) =>
      _exchange.write(packet: packet);

  /// This method allows to read a specific attribute value from the device and thanks to the
  /// [HaloDataId] given
  @override
  Future<ResultWithRequiredValue<HaloErrorType, HaloPacket>> readAttribute({
    required HaloDataId dataId,
  }) => _exchange.read(dataId: dataId);

  /// This method allows to subscribe to the modification of a specific attribute thanks to the
  /// [HaloDataId] given
  /// For performance issues, it's better if the device already knows (by hardcoded configs in
  /// the Firmware) what are the attributes to send update
  @override
  Future<HaloErrorType> subAttribute({required HaloDataId dataId}) =>
      _exchange.sendCmdNoValue(cmdId: HaloCmdId.sub, id: [dataId.id]);

  /// This method allows to unsubscribe from the modification of a specific attribute thanks to the
  /// [HaloDataId] given
  /// For performance issues, it's better if the device already knows (by hardcoded configs in
  /// the Firmware) what are the attributes to send update
  @override
  Future<HaloErrorType> unSubAttribute({required HaloDataId dataId}) =>
      _exchange.sendCmdNoValue(cmdId: HaloCmdId.unSub, id: [dataId.id]);

  /// Manage the close of all the resources at the end of the class
  /// Need to be called by the owner of the class
  @override
  Future<void> close() async {
    await _exchange.close();
    await super.close();
  }
}
