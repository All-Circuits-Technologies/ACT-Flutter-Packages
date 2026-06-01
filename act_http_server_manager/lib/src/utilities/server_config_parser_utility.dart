// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <borlnov.obsessio@gmail.com>
//
// SPDX-License-Identifier: Apache-2.0

import 'package:act_dart_utility/act_dart_utility.dart';
import 'package:act_global_manager/act_global_manager.dart';

/// This utility class is responsible for parsing the server configuration from the config manager.
sealed class ServerConfigParserUtility {
  /// This is the json key to use to parse the min value of the ports range from a json
  static const String _portsRangeMinJsonKey = "min";

  /// This is the json key to use to parse the max value of the ports range from a json
  static const String _portsRangeMaxJsonKey = "max";

  /// This method is used to try to parse the ports range from a json.
  ///
  /// It returns null if the parsing fails.
  static NumBoundaries<int>? tryToParseBoundaries(Map<String, dynamic> json) {
    final logger = appLogger();

    final min = JsonUtility.getNotNullOnePrimaryElement<int>(
      json: json,
      key: _portsRangeMinJsonKey,
      logger: logger,
    );
    final max = JsonUtility.getNotNullOnePrimaryElement<int>(
      json: json,
      key: _portsRangeMaxJsonKey,
      logger: logger,
    );

    if (max == null || min == null) {
      logger.e("Failed to parse the ports range from the json: $json");
      return null;
    }

    return NumBoundaries<int>(min: min, max: max);
  }
}
