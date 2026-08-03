// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'dart:convert';

import 'package:act_amplify_api/act_amplify_api.dart';
import 'package:act_foundation/act_foundation.dart';
import 'package:act_http_core/act_http_core.dart';
import 'package:act_test_utility/act_test_utility.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late FakeLogger logger;

  setUp(() {
    logger = FakeLogger();
    FakeGlobalManager.install(logger: logger);
  });

  group("HttpResponseUtility.tryDecodeBody", () {
    test("reads the body the server answered with", () {
      final response = AWSHttpResponse(statusCode: 200, body: utf8.encode("a body"));

      expect(HttpResponseUtility.tryDecodeBody(response), "a body");
    });

    test("reads the body with the encoding it is given", () {
      final response = AWSHttpResponse(statusCode: 200, body: latin1.encode("a bódy"));

      expect(HttpResponseUtility.tryDecodeBody(response, encoding: latin1), "a bódy");
    });

    test("reads nothing when the body is not the text the encoding expects", () {
      final response = AWSHttpResponse(statusCode: 200, body: const [0xC3]);

      expect(HttpResponseUtility.tryDecodeBody(response), isNull);
    });

    test("warns when the body cannot be read", () {
      final response = AWSHttpResponse(statusCode: 200, body: const [0xC3]);

      HttpResponseUtility.tryDecodeBody(response);

      expect(logger.recordsAtLevel(LogsLevel.warn), hasLength(1));
    });
  });

  group("HttpResponseUtility.getStatus", () {
    test("names the status the server answered with", () {
      final response = AWSHttpResponse(statusCode: 404, body: const []);

      expect(HttpResponseUtility.getStatus(response), ServerResponseStatus.notFound);
    });

    test("falls back to the family of a status it does not name", () {
      final response = AWSHttpResponse(statusCode: 418, body: const []);

      expect(HttpResponseUtility.getStatus(response), ServerResponseStatus.genericClientError);
    });
  });
}
