// SPDX-FileCopyrightText: 2026 Dorian Benech <dorian.benech@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_http_client_manager/act_http_client_manager.dart';
import 'package:act_thingsboard_client/src/types/tb_claim_outcome.dart';
import 'package:equatable/equatable.dart';
import 'package:thingsboard_client/thingsboard_client.dart';

/// One answer of Thingsboard to a claim, before the application decides what it means.
///
/// [response] is null whenever the call did not reach the claim logic at all: a transport failure,
/// a session which is over, or an answer which carries no claim answer. [httpStatus] then carries
/// the status Thingsboard answered with, when there was one, and [deviceId] the device Thingsboard
/// says it bound, which only a successful claim carries.
class TbClaimAttempt extends Equatable {
  /// The Thingsboard HTTP status for a device name it does not know
  static const _notFoundHttpStatus = 404;

  /// The Thingsboard HTTP status for a claim it refuses
  static const _badRequestHttpStatus = 400;

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

  /// What this answer amounts to, which is what the application acts on.
  ///
  /// The whole decision table lives here, because it cannot be reached through a real server in a
  /// unit test.
  TbClaimOutcome get outcome {
    if (status == RequestStatus.loginError) {
      return TbClaimOutcome.loginError;
    }

    switch (response) {
      case ClaimResponse.SUCCESS:
        return TbClaimOutcome.success;
      case ClaimResponse.CLAIMED:
        return TbClaimOutcome.alreadyClaimed;
      case ClaimResponse.FAILURE:
        return TbClaimOutcome.refused;
      case null:
        break;
    }

    // No readable claim answer: tell an unknown device apart from anything else, because that one
    // means the device was never created and no amount of retrying will help.
    if (httpStatus == _notFoundHttpStatus) {
      return TbClaimOutcome.unknownDevice;
    }

    if (httpStatus == _badRequestHttpStatus) {
      // Thingsboard answers 400 when the secret matches no claim the device is waiting for
      return TbClaimOutcome.secretRefused;
    }

    return TbClaimOutcome.communicationError;
  }

  /// Class properties
  @override
  List<Object?> get props => [status, httpStatus, response, deviceId];
}
