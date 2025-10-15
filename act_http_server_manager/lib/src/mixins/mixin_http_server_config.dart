// SPDX-FileCopyrightText: 2025 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_config_manager/act_config_manager.dart';

/// Extends the [AbstractConfigManager] to add config variables which will be used by the
/// HttpServerManager
mixin MixinHttpServerConfig on AbstractConfigManager {
  /// This is the name of the server used to identify it
  final httpServerName = const NotNullableConfigVar<String>(
    "http.server.name",
    defaultValue: "Http server",
  );

  /// This is the hostname to use when we create the HTTP server
  final httpServerHostname = const NotNullableConfigVar<String>(
    "http.server.hostname",
    defaultValue: "0.0.0.0",
  );

  /// This is the port to use when we create the HTTP server
  final httpServerPort = const NotNullableConfigVar<int>("http.server.port", defaultValue: 80);

  /// This is the base path to use for all the routes in the HTTP server
  final httpServerBasePath = const ConfigVar<String>("http.server.basePath");
}
