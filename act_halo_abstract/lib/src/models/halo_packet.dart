// SPDX-FileCopyrightText: 2023 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_halo_abstract/src/models/halo_data_id.dart';
import 'package:act_halo_abstract/src/models/halo_payload_packet.dart';
import 'package:equatable/equatable.dart';

/// This defines a HALO packet, with a [HaloDataId] and a [HaloPayloadPacket]
class HaloPacket extends Equatable {
  final HaloDataId dataId;
  final HaloPayloadPacket payload;

  /// Class constructor
  const HaloPacket({
    required this.dataId,
    required this.payload,
  }) : super();

  @override
  List<Object?> get props => [dataId, payload];
}
