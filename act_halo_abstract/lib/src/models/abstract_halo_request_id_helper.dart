// SPDX-FileCopyrightText: 2023 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_global_manager/act_global_manager.dart';
import 'package:act_halo_abstract/src/mixins/mixin_halo_request_id.dart';

/// Defines the HALO request ID helper to list all the request ID managed
abstract class AbstractHaloRequestIdHelper {
  /// The list of request ids managed by the app
  ///
  /// The key of the map is the [MixinHaloRequestId.uniqueId] and not [MixinHaloRequestId.rawValue].
  final Map<int, MixinHaloRequestId> requestIds;

  /// This contains the default execution timeout to use for each request. If no timeout is defined
  /// for a request, the [defaultRequestTimeout] will be used, if it's not set, the global default
  /// one will be used.
  ///
  /// The key of the map is the [MixinHaloRequestId.uniqueId] and not [MixinHaloRequestId.rawValue].
  final Map<int, Duration> overriddenExecutionTimeout;

  /// This contains the default execution timeout to use for all the requests. The
  /// [overriddenExecutionTimeout] overrides this value.
  ///
  /// If no timeout is defined for a request, the global default one will be used.
  final Duration? defaultRequestTimeout;

  /// Class constructor
  AbstractHaloRequestIdHelper({
    required this.requestIds,
    this.overriddenExecutionTimeout = const {},
    this.defaultRequestTimeout,
  });

  /// Helpful method to merge maps together
  /// The elements contained in the [toOverwriteWith] map have the supremacy over the
  /// [elementRequests] elements; nevertheless, it's not advised to overwrite ids because that
  /// means that you are losing methods.
  static Map<int, MixinHaloRequestId> mergeRequestElement({
    required Map<int, MixinHaloRequestId> elementRequests,
    required Map<int, MixinHaloRequestId> toOverwriteWith,
  }) {
    final requestIds = Map<int, MixinHaloRequestId>.from(elementRequests);

    for (final tmpRequest in toOverwriteWith.entries) {
      final uniqueId = tmpRequest.key;

      if (requestIds.containsKey(uniqueId)) {
        appLogger().w("A request already exists: ${requestIds[uniqueId]}, we overwrite it with: "
            "${tmpRequest.value}, the common key is: $uniqueId");
      }

      requestIds[uniqueId] = tmpRequest.value;
    }

    return requestIds;
  }
}
