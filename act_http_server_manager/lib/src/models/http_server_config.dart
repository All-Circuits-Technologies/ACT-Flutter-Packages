// SPDX-FileCopyrightText: 2025 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_dart_utility/act_dart_utility.dart';
import 'package:equatable/equatable.dart';

/// This class is used to configure a http server
class HttpServerConfig extends Equatable {
  /// This is the name of the server used to identify it
  final String serverName;

  /// This is the hostname of the HTTP server
  final String hostname;

  /// This is the ports range of the HTTP server
  ///
  /// If the server is not able to bind to the first port in the range, it will try the next one
  /// until it finds a free port or reaches the end of the range.
  final NumBoundaries<int> portsRange;

  /// This is the base path of all the routes in the server
  final String? basePath;

  /// Class constructor
  const HttpServerConfig({
    required this.serverName,
    required this.hostname,
    required this.portsRange,
    this.basePath,
  });

  /// Class properties
  @override
  List<Object?> get props => [serverName, hostname, portsRange, basePath];
}
