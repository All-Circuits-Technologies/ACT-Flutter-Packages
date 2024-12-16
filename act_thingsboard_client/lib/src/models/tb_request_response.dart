// SPDX-FileCopyrightText: 2023 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_server_req_manager/act_server_req_manager.dart';
import 'package:equatable/equatable.dart';

/// This contains the response received by Thingsboard but also a global request result guessed from
/// context
class TbRequestResponse<T> extends Equatable {
  /// The result of the response
  final RequestResult result;

  /// The Thingsboard request response
  final T? requestResponse;

  /// True if the [result] is equal to [RequestResult.success]
  bool get isOk => result.isOk;

  /// Class constructor
  const TbRequestResponse({required this.result, this.requestResponse});

  /// Export the class member to patterns
  (RequestResult, T?) toPatterns() => (result, requestResponse);

  @override
  List<Object?> get props => [result, requestResponse];
}
