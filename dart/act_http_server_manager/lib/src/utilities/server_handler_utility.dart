// SPDX-FileCopyrightText: 2025 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_http_server_manager/src/services/handlers/abs_server_handler.dart';
import 'package:shelf/shelf.dart';

/// Contains utility methods to manager server handlers
sealed class ServerHandlersUtility {
  /// Manage the server handlers
  static Future<Response> manageServerHandlers({
    required Request request,
    required Handler innerHandler,
    required List<AbsServerHandler> routeHandlers,
  }) async {
    var tmpRequest = request;

    for (final globalHandler in routeHandlers) {
      final result = await globalHandler.beforeHandler(request: tmpRequest);
      if (result.forceResponse != null) {
        return result.forceResponse!;
      }

      if (result.overrideRequest != null) {
        tmpRequest = result.overrideRequest!;
      }
    }

    var tmpResponse = await innerHandler(tmpRequest);
    for (final globalHandler in routeHandlers.reversed) {
      tmpResponse = await globalHandler.afterHandler(request: tmpRequest, response: tmpResponse);
    }

    return tmpResponse;
  }
}
