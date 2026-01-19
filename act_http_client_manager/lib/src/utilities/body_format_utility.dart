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
    final convertedBody = _convertRequestBody(requestParam: requestParam, logsHelper: logsHelper);

    if (convertedBody == null) {
      return null;
    }

    final request = _createAndFormatRequest(
      convertedBody: convertedBody,
      httpMethod: requestParam.httpMethod,
      urlToRequest: urlToRequest,
    );

    request.headers.addAll(requestParam.headers);

    // We had guessed the body content type and we set it in the request
    if (convertedBody.contentType != HttpMimeTypes.empty &&
        !request.headers.containsKey(HeaderConstants.contentTypeHeaderKey)) {
      logsHelper.d("We had guessed the content type: ${convertedBody.contentType.stringValue}, and "
          "we set it in the request header");
      request.headers[HeaderConstants.contentTypeHeaderKey] = convertedBody.contentType.stringValue;
    }

    return request;
  }

  /// Tries to guess the body type based on its runtime type
  /// Returns null if the body type is not recognized
  // The body is of unknown type that's why is of dynamic type
  // ignore: avoid_annotating_with_dynamic
  static HttpBodyTypes? tryToGuessBodyType(dynamic body) {
    // We use a for and a switch to be sure we receive an error if we add a new type and don't
    // handle it here
    for (final value in HttpBodyTypes.values) {
      switch (value) {
        case HttpBodyTypes.none:
          if (body == null) {
            return HttpBodyTypes.none;
          }
          break;
        case HttpBodyTypes.string:
          if (body is String) {
            return HttpBodyTypes.string;
          }
          break;
        case HttpBodyTypes.binary:
          if (body is Uint8List || body is List<int>) {
            return HttpBodyTypes.binary;
          }
          break;
        case HttpBodyTypes.mapStringString:
          if (body is Map<String, String>) {
            return HttpBodyTypes.mapStringString;
          }
          break;
        case HttpBodyTypes.json:
          if (body is Map<String, dynamic> || body is List<dynamic>) {
            return HttpBodyTypes.json;
          }
          break;
        case HttpBodyTypes.files:
          if (body is MultipartFile) {
            return HttpBodyTypes.files;
          }

          if (body is List<dynamic>) {
            final allAreFiles = body.every((element) => element is MultipartFile);
            if (allAreFiles) {
              return HttpBodyTypes.files;
            }
          }
          break;
      }
    }

    return null;
  }

  /// The methods parses the body given and parse it to manageable type for the external http lib
  ///
  /// Also returns the mime type linked to body converted
  static ConvertedBody? _convertRequestBody({
    required RequestParam requestParam,
    required LogsHelper logsHelper,
  }) {
    final requestBody = requestParam.body;
    var requestMimeType = requestParam.requestMimeType;

    if (requestMimeType == null) {
      final bodyType = tryToGuessBodyType(requestBody);
      if (bodyType == null) {
        logsHelper.w("We can't guess the body type for the given body, the type is: "
            "${requestBody.runtimeType} and it's unknown");
        return null;
      }

      requestMimeType = HttpMimeTypes.getDefaultValueByBodyType(bodyType);
    }

    return _tryToConvertRequestBodyFromMimeType(
      requestMimeType: requestMimeType,
      body: requestBody,
      logsHelper: logsHelper,
    );
  }

  /// Try to convert the request body from the given mime type
  ///
  /// Returns `null` if the body type is not valid for the given mime type
  static ConvertedBody? _tryToConvertRequestBodyFromMimeType({
    required HttpMimeTypes requestMimeType,
    // We can't avoid dynamic here because we want to accept any type of body
    // ignore: avoid_annotating_with_dynamic
    required dynamic body,
    required LogsHelper logsHelper,
  }) {
    var requestBody = body;

    // In the switch we only manage the validation of the body type and conversion if needed
    switch (requestMimeType) {
      case HttpMimeTypes.empty:
        // Nothing to send; we set body to null in order to avoid any problems
        requestBody = null;
        break;

      case HttpMimeTypes.multipartFormData:
        if (requestBody is MultipartFile) {
          // We convert it to a list
          requestBody = [requestBody];
          break;
        }

        if (requestBody is List<dynamic>) {
          final allAreFiles = requestBody.every((element) => element is MultipartFile);
          if (allAreFiles) {
            // Nothing to do
            break;
          }
        }

        logsHelper.w("We expect to have a MultipartFile or List<MultipartFile> body for the "
            "request $requestMimeType MIME type");
        return null;
      case HttpMimeTypes.applicationOctetStream:
      case HttpMimeTypes.gzip:
      case HttpMimeTypes.csvText:
        if (requestBody is! Uint8List && requestBody is! List<int>) {
          logsHelper.w("We expect to have an Uint8List or List<int> body for the request "
              "$requestMimeType MIME type");
          return null;
        }

        if (requestBody is List<int>) {
          requestBody = Uint8List.fromList(requestBody);
        }
        break;

      case HttpMimeTypes.formUrlEncoded:
        if (requestBody is! Map<String, String>) {
          logsHelper.w(
              "We expect to have a Map<String, String> body for the request $requestMimeType MIME "
              "type");
          return null;
        }
        break;

      case HttpMimeTypes.plainText:
        if (requestBody is! String) {
          logsHelper
              .w("We expect to have a String body for the request $requestMimeType MIME type");
          return null;
        }
        break;

      case HttpMimeTypes.json:
        if (requestBody is! Map<String, dynamic> &&
            requestBody is! List<dynamic> &&
            requestBody is! String) {
          logsHelper
              .w("We expect to have a String, Map<String, dynamic> or List<dynamic> body for the "
                  "request $requestMimeType MIME type");
          return null;
        }

        var anErrorOccurred = false;
        if (requestBody is String) {
          // We try to decode it to verify if the JSON is valid
          try {
            jsonDecode(requestBody);
          } catch (error) {
            logsHelper.w(
                "We expect to have a valid JSON String body for the request $requestMimeType MIME "
                "type, error when decoding: $error");
            anErrorOccurred = true;
          }
        } else {
          try {
            requestBody = jsonEncode(requestBody);
          } catch (error) {
            logsHelper
                .w("We expect to have a valid JSON body for the request $requestMimeType MIME "
                    "type, error when encoding: $error");
            return null;
          }
        }

        if (anErrorOccurred) {
          return null;
        }
        break;
    }

    return ConvertedBody(body: requestBody, contentType: requestMimeType);
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
      return (isOk: true, body: null);
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
        case HttpMimeTypes.applicationOctetStream:
        case HttpMimeTypes.gzip:
        case HttpMimeTypes.csvText:
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

  /// Create and format a [BaseRequest] from the converted body, http method and url given
  static BaseRequest _createAndFormatRequest({
    required ConvertedBody convertedBody,
    required HttpMethods httpMethod,
    required Uri urlToRequest,
  }) {
    BaseRequest request;

    final contentType = convertedBody.contentType;
    if (contentType == HttpMimeTypes.multipartFormData) {
      final tmpMultiRequest = MultipartRequest(httpMethod.stringValue, urlToRequest);
      tmpMultiRequest.files.addAll(convertedBody.body! as List<MultipartFile>);
      request = tmpMultiRequest;
    } else {
      final tmpRequest = Request(httpMethod.stringValue, urlToRequest);
      switch (contentType) {
        case HttpMimeTypes.json:
        case HttpMimeTypes.plainText:
          tmpRequest.body = convertedBody.body! as String;
          break;
        case HttpMimeTypes.applicationOctetStream:
        case HttpMimeTypes.gzip:
        case HttpMimeTypes.csvText:
          tmpRequest.bodyBytes = convertedBody.body! as Uint8List;
          break;
        case HttpMimeTypes.formUrlEncoded:
          tmpRequest.bodyFields = convertedBody.body! as Map<String, String>;
          break;
        case HttpMimeTypes.empty:
          // Nothing to do
          break;
        case HttpMimeTypes.multipartFormData:
          // Already managed
          break;
      }
      request = tmpRequest;
    }

    return request;
  }
}
