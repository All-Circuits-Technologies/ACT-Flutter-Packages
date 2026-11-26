// SPDX-FileCopyrightText: 2025 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_dart_utility/act_dart_utility.dart';
import 'package:act_global_manager/act_global_manager.dart';
import 'package:act_http_core/act_http_core.dart';
import 'package:equatable/equatable.dart';
import 'package:shelf/shelf.dart';

/// This class is used to identify a listening http route
class HttpRouteListeningId extends Equatable {
  /// This is the character used to identify the start of an id key in a path segment
  static const idKeyInPathStartChar = "<";

  /// This is the character used to identify the end of an id key in a path segment
  static const idKeyInPathEndChar = ">";

  /// Used when the method is unknown
  static const unknownMethod = "UNKNOWN";

  /// This is the method
  final HttpMethods? method;

  /// This is the path segments of the route
  final List<String> pathSegments;

  /// Class constructor
  const HttpRouteListeningId._({required this.method, required this.pathSegments});

  /// Creates a new [HttpRouteListeningId] from the given [method] and [relativeRoute]
  factory HttpRouteListeningId.fromRouteListening({
    required HttpMethods method,
    required String relativeRoute,
  }) {
    final pathSegments = StringListUtility.trim(relativeRoute.split(UriUtility.pathSeparator));

    return HttpRouteListeningId._(method: method, pathSegments: pathSegments);
  }

  /// Creates a new [HttpRouteListeningId] from the given [request]
  factory HttpRouteListeningId.fromRequest({required Request request}) {
    final parsedMethod = HttpMethods.parseFromValue(request.method);
    if (parsedMethod == null) {
      appLogger().w("The request method: ${request.method} isn't known, we can't parse it");
    }
    final pathSegments = StringListUtility.trim(request.url.pathSegments);

    return HttpRouteListeningId._(method: parsedMethod, pathSegments: pathSegments);
  }

  /// Test if the current path segments are the same as the [otherPathSegments] given
  ///
  /// If one path has an id key and the other not, we consider the paths as identical.
  /// For instance: `/api/item/<itemId>` and `/api/item/123` are considered identical
  bool isSamePathSegments(List<String> otherPathSegments) {
    final currLength = pathSegments.length;
    if (otherPathSegments.length != currLength) {
      return false;
    }

    for (var idx = 0; idx < currLength; ++idx) {
      final elem = pathSegments[idx];
      final otherElem = otherPathSegments[idx];

      if (_testIfPathSegmentIsAnIdKey(elem) || _testIfPathSegmentIsAnIdKey(otherElem)) {
        // We don't test further: one path as an id key
        continue;
      }

      if (elem != otherElem) {
        // The element is different; therefore, the paths are not identical
        return false;
      }
    }

    return true;
  }

  /// Test if the given [pathSegment] is an id key
  static bool _testIfPathSegmentIsAnIdKey(String pathSegment) {
    final length = pathSegment.length;
    if (length < 2) {
      return false;
    }

    return pathSegment[0] == idKeyInPathStartChar && pathSegment[length - 1] == idKeyInPathEndChar;
  }

  /// Model properties
  @override
  List<Object?> get props => [method, ...pathSegments];
}
