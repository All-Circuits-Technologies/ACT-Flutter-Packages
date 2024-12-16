// SPDX-FileCopyrightText: 2024 Théo Magne <theo.magne@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_config_manager/act_config_manager.dart';

/// Mixin to add AWS Iot configuration
mixin MixinAwsIotConf on AbstractConfigManager {
  /// The AWS Iot endpoint to use for the connection
  final awsIotEndpoint = const ConfigVar<String>(
    "aws.iot.endpoint",
  );

  /// The AWS Iot region to use for the connection
  final awsIotRegion = const ConfigVar<String>(
    "aws.iot.region",
  );
}
