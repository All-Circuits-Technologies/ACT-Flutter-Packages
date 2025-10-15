// SPDX-FileCopyrightText: 2025 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_http_server_manager/src/models/http_request_log.dart';
import 'package:act_http_server_manager/src/services/handlers/abs_server_handler.dart';
import 'package:act_logger_manager/act_logger_manager.dart';
import 'package:flutter/foundation.dart';
import 'package:shelf/shelf.dart' show Request, Response;
import 'package:uuid/uuid.dart';

/// This is the server handler used to add request ID to the request on the server
class RequestIdServerHandler extends AbsServerHandler {
  /// This is the key used in the request context to store the request id
  static const requestIdContext = "requestId";

  /// Default value for request id when not found
  static const requestIdDefaultValue = "unknown";

  /// Class constructor
  const RequestIdServerHandler({required super.httpLoggingManager});

  /// {@macro act_http_server_manager.AbsServerHandler.beforeHandler}
  @override
  Future<({Response? forceResponse, Request? overrideRequest})> beforeHandler({
    required Request request,
  }) async {
    final requestId = shortHash(const Uuid().v1());
    httpLoggingManager.addLog(
      HttpRequestLog.requestNow(
        requestId: requestId,
        request: request,
        logLevel: Level.info,
        message: "Received request",
      ),
    );

    final context = Map<String, Object>.from(request.context);
    context[requestIdContext] = requestId;

    final newReq = request.change(context: context);
    return (forceResponse: null, overrideRequest: newReq);
  }

  /// {@macro act_http_server_manager.AbsServerHandler.afterHandler}
  @override
  Future<Response> afterHandler({required Request request, required Response response}) async {
    final requestId = extractRequestId(request);
    httpLoggingManager.addLog(
      HttpRequestLog.requestNow(
        requestId: requestId,
        request: request,
        logLevel: Level.info,
        message: "Responded with status code ${response.statusCode}",
      ),
    );
    return response;
  }

  /// Extract the request id from the request context
  static String extractRequestId(Request request) => request.context[requestIdContext]! as String;

  /// Try to extract the request id from the request context
  static String? tryToExtractRequestId(Request request) {
    final requestId = request.context[requestIdContext];
    if (requestId == null || requestId is! String) {
      return null;
    }

    return requestId;
  }

  /// Try to extract the request id from the request context and return a default value if not found
  static String tryToExtractRequestIdWithDefaultValue(Request request) =>
      tryToExtractRequestId(request) ?? requestIdDefaultValue;
}
