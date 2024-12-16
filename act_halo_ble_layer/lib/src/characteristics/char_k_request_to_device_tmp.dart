// SPDX-FileCopyrightText: 2023 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'dart:typed_data';

import 'package:act_ble_manager/act_ble_manager.dart';
import 'package:act_halo_ble_layer/src/characteristics/abstract_halo_characteristic.dart';
import 'package:act_halo_ble_layer/src/characteristics/mix_char_notification.dart';

/// The HALO characteristic K for request to device temporary exchange
class CharKRequestToDeviceTmp extends AbstractHaloCharacteristic
    with MixCharNotification {
  /// The characteristic name
  static const characteristicName = "request_to_device_exchange_zone";

  /// Class constructor
  CharKRequestToDeviceTmp({
    required super.uuid,
  }) : super(
          name: characteristicName,
          scope: CharacteristicScope.readWrite,
          receiveType: Uint8List,
          sendType: Uint8List,
        );
}
