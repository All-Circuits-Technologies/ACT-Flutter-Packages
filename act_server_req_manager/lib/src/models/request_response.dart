// SPDX-FileCopyrightText: 2023 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_server_req_manager/src/types/request_result.dart';
import 'package:equatable/equatable.dart';
import 'package:http/http.dart';

/// This is the request response
class RequestResponse<Body> extends Equatable {
  /// The result of the response
  final RequestResult result;

  /// The response received from the third server
  final Response? response;

  /// The body contained in the response received
  final Body? castedBody;

  /// Class constructor
  const RequestResponse({
    required this.result,
    this.response,
    this.castedBody,
  });

  /// Export the class members to a pattern
  (RequestResult, Response?, Body?) toPatterns() =>
      (result, response, castedBody);

  @override
  List<Object?> get props => [result, response, castedBody];
}
