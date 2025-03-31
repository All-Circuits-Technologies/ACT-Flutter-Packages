// SPDX-FileCopyrightText: 2024 Théo Magne <theo.magne@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_aws_iot_core/src/aws_iot_named_shadow.dart';
import 'package:act_aws_iot_core/src/mixins/mixin_aws_iot_shadow_enum.dart';
import 'package:act_aws_iot_core/src/models/aws_iot_shadows_config_model.dart';
import 'package:act_aws_iot_core/src/services/abs_aws_iot_service.dart';
import 'package:act_aws_iot_core/src/services/aws_iot_mqtt_service.dart';

/// This service handles the [AwsIotNamedShadow] of devices
class AwsIotShadowsService extends AbsAwsIotService {
  /// This is the logs category for the service
  static const _logsCategory = 'shadows';

  /// This is the mqtt service that will be used to interact with the shadows
  final AwsIotMqttService mqttService;

  /// This is the model that contains the configuration of the shadows service
  final AwsIotShadowsConfigModel config;

  /// This map associates a device name with its shadow
  final Map<String, Map<MixinAwsIotShadowEnum, AwsIotNamedShadow>> _shadowsMap;

  /// This gettter returns the list of devices that are currently managed by the service
  List<String> get devices => _shadowsMap.keys.toList();

  /// Class constructor
  AwsIotShadowsService({
    required this.config,
    required this.mqttService,
    required super.iotManagerLogsHelper,
  })  : _shadowsMap = {},
        super(logsCategory: _logsCategory);

  /// This method will add the shadows of a given [deviceName] to the service if they don't
  /// exist yet and return them
  /// [ShadowEnum] must be the type of the values in shadowsList of [config]
  Future<Map<ShadowEnum, AwsIotNamedShadow>>
      addAndGetShadowsForDevice<ShadowEnum extends MixinAwsIotShadowEnum>(String deviceName) async {
    // Return the shadows if they already exist
    if (_shadowsMap.containsKey(deviceName)) {
      return _shadowsMap[deviceName]!.cast<ShadowEnum, AwsIotNamedShadow>();
    }

    final shadowsOfDevice = <MixinAwsIotShadowEnum, AwsIotNamedShadow>{};
    for (final shadow in config.shadowsList) {
      final newShadow = AwsIotNamedShadow(
        mqttService: mqttService,
        logsHelper: logsHelper,
        thingName: deviceName,
        shadowName: shadow.shadowName,
      );
      await newShadow.init();

      shadowsOfDevice[shadow] = newShadow;
    }

    _shadowsMap[deviceName] = shadowsOfDevice;
    return shadowsOfDevice.cast<ShadowEnum, AwsIotNamedShadow>();
  }

  /// This method returns the shadow of a given [deviceName] and [shadow]
  /// Null is returned if no shadows exist for the provided [deviceName]
  AwsIotNamedShadow? getShadow(
    String deviceName,
    MixinAwsIotShadowEnum shadow,
  ) =>
      _shadowsMap[deviceName]?[shadow];

  /// This method removes the shadows of a given [deviceName]
  void removeShadowsOfDevice(String deviceName) {
    if (!_shadowsMap.containsKey(deviceName)) {
      logsHelper.w('No shadows found for device $deviceName, cannot remove them');
      return;
    }

    _shadowsMap.remove(deviceName);
  }
}
