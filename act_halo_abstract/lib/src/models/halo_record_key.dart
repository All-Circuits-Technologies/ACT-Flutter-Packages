// SPDX-FileCopyrightText: 2023 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_dart_utility/act_dart_utility.dart';
import 'package:act_halo_abstract/src/models/halo_data_id.dart';
import 'package:equatable/equatable.dart';

/// Defines the key for the HALO record data exchanged between the client and the device
class HaloRecordKey<T> extends Equatable {
  /// This unique index is never used by record key and when it's given, it signifies ALL the record
  /// data for a particular data id
  static const getAllUniqueIndex = 0x00;

  /// The data id linked to this record
  final HaloDataId<T> dataId;

  /// The unique index attached to the [HaloRecordKey]
  final int uniqueIndex;

  /// Class constructor
  const HaloRecordKey({
    required this.dataId,
    required this.uniqueIndex,
  }) : assert(
            0 <= uniqueIndex && uniqueIndex <= ByteUtility.maxUInt8,
            "The expected format of the unique index is an UInt8, the value given overflows the "
            "min and max: $uniqueIndex");

  /// Defines a [HaloRecordKey] to get them all
  const HaloRecordKey.getAll({
    required this.dataId,
  }) : uniqueIndex = getAllUniqueIndex;

  @override
  List<Object?> get props => [dataId, uniqueIndex];
}
