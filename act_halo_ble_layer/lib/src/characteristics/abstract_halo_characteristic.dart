// SPDX-FileCopyrightText: 2023 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_ble_manager/act_ble_manager.dart';

/// This is the abstract class for defining all the HALO characteristics
abstract class AbstractHaloCharacteristic extends AbstractCharacteristicInfo {
  /// Say if the characteristic may notify and can be subscribed
  @override
  bool get hasNotification => false;

  /// Class constructor
  AbstractHaloCharacteristic(
      {required super.name,
      required super.uuid,
      required super.scope,
      super.receiveType,
      super.sendType});
}
