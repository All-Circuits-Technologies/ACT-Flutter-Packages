// SPDX-FileCopyrightText: 2023 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_logger_manager/act_logger_manager.dart';
import 'package:act_server_req_manager/src/models/requester_server_url_config.dart';
import 'package:equatable/equatable.dart';

/// Contains the config for initialize the requester
class RequesterConfig extends Equatable {
  /// True to enable the logger for this requester
  final bool loggerEnabled;

  /// The logger category of this requester
  final String loggerCategory;

  /// The parent logs helper if one is needed
  final LogsHelper? parentLogsHelper;

  /// The config of the requester server url, to use by default
  final RequesterServerUrlConfig defaultServerInfo;

  /// This contains specific URL config for particular relative path
  ///
  /// This can be useful, if the distant server is in microservices and the requests have different
  /// host url, port, etc.
  final Map<String, RequesterServerUrlConfig>? serverInfoByUrl;

  /// The default timeout for all the request done to the server
  final Duration defaultTimeout;

  /// Class constructor
  const RequesterConfig({
    required this.loggerEnabled,
    required this.loggerCategory,
    required this.defaultTimeout,
    this.parentLogsHelper,
    required this.defaultServerInfo,
    this.serverInfoByUrl,
  });

  @override
  List<Object?> get props => [
        loggerEnabled,
        loggerCategory,
        parentLogsHelper,
        defaultServerInfo,
        serverInfoByUrl,
      ];
}
