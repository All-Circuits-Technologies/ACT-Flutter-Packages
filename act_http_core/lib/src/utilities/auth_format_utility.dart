// SPDX-FileCopyrightText: 2025 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'dart:convert';

import 'package:act_http_core/act_http_core.dart';
import 'package:act_http_core/src/constants/header_constants.dart';

/// This pseudo-class contains authentication format utility functions.
sealed class AuthFormatUtility {
  /// Formats a Basic authentication header.
  ///
  /// Returns a tuple containing the header key and the formatted value.
  static ({String key, String value}) formatBasicAuthentication({
    required String username,
    required String password,
  }) {
    final toEncode = "$username${HeaderConstants.credsSeparator}$password";
    final encoded = base64Encode(toEncode.codeUnits);

    return (
      key: HeaderConstants.authorizationHeaderKey,
      value: HeaderConstants.authBasic.replaceFirst(HeaderConstants.credsBasicKey, encoded),
    );
  }
}
