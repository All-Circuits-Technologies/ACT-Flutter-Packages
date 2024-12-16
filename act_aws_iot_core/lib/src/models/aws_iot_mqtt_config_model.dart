// SPDX-FileCopyrightText: 2024 Théo Magne <theo.magne@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_amplify_cognito/act_amplify_cognito.dart';
import 'package:act_aws_iot_core/src/mixins/mixin_aws_iot_conf.dart';
import 'package:act_aws_iot_core/src/services/aws_iot_mqtt_service.dart';
import 'package:act_global_manager/act_global_manager.dart';
import 'package:equatable/equatable.dart';

/// The configuration used by the [AwsIotMqttService]
class AwsIotMqttConfigModel extends Equatable {
  /// The default port number used for MQTT connections.
  static const _defaultMqttPort = 443;

  /// The default duration for which the signer validity is maintained.
  static const _defaultSignerValidityDuration = Duration(minutes: 15);

  /// The region to use to connect to the mqtt server
  final String region;

  /// The endpoint to use to connect to the mqtt server
  final String endpoint;

  /// This is the cognito service to use
  final AmplifyCognitoService cognitoService;

  /// The duration for which the signer validity is maintained.
  final Duration signerValidityDuration;

  /// The port number used for MQTT connections.
  final int mqttPort;

  /// Class constructor
  const AwsIotMqttConfigModel._({
    required this.region,
    required this.endpoint,
    required this.cognitoService,
    required this.signerValidityDuration,
    required this.mqttPort,
  });

  /// This method tries to get the configuration from the
  static AwsIotMqttConfigModel? get<ConfigManager extends MixinAwsIotConf>({
    required AmplifyCognitoService cognitoService,
    Duration? signerValidityDuration,
    int? mqttPort,
  }) {
    final configManager = globalGetIt().get<ConfigManager>();

    final region = configManager.awsIotRegion.load();
    if (region == null) {
      appLogger().f('AwsIotMqttConfigModel: The region is not set in the configuration');
      return null;
    }

    final endpoint = configManager.awsIotEndpoint.load();
    if (endpoint == null) {
      appLogger().f('AwsIotMqttConfigModel: The endpoint is not set in the configuration');
      return null;
    }

    return AwsIotMqttConfigModel._(
      region: region,
      endpoint: endpoint,
      cognitoService: cognitoService,
      signerValidityDuration: signerValidityDuration ?? _defaultSignerValidityDuration,
      mqttPort: mqttPort ?? _defaultMqttPort,
    );
  }

  /// Properties of the model
  @override
  List<Object?> get props => [
        region,
        endpoint,
        cognitoService,
        signerValidityDuration,
        mqttPort,
      ];
}
