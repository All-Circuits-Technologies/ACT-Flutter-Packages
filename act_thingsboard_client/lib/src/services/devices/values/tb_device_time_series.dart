// SPDX-FileCopyrightText: 2023 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_thingsboard_client/src/models/tb_ts_value.dart';
import 'package:act_thingsboard_client/src/services/devices/values/a_tb_telemetry.dart';
import 'package:thingsboard_client/thingsboard_client.dart';

/// Allows to manage and get values from time series
class TbDeviceTimeSeries extends ATbTelemetry<TbTsValue> {
  /// The logs category linked to the time series class
  static const _timeSeriesName = "timeSeries";

  /// Class constructor
  TbDeviceTimeSeries({
    required super.requestManager,
    required super.logsHelper,
    required super.deviceId,
  }) : super(telemetryName: _timeSeriesName);

  /// Create a subscription command linked to time series
  @override
  SubscriptionCmd createSubCmd(String keys) => TimeseriesSubscriptionCmd(
        entityType: EntityType.DEVICE,
        entityId: deviceId,
        keys: keys,
      );

  /// Called to parse the subscription update received and get the [TsValue] linked
  @override
  Future<Map<String, TbTsValue>> onUpdateValuesImpl(SubscriptionUpdate subUpdate) async {
    final elements = <String, TbTsValue>{};

    for (final tmp in subUpdate.data.entries) {
      if (tmp.value.isNotEmpty) {
        elements[tmp.key] = TbTsValue.fromTsValue(tmp.value.first);
      }
    }

    return elements;
  }

  /// Get the timestamp value linked to the last update value
  @override
  int? getTimestamp(TbTsValue? value) => value?.ts;
}
