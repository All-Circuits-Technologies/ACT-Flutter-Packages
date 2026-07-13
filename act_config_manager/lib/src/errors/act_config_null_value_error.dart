// SPDX-FileCopyrightText: 2025 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_foundation/act_foundation.dart';

/// This error is thrown when a config variable is null and no default value is provided.
class ActConfigNullValueError extends ActError {
  /// The key of the config variable that is null
  final String key;

  /// Class constructor
  ActConfigNullValueError({required this.key})
    : super("The value of the config variable: $key, is null, and we don't have a default value");
}
