// SPDX-FileCopyrightText: 2025 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_config_manager/act_config_manager.dart';
import 'package:act_internet_connectivity_manager/src/constants/internet_constants.dart'
    as internet_constants;

/// Extends the [AbstractConfigManager] to add config variables which will be used by the
/// InternetConnectivityManager
mixin MixinInternetTestConfig on AbstractConfigManager {
  /// This is the server FDQN to use when we try to connect to internet
  final serverFqdnToTest = const NotNullableConfigVar<String>(
      "internetConnectivity.serverFqdnToTest",
      defaultValue: internet_constants.defaultServerFqdnToTest);

  /// This defines a period for retesting internet connection and verify if the internet connection
  /// is constant
  final testPeriod = const NotNullParserConfigVar<Duration, int>(
    "internetConnectivity.testPeriodInMs",
    parser: _parseMsDuration,
    defaultValue: internet_constants.defaultTestPeriod,
  );

  /// This defines the number of time we want to have a stable internet connection "status" when
  /// testing the connection with a period (value defined here: [testPeriod])
  final constantValueNb = const NotNullableConfigVar<int>("internetConnectivity.constantValueNb",
      defaultValue: internet_constants.defaultConstantValueNb);

  /// This is the periodic verification enabling, used to know if we should periodically
  /// verify if we have internet or not
  final periodicVerificationEnable = const NotNullableConfigVar<bool>(
      "internetConnectivity.periodicVerification.enable",
      defaultValue: internet_constants.defaultPeriodicVerificationEnable);

  /// This is the periodic verification max duration to wait before checking again if we have
  /// internet
  final periodicVerificationMaxDuration = const NotNullParserConfigVar<Duration, int>(
      "internetConnectivity.periodicVerification.maxDurationInS",
      parser: _parseSecDuration,
      defaultValue: internet_constants.defaultPeriodicVerificationMaxDuration);

  /// This is the periodic verification min duration to wait before checking again if we have
  /// internet
  final periodicVerificationMinDuration = const NotNullParserConfigVar<Duration, int>(
    "internetConnectivity.periodicVerification.minDurationInS",
    parser: _parseSecDuration,
    defaultValue: internet_constants.defaultPeriodicVerificationMinDuration,
  );

  /// Parse the given [durationInS] to a [Duration] object.
  ///
  /// If the [durationInS] is negative, it returns null.
  static Duration? _parseSecDuration(int durationInS) {
    if (durationInS < 0) {
      return null;
    }

    return Duration(seconds: durationInS);
  }

  /// Parse the given [durationInMs] to a [Duration] object.
  ///
  /// If the [durationInMs] is negative, it returns null.
  static Duration? _parseMsDuration(int durationInMs) {
    if (durationInMs < 0) {
      return null;
    }

    return Duration(milliseconds: durationInMs);
  }
}
