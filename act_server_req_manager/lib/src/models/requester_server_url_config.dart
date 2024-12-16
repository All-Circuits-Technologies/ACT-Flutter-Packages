// SPDX-FileCopyrightText: 2023 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:equatable/equatable.dart';

/// The definition of the first server URL part
class RequesterServerUrlConfig extends Equatable {
  /// True, if the URLs have to use SSL
  final bool isUsingSsl;

  /// The server hostname
  final String hostname;

  /// The server port, if needed
  final int? port;

  /// Sometimes, all the requests done to the server have the same URL path base, for instance :
  /// http://test.com/v1/ (here the base path for all the URL is "/v1")
  /// The [baseUrl] is useful to set that
  final String? baseUrl;

  /// Class constructor
  const RequesterServerUrlConfig({
    required this.isUsingSsl,
    required this.hostname,
    this.port,
    this.baseUrl,
  });

  @override
  List<Object?> get props => [isUsingSsl, hostname, port, baseUrl];
}
