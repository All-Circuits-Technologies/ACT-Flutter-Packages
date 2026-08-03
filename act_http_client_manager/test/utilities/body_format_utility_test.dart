// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'dart:convert';
import 'dart:typed_data';

import 'package:act_foundation/act_foundation.dart';
import 'package:act_http_client_manager/act_http_client_manager.dart';
import 'package:act_http_client_manager/src/utilities/body_format_utility.dart';
import 'package:act_http_core/act_http_core.dart';
import 'package:act_logger_manager/act_logger_manager.dart';
import 'package:act_test_utility/act_test_utility.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart';

/// The URL the requests of the tests are sent to.
final _url = Uri.parse("http://a.server/v1/items");

void main() {
  late FakeExternalLogger logs;
  late LogsHelper logsHelper;

  setUp(() {
    logs = FakeExternalLogger();
    logsHelper = logs.buildHelper(category: "aRequester");
  });

  /// The warnings the formatting wrote.
  List<String> warnings() =>
      logs.recordsAtLevel(LogsLevel.warn).map((record) => "${record.message}").toList();

  /// Formats the request of a call which carries [body].
  BaseRequest? formatRequest({
    Object? body,
    HttpMimeTypes? requestMimeType,
    Map<String, String>? headers,
  }) => BodyFormatUtility.formatRequest(
    requestParam: RequestParam(
      httpMethod: HttpMethods.post,
      relativeRoute: "items",
      body: body,
      requestMimeType: requestMimeType,
      headers: headers,
    ),
    logsHelper: logsHelper,
    urlToRequest: _url,
  );

  /// Formats the answer of a server which sent [body] with [statusCode].
  RequestResponse<ParsedBody> formatResponse<ParsedBody, RespBody>({
    String body = "",
    int statusCode = 200,
    String? contentType,
    HttpMimeTypes? expectedMimeType,
    HttpMethods httpMethod = HttpMethods.get,
    ParsedBody? Function(RespBody body)? parseRespBody,
  }) => BodyFormatUtility.formatResponse<ParsedBody, RespBody>(
    requestParam: RequestParam(
      httpMethod: httpMethod,
      relativeRoute: "items",
      expectedMimeType: expectedMimeType,
    ),
    responseReceived: Response(
      body,
      statusCode,
      headers: contentType == null
          ? const {}
          : {HeaderConstants.contentTypeHeaderKey.toLowerCase(): contentType},
    ),
    urlToRequest: _url,
    parseRespBody: parseRespBody,
    logsHelper: logsHelper,
  );

  group("BodyFormatUtility.tryToGuessBodyType", () {
    test("answers that there is no body when there is none", () {
      expect(BodyFormatUtility.tryToGuessBodyType(null), HttpBodyTypes.none);
    });

    test("answers a text body for a string", () {
      expect(BodyFormatUtility.tryToGuessBodyType("a body"), HttpBodyTypes.string);
    });

    test("answers a binary body for bytes", () {
      expect(BodyFormatUtility.tryToGuessBodyType(Uint8List.fromList([1, 2])), HttpBodyTypes.binary);
    });

    test("answers a form body for a map of strings", () {
      expect(
        BodyFormatUtility.tryToGuessBodyType(<String, String>{"a": "b"}),
        HttpBodyTypes.mapStringString,
      );
    });

    test("answers a json body for a map of values", () {
      expect(
        BodyFormatUtility.tryToGuessBodyType(<String, dynamic>{"a": 1}),
        HttpBodyTypes.json,
      );
    });

    test("answers a file body for a file", () {
      expect(
        BodyFormatUtility.tryToGuessBodyType(MultipartFile.fromString("a file", "content")),
        HttpBodyTypes.files,
      );
    });

    test("answers a file body for a list of files, which json would also accept", () {
      expect(
        BodyFormatUtility.tryToGuessBodyType([
          MultipartFile.fromString("a file", "content"),
          MultipartFile.fromString("another file", "content"),
        ]),
        HttpBodyTypes.files,
      );
    });

    test("answers a json body for an empty list, which carries no file to send", () {
      expect(BodyFormatUtility.tryToGuessBodyType(<dynamic>[]), HttpBodyTypes.json);
    });

    test("answers a binary body for a list of numbers, which json would also accept", () {
      expect(BodyFormatUtility.tryToGuessBodyType([1, 2]), HttpBodyTypes.binary);
    });

    test("answers nothing for a body of a type no MIME type carries", () {
      expect(BodyFormatUtility.tryToGuessBodyType(42), isNull);
    });
  });

  group("BodyFormatUtility.formatRequest", () {
    test("sends the body of a request which has no MIME type as the guessed one", () {
      final request = formatRequest(body: <String, dynamic>{"name": "a name"})! as Request;

      expect(
        request.headers[HeaderConstants.contentTypeHeaderKey],
        "application/json; charset=utf-8",
      );
      expect(request.body, '{"name":"a name"}');
    });

    test("keeps the MIME type the request already carries in its headers", () {
      final request = formatRequest(
        body: "a body",
        headers: {HeaderConstants.contentTypeHeaderKey: "text/csv"},
      )!;

      expect(request.headers[HeaderConstants.contentTypeHeaderKey], "text/csv");
    });

    test("sends the headers of the request", () {
      final request = formatRequest(body: "a body", headers: {"X-Token": "a token"})!;

      expect(request.headers["X-Token"], "a token");
    });

    test("sends the method and the URL of the request", () {
      final request = formatRequest(body: "a body")!;

      expect(request.method, "POST");
      expect(request.url, _url);
    });

    test("announces no MIME type for a request which carries no body", () {
      final request = formatRequest()!;

      expect(request.headers.containsKey(HeaderConstants.contentTypeHeaderKey), isFalse);
      expect(request.contentLength, 0);
    });

    test("sends a text body as it is", () {
      final request = formatRequest(body: "a body")! as Request;

      expect(request.headers[HeaderConstants.contentTypeHeaderKey], "text/plain; charset=utf-8");
      expect(request.body, "a body");
    });

    test("sends the fields of a form body", () {
      final request = formatRequest(body: <String, String>{"name": "a name"})! as Request;

      expect(
        request.headers[HeaderConstants.contentTypeHeaderKey],
        startsWith("application/x-www-form-urlencoded"),
      );
      expect(request.bodyFields, {"name": "a name"});
    });

    test("sends the bytes of a binary body", () {
      final request = formatRequest(body: Uint8List.fromList([1, 2, 3]))! as Request;

      expect(request.headers[HeaderConstants.contentTypeHeaderKey], "application/octet-stream");
      expect(request.bodyBytes, [1, 2, 3]);
    });

    test("turns a list of bytes into the bytes of a binary body", () {
      final request = formatRequest(
        body: [1, 2, 3],
        requestMimeType: HttpMimeTypes.gzip,
      )! as Request;

      expect(request.bodyBytes, [1, 2, 3]);
    });

    test("sends a file as the only part of a multipart request", () {
      final request =
          formatRequest(body: MultipartFile.fromString("a file", "content"))! as MultipartRequest;

      expect(request.files.map((file) => file.field), ["a file"]);
    });

    test("sends every file of a list as a part of a multipart request", () {
      final request =
          formatRequest(
                body: [
                  MultipartFile.fromString("a file", "content"),
                  MultipartFile.fromString("another file", "content"),
                ],
              )!
              as MultipartRequest;

      expect(request.files.map((file) => file.field), ["a file", "another file"]);
    });

    test("sends a json body which is already written as a string as it is", () {
      final request =
          formatRequest(body: '{"name":"a name"}', requestMimeType: HttpMimeTypes.json)! as Request;

      expect(request.body, '{"name":"a name"}');
    });

    test("sends nothing for a request whose MIME type says it carries no body", () {
      final request = formatRequest(body: "a body", requestMimeType: HttpMimeTypes.empty)!;

      expect(request.contentLength, 0);
    });

    test("refuses a body of a type no MIME type carries", () {
      expect(formatRequest(body: 42), isNull);
      expect(warnings().single, contains("can't guess the body type"));
    });

    test("refuses a body which is not what the MIME type of the request announces", () {
      expect(formatRequest(body: "a body", requestMimeType: HttpMimeTypes.formUrlEncoded), isNull);
      expect(warnings().single, contains("Map<String, String>"));
    });

    test("refuses files which are not files", () {
      expect(
        formatRequest(body: ["a file"], requestMimeType: HttpMimeTypes.multipartFormData),
        isNull,
      );
      expect(warnings().single, contains("MultipartFile"));
    });

    test("refuses bytes which are not bytes", () {
      expect(
        formatRequest(body: "a body", requestMimeType: HttpMimeTypes.applicationOctetStream),
        isNull,
      );
      expect(warnings().single, contains("Uint8List"));
    });

    test("refuses a json body which is written as a string the server could not read", () {
      expect(formatRequest(body: "not json", requestMimeType: HttpMimeTypes.json), isNull);
      expect(warnings().single, contains("valid JSON String"));
    });

    test("refuses a json body which cannot be encoded", () {
      expect(
        formatRequest(body: <String, dynamic>{"date": DateTime(2026)}, requestMimeType: HttpMimeTypes.json),
        isNull,
      );
      expect(warnings().single, contains("error when encoding"));
    });
  });

  group("BodyFormatUtility.formatResponse", () {
    test("answers a success for a server which answered nothing", () {
      final response = formatResponse<String, String>();

      expect(response.status, RequestStatus.success);
      expect(response.castedBody, isNull);
    });

    test("keeps the answer of the server, whatever it says", () {
      final response = formatResponse<String, String>(body: "a body", statusCode: 500);

      expect(response.response?.statusCode, 500);
    });

    test("answers a login error for a server which refused the credentials", () {
      final response = formatResponse<String, String>(statusCode: 401);

      expect(response.status, RequestStatus.loginError);
    });

    test("answers an error for a server which answered anything else than a success", () {
      final response = formatResponse<String, String>(statusCode: 404);

      expect(response.status, RequestStatus.globalError);
    });

    test("answers an error for a status a server sends before answering", () {
      final response = formatResponse<String, String>(statusCode: 100);

      expect(response.status, RequestStatus.globalError);
    });

    test("reads a json body the request expected", () {
      final response = formatResponse<Map<String, dynamic>, Map<String, dynamic>>(
        body: '{"name":"a name"}',
        contentType: "application/json",
        expectedMimeType: HttpMimeTypes.json,
      );

      expect(response.status, RequestStatus.success);
      expect(response.castedBody, {"name": "a name"});
    });

    test("reads the fields of a form body the request expected", () {
      final response = formatResponse<Map<String, String>, Map<String, String>>(
        body: "name=a+name",
        contentType: "application/x-www-form-urlencoded",
        expectedMimeType: HttpMimeTypes.formUrlEncoded,
      );

      expect(response.castedBody, {"name": "a name"});
    });

    test("reads a text body the request expected", () {
      final response = formatResponse<String, String>(
        body: "a body",
        contentType: "text/plain",
        expectedMimeType: HttpMimeTypes.plainText,
      );

      expect(response.castedBody, "a body");
    });

    test("reads the bytes of a binary body the request expected", () {
      final response = formatResponse<Uint8List, Uint8List>(
        body: "abc",
        contentType: "application/octet-stream",
        expectedMimeType: HttpMimeTypes.applicationOctetStream,
      );

      expect(response.castedBody, utf8.encode("abc"));
    });

    test("builds the value the request parses the body into", () {
      final response = formatResponse<String, Map<String, dynamic>>(
        body: '{"name":"a name"}',
        contentType: "application/json",
        expectedMimeType: HttpMimeTypes.json,
        parseRespBody: (body) => body["name"] as String,
      );

      expect(response.castedBody, "a name");
    });

    test("reads nothing from a server which announced no MIME type", () {
      final response = formatResponse<Map<String, dynamic>, Map<String, dynamic>>(
        body: '{"name":"a name"}',
        expectedMimeType: HttpMimeTypes.json,
      );

      expect(response.status, RequestStatus.success);
      expect(response.castedBody, isNull);
    });

    test("answers an error for a body which is not what the request expected", () {
      final response = formatResponse<Map<String, dynamic>, Map<String, dynamic>>(
        body: "not json",
        contentType: "application/json",
        expectedMimeType: HttpMimeTypes.json,
      );

      expect(response.status, RequestStatus.globalError);
      expect(warnings().first, contains("error occurred when tried to parse the body"));
    });

    test("answers an error for a body which is not of the type the request asked for", () {
      final response = formatResponse<int, Map<String, dynamic>>(
        body: '{"name":"a name"}',
        contentType: "application/json",
        expectedMimeType: HttpMimeTypes.json,
      );

      expect(response.status, RequestStatus.globalError);
      expect(response.castedBody, isNull);
      expect(warnings().single, contains("hasn't the same type as the parsed body"));
    });
  });
}
