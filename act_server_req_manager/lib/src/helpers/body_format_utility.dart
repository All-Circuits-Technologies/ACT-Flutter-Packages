// SPDX-FileCopyrightText: 2023 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'dart:convert';
import 'dart:io';

import 'package:act_logger_manager/act_logger_manager.dart';
import 'package:act_server_req_manager/src/models/converted_body.dart';
import 'package:act_server_req_manager/src/models/request_param.dart';
import 'package:act_server_req_manager/src/models/request_response.dart';
import 'package:act_server_req_manager/src/server_req_constants.dart';
import 'package:act_server_req_manager/src/types/http_methods.dart';
import 'package:act_server_req_manager/src/types/mime_types.dart';
import 'package:act_server_req_manager/src/types/request_status.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart';

/// Contains useful methods to format and cast the request or response body
sealed class BodyFormatUtility {
  /// Format a [BaseRequest] from a [RequestParam] and [Uri] given
  static BaseRequest? formatRequest({
    required RequestParam requestParam,
    required LogsHelper logsHelper,
    required Uri urlToRequest,
  }) {
    final convertedBody = _convertRequestBody(body: requestParam.body, logsHelper: logsHelper);

    if (convertedBody == null) {
      return null;
    }

    final request = Request(requestParam.httpMethod.str, urlToRequest);

    request.headers.addAll(requestParam.headers);

    // We had guessed the body content type and we set it in the request
    if (convertedBody.contentType != MimeTypes.empty &&
        !request.headers.containsKey(ServerReqConstants.contentTypeHeader)) {
      logsHelper.d("We had guessed the content type: ${convertedBody.contentType.str}, and we set "
          "it in the request header");
      request.headers[ServerReqConstants.contentTypeHeader] = convertedBody.contentType.str;
    }

    switch (convertedBody.contentType) {
      case MimeTypes.json:
      case MimeTypes.plainText:
        request.body = convertedBody.body! as String;
        break;
      case MimeTypes.multipartFormData:
        request.bodyBytes = convertedBody.body! as Uint8List;
        break;
      case MimeTypes.formUrlEncoded:
        request.bodyFields = convertedBody.body! as Map<String, String>;
        break;
      case MimeTypes.empty:
        // Nothing to do
        break;
    }

    return request;
  }

  /// The methods parses the body given and parse it to manageable type for the external http lib
  ///
  /// Also returns the mime type linked to body converted
  static ConvertedBody? _convertRequestBody({
    // We use a dynamic value here because we get it from a json
    // ignore: avoid_annotating_with_dynamic
    required dynamic body,
    required LogsHelper logsHelper,
  }) {
    ConvertedBody? convertedBody;

    if (body == null) {
      // There is nothing to send
      convertedBody = const ConvertedBody.empty();
    } else if (body is String) {
      convertedBody = ConvertedBody.string(body: body);
    } else if (body is Map<String, String>) {
      convertedBody = ConvertedBody.formUrlEncoded(body: body);
    } else if (body is Uint8List) {
      convertedBody = ConvertedBody.multipartFormData(body: body);
    } else if (body is List<int>) {
      convertedBody = ConvertedBody.multipartFormDataIntList(body: body);
    } else {
      convertedBody = ConvertedBody.tryParseJson(body, logsHelper: logsHelper);
    }

    return convertedBody;
  }

  /// Format a response [RequestResponse] from a [Response] received and the request [RequestParam]
  /// info
  static RequestResponse<Body> formatResponse<Body>({
    required RequestParam requestParam,
    required Response responseReceived,
    required Uri urlToRequest,
    required LogsHelper logsHelper,
  }) {
    if (responseReceived.statusCode < HttpStatus.ok ||
        responseReceived.statusCode >= HttpStatus.multipleChoices) {
      logsHelper.t("The response received isn't ok, http status: ${responseReceived.statusCode}, "
          "reason phrase: ${responseReceived.reasonPhrase}");

      if (requestParam.httpMethod != HttpMethods.head) {
        try {
          logsHelper.d("The response received: ${responseReceived.body}");
        } catch (error) {
          // Nothing to do
        }
      }

      var result = RequestStatus.globalError;

      if (responseReceived.statusCode == HttpStatus.unauthorized) {
        result = RequestStatus.loginError;
      }

      return RequestResponse<Body>(status: result, response: responseReceived);
    }

    final (result, body) = _parseResponseBody<Body>(
      requestParam: requestParam,
      responseReceived: responseReceived,
      logsHelper: logsHelper,
    );

    var finalResult = RequestStatus.success;

    if (!result) {
      logsHelper.w("An error occurred when tried to parse body from response of request: "
          "$urlToRequest");
      finalResult = RequestStatus.globalError;
    }

    return RequestResponse<Body>(
      status: finalResult,
      response: responseReceived,
      castedBody: body,
    );
  }

  /// Parse and cast the response body of [Response] to the expected body type
  static (bool, Body?) _parseResponseBody<Body>({
    required RequestParam requestParam,
    required Response responseReceived,
    required LogsHelper logsHelper,
  }) {
    var responseType = requestParam.expectedMimeType ?? MimeTypes.empty;

    if (!responseReceived.headers.containsKey(ServerReqConstants.contentTypeHeader) &&
        !responseReceived.headers.containsKey(ServerReqConstants.contentTypeHeader.toLowerCase())) {
      // There is no content type
      responseType = MimeTypes.empty;
    }

    Body? body;

    if (responseType == MimeTypes.empty) {
      // Nothing to do
      return (true, body);
    }

    try {
      switch (responseType) {
        case MimeTypes.json:
          body = jsonDecode(responseReceived.body) as Body;
          break;

        case MimeTypes.formUrlEncoded:
          body = Uri.splitQueryString(responseReceived.body) as Body;
          break;

        case MimeTypes.multipartFormData:
          body = responseReceived.bodyBytes as Body;
          break;

        case MimeTypes.plainText:
          body = responseReceived.body as Body;
          break;

        case MimeTypes.empty:
          // Already managed in previous test
          break;
      }
    } catch (error) {
      logsHelper.w("An error occurred when tried to parse the body of a response received, from "
          "type: $responseType, error: $error");
    }

    return ((body != null), body);
  }
}
