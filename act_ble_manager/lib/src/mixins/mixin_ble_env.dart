// SPDX-FileCopyrightText: 2023 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_env_manager/act_env_manager.dart';

/// This mixin has to be applied in the EnvManager of the main app, in order to get the env used
/// by the BleManager lib
mixin MixinBleEnv on AbstractEnvManager {
  /// True if we want to display the BLE scanned devices in logs
  final displayScannedDeviceInLogs = NotNullableEnvVar<bool>(
    "BLE_DISPLAY_SCANNED_DEVICE_IN_LOGS",
    defaultValue: false,
  );
}
