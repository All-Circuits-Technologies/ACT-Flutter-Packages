// SPDX-FileCopyrightText: 2023 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_halo_abstract/src/models/halo_payload_packet.dart';
import 'package:act_halo_abstract/src/models/halo_request_id.dart';
import 'package:act_halo_abstract/src/types/halo_error_type.dart';
import 'package:equatable/equatable.dart';

/// This class represents the result of a request
class HaloRequestResult extends Equatable {
  /// This is the id of a request
  final HaloRequestId requestId;

  /// The number of values expected in the result
  final int nbValues;

  /// The result of the request (or null if a problem occurred or if the method doesn't return a
  /// result)
  final HaloPayloadPacket? result;

  /// The [error] linked to the request result
  final HaloErrorType error;

  /// The class constructor
  const HaloRequestResult({
    required this.requestId,
    required this.result,
    required this.error,
    this.nbValues = 0,
  });

  /// An easy constructor when you want to create an error result
  const HaloRequestResult.error({
    required this.requestId,
    required this.error,
  })  : result = null,
        nbValues = 0;

  @override
  List<Object?> get props => [requestId, result, error, nbValues];
}
