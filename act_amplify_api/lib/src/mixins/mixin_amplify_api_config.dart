// SPDX-FileCopyrightText: 2024 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_config_manager/act_config_manager.dart';
import 'package:amplify_flutter/amplify_flutter.dart';

/// This is the mixin to use with the ConfigManager of the app in order to add Amplify api configs
mixin MixinAmplifyApiConfig on AbstractConfigManager {
  /// This config is used to extend the Amplify generated config file with more AWS API plugin
  /// config.
  /// See: https://docs.amplify.aws/gen1/flutter/build-a-backend/restapi/existing-resources/ for
  /// more information
  final amplifyApiConfig = const ParserConfigVar<ApiConfig, Map<String, dynamic>>(
    "amplify.api.config",
    parser: ApiConfig.fromJson,
  );
}
