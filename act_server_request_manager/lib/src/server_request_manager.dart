// Copyright (c) 2020. BMS Circuits

import 'dart:async';
import 'dart:convert';

import 'package:act_abstract_manager/act_abstract_manager.dart';
import 'package:act_global_manager/act_global_manager.dart';
import 'package:act_server_request_manager/src/data/server_constants.dart';
import 'package:act_server_request_manager/src/http/http_method.dart';
import 'package:act_server_request_manager/src/http/http_query_client.dart';
import 'package:act_server_request_manager/src/request_result.dart';
import 'package:act_server_request_manager/src/server_helper.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:tuple/tuple.dart';

enum ServerComState { Ok, FailedToCommunicate }

/// Builder for creating the ServerObserverManager
class ServerRequestBuilder extends ManagerBuilder<ServerRequestManager> {
  /// Class constructor with the class construction
  ServerRequestBuilder() : super(() => ServerRequestManager());

  /// List of manager dependence
  @override
  Iterable<Type> dependsOn() => [];
}

/// Helpful manager to communicate with server
class ServerRequestManager extends AbstractManager {
  ServerComState _lastRequestState;
  StreamController<ServerComState> _requestStateStreamCtrl;

  /// This stream emits events when we detect that network communication fails
  /// or if it comes to live
  Stream<ServerComState> get requestStateStream =>
      _requestStateStreamCtrl.stream;

  /// Get the current request state
  ServerComState get requestState => _lastRequestState;

  ServerRequestManager() : super() {
    _requestStateStreamCtrl = StreamController<ServerComState>.broadcast();
  }

  @override
  Future<void> initManager() async => null;

  @override
  Future<void> dispose() async {
    return _requestStateStreamCtrl.close();
  }

  /// This method helps to send a request to the server
  ///
  /// It returns the response got and the result of the request. The response
  /// can be null if an error occurred while sending the request
  Future<Tuple2<RequestResult, Response>> sendHttpRequest({
    @required HttpMethod command,
    @required Uri url,
    Map<String, String> headers = const {},
    Map<String, dynamic> body = const {},
    GetXAuthHeaderAsync getXAuth,
    bool updateRequestState = true,
  }) async {
    HttpQueryClient client;

    if (getXAuth != null) {
      client = HttpQueryClient.withXAuth(getXAuth);
    } else {
      client = HttpQueryClient();
    }

    Request request = Request(command.str.toUpperCase(), url);
    request.headers.addAll(headers);

    if (command == HttpMethod.patch ||
        command == HttpMethod.post ||
        command == HttpMethod.put) {
      // Only those commands have body
      request.body = jsonEncode(body);
    }

    Response response;

    AppLogger().d("[HTTP] ${command.str.toUpperCase()} - "
        "${url.toString()}: Send request to server");

    RequestResult result = RequestResult.Ok;

    try {
      StreamedResponse streamedResponse = await client.send(request);
      response = await Response.fromStream(streamedResponse);
      AppLogger().d("[HTTP] Response received, status code: "
          "${response?.statusCode}");
      AppLogger().v("[HTTP] Response received, body: "
          "${response?.body}");
    } catch (error) {
      AppLogger().w("[HTTP] An error occurred when trying to communicate "
          "with the server: $error");
      result = ServerHelper.parseRequestError(error);
    } finally {
      client.close();
    }

    if (updateRequestState) {
      _updateRequestState(result);
    }

    return Tuple2(result, response);
  }

  /// Called at each result to update the server request communication state
  void _updateRequestState(RequestResult result) {
    ServerComState tmpState = ServerComState.Ok;

    if (result == RequestResult.DisconnectFromNetwork) {
      tmpState = ServerComState.FailedToCommunicate;
    }

    if (tmpState != _lastRequestState) {
      _lastRequestState = tmpState;
      _requestStateStreamCtrl.add(_lastRequestState);
    }
  }
}
