// SPDX-FileCopyrightText: 2025 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_http_core/act_http_core.dart';
import 'package:act_http_server_manager/src/models/http_request_log.dart';
import 'package:act_http_server_manager/src/services/handlers/abs_server_handler.dart';
import 'package:act_http_server_manager/src/services/handlers/request_id_server_handler.dart';
import 'package:act_jwt_utilities/act_jwt_utilities.dart';
import 'package:act_logger_manager/act_logger_manager.dart';
import 'package:shelf/shelf.dart' show Request, Response;

/// This server handler is used to verify if a JWT is present in the header and if it's valid
///
/// This handler expects that a [RequestIdServerHandler] is present before.
class VerifyJwtAuthServerHandler extends AbsServerHandler {
  /// This is the key used in the request context to store the extracted jwt
  static const jwtContext = "jwt";

  /// This is the header key where to find the JWT
  final String headerKey;

  /// This is the bearer label expected in the auth value
  final String expectedBearerLabel;

  /// Instance of the JWT handler to use to verify the token
  final AbstractJwtHandler jwtHandler;

  /// Class constructor
  const VerifyJwtAuthServerHandler({
    required super.httpLoggingManager,
    required this.jwtHandler,
    this.headerKey = HeaderConstants.authorizationHeaderKey,
    this.expectedBearerLabel = HeaderConstants.authBearerKey,
  });

  /// {@macro act_http_server_manager.AbsServerHandler.beforeHandler}
  @override
  Future<({Response? forceResponse, Request? overrideRequest})> beforeHandler({
    required Request request,
  }) async {
    final requestId = RequestIdServerHandler.tryToExtractRequestIdWithDefaultValue(request);

    final authenticationValue = request.headers[headerKey];
    if (authenticationValue == null) {
      httpLoggingManager.addLog(
        HttpRequestLog.requestNow(
          requestId: requestId,
          request: request,
          logLevel: Level.trace,
          message: "The request received doesn't contain the expected authentication header",
        ),
      );
      return (forceResponse: Response.unauthorized(null), overrideRequest: null);
    }

    final tokenValue = JwtParserUtility.extractJwtFromHeaderValue(
      headerValue: authenticationValue,
      bearerKey: expectedBearerLabel,
    );
    if (tokenValue == null) {
      httpLoggingManager.addLog(
        HttpRequestLog.requestNow(
          requestId: requestId,
          request: request,
          logLevel: Level.trace,
          message:
              "The authentication header doesn't contain the bearer info or the value "
              "isn't well formatted",
        ),
      );
      return (forceResponse: Response.unauthorized(null), overrideRequest: null);
    }

    final token = await jwtHandler.verify(token: tokenValue);
    if (token == null) {
      httpLoggingManager.addLog(
        HttpRequestLog.requestNow(
          requestId: requestId,
          request: request,
          logLevel: Level.trace,
          message: "The token isn't valid",
        ),
      );
      return (forceResponse: Response.unauthorized(null), overrideRequest: null);
    }

    final context = Map<String, Object>.from(request.context);
    context[jwtContext] = token;

    final newReq = request.change(context: context);
    return (forceResponse: null, overrideRequest: newReq);
  }

  /// {@macro act_http_server_manager.AbsServerHandler.afterHandler}
  @override
  Future<Response> afterHandler({required Request request, required Response response}) async =>
      response;

  /// Extract the JWT from the request context
  static JWT extractJwt(Request request) => request.context[jwtContext]! as JWT;

  /// Try to extract the JWT from the request context
  static JWT? tryToExtractJwt(Request request) {
    final jwt = request.context[jwtContext];
    if (jwt == null || jwt is! JWT) {
      return null;
    }

    return jwt;
  }
}
