// SPDX-FileCopyrightText: 2023 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:equatable/equatable.dart';
import 'package:geolocator/geolocator.dart';

/// This class contains the basic information to configure the LocationManager
class LocationInitConfig extends Equatable {
  /// Default time limit duration used when trying to get position
  static const defaultTimeLimitWhenGettingPosition = Duration(seconds: 10);

  /// This is the default accuracy which will be used when getting the position
  final LocationAccuracy accuracy;

  /// True if we want to ask the user the always location permission
  ///
  /// Most of the time, "always" isn't need.
  final bool isLocationUsageAlways;

  /// This is the default time limit used when trying to get the current position
  final Duration timeLimitWhenGettingPosition;

  /// Class constructor
  const LocationInitConfig({
    required this.accuracy,
    required this.isLocationUsageAlways,
    this.timeLimitWhenGettingPosition = defaultTimeLimitWhenGettingPosition,
  });

  /// Default class constructor
  const LocationInitConfig.defaultConfig()
      : accuracy = LocationAccuracy.reduced,
        isLocationUsageAlways = false,
        timeLimitWhenGettingPosition = defaultTimeLimitWhenGettingPosition;

  @override
  List<Object?> get props => [
        accuracy,
        isLocationUsageAlways,
        timeLimitWhenGettingPosition,
      ];
}
