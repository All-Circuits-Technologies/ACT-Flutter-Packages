// SPDX-FileCopyrightText: 2026 Dorian Benech <dorian.benech@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_http_client_manager/act_http_client_manager.dart';
import 'package:equatable/equatable.dart';
import 'package:thingsboard_client/thingsboard_client.dart';

/// One answer of Thingsboard to a claim, before the application decides what it means.
///
/// [response] is null whenever the call did not reach the claim logic at all: a transport failure,
/// a session which is over, or an answer which carries no claim answer. [httpStatus] then carries
/// the status Thingsboard answered with, when there was one, and [deviceId] the device Thingsboard
/// says it bound, which only a successful claim carries.
class TbClaimAttempt extends Equatable {
  /// The result of the request to the server
  final RequestStatus status;

  /// The HTTP status the server answered with, if it answered at all
  final int? httpStatus;

  /// What the server answered to the claim, if it answered anything which can be read
  final ClaimResponse? response;

  /// The device the server says it bound, which only a successful claim carries
  final String? deviceId;

  /// Class constructor
  const TbClaimAttempt({
    required this.status,
    this.httpStatus,
    this.response,
    this.deviceId,
  });

  /// Class properties
  @override
  List<Object?> get props => [status, httpStatus, response, deviceId];
}
