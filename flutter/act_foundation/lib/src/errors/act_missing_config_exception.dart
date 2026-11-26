// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_foundation/src/errors/act_exception.dart';

/// This exception is thrown when a required configuration value is missing (null, empty or not
/// set) and prevents the caller from continuing.
class ActMissingConfigException extends ActException {
  /// Class constructor
  ///
  /// [configName] is the name (or a short description) of the missing configuration value.
  ActMissingConfigException(String configName)
    : super("The configuration value: $configName, is missing or hasn't been given");
}
