// SPDX-FileCopyrightText: 2023 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_halo_abstract/src/models/halo_payload_packet.dart';
import 'package:act_halo_abstract/src/models/halo_record_key.dart';
import 'package:equatable/equatable.dart';

/// Defines the packet which contains data linked to the record data
class HaloRecordPacket extends Equatable {
  final HaloRecordKey recordKey;
  final HaloPayloadPacket payload;

  /// Class constructor
  const HaloRecordPacket({
    required this.recordKey,
    required this.payload,
  }) : super();

  @override
  List<Object?> get props => [recordKey, payload];
}
