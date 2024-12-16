// SPDX-FileCopyrightText: 2023 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'dart:convert';

import 'package:act_server_req_manager/src/types/http_methods.dart';
import 'package:act_server_req_manager/src/types/mime_types.dart';
import 'package:equatable/equatable.dart';

/// Contains all the needed parameters to request a distant url
class RequestParam extends Equatable {
  /// The HTTP method of the request
  final HttpMethods httpMethod;

  /// The relative route of the URL
  final String relativeRoute;

  /// The request headers
  final Map<String, String> headers;

  /// This contains key/value map and its useful to replace elements in the URL which match the key
  /// by the value given.
  ///
  /// This can be useful, for instance, to add ids in paths
  final Map<String, String>? routeParams;

  /// The request query parameters
  final Map<String, dynamic>? queryParameters;

  /// The request body
  final dynamic body;

  /// The body encoding
  final Encoding? encoding;

  /// The max timeout of the request, if not given, the default timeout is used
  final Duration? timeout;

  /// The expected MIME type of the request response (in case the request is a success)
  final MimeTypes? expectedMimeType;

  /// Class constructor
  RequestParam({
    required this.httpMethod,
    required this.relativeRoute,
    Map<String, String>? headers,
    this.routeParams,
    this.queryParameters,
    this.body,
    this.encoding,
    this.timeout,
    this.expectedMimeType,
  }) : headers = headers ?? <String, String>{};

  @override
  List<Object?> get props => [
        httpMethod,
        relativeRoute,
        headers,
        routeParams,
        queryParameters,
        body,
        encoding,
        expectedMimeType,
      ];
}
