// SPDX-FileCopyrightText: 2023 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_halo_abstract/act_halo_abstract.dart';
import 'package:act_halo_ble_layer/src/halo_ble_companion.dart';
import 'package:act_halo_ble_layer/src/material_layer/halo_ble_attribute_material.dart';
import 'package:act_halo_ble_layer/src/material_layer/halo_ble_instant_data_material.dart';
import 'package:act_halo_ble_layer/src/material_layer/halo_ble_record_data_material.dart';
import 'package:act_halo_ble_layer/src/material_layer/halo_ble_request_from_device_material.dart';
import 'package:act_halo_ble_layer/src/material_layer/halo_ble_request_to_device_material.dart';

/// This is BLE material layer
class HaloBleMaterial extends AbstractHaloMaterial {
  /// This is the BLE companion to work with HALO BLE
  final HaloBleCompanion bleCompanion;

  /// Class constructor
  HaloBleMaterial({
    required this.bleCompanion,
  }) : super(
          attributeMaterial: HaloBleAttributeMaterial(
            bleCompanion: bleCompanion,
          ),
          instantDataMaterial: HaloBleInstantDataMaterial(
            bleCompanion: bleCompanion,
          ),
          recordDataMaterial: HaloBleRecordDataMaterial(
            bleCompanion: bleCompanion,
          ),
          requestFromDeviceMaterial: HaloBleRequestFromDeviceMaterial(
            bleCompanion: bleCompanion,
          ),
          requestToDeviceMaterial: HaloBleRequestToDeviceMaterial(
            bleCompanion: bleCompanion,
          ),
        );
}
