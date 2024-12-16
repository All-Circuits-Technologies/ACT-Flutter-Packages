// Copyright (c) 2020. BMS Circuits

import 'dart:io';

import 'package:act_server_request_manager/src/data/server_constants.dart';

/// This class allows to redefine the [HttpOverrides] class for all the network
/// message (web socket and REST api)
class HttpOverridesSelfSigned extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext context) {
    var httpClient = super.createHttpClient(context);

    httpClient.badCertificateCallback = _badCertificateCallback;

    return httpClient;
  }

  /// Called to validate self signed certificate only the AC Tech self signed
  /// certificate are allowed
  static bool _badCertificateCallback(
    X509Certificate cert,
    String host,
    int port,
  ) {
    return cert.subject == ServerConstants.certificateSelfSignedName;
  }
}
