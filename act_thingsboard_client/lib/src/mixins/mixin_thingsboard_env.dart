// SPDX-FileCopyrightText: 2023 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_env_manager/act_env_manager.dart';

/// This mixin contains all the environment variables needed by the ACT Thingsboard package
mixin MixinThingsboardEnv on AbstractEnvManager {
  /// This is the hostname of the Thingsboard server to request
  final tbHostname = EnvVar<String>('TB_HOST');

  /// This is the port of the Thingsboard server to request
  final tbPort = EnvVar<int>('TB_PORT');

  /// This is the default username to use if none is contained in the app memory
  /// WARNING: the value of this env variable has to be contained in a "local.env" file
  final tbDefaultUsername = EnvVar<String>('TB_DEFAULT_USERNAME');

  /// This is the default password to use if none is contained in the app memory
  /// WARNING: the value of this env variable has to be contained in a "local.env" file
  final tbDefaultPassword = EnvVar<String>('TB_DEFAULT_PASSWORD');
}
