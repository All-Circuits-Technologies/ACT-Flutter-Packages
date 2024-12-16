// Copyright (c) 2020. BMS Circuits

import 'dart:convert';
import 'dart:io';

import 'package:act_global_manager/act_global_manager.dart';
import 'package:act_server_request_manager/src/data/server_constants.dart';
import 'package:act_server_request_manager/src/http/http_method.dart';
import 'package:act_server_request_manager/src/request_result.dart';
import 'package:act_server_request_manager/src/server_request_manager.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:tuple/tuple.dart';

/// HTTP status code category
abstract class HttpStatusCodeCategory {
  static const int informative = 1;
  static const int success = 2;
  static const int redirection = 3;
  static const int clientError = 4;
  static const int serverError = 5;
}

/// This enum allows to define what to do with the response received.
///
/// If [Ok], the response is valid and so nothing need to be done.
/// If [Error], the response is an error and therefore, we have to directly
/// return.
/// If [RepeatRequest], we have to repeat this same request.
/// If [RefreshXAuthAndRepeatRequest], we have to refresh the server X
/// Authentication credentials before retry to send the same request
enum _ResponseAction { Ok, Error, RepeatRequest, RefreshXAuthAndRepeatRequest }

/// This abstract class contains the shared methods for requesting both the
/// thingsboard server and the Water Saver hotspot server
abstract class AbstractHttpRequestMaker {
  /// Main method to send request to the server, it manages what have to be done
  /// depending of the request response
  ///
  /// If [needAuth] equals to true, it means that the request needs the user to
  /// be authenticated.
  /// [tryNumber] is used for recursive calls, to know how many calls have
  /// already be done, to avoid to repeat the request endlessly
  /// [requestingMainServer] is used to specify if we are requesting the
  /// Thingsboard server (the value is equals to true in that case) or the
  /// Water Saver hotspot server
  static Future<Tuple2<RequestResult, Response>> sendHttpRequest({
    @required HttpMethod command,
    @required Uri url,
    Map<String, String> headers = const {},
    Map<String, dynamic> body = const {},
    int tryNumber = 1,
    bool updateRequestState = true,
    GetXAuthHeaderAsync getXAuth,
    RefreshXAuthHeaderAsync refreshXAuth,
  }) async {
    Tuple2<RequestResult, Response> serverResult =
        await GlobalGetIt().get<ServerRequestManager>().sendHttpRequest(
              command: command,
              url: url,
              headers: headers,
              body: body,
              updateRequestState: updateRequestState,
              getXAuth: getXAuth,
            );

    // Check the response got and decide what to do next
    _ResponseAction responseAction = await _checkResponse(serverResult, url);

    if (responseAction == _ResponseAction.RefreshXAuthAndRepeatRequest &&
        refreshXAuth == null) {
      AppLogger().w("[HTTP] The request needs an authentication but no method "
          "has been given");
      responseAction = _ResponseAction.Error;
    } else if ((responseAction ==
                _ResponseAction.RefreshXAuthAndRepeatRequest ||
            responseAction == _ResponseAction.RepeatRequest) &&
        tryNumber >= ServerConstants.maxTryNumberBeforeError) {
      // If we need to repeat requests but we overflow the max try number, this
      // is an error

      AppLogger().w("[HTTP] Max try number raised for this request");
      responseAction = _ResponseAction.Error;
    }

    if (responseAction == _ResponseAction.Ok) {
      return serverResult;
    }

    if (responseAction == _ResponseAction.Error) {
      if (serverResult.item1 != RequestResult.Ok) {
        return serverResult;
      }

      return Tuple2(RequestResult.GenericError, serverResult.item2);
    }

    bool wait = true;

    if (responseAction == _ResponseAction.RefreshXAuthAndRepeatRequest) {
      // Refresh X Authentication credentials
      Tuple2<RequestResult, String> result = await refreshXAuth();

      if (result.item1 != RequestResult.Ok) {
        AppLogger().w("[HTTP] The refresh of the X Auth credentials failed, "
            "don't go further");
        return serverResult;
      }

      wait = false;
    }

    if (wait) {
      // If we are here it's for retry to send the request, we wait some times
      // before retrying
      await Future.delayed(ServerConstants.timeToWaitBeforeRetryingInMs);
    }

    return sendHttpRequest(
      command: command,
      url: url,
      body: body,
      headers: headers,
      getXAuth: getXAuth,
      refreshXAuth: refreshXAuth,
      tryNumber: ++tryNumber,
      updateRequestState: updateRequestState,
    );
  }

  /// Check response and decide what to do
  static Future<_ResponseAction> _checkResponse(
    Tuple2<RequestResult, Response> serverResult,
    Uri url,
  ) async {
    if (serverResult.item1 == RequestResult.WrongCredentials) {
      AppLogger().i("[HTTP] The user isn't authenticated or the X Auth  "
          "credentials are no more valid");
      return _ResponseAction.RefreshXAuthAndRepeatRequest;
    }

    if (serverResult.item1 != RequestResult.Ok || serverResult.item2 == null) {
      // Useless to repeat in that case
      return _ResponseAction.Error;
    }

    Response response = serverResult.item2;

    // Check first digit of status code and log response
    int firstNumberResponse = int.parse(response.statusCode.toString()[0]);

    if (firstNumberResponse == HttpStatusCodeCategory.success) {
      return _ResponseAction.Ok;
    }

    if (firstNumberResponse == HttpStatusCodeCategory.serverError) {
      AppLogger().i("[HTTP] A problem occurred on the server, retry the "
          "request");
      return _ResponseAction.RepeatRequest;
    }

    if (firstNumberResponse == HttpStatusCodeCategory.informative) {
      AppLogger().i("[HTTP] Receive an informative response, retry request");
      return _ResponseAction.RepeatRequest;
    }

    if (firstNumberResponse == HttpStatusCodeCategory.redirection) {
      AppLogger().i("[HTTP] Receive a redirection response, retry request");
      return _ResponseAction.RepeatRequest;
    }

    // Manage particular status code
    switch (response.statusCode) {
      case HttpStatus.unauthorized:
        AppLogger().i("[HTTP] The user isn't authenticated or the X Auth  "
            "credentials are no more valid");
        return _ResponseAction.RefreshXAuthAndRepeatRequest;

      case HttpStatus.forbidden:
        AppLogger().w("[HTTP] The user has no right to access those "
            "data");
        return _ResponseAction.Error;

      default:
        AppLogger().w("[HTTP] There is a problem with the request, "
            "useless to retry to send it to server");
        return _ResponseAction.Error;
    }
  }

  /// Parse the response body to a Json
  static Map<String, dynamic> parseJsonBodyToObj(Response response) =>
      _parseJsonBody(response);

  /// Parse the response body to a Json Array
  static List<dynamic> parseJsonBodyToArray(Response response) =>
      _parseJsonBody(response);

  /// Parse the response body from an object or list to a Json
  static T _parseJsonBody<T>(Response response) {
    if (response == null) {
      return null;
    }

    T data;

    try {
      data = jsonDecode(response.body) as T;
    } catch (error) {
      AppLogger().w("Cannot parse to json, the response body: "
          "${response.body}");
    }

    return data;
  }
}
