// SPDX-FileCopyrightText: 2025 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_abstract_manager/act_abstract_manager.dart';
import 'package:act_http_logging_manager/act_http_logging_manager.dart';
import 'package:shelf/shelf.dart' show Request, Response;

/// This is the abstract class for a server handler
///
/// The derived classes are called at the root of the server routes before any other routes.
abstract class AbsServerHandler extends AbsWithLifeCycle {
  /// This is the http logging manager
  final HttpLoggingManager _httpLoggingManager;

  /// Getter of the [_httpLoggingManager]
  HttpLoggingManager get httpLoggingManager => _httpLoggingManager;

  /// Class constructor
  const AbsServerHandler({required HttpLoggingManager httpLoggingManager})
    : _httpLoggingManager = httpLoggingManager;

  /// {@template act_http_server_manager.AbsServerHandler.beforeHandler}
  /// This method is called before the route handler.
  ///
  /// If the `forceResponse` parameter is not null, we don't go further and directly sent this
  /// response. The method [afterHandler] won't be called.
  ///
  /// If the `overrideRequest` is not null, it means that we have updated the request and this is
  /// the object to use in all the next handler call.
  /// {@endtemplate}
  Future<({Response? forceResponse, Request? overrideRequest})> beforeHandler({
    required Request request,
  }) async => (forceResponse: null, overrideRequest: null);

  /// {@template act_http_server_manager.AbsServerHandler.afterHandler}
  /// This method is called after the route handler and [response] is the response received from the
  /// handler.
  ///
  /// This method is not called if one server handler has answered in the `forceResponse` before
  /// the call of the route handler.
  ///
  /// You may update the [response] by returning an updated one.
  /// {@endtemplate}
  Future<Response> afterHandler({required Request request, required Response response}) async =>
      response;
}
