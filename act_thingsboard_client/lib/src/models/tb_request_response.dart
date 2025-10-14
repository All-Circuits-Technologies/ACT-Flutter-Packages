// SPDX-FileCopyrightText: 2023 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_http_client_manager/act_http_client_manager.dart';
import 'package:equatable/equatable.dart';

/// This contains the response received by Thingsboard but also a global request result guessed from
/// context
class TbRequestResponse<T> extends Equatable {
  /// The result of the response
  final RequestStatus status;

  /// The Thingsboard request response
  final T? requestResponse;

  /// True if the [status] is equal to [RequestStatus.success]
  bool get isOk => status.isOk;

  /// Class constructor
  const TbRequestResponse({required this.status, this.requestResponse});

  /// Export the class member to patterns
  (RequestStatus, T?) toPatterns() => (status, requestResponse);

  /// Class properties
  @override
  List<Object?> get props => [status, requestResponse];
}
