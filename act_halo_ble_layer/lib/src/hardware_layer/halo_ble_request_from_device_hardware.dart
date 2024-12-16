// SPDX-FileCopyrightText: 2023 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_halo_abstract/act_halo_abstract.dart';
import 'package:act_halo_ble_layer/src/halo_ble_companion.dart';

/// This is the BLE hardware layer for managing request from device
class HaloBleRequestFromDeviceHardware extends AbstractHaloRequestFromDeviceHardware {
  /// Class constructor
  HaloBleRequestFromDeviceHardware({
    required HaloBleCompanion bleCompanion,
  });
}
