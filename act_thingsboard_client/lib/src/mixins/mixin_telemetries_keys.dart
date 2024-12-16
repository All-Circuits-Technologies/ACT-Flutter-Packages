// SPDX-FileCopyrightText: 2023 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

/// This mixin is used as skeleton for the telemetries keys (attributes and time series)
mixin MixinTelemetriesKeys {
  /// Get the string key used in thingsboard to represent this telemetry element
  String getTbKey();

  /// Convert the telemetry keys list to string keys used in thingsboard
  static List<String> parseTelemetryKeyList(List<MixinTelemetriesKeys> telemetriesKeys) {
    final onlyKeys = <String>[];

    for (final telemetryKey in telemetriesKeys) {
      onlyKeys.add(telemetryKey.getTbKey());
    }

    return onlyKeys;
  }
}
