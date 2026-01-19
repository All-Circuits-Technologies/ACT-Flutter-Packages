// SPDX-FileCopyrightText: 2025 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_http_core/act_http_core.dart';

/// Contains useful methods to manipulate HTTP headers
sealed class HeaderUtilities {
  /// Double quote character
  static const _quoteChar = '"';

  /// Single quote character
  static const _singleQuoteChar = "'";

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

  /// Parse the header value from the given [value] and get all the elements stored in it
  ///
  /// The method removes quotes around values if they are quoted.
  ///
  /// Return an empty if there is no value. If there is only one value without key, return a list
  /// with one element with a null key.
  ///
  /// Example:
  /// ```dart
  /// final headerValue = HeaderUtilities.parseHeaderValue(
  ///   value: 'attachment; filename=filename.jpg',
  /// );
  ///
  ///  // Result: [
  ///  //   (value: 'attachment', key: null),
  ///  //   (value: 'filename.jpg', key: 'filename'),
  ///  // ]
  ///  ```
  static List<({String value, String? key})> parseHeaderValue({
    required String value,
    String valuesSeparator = HeaderConstants.headerValueSeparatorChar,
  }) {
    if (value.isEmpty) {
      return [];
    }

    final result = <({String value, String? key})>[];
    final splitValue = value.split(valuesSeparator);
    for (final part in splitValue) {
      final keyValueSplit = part.split(HeaderConstants.propertySeparatorInHeaderValue);
      if (keyValueSplit.length >= 2) {
        final key = keyValueSplit[0].trim();
        var tmpValue = keyValueSplit[1].trim();

        // Remove quotes if the value is quoted
        if ((tmpValue.startsWith(_quoteChar) && tmpValue.endsWith(_quoteChar)) ||
            (tmpValue.startsWith(_singleQuoteChar) && tmpValue.endsWith(_singleQuoteChar))) {
          tmpValue = tmpValue.substring(1, tmpValue.length - 1);
        }

        result.add((value: tmpValue, key: key));
      } else {
        result.add((value: part.trim(), key: null));
      }
    }

    return result;
  }

  /// Get the header value from the given headers map for the given header key
  ///
  /// Return null if the [headerKey] is not contained in the [headers]. If there is no value, return
  /// an empty list. If there is only one value without key, return a list with one element with a
  /// null key.
  ///
  /// Example:
  /// ```dart
  /// final headerValue = HeaderUtilities.getHeaderValue(
  ///   headers: {
  ///     'Content-Disposition': 'attachment; filename=filename.jpg',
  ///   },
  ///   headerKey: 'Content-Disposition',
  /// );
  ///
  ///  // Result: [
  ///  //   (value: 'attachment', key: null),
  ///  //   (value: 'filename.jpg', key: 'filename'),
  ///  // ]
  ///  ```
  static List<({String value, String? key})>? getHeaderValue({
    required Map<String, String> headers,
    required String headerKey,
    String valuesSeparator = HeaderConstants.headerValueSeparatorChar,
  }) {
    // We also try the lower case value of the header key, because some flutter packages (like http)
    // use lower case keys for headers.
    final headerValue = headers[headerKey] ?? headers[headerKey.toLowerCase()];
    if (headerValue == null) {
      // The header key is not present in headers
      return null;
    }

    return parseHeaderValue(value: headerValue, valuesSeparator: valuesSeparator);
  }

  /// Get the file name from the `Content-Disposition` filename key
  ///
  /// Return null if there is no filename value in headers.
  ///
  /// The method doesn't manage (for now) `filename*` key
  static String? getFileNameFromHeaders({
    required Map<String, String> headers,
    String valuesSeparator = HeaderConstants.headerValueSeparatorChar,
  }) {
    final contentDispoValues = getHeaderValue(
      headers: headers,
      headerKey: HeaderConstants.contentDispositionHeaderKey,
      valuesSeparator: valuesSeparator,
    );
    if (contentDispoValues == null) {
      // No content disposition value in the headers
      return null;
    }

    for (final tmpValue in contentDispoValues) {
      if (tmpValue.key == HeaderConstants.contentDispositionFilenameKey) {
        return tmpValue.value;
      }
    }

    // The file name hasn't been found
    return null;
  }
}
