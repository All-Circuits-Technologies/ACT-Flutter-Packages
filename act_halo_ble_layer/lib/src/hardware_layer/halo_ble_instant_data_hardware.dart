// SPDX-FileCopyrightText: 2023 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'dart:async';

import 'package:act_dart_result/act_dart_result.dart';
import 'package:act_global_manager/act_global_manager.dart';
import 'package:act_halo_abstract/act_halo_abstract.dart';
import 'package:act_halo_ble_layer/src/halo_ble_companion.dart';
import 'package:act_halo_ble_layer/src/hardware_layer/halo_ble_data_exchange.dart';

/// This is the BLE hardware layer for managing instant data
///
/// It is the attribute service without the write: the commands go through the characteristic E,
/// the values through the characteristic F and the characteristic D notifies the flags of the
/// instant data which changed (see [HaloBleDataExchange]).
class HaloBleInstantDataHardware extends AbstractHaloInstantDataHardware {
  /// The exchanges of the instant data service
  late final HaloBleDataExchange _exchange;

  /// Class constructor
  HaloBleInstantDataHardware({required HaloBleCompanion bleCompanion}) {
    final config = bleCompanion.haloBleConfig;
    _exchange = HaloBleDataExchange(
      bleCompanion: bleCompanion,
      label: "instant data",
      cmdChar: config.charEInstCmd,
      tmpChar: config.charFInstTmp,
      flags: (
        char: config.charDInstNotify,
        onNewValue: (packet) {
          if (!instantDataNewValueCtrl.isClosed) {
            instantDataNewValueCtrl.add(packet);
          }
        },
      ),
    );
  }

  /// This method allows to read a specific instant data value from the device and thanks to the
  /// [HaloDataId] given
  @override
  Future<ResultWithRequiredValue<HaloErrorType, HaloPacket>> readInstantData({
    required HaloDataId dataId,
  }) => _exchange.read(dataId: dataId);

  /// This method allows to subscribe to the modification of a specific instant data thanks to the
  /// [HaloDataId] given
  /// For performance issues, it's better if the device already knows (by hardcoded configs in
  /// the Firmware) what are the instant data to send update
  @override
  Future<HaloErrorType> subInstantData({required HaloDataId dataId}) =>
      _exchange.sendCmdNoValue(cmdId: HaloCmdId.sub, id: [dataId.id]);

  /// This method allows to unsubscribe from the modification of a specific instant data thanks to
  /// the [HaloDataId] given
  /// For performance issues, it's better if the device already knows (by hardcoded configs in
  /// the Firmware) what are the instant data to send update
  @override
  Future<HaloErrorType> unSubInstantData({required HaloDataId dataId}) =>
      _exchange.sendCmdNoValue(cmdId: HaloCmdId.unSub, id: [dataId.id]);

  /// The instant data can't be written over BLE (the API stays for the WebSocket), nothing is sent
  @override
  Future<HaloErrorType> writeInstantData({required HaloPacket packet}) async {
    appLogger().w("The instant data can't be written over BLE: ${packet.dataId.id}");

    return HaloErrorType.notImplementedYet;
  }

  /// Manage the close of all the resources at the end of the class
  /// Need to be called by the owner of the class
  @override
  Future<void> close() async {
    await _exchange.close();
    await super.close();
  }
}
