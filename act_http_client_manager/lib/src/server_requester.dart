// SPDX-FileCopyrightText: 2023 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'dart:async';

import 'package:act_abstract_manager/act_abstract_manager.dart';
import 'package:act_dart_utility/act_dart_utility.dart';
import 'package:act_http_client_manager/src/constants/server_req_constants.dart'
    as server_req_constants;
import 'package:act_http_client_manager/src/models/request_param.dart';
import 'package:act_http_client_manager/src/models/request_response.dart';
import 'package:act_http_client_manager/src/models/server_urls.dart';
import 'package:act_http_client_manager/src/types/request_status.dart';
import 'package:act_http_client_manager/src/utilities/body_format_utility.dart';
import 'package:act_http_client_manager/src/utilities/url_format_utility.dart';
import 'package:act_logger_manager/act_logger_manager.dart';
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

  /// The lock utility is used when there is a max parallel requests number
  final LockUtility? _lockUtility;

  /// The on release watcher, this is used to watch when the requester is released and close the
  /// client if needed
  late final OnReleaseWatcher _onReleaseWatcher;

  /// The current opened client to request the server with
  Client? _client;

  /// Class constructor
  ///
  /// [maxParallelRequestsNb] is used to define the maximum number of parallel requests that can be
  /// done at the same time. If null, there is no limit on the number of parallel requests.
  ServerRequester({
    required this.logsHelper,
    required ServerUrls serverUrls,
    required this.defaultTimeout,
    required int? maxParallelRequestsNb,
  })  : _serverUrls = serverUrls,
        _lockUtility = (maxParallelRequestsNb != null)
            ? LockUtility(maxParallelRequestsNb: maxParallelRequestsNb)
            : null {
    _onReleaseWatcher = OnReleaseWatcher(
      thresholdDuration: server_req_constants.clientSessionDuration,
      callback: _closeClient,
    );
  }

  /// This method requests the third server without managing the login
  Future<RequestResponse<ParsedRespBody>> executeRequestWithoutAuth<ParsedRespBody, RespBody>({
    required RequestParam requestParam,
    ParsedRespBody? Function(RespBody body)? parseRespBody,
  }) =>
      _wrapRequestWithLock(() async => _onReleaseWatcher.supervise(() async {
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
              return const RequestResponse(status: RequestStatus.globalError);
            }

            logsHelper
                .d("Request the server: ${requestParam.httpMethod.stringValue} - $urlToRequest");

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
              return const RequestResponse(status: RequestStatus.globalError);
            }

            return BodyFormatUtility.formatResponse<ParsedRespBody, RespBody>(
              requestParam: requestParam,
              responseReceived: response,
              logsHelper: logsHelper,
              urlToRequest: urlToRequest,
              parseRespBody: parseRespBody,
            );
          }));

  /// Get the current opened client or create a new one
  Client _createOrGetClient() {
    _client ??= Client();
    return _client!;
  }

  /// Close the http client
  void _closeClient() {
    _client?.close();
    _client = null;
  }

  /// If [_lockUtility] is not null, use it to call the [criticalSection].
  ///
  /// If [_lockUtility] is null, directly calls [criticalSection]
  Future<T> _wrapRequestWithLock<T>(Future<T> Function() criticalSection) async {
    if (_lockUtility == null) {
      return criticalSection();
    }

    return _lockUtility!.protectLock(criticalSection);
  }

  /// Call to dispose the requester
  @override
  Future<void> disposeLifeCycle() async {
    _closeClient();

    await super.disposeLifeCycle();
  }
}
