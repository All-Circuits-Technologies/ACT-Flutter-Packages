// Copyright (c) 2020. BMS Circuits

import 'dart:io';

import 'package:act_server_request_manager/src/data/server_constants.dart';
import 'package:act_server_request_manager/src/x_auth_exception.dart';
import 'package:flutter/cupertino.dart';
import 'package:http/http.dart';
import 'package:http/io_client.dart';

/// HTTP query client service
class HttpQueryClient extends IOClient {
  final GetXAuthHeaderAsync getXAuth;
  final HttpClient _innerClient;
  final bool persistentConnection;

  /// Default factory constructor, to use when requests have no need of the
  /// server token
  ///
  /// [persistentConnection] is used for set the persistentConnection of
  /// requests
  factory HttpQueryClient({bool persistentConnection = false}) {
    return HttpQueryClient._(
      innerClient: _buildClient(),
      persistentConnection: persistentConnection,
    );
  }

  /// Factory constructor, to use for requests which need a X Authorisation
  /// element in header
  ///
  /// [persistentConnection] is used for set the persistentConnection of
  /// requests
  factory HttpQueryClient.withXAuth(
    GetXAuthHeaderAsync getXAuth, {
    bool persistentConnection = false,
  }) {
    assert(getXAuth != null);

    return HttpQueryClient._(
      getXAuth: getXAuth,
      innerClient: _buildClient(),
      persistentConnection: persistentConnection,
    );
  }

  /// Private constructor to build the [HttpQueryClient]
  HttpQueryClient._({
    this.getXAuth,
    @required HttpClient innerClient,
    this.persistentConnection,
  })  : assert(innerClient != null),
        _innerClient = innerClient,
        super(innerClient);

  /// This class allows to create a HttpClient with default data
  static HttpClient _buildClient() {
    HttpClient client = HttpClient();

    client.connectionTimeout = ServerConstants.connectionTimeout;

    return client;
  }

  /// Override the parent send method to add default headers and set, if needed,
  /// the token in headers
  @override
  Future<IOStreamedResponse> send(BaseRequest request) async {
    ServerConstants.defaultHeaders.forEach((String key, String value) {
      _concatHeaderValue(request.headers, key, value);
    });

    if (getXAuth != null) {
      var xAuth = await getXAuth();

      if (xAuth.isEmpty) {
        throw XAuthException();
      }

      request.headers[ServerConstants.xAuthorizationHttpHeader] = xAuth;
    }

    request.persistentConnection = persistentConnection;

    return super.send(request);
  }

  /// Get the right separator for the right element in request headers
  ///
  /// The [headerName] to get it's recommended separator, if the [headerName] is
  /// not known, use the default separator
  static String _getSeparator(String headerName) {
    var separator = ServerConstants.headerSeparator[headerName];

    if (separator == null) {
      separator = ServerConstants.defaultHeaderSeparator;
    }

    return separator;
  }

  /// This method is useful to add a value to the [headers] and respect the
  /// already existent values.
  ///
  /// It places the [valueToAdd] before all the existent values. If the
  /// [headerName] is not known, it will add the header.
  static void _concatHeaderValue(
    Map<String, String> headers,
    String headerName,
    String valueToAdd,
  ) {
    var tmpValue = headers[headerName] ?? "";

    if (tmpValue.isNotEmpty) {
      var separator = _getSeparator(headerName);

      tmpValue = separator + " " + tmpValue;
    }

    headers[headerName] = valueToAdd + tmpValue;
  }
}
