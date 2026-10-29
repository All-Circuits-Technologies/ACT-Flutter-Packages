// SPDX-FileCopyrightText: 2023 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_dart_result/act_dart_result.dart';
import 'package:act_halo_abstract/src/mixins/mixin_halo_request_id.dart';
import 'package:act_halo_abstract/src/models/halo_payload_packet.dart';
import 'package:act_halo_abstract/src/types/halo_error_type.dart';

/// This class represents the result of a request
///
/// The inherited [status] is the error linked to the request result, and the inherited [value] is
/// the result of the request (or null if a problem occurred or if the method doesn't return a
/// result)
class HaloRequestResult extends ResultWithStatus<HaloErrorType, HaloPayloadPacket> {
  /// This is the id of a request
  final MixinHaloRequestId requestId;

  /// The number of values expected in the result
  final int nbValues;

  /// The class constructor
  const HaloRequestResult({
    required this.requestId,
    required super.status,
    super.value,
    super.extraInfo,
    this.nbValues = 0,
  });

  /// An easy constructor when you want to create an error result
  const HaloRequestResult.error({
    required this.requestId,
    required super.status,
  }) : nbValues = 0;

  @override
  List<Object?> get props => [...super.props, requestId, nbValues];
}
