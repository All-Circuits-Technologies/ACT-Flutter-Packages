// SPDX-FileCopyrightText: 2023 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_config_manager/act_config_manager.dart';

/// This mixin has to be applied in the EnvManager of the main app, in order to get the env used
/// by the BleManager lib
mixin MixinBleConf on AbstractConfigManager {
  /// True if we want to display the BLE scanned devices in logs
  final displayScannedDeviceInLogs = const NotNullableConfigVar<bool>(
    "ble.logs.displayScannedDevice",
    defaultValue: false,
  );
}
