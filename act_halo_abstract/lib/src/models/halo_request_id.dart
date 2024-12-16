// SPDX-FileCopyrightText: 2023 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_dart_utility/act_dart_utility.dart';
import 'package:act_global_manager/act_global_manager.dart';
import 'package:act_halo_abstract/src/types/halo_request_type.dart';
import 'package:equatable/equatable.dart';

/// Defines the id of the HALO requests
class HaloRequestId extends Equatable {
  /// The id of the request
  final int id;

  /// The type of request
  final HaloRequestType type;

  /// Class constructor
  const HaloRequestId({
    required this.id,
    required this.type,
  }) : assert(
            0 <= id && id <= ByteUtility.maxUInt8,
            "The expected format of the id is an UInt8, the value given overflows the min and "
            "max: $id");

  @override
  List<Object?> get props => [id, type];
}

/// Defines the HALO request ID helper to list all the request ID managed
abstract class AbstractHaloRequestIdHelper {
  /// The list of request ids managed by the app
  final Map<int, HaloRequestId> requestIds;

  /// Class constructor
  AbstractHaloRequestIdHelper({
    required this.requestIds,
  });

  /// Helpful method to merge maps together
  /// The elements contained in the [toOverwriteWith] map have the supremacy over the
  /// [elementRequests] elements; nevertheless, it's not advised to overwrite ids because that
  /// means that you are losing methods.
  static Map<int, HaloRequestId> mergeRequestElement({
    required Map<int, HaloRequestId> elementRequests,
    required Map<int, HaloRequestId> toOverwriteWith,
  }) {
    final requestIds = Map<int, HaloRequestId>.from(elementRequests);

    for (final tmpRequest in toOverwriteWith.entries) {
      final hexValue = tmpRequest.key;

      if (requestIds.containsKey(hexValue)) {
        appLogger().w(
            "A request already exists: ${requestIds[hexValue]}, we overwrite it with: "
            "${tmpRequest.value}, the common key is: $hexValue");
      }

      requestIds[hexValue] = tmpRequest.value;
    }

    return requestIds;
  }
}
