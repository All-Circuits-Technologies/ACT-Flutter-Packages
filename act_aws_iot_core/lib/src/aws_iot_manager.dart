// SPDX-FileCopyrightText: 2024 Théo Magne <theo.magne@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_abstract_manager/act_abstract_manager.dart';
import 'package:act_amplify_cognito/act_amplify_cognito.dart';
import 'package:act_amplify_core/act_amplify_core.dart';
import 'package:act_aws_iot_core/src/mixins/mixin_aws_iot_conf.dart';
import 'package:act_aws_iot_core/src/mixins/mixin_aws_iot_shadow_enum.dart';
import 'package:act_aws_iot_core/src/models/aws_iot_mqtt_config_model.dart';
import 'package:act_aws_iot_core/src/models/aws_iot_shadows_config_model.dart';
import 'package:act_aws_iot_core/src/services/aws_iot_mqtt_service.dart';
import 'package:act_aws_iot_core/src/services/aws_iot_shadows_service.dart';
import 'package:act_dart_utility/act_dart_utility.dart';
import 'package:act_global_manager/act_global_manager.dart';
import 'package:act_internet_connectivity_manager/act_internet_connectivity_manager.dart';
import 'package:act_logger_manager/act_logger_manager.dart';
import 'package:act_shared_auth/act_shared_auth.dart';
import 'package:flutter/foundation.dart';

/// Builder class to create an [AwsIotManager] instance.
/// You must specify the [AuthManager] and [AmplifyManager] types to use in the
/// [AwsIotManager] instance.
class AwsIotBuilder<
    T extends AwsIotManager<AuthManager, AmplifyManager, ConfigManager>,
    AuthManager extends AbsAuthManager,
    AmplifyManager extends AbsAmplifyManager,
    ConfigManager extends MixinAwsIotConf> extends ManagerBuilder<T> {
  /// Class constructor
  AwsIotBuilder(super.factory);

  @override
  @mustCallSuper
  Iterable<Type> dependsOn() => [
        LoggerManager,
        ConfigManager,
        InternetConnectivityManager,
        AmplifyManager,
        AuthManager,
      ];
}

/// Abstract class to store aws iot services and manage them in an application.
abstract class AwsIotManager<
    AuthManager extends AbsAuthManager,
    AmplifyManager extends AbsAmplifyManager,
    ConfigManager extends MixinAwsIotConf> extends AbstractManager {
  /// Class logger category
  static const String _awsIotManagerLogCategory = 'aws_iot';

  /// Logs helper
  @protected
  late final LogsHelper logsHelper;

  /// Mqtt client iot service.
  late final AwsIotMqttService mqttService;

  /// Shadows service
  late final AwsIotShadowsService shadowsService;

  /// Return the [AmplifyCognitoService] to use for the aws iot services.
  /// Must be impleted in the concrete class.
  @protected
  AmplifyCognitoService get cognitoService;

  /// Return the list of shadow types to use for the aws iot services.
  /// Must be impleted in the concrete class.
  @protected
  List<MixinAwsIotShadowEnum> get shadowTypesList;

  /// Class constructor
  AwsIotManager();

  /// Start the aws iot services.
  @override
  @mustCallSuper
  Future<void> initManager() async {
    logsHelper = LogsHelper(
      logsManager: globalGetIt().get<LoggerManager>(),
      logsCategory: _awsIotManagerLogCategory,
    );
    logsHelper.d('Starting aws iot services...');

    // Create the configuration for the services
    final mqttConfig = AwsIotMqttConfigModel.get<ConfigManager>(cognitoService: cognitoService);
    if (mqttConfig == null) {
      throw (Exception('Missing mandatory configuration for the AwsIotManager'));
    }

    final shadowConfig = AwsIotShadowsConfigModel(shadowsList: shadowTypesList);

    final observers = await getExtraMqttObserversForConnection();

    // Create the services
    mqttService = AwsIotMqttService<AuthManager, AmplifyManager>(
      iotManagerLogsHelper: logsHelper,
      config: mqttConfig,
      extraStreamObservers: observers,
    );
    shadowsService = AwsIotShadowsService(
      iotManagerLogsHelper: logsHelper,
      config: shadowConfig,
      mqttService: mqttService,
    );

    // Initialize the services
    await mqttService.initService();
    await shadowsService.initService();
  }

  /// This can be used by the derived class to add extra stream observers for managing the
  /// connection
  @protected
  Future<List<StreamObserver>> getExtraMqttObserversForConnection() async => const [];

  /// Dispose the aws iot services.
  @override
  Future<void> dispose() async {
    await shadowsService.dispose();
    await mqttService.dispose();

    return super.dispose();
  }
}
