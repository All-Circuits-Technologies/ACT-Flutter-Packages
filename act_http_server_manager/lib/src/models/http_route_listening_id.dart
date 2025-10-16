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
  /// Used when the method is unknown
  static const unknownMethod = "UNKNOWN";

  /// This is a unique key for this route listening
  final String uniqueKey;

  /// This is the method
  final HttpMethods? method;

  /// This is the path segments of the route
  final String route;

  /// Class constructor
  const HttpRouteListeningId._({
    required this.uniqueKey,
    required this.method,
    required this.route,
  });

  /// Creates a new [HttpRouteListeningId] from the given [method] and [relativeRoute]
  factory HttpRouteListeningId.fromRouteListening({
    required HttpMethods method,
    required String relativeRoute,
  }) {
    var route = relativeRoute;
    var offset = 0;
    final length = route.length;
    var end = length;
    if (route.startsWith(UriUtility.pathSeparator)) {
      offset = 1;
    }

    if (route.endsWith(UriUtility.pathSeparator)) {
      end -= 1;
    }

    route = route.substring(offset, end);

    return HttpRouteListeningId._(
      uniqueKey: _generateKey(method: method, route: route),
      method: method,
      route: route,
    );
  }

  /// Creates a new [HttpRouteListeningId] from the given [request]
  factory HttpRouteListeningId.fromRequest({required Request request}) {
    final parsedMethod = HttpMethods.parseFromValue(request.method);
    if (parsedMethod == null) {
      appLogger().w("The request method: ${request.method} isn't known, we can't parse it");
    }
    final pathSegments = StringListUtility.trim(request.url.pathSegments);
    final route = pathSegments.join(UriUtility.pathSeparator);

    return HttpRouteListeningId._(
      uniqueKey: _generateKey(method: parsedMethod, route: route),
      method: parsedMethod,
      route: route,
    );
  }

  /// Generate a unique key for this route listening
  static String _generateKey({required HttpMethods? method, required String route}) =>
      "${method?.stringValue ?? unknownMethod} - $route";

  /// Model properties
  @override
  List<Object?> get props => [uniqueKey];
}
