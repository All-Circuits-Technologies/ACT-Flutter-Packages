// SPDX-FileCopyrightText: 2023 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_halo_abstract/act_halo_abstract.dart';
import 'package:act_halo_ble_layer/src/halo_ble_companion.dart';

/// This is the BLE hardware layer for managing attributes
class HaloBleAttributeHardware extends AbstractHaloAttributeHardware {
  /// Class constructor
  HaloBleAttributeHardware({
    required HaloBleCompanion bleCompanion,
  });

  /// This method allows to write a specific attribute value to the device
  @override
  Future<HaloErrorType> writeAttribute({required HaloPacket packet}) {
    // TODO(brolandeau): implement writeAttribute
    throw UnimplementedError();
  }

  /// This method allows to read a specific attribute value from the device and thanks to the
  /// [HaloDataId] given
  @override
  Future<(HaloErrorType, HaloPacket?)> readAttribute({required HaloDataId dataId}) {
    // TODO(brolandeau): implement readAttribute
    throw UnimplementedError();
  }

  /// This method allows to subscribe to the modification of a specific attribute thanks to the
  /// [HaloDataId] given
  /// For performance issues, it's better if the device already knows (by hardcoded configs in
  /// the Firmware) what are the attributes to send update
  @override
  Future<HaloErrorType> subAttribute({required HaloDataId dataId}) {
    // TODO(brolandeau): implement subAttribute
    throw UnimplementedError();
  }

  /// This method allows to unsubscribe from the modification of a specific attribute thanks to the
  /// [HaloDataId] given
  /// For performance issues, it's better if the device already knows (by hardcoded configs in
  /// the Firmware) what are the attributes to send update
  @override
  Future<HaloErrorType> unSubAttribute({required HaloDataId dataId}) {
    // TODO(brolandeau): implement unSubAttribute
    throw UnimplementedError();
  }
}
