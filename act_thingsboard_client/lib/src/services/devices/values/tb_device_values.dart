// SPDX-FileCopyrightText: 2023 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'dart:async';

import 'package:act_logger_manager/act_logger_manager.dart';
import 'package:act_thingsboard_client/src/managers/abs_tb_server_req_manager.dart';
import 'package:act_thingsboard_client/src/services/devices/values/tb_device_attributes.dart';
import 'package:act_thingsboard_client/src/services/devices/values/tb_device_time_series.dart';
import 'package:act_thingsboard_client/src/services/devices/values/tb_telemetry_handler.dart';
import 'package:thingsboard_client/thingsboard_client.dart';

/// Contains the memory cache of the subscribed telemetry (attributes and time series) linked to a
/// particular device
class TbDeviceValues {
  /// The logs helper linked to the device values
  final LogsHelper logsHelper;

  /// The id of the device covered
  final String deviceId;

  /// The client attributes of the device
  late final TbDeviceAttributes _clientAttributes;

  /// Getter of the client attributes handler
  TbDeviceAttributes get clientAttributes => _clientAttributes;

  /// The shared attributes of the device
  late final TbDeviceAttributes _sharedAttributes;

  /// Getter of the shared attributes handler
  TbDeviceAttributes get sharedAttributes => _sharedAttributes;

  /// The server attributes of the device
  late final TbDeviceAttributes _serverAttributes;

  /// Getter of the server attributes handler
  TbDeviceAttributes get serverAttributes => _serverAttributes;

  /// The time series of the device
  late final TbDeviceTimeSeries _timeSeries;

  /// Getter of the time series handler
  TbDeviceTimeSeries get timeSeries => _timeSeries;

  /// Class constructor
  TbDeviceValues({
    required AbsTbServerReqManager requestManager,
    required this.deviceId,
    required LogsHelper logsHelper,
  }) : logsHelper = logsHelper.createASubLogsHelper(deviceId) {
    _clientAttributes = TbDeviceAttributes(
      requestManager: requestManager,
      logsHelper: logsHelper,
      deviceId: deviceId,
      scope: AttributeScope.CLIENT_SCOPE,
    );

    _sharedAttributes = TbDeviceAttributes(
      requestManager: requestManager,
      logsHelper: logsHelper,
      deviceId: deviceId,
      scope: AttributeScope.SHARED_SCOPE,
    );

    _serverAttributes = TbDeviceAttributes(
      requestManager: requestManager,
      logsHelper: logsHelper,
      deviceId: deviceId,
      scope: AttributeScope.SERVER_SCOPE,
    );

    _timeSeries = TbDeviceTimeSeries(
      requestManager: requestManager,
      logsHelper: logsHelper,
      deviceId: deviceId,
    );
  }

  /// Create a telemetry handler to observe attributes or time series values
  TbTelemetryHandler createTelemetryHandler() => TbTelemetryHandler(deviceValues: this);

  /// Class dispose method
  Future<void> dispose() async {
    await Future.wait([
      _clientAttributes.dispose(),
      _sharedAttributes.dispose(),
      _serverAttributes.dispose(),
      _timeSeries.dispose(),
    ]);
  }
}
