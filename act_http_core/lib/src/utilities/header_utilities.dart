// SPDX-FileCopyrightText: 2025 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_http_core/act_http_core.dart';

/// Contains useful methods to manipulate HTTP headers
sealed class HeaderUtilities {
  /// Formats a header value from a list of values and optional keys
  ///
  /// Example:
  /// ```dart
  /// final headerValue = HeaderUtilities.formatHeaderValue(
  ///   values: [
  ///     (value: 'attachment', key: null),
  ///     (value: 'filename', key: 'filename.jpg'),
  ///   ],
  ///  );
  ///
  ///  // Result: 'attachment; filename=filename.jpg'
  ///  ```
  static String formatHeaderValue({
    required List<({String value, String? key})> values,
    String valuesSeparator = HeaderConstants.headerValueSeparator,
  }) {
    final valuesPart = <String>[];
    for (final value in values) {
      if (value.key != null) {
        valuesPart.add(
          '${value.key}${HeaderConstants.propertySeparatorInHeaderValue}${value.value}',
        );
      } else {
        valuesPart.add(value.value);
      }
    }

    return valuesPart.join(valuesSeparator);
  }
}
