// SPDX-FileCopyrightText: 2023 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'dart:async';

import 'package:act_abstract_manager/act_abstract_manager.dart';
import 'package:act_logger_manager/act_logger_manager.dart';
import 'package:act_server_req_manager/src/helpers/body_format_utility.dart';
import 'package:act_server_req_manager/src/helpers/url_format_utility.dart';
import 'package:act_server_req_manager/src/models/request_param.dart';
import 'package:act_server_req_manager/src/models/request_response.dart';
import 'package:act_server_req_manager/src/models/server_urls.dart';
import 'package:act_server_req_manager/src/server_req_constants.dart';
import 'package:act_server_req_manager/src/types/request_result.dart';
import 'package:http/http.dart';

/// We can request the server through this requester. This doesn't manage the login (it's done by
/// the manager)
class ServerRequester extends AbsWithLifeCycle {
  /// The logs helper linked to the requester
  final LogsHelper logsHelper;

  /// The server URLs to use
  final ServerUrls _serverUrls;

  /// The default timeout in milliseconds
  final Duration defaultTimeout;

  /// The current opened client to request the server with
  Client? _client;

  /// The timeout used to close the client when no more requests are done
  Timer? _closeClientTimer;

  /// Class constructor
  ServerRequester({
    required this.logsHelper,
    required ServerUrls serverUrls,
    required this.defaultTimeout,
  }) : _serverUrls = serverUrls;

  /// Get the current opened client or create a new one
  Client _createOrGetClient() {
    _closeClientTimer?.cancel();

    _client ??= Client();
    _closeClientTimer = Timer(ServerReqConstants.clientSessionDuration, _closeClient);
    return _client!;
  }

  /// This method requests the third server without managing the login
  Future<RequestResponse<RespBody>> executeRequestWithoutAuth<RespBody>(
      RequestParam requestParam) async {
    final urlToRequest = UrlFormatUtility.formatFullUrl(
      requestParam: requestParam,
      serverUrls: _serverUrls,
    );

    final request = BodyFormatUtility.formatRequest(
      requestParam: requestParam,
      logsHelper: logsHelper,
      urlToRequest: urlToRequest,
    );

    if (request == null) {
      return const RequestResponse(result: RequestResult.globalError);
    }

    logsHelper.d("Request the server: ${requestParam.httpMethod.str} - $urlToRequest");

    var timeout = defaultTimeout;

    if (requestParam.timeout != null && requestParam.timeout != Duration.zero) {
      timeout = requestParam.timeout!;
    }

    final client = _createOrGetClient();
    Response? response;

    try {
      final streamedResponse = await client.send(request).timeout(timeout);
      response = await Response.fromStream(streamedResponse);
    } catch (error) {
      _closeClient();
      logsHelper.e("An error occurred when requesting a server on uri: $urlToRequest, "
          "error: $error");
    }

    if (response == null) {
      return const RequestResponse(result: RequestResult.globalError);
    }

    return BodyFormatUtility.formatResponse(
      requestParam: requestParam,
      responseReceived: response,
      logsHelper: logsHelper,
      urlToRequest: urlToRequest,
    );
  }

  /// Close the http client
  void _closeClient() {
    _closeClientTimer?.cancel();
    _client?.close();
    _client = null;
  }

  /// Call to dispose the requester
  @override
  Future<void> disposeLifeCycle() async {
    _closeClient();

    await super.disposeLifeCycle();
  }
}
