// SPDX-FileCopyrightText: 2023 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_config_manager/act_config_manager.dart';

/// This mixin contains all the environment variables needed by the ACT Thingsboard package
mixin MixinThingsboardConf on AbstractConfigManager {
  /// This is the hostname of the Thingsboard server to request
  final tbHostname = const ConfigVar<String>('thingsboard.host');

  /// This is the port of the Thingsboard server to request
  final tbPort = const ConfigVar<int>('thingsboard.port');
}
