// SPDX-FileCopyrightText: 2024 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'dart:convert';

import 'package:act_amplify_api/src/types/server_response_status.dart';
import 'package:act_global_manager/act_global_manager.dart';
import 'package:amplify_flutter/amplify_flutter.dart';

/// Contains utility methods to help the management of the [AWSHttpResponse] class
sealed class HttpResponseUtility {
  /// Try to decode the body of the response
  ///
  /// If a problem occurred, the method returns null
  static String? tryDecodeBody(
    AWSHttpResponse response, {
    Encoding encoding = utf8,
  }) {
    String decoded;
    try {
      decoded = response.decodeBody(encoding: encoding);
    } catch (error) {
      appLogger().w("An error occurred when tried to decode a response received from AWS server: "
          "$error");
      return null;
    }

    return decoded;
  }

  /// Get the server response status from the [response] given
  static ServerResponseStatus getStatus(AWSHttpResponse response) =>
      ServerResponseStatus.parseFromHttpStatus(response.statusCode);
}
