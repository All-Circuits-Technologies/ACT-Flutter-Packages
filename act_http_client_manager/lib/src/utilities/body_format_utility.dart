// SPDX-FileCopyrightText: 2023 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'dart:convert';

import 'package:act_http_client_manager/src/models/converted_body.dart';
import 'package:act_http_client_manager/src/models/request_param.dart';
import 'package:act_http_client_manager/src/models/request_response.dart';
import 'package:act_http_client_manager/src/types/request_status.dart';
import 'package:act_http_core/act_http_core.dart';
import 'package:act_logger_manager/act_logger_manager.dart';
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

    final request = Request(requestParam.httpMethod.stringValue, urlToRequest);

    request.headers.addAll(requestParam.headers);

    // We had guessed the body content type and we set it in the request
    if (convertedBody.contentType != HttpMimeTypes.empty &&
        !request.headers.containsKey(HeaderConstants.contentTypeHeaderKey)) {
      logsHelper.d("We had guessed the content type: ${convertedBody.contentType.stringValue}, and "
          "we set it in the request header");
      request.headers[HeaderConstants.contentTypeHeaderKey] = convertedBody.contentType.stringValue;
    }

    switch (convertedBody.contentType) {
      case HttpMimeTypes.json:
      case HttpMimeTypes.plainText:
        request.body = convertedBody.body! as String;
        break;
      case HttpMimeTypes.multipartFormData:
        request.bodyBytes = convertedBody.body! as Uint8List;
        break;
      case HttpMimeTypes.formUrlEncoded:
        request.bodyFields = convertedBody.body! as Map<String, String>;
        break;
      case HttpMimeTypes.empty:
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
  static RequestResponse<ParsedBody> formatResponse<ParsedBody, RespBody>({
    required RequestParam requestParam,
    required Response responseReceived,
    required Uri urlToRequest,
    required ParsedBody? Function(RespBody body)? parseRespBody,
    required LogsHelper logsHelper,
  }) {
    if (responseReceived.statusCode < ServerResponseStatus.ok.httpStatus! ||
        responseReceived.statusCode >= ServerResponseStatus.multipleChoices.httpStatus!) {
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

      if (responseReceived.statusCode == ServerResponseStatus.unauthorized.httpStatus!) {
        result = RequestStatus.loginError;
      }

      return RequestResponse<ParsedBody>(status: result, response: responseReceived);
    }

    final result = _parseResponseBody<RespBody>(
      requestParam: requestParam,
      responseReceived: responseReceived,
      logsHelper: logsHelper,
    );

    var finalResult = RequestStatus.success;

    if (!result.isOk) {
      logsHelper.w("An error occurred when trying to parse body from response of request: "
          "$urlToRequest");
      finalResult = RequestStatus.globalError;
    }

    ParsedBody? parsedBody;
    if (result.body != null) {
      if (parseRespBody != null) {
        parsedBody = parseRespBody(result.body as RespBody);
      } else if (result.body is ParsedBody) {
        parsedBody = result.body as ParsedBody;
      } else {
        logsHelper.w("The received body type: $RespBody, hasn't the same type as the parsed body: "
            "$ParsedBody, but you haven't set a parse method (and the body isn't null)");
        finalResult = RequestStatus.globalError;
      }
    }

    return RequestResponse<ParsedBody>(
      status: finalResult,
      response: responseReceived,
      castedBody: parsedBody,
    );
  }

  /// Parse and cast the response body of [Response] to the expected body type
  static ({bool isOk, Body? body}) _parseResponseBody<Body>({
    required RequestParam requestParam,
    required Response responseReceived,
    required LogsHelper logsHelper,
  }) {
    var responseType = requestParam.expectedMimeType ?? HttpMimeTypes.empty;

    if (!responseReceived.headers.containsKey(HeaderConstants.contentTypeHeaderKey) &&
        !responseReceived.headers.containsKey(HeaderConstants.contentTypeHeaderKey.toLowerCase())) {
      // There is no content type
      responseType = HttpMimeTypes.empty;
    }

    Body? body;

    if (responseType == HttpMimeTypes.empty) {
      // Nothing to do
      return (isOk: true, body: body);
    }

    try {
      switch (responseType) {
        case HttpMimeTypes.json:
          body = jsonDecode(responseReceived.body) as Body;
          break;

        case HttpMimeTypes.formUrlEncoded:
          body = Uri.splitQueryString(responseReceived.body) as Body;
          break;

        case HttpMimeTypes.multipartFormData:
          body = responseReceived.bodyBytes as Body;
          break;

        case HttpMimeTypes.plainText:
          body = responseReceived.body as Body;
          break;

        case HttpMimeTypes.empty:
          // Already managed in previous test
          break;
      }
    } catch (error) {
      logsHelper.w("An error occurred when tried to parse the body of a response received, from "
          "type: $responseType, error: $error");
    }

    return (isOk: (body != null), body: body);
  }
}
