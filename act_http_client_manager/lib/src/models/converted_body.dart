// SPDX-FileCopyrightText: 2023 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_http_core/act_http_core.dart';
import 'package:equatable/equatable.dart';

/// Contains the request body which can be used by the external http lib
class ConvertedBody extends Equatable {
  /// The converted body and usable by the external http lib
  final Object? body;

  /// The [HttpMimeTypes] of the body
  final HttpMimeTypes contentType;

  /// Default class constructor
  const ConvertedBody({
    required this.body,
    required this.contentType,
  });

  @override
  List<Object?> get props => [body, contentType];
}
