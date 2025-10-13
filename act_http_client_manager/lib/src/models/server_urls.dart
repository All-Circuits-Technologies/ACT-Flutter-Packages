// SPDX-FileCopyrightText: 2023 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:equatable/equatable.dart';

/// Contains the base of the URL to use depending of the request to execute
class ServerUrls extends Equatable {
  /// The default URL base for all the requests
  final Uri defaultUrl;

  /// Contains the URL bases to use for specific request
  /// The map key is the request relative route
  final Map<String, Uri> byRelRoute;

  /// Class constructor
  const ServerUrls({
    required this.defaultUrl,
    required this.byRelRoute,
  });

  @override
  List<Object?> get props => [defaultUrl, byRelRoute];
}
