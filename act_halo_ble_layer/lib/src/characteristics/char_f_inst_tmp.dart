// SPDX-FileCopyrightText: 2023 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'dart:typed_data';

import 'package:act_ble_manager/act_ble_manager.dart';
import 'package:act_halo_ble_layer/src/characteristics/abstract_halo_characteristic.dart';

/// The HALO characteristic F for instant data temporary exchange
class CharFInstTmp extends AbstractHaloCharacteristic {
  /// The characteristic name
  static const characteristicName = "instant_data_exchange_zone";

  /// Class constructor
  CharFInstTmp({
    required super.uuid,
  }) : super(
          name: characteristicName,
          scope: CharacteristicScope.readWrite,
          receiveType: Uint8List,
          sendType: Uint8List,
        );
}
