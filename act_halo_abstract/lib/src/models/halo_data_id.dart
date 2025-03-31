// SPDX-FileCopyrightText: 2023 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_dart_utility/act_dart_utility.dart';
import 'package:equatable/equatable.dart';

/// Defines the id for all the HALO data exchanged between the device and the client
class HaloDataId<T> extends Equatable {
  /// This is the [value] of the halo data id
  final T value;

  /// This is the id exchanged with the firmware
  final int id;

  /// Class constructor
  ///
  /// The [id] is an INT8
  const HaloDataId({
    required this.id,
    required this.value,
  }) : assert(
            0 <= id && id <= ByteUtility.maxUInt8,
            "The expected format of the id is an UInt8, the value given overflows the min and "
            "max: $id");

  @override
  List<Object?> get props => [value, id];
}

/// Defines the HALO data ID helper to list all the data ID managed
abstract class AbstractHaloDataIdHelper<T> {
  /// This is the [dataIds] linked to the value
  final Map<T, HaloDataId<T>> dataIds;

  /// Class constructor
  AbstractHaloDataIdHelper({
    required this.dataIds,
  });
}
