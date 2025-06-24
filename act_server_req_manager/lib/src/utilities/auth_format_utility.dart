// SPDX-FileCopyrightText: 2025 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'dart:convert';

import 'package:act_server_req_manager/act_server_req_manager.dart';

/// This pseudo-class contains authentication format utility functions.
sealed class AuthFormatUtility {
  /// Formats a Basic authentication header.
  ///
  /// Returns a tuple containing the header key and the formatted value.
  static ({String key, String value}) formatBasicAuthentication({
    required String username,
    required String password,
  }) {
    final toEncode = "$username${AuthConstants.credsSeparator}$password";
    final encoded = base64Encode(toEncode.codeUnits);

    return (
      key: AuthConstants.authorizationKey,
      value: AuthConstants.authBasic.replaceFirst(
        AuthConstants.credsBasicKey,
        encoded,
      ),
    );
  }
}
