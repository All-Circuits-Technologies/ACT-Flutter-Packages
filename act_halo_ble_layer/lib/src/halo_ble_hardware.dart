// SPDX-FileCopyrightText: 2023 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_halo_abstract/act_halo_abstract.dart';
import 'package:act_halo_ble_layer/src/halo_ble_companion.dart';
import 'package:act_halo_ble_layer/src/hardware_layer/halo_ble_attribute_hardware.dart';
import 'package:act_halo_ble_layer/src/hardware_layer/halo_ble_instant_data_hardware.dart';
import 'package:act_halo_ble_layer/src/hardware_layer/halo_ble_record_data_hardware.dart';
import 'package:act_halo_ble_layer/src/hardware_layer/halo_ble_request_from_device_hardware.dart';
import 'package:act_halo_ble_layer/src/hardware_layer/halo_ble_request_to_device_hardware.dart';

/// This is BLE hardware layer
class HaloBleHardware extends AbstractHaloHardware {
  /// This is the BLE companion to work with HALO BLE
  final HaloBleCompanion bleCompanion;

  /// Class constructor
  HaloBleHardware({
    required this.bleCompanion,
  }) : super(
          attributeHardware: HaloBleAttributeHardware(
            bleCompanion: bleCompanion,
          ),
          instantDataHardware: HaloBleInstantDataHardware(
            bleCompanion: bleCompanion,
          ),
          recordDataHardware: HaloBleRecordDataHardware(
            bleCompanion: bleCompanion,
          ),
          requestFromDeviceHardware: HaloBleRequestFromDeviceHardware(
            bleCompanion: bleCompanion,
          ),
          requestToDeviceHardware: HaloBleRequestToDeviceHardware(
            bleCompanion: bleCompanion,
          ),
        );
}
