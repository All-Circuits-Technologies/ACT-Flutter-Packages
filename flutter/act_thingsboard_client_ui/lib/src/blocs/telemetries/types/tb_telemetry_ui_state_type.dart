// SPDX-FileCopyrightText: 2023 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

/// Represents what the Thingsboard telemetry state brings (if new telemetries are available or if
/// it's for other things)
enum TbTelemetryUiStateType {
  /// Means that new attributes are available
  newAttributes,

  /// Means that new time series are available
  newTimeSeries,

  /// Other event occurred
  other,
}
