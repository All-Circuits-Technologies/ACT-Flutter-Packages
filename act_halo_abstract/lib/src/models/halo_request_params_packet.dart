// SPDX-FileCopyrightText: 2023 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_halo_abstract/src/halo_constants.dart' as halo_constants;
import 'package:act_halo_abstract/src/models/halo_payload_packet.dart';
import 'package:act_halo_abstract/src/models/halo_request_id.dart';
import 'package:equatable/equatable.dart';

/// This class represents the parameters of a request
class HaloRequestParamsPacket extends Equatable {
  /// This is the id of a request
  final HaloRequestId requestId;

  /// The length of the list represents the request number of parameters
  /// Each element of the list represents the number of values for each parameter; most of the time
  /// the value will be equal to 1, but it can be more if the parameter is a list, or equals to 0 if
  /// the parameter has a default value and the caller doesn't give the value (and so have chosen
  /// to use the default value)
  final List<int> nbValues;

  /// The parameters of the request
  final HaloPayloadPacket parameters;

  /// Class constructor
  const HaloRequestParamsPacket({
    required this.requestId,
    required this.nbValues,
    required this.parameters,
  }) : assert(
            nbValues.length <= halo_constants.maxRequestParameterNumber,
            "The protocol standard defined that the request can't have more than: "
            "${halo_constants.maxRequestParameterNumber} parameters");

  /// This is a shortcut to create a void parameters object
  HaloRequestParamsPacket.voidParams({
    required this.requestId,
  })  : nbValues = [],
        parameters = HaloPayloadPacket();

  @override
  List<Object?> get props => [requestId, nbValues, parameters];
}
