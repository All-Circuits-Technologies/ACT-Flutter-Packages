// SPDX-FileCopyrightText: 2023 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'dart:typed_data';

import 'package:act_ble_manager/act_ble_manager.dart';
import 'package:act_halo_ble_layer/src/characteristics/abstract_halo_characteristic.dart';
import 'package:act_halo_ble_layer/src/characteristics/mix_char_notification.dart';

/// The HALO characteristic A for attribute notification exchange
class CharAAttrNotify extends AbstractHaloCharacteristic
    with MixCharNotification {
  /// The characteristic name
  static const characteristicName = "attribute_notification";

  /// Class constructor
  CharAAttrNotify({
    required super.uuid,
  }) : super(
          name: characteristicName,
          scope: CharacteristicScope.readOnly,
          receiveType: Uint8List,
        );
}
