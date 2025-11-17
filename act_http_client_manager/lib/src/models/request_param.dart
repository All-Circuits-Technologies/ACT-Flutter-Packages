// SPDX-FileCopyrightText: 2023 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'dart:convert';

import 'package:act_http_core/act_http_core.dart';
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

  /// The MIME type of the request
  ///
  /// If null, we try to guess the MIM type
  final HttpMimeTypes? requestMimeType;

  /// The expected MIME type of the request response (in case the request is a success)
  final HttpMimeTypes? expectedMimeType;

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
    this.requestMimeType,
    this.expectedMimeType,
  }) : headers = headers ?? <String, String>{};

  /// Creates a copy of this [RequestParam] with the given parameters.
  RequestParam copyWith({
    HttpMethods? httpMethod,
    String? relativeRoute,
    Map<String, String>? headers,
    Map<String, String>? routeParams,
    bool forceRouteParams = false,
    Map<String, dynamic>? queryParameters,
    bool forceQueryParameters = false,
    // We want to explicitly write the dynamic type here
    // ignore: avoid_annotating_with_dynamic
    dynamic body,
    bool forceBody = false,
    Encoding? encoding,
    bool forceEncoding = false,
    Duration? timeout,
    bool forceTimeout = false,
    HttpMimeTypes? requestMimeType,
    bool forceRequestMimeType = false,
    HttpMimeTypes? expectedMimeType,
    bool forceExpectedMimeType = false,
  }) =>
      RequestParam(
        httpMethod: httpMethod ?? this.httpMethod,
        relativeRoute: relativeRoute ?? this.relativeRoute,
        headers: headers ?? this.headers,
        routeParams: routeParams ?? (forceRouteParams ? null : this.routeParams),
        queryParameters: queryParameters ?? (forceQueryParameters ? null : this.queryParameters),
        body: body ?? (forceBody ? null : this.body),
        encoding: encoding ?? (forceEncoding ? null : this.encoding),
        timeout: timeout ?? (forceTimeout ? null : this.timeout),
        requestMimeType: requestMimeType ?? (forceRequestMimeType ? null : this.requestMimeType),
        expectedMimeType:
            expectedMimeType ?? (forceExpectedMimeType ? null : this.expectedMimeType),
      );

  @override
  List<Object?> get props => [
        httpMethod,
        relativeRoute,
        headers,
        routeParams,
        queryParameters,
        body,
        encoding,
        requestMimeType,
        expectedMimeType,
      ];
}
