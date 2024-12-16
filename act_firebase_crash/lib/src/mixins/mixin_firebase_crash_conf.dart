// SPDX-FileCopyrightText: 2024 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_config_manager/act_config_manager.dart';

/// This mixin is used to add env variables needed by the firebase crash service
mixin MixinFirebaseCrashConf on AbstractConfigManager {
  /// Env variable linked to the firebase crash enable default value
  final firebaseCrashEnable = const ConfigVar<bool>(
    "firebase.crash.enable",
  );

  /// Env variable linked to the firebase crash auto log default value
  final firebaseCrashAutoLogEnable = const ConfigVar<bool>(
    "firebase.crash.autoLogEnable",
  );
}
