// Copyright (c) 2020. BMS Circuits

import 'package:act_abstract_manager/act_abstract_manager.dart';
import 'package:flutter/foundation.dart';

/// Builder for creating the AbstractConstantsManager
abstract class AbstractConstantsBuilder<T extends AbstractConstantsManager>
    extends ManagerBuilder<T> {
  /// Class constructor with the class construction
  AbstractConstantsBuilder({
    ClassFactory<T> factory,
  }) : super(factory);

  /// List of manager dependence
  @override
  Iterable<Type> dependsOn() => [];
}

abstract class AbstractConstantsManager<T> extends AbstractManager {
  /// Max device number by page returned by server request
  static const int maxDeviceNumberByPage = 10;

  /// The web socket auto reconnect minimal interval
  static const Duration webSocketAutoReconnectMinInterval =
      Duration(milliseconds: 250);

  /// The web socket auto reconnect maximal interval
  static const Duration webSocketAutoReconnectMaxInterval =
      Duration(seconds: 15);

  /// The web socket ping interval
  static const Duration webSocketPingIntervalDuration = Duration(seconds: 5);

  /// The web socket parameter in uri for token
  static const String webSocketTokenParam = "token";

  /// The web socket relative URI
  static const String webSocketRelativeUri = "/api/ws/plugins/telemetry";

  /// The body json key to extract the error code
  static const String serverErrorCodeKey = "errorCode";

  /// Error code when the authentication failed (because credentials aren't
  /// correct) returned by the server
  static const int serverLoggingErrorCode = 10;

  final String fqdnHttp;
  final int portHttps;
  final String webSocketTlsScheme;

  /// HTTP server address getter
  String get serverAddress => fqdnHttp + ":" + portHttps.toString();

  AbstractConstantsManager({
    @required this.fqdnHttp,
    @required this.portHttps,
    @required this.webSocketTlsScheme,
  })  : assert(fqdnHttp != null),
        assert(portHttps != null),
        assert(webSocketTlsScheme != null),
        super();
}
