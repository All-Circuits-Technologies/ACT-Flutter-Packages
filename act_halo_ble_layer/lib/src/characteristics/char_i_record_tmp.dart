// SPDX-FileCopyrightText: 2023 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'dart:typed_data';

import 'package:act_ble_manager/act_ble_manager.dart';
import 'package:act_halo_ble_layer/src/characteristics/abstract_halo_characteristic.dart';
import 'package:act_halo_ble_layer/src/characteristics/mix_char_notification.dart';

/// The HALO characteristic I for record data temporary exchange
class CharIRecordTmp extends AbstractHaloCharacteristic with MixCharNotification {
  /// The characteristic name
  static const characteristicName = "record_data_exchange_zone";

  /// Class constructor
  CharIRecordTmp({
    required super.uuid,
  }) : super(
          name: characteristicName,
          scope: CharacteristicScope.readOnly,
          receiveType: Uint8List,
        );
}
