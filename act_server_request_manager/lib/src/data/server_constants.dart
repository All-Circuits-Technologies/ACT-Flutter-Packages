// Copyright (c) 2020. BMS Circuits

import 'dart:io';

import 'package:act_server_request_manager/src/request_result.dart';
import 'package:tuple/tuple.dart';

/// Callback for getting the current token
typedef Future<String> GetXAuthHeaderAsync();

typedef Future<Tuple2<RequestResult, String>> RefreshXAuthHeaderAsync();

abstract class ServerConstants {
  /// Header to add in request for passing the server request
  static const String xAuthorizationHttpHeader = "X-Authorization";

  /// This has to be prepend to the server token, in order to request the server
  static const String tokenPrefix = "Bearer ";

  /// Used to define the type of request and response body to json
  static const String applicationJsonValue = "application/json";

  /// Subject of the self signed certificate created by AC Tech
  static const String certificateSelfSignedName =
      "/C=FR/ST=49/L=Angers/O=BMS Circuits"
      "/OU=AC Technologies/CN=gttest.acangers.net.selfsigned.invalid"
      "/emailAddress=monitoring@acangers.net";

  /// Separator character for each kind of header
  static const Map<String, String> headerSeparator = {
    HttpHeaders.contentTypeHeader: ";",
    HttpHeaders.acceptHeader: ",",
  };

  /// Default header separator if the header is not known
  static const String defaultHeaderSeparator = ',';

  /// Default header values for all request
  static const Map<String, String> defaultHeaders = {
    HttpHeaders.contentTypeHeader: applicationJsonValue,
    HttpHeaders.acceptHeader: applicationJsonValue,
  };

  /// Duration connection timeout for request
  static const Duration connectionTimeout = Duration(minutes: 3);

  /// Request sending max try number
  static const int maxTryNumberBeforeError = 2;

  /// Time to wait before repeating the request
  static const Duration timeToWaitBeforeRetryingInMs = Duration(
    milliseconds: 3000,
  );

  /// The OS exception error code for the failed host lookup
  static const int WsNetworkFailedHostLookup = 7;

  /// The OS exception error code for the Network unreachable error
  static const int WsNetworkUnreachableOsErrorCode = 101;

  /// The OS exception error code for the connection timeout error
  static const int WsNetworkConnectionTimeoutOsErrorCode = 110;

  /// The OS exception error code for the connection refused error (happens when
  /// the OS refuses that app communicates, for instance: no connection when
  /// the app is in background)
  static const int WsNetworkConnectionConnRefusedErrorCode = 111;
}
