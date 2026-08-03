// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_http_client_manager/act_http_client_manager.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group("RequestResponse.toPatterns", () {
    test("gives back the status, the answer of the server and the parsed body", () {
      final serverResponse = Response("a body", 200);
      final response = RequestResponse<String>(
        status: RequestStatus.success,
        response: serverResponse,
        castedBody: "a body",
      );

      final (status, received, body) = response.toPatterns();

      expect(status, RequestStatus.success);
      expect(received, serverResponse);
      expect(body, "a body");
    });

    test("gives back nothing but the status of a request which never reached the server", () {
      const response = RequestResponse<String>(status: RequestStatus.timeoutError);

      final (status, received, body) = response.toPatterns();

      expect(status, RequestStatus.timeoutError);
      expect(received, isNull);
      expect(body, isNull);
    });
  });
}
