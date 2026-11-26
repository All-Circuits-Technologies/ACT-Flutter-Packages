// SPDX-FileCopyrightText: 2023 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_dart_utility/act_dart_utility.dart';
import 'package:act_thingsboard_client/src/models/tb_ext_attribute_data.dart';
import 'package:act_thingsboard_client/src/models/tb_ts_value.dart';
import 'package:thingsboard_client/thingsboard_client.dart';

/// Helpful class to manage telemetries information
sealed class TbTelemetriesHelper {
  /// Get the attribute value from a given [TbExtAttributeData]
  ///
  /// Returns null if the value is null or if we fail to parse the value retrieved
  ///
  /// The method raises an exception if the wanted type is unknown
  static T? getAttributeValue<T>(TbExtAttributeData? extAttr) =>
      StringUtility.parseStrValue<T>(extAttr?.data.value as String?);

  /// Get the time series value from a given [TsValue]
  ///
  /// Returns null if the value is null or if we fail to parse the value retrieved
  ///
  /// The method raises an exception if the wanted type is unknown
  static T? getTsValue<T>(TbTsValue? tsValue) => StringUtility.parseStrValue<T>(tsValue?.value);

  /// Parse the lastTs of the given [TsValue] and returns a [DateTime]
  ///
  /// Returns null if the value or timestamp is null
  static DateTime? getTsLastUtcReceptionTime(TbTsValue? tsValue) => _parseUtcDateTime(tsValue?.ts);

  /// Parse the lastTs of the given [TbExtAttributeData] and returns a [DateTime]
  ///
  /// Returns null if the value or timestamp is null
  static DateTime? getAttributeLastUtcReceptionTime(TbExtAttributeData? extAttr) =>
      _parseUtcDateTime(extAttr?.data.lastUpdateTs);

  /// Useful method to parse an UTC millisecond timestamp to [DateTime]
  static DateTime? _parseUtcDateTime(int? tsInMs) {
    if (tsInMs == null) {
      return null;
    }

    return DateTime.fromMillisecondsSinceEpoch(tsInMs, isUtc: true);
  }
}
