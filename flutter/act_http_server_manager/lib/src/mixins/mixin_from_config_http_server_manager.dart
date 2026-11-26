// SPDX-FileCopyrightText: 2025 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_http_logging_manager/act_http_logging_manager.dart';
import 'package:act_http_server_manager/act_http_server_manager.dart';
import 'package:flutter/foundation.dart';

/// This mixin can be used to get the server config from a config manager
mixin MixinFromConfigHttpServerManager on AbsHttpServerManager {
  /// {@template act_http_server_manager.MixinFromConfigHttpServerManager.configGetter}
  /// This is the getter of the config manager
  /// {@endtemplate}
  @protected
  MixinHttpServerConfig Function() get configGetter;

  /// {@macro act_http_server_manager.HttpServerManager.getServerConfig}
  @override
  Future<HttpServerConfig> getServerConfig({required HttpLoggingManager httpLoggingManager}) async {
    final configManager = configGetter();
    return HttpServerConfig(
      serverName: configManager.httpServerName.load(),
      hostname: configManager.httpServerHostname.load(),
      port: configManager.httpServerPort.load(),
      basePath: configManager.httpServerBasePath.load(),
    );
  }
}
