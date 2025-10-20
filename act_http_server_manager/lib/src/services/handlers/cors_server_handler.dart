// SPDX-FileCopyrightText: 2025 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_http_core/act_http_core.dart';
import 'package:act_http_server_manager/src/models/http_route_listening_id.dart';
import 'package:act_http_server_manager/src/services/abs_api_service.dart';
import 'package:act_http_server_manager/src/services/handlers/abs_server_handler.dart';
import 'package:shelf/shelf.dart' show Request, Response;

/// This is the server handler used to manage CORS (cross origin resource sharing) on the server
class CorsServerHandler extends AbsServerHandler {
  /// This is the separator to use between the values of access control allows elements
  static const _allowValuesSeparator = ", ";

  /// This is the default value to accept all origin on the server
  static const allowOriginAll = "*";

  /// This is the default value to accept all the methods on the server
  static final allowMethodsAll = HttpMethods.values
      .map((method) => method.stringValue)
      .join(_allowValuesSeparator);

  /// This is the default value to accept some generic headers
  static final allowsGenericHeaders = [
    HeaderConstants.originHeaderKey,
    HeaderConstants.xRequestedWithHeaderKey,
    HeaderConstants.contentTypeHeaderKey,
    HeaderConstants.acceptHeaderKey,
    HeaderConstants.authorizationHeaderKey,
  ].join(_allowValuesSeparator);

  /// This is the list of all the API services registered in the server
  final List<AbsApiService> _apiServices;

  /// This is the list of all the routes listened in the server
  ///
  /// If null, this means that we don't have retrieved the routes yet.
  List<HttpRouteListeningId>? _allListeningRoutes;

  /// This is the value of the access control allow origin
  final String accessControlAllowOriginValue;

  /// This is the value of the access control allows methods
  final String accessControlAllowMethodsValue;

  /// This is the value of the access control allow headers
  final String accessControlAllowHeadersValue;

  /// This is the list of all the routes listened in the server
  List<HttpRouteListeningId> get _listeningRoutes {
    if (_allListeningRoutes != null) {
      return _allListeningRoutes!;
    }

    _allListeningRoutes = _apiServices
        .expand((service) => service.registeredRoutes)
        .toList(growable: false);
    return _allListeningRoutes!;
  }

  /// Class constructor
  CorsServerHandler({
    required super.httpLoggingManager,
    required List<AbsApiService> apiServices,
    this.accessControlAllowOriginValue = allowOriginAll,
    String? accessControlAllowMethodsValue,
    String? accessControlAllowHeadersValue,
  }) : _apiServices = apiServices,
       accessControlAllowMethodsValue = accessControlAllowMethodsValue ?? allowMethodsAll,
       accessControlAllowHeadersValue = accessControlAllowHeadersValue ?? allowsGenericHeaders;

  /// {@macro act_http_server_manager.AbsServerHandler.beforeHandler}
  @override
  Future<({Response? forceResponse, Request? overrideRequest})> beforeHandler({
    required Request request,
  }) async {
    final requestMethod = request.method.toUpperCase();
    if (requestMethod != HttpMethods.options.stringValue) {
      // Nothing to do
      return (forceResponse: null, overrideRequest: null);
    }

    final httpRouteListening = HttpRouteListeningId.fromRequest(request: request);
    var routeFoundAndNotManaged = false;
    for (final route in _listeningRoutes) {
      if (!route.isSamePathSegments(httpRouteListening.pathSegments)) {
        // Nothing more to do
        continue;
      }

      if (route.method == HttpMethods.options) {
        // The path is already managed by an API service, we don't do anything else
        routeFoundAndNotManaged = false;
        break;
      }

      // The route is managed by the server; therefore, the client has requested the server with
      // an OPTIONS request to get the CORS info
      //
      // We don't return here, because an OPTIONS request on the same route may exist.
      routeFoundAndNotManaged = true;
    }

    if (routeFoundAndNotManaged) {
      return (forceResponse: _addCorsHeaders(Response.ok(null)), overrideRequest: null);
    }

    return (forceResponse: null, overrideRequest: null);
  }

  /// {@macro act_http_server_manager.AbsServerHandler.afterHandler}
  @override
  Future<Response> afterHandler({required Request request, required Response response}) async =>
      _addCorsHeaders(response);

  /// This method adds the CORS headers to the response given
  Response _addCorsHeaders(Response response) {
    final tmpHeaders = Map<String, String>.from(response.headers);
    tmpHeaders[HeaderConstants.accessControlAllowOriginHeaderKey] = accessControlAllowOriginValue;
    tmpHeaders[HeaderConstants.accessControlAllowMethodsHeaderKey] = accessControlAllowMethodsValue;
    tmpHeaders[HeaderConstants.accessControlAllowHeadersHeaderKey] = accessControlAllowHeadersValue;
    return response.change(headers: tmpHeaders);
  }
}
