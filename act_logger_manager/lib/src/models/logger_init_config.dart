// SPDX-FileCopyrightText: 2023 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:equatable/equatable.dart';
import 'package:logger/logger.dart';

/// Contains default information to use to initialise the logger
class LoggerInitConfig extends Equatable {
  /// The log level to apply to logs
  final Level logLevel;

  /// If true, logs are printed in console in release
  final bool printLogInRelease;

  /// Class constructor
  const LoggerInitConfig({
    this.logLevel = Level.warning,
    this.printLogInRelease = false,
  });

  /// Parse the given [strLevel] to a known [Level]
  ///
  /// If the [strLevel] isn't known, null is returned
  static Level? parseLevel(String? strLevel) {
    if (strLevel == null) {
      return null;
    }

    Level? parsedLevel;
    final lowerStrLevel = strLevel.toLowerCase();

    for (final value in Level.values) {
      if (value.name.toLowerCase() == lowerStrLevel) {
        parsedLevel = value;
      }
    }

    return parsedLevel;
  }

  @override
  List<Object?> get props => [logLevel, printLogInRelease];
}
