// SPDX-FileCopyrightText: 2023 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_halo_abstract/act_halo_abstract.dart';
import 'package:act_halo_ble_layer/src/halo_ble_companion.dart';

/// This is the BLE hardware layer for managing instant data
class HaloBleInstantDataHardware extends AbstractHaloInstantDataHardware {
  /// Class constructor
  HaloBleInstantDataHardware({
    // We keep the parameter for future, for now the class is only a pattern
    // ignore: avoid_unused_constructor_parameters
    required HaloBleCompanion bleCompanion,
  });

  /// This method allows to read a specific instant data value from the device and thanks to the
  /// [HaloDataId] given
  @override
  Future<(HaloErrorType, HaloPacket?)> readInstantData({required HaloDataId dataId}) {
    // TODO(brolandeau): implement readInstantData
    throw UnimplementedError();
  }

  /// This method allows to subscribe to the modification of a specific instant data thanks to the
  /// [HaloDataId] given
  /// For performance issues, it's better if the device already knows (by hardcoded configs in
  /// the Firmware) what are the instant data to send update
  @override
  Future<HaloErrorType> subInstantData({required HaloDataId dataId}) {
    // TODO(brolandeau): implement subInstantData
    throw UnimplementedError();
  }

  /// This method allows to unsubscribe from the modification of a specific instant data thanks to
  /// the [HaloDataId] given
  /// For performance issues, it's better if the device already knows (by hardcoded configs in
  /// the Firmware) what are the instant data to send update
  @override
  Future<HaloErrorType> unSubInstantData({required HaloDataId dataId}) {
    // TODO(brolandeau): implement unSubInstantData
    throw UnimplementedError();
  }

  /// This method allows to write a specific instant data value to the device
  @override
  Future<HaloErrorType> writeInstantData({required HaloPacket packet}) {
    // TODO(brolandeau): implement writeInstantData
    throw UnimplementedError();
  }
}
