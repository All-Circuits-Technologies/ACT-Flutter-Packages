// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_http_client_manager/act_http_client_manager.dart';
import 'package:act_thingsboard_client/act_thingsboard_client.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group("TbRequestResponse.isOk", () {
    test("says that a response the server answered is ok", () {
      const response = TbRequestResponse<int>(status: RequestStatus.success, requestResponse: 1);

      expect(response.isOk, isTrue);
    });

    test("says that a response which failed is not ok", () {
      const response = TbRequestResponse<int>(status: RequestStatus.loginError);

      expect(response.isOk, isFalse);
    });

    test("says that a response the server answered nothing to is ok", () {
      const response = TbRequestResponse<int>(status: RequestStatus.success);

      expect(response.isOk, isTrue);
      expect(response.requestResponse, isNull);
    });
  });

  group("TbRequestResponse.toPatterns", () {
    test("gives back the status and what the server answered", () {
      const response = TbRequestResponse<String>(
        status: RequestStatus.success,
        requestResponse: "an answer",
      );

      expect(response.toPatterns(), (RequestStatus.success, "an answer"));
    });
  });

  group("TbRequestResponse", () {
    test("is the same as a response which holds the same status and answer", () {
      const response = TbRequestResponse<int>(status: RequestStatus.success, requestResponse: 1);

      expect(response, const TbRequestResponse<int>(status: RequestStatus.success, requestResponse: 1));
    });

    test("is not the same as a response which holds another status", () {
      const response = TbRequestResponse<int>(status: RequestStatus.success, requestResponse: 1);

      expect(
        response,
        isNot(const TbRequestResponse<int>(status: RequestStatus.globalError, requestResponse: 1)),
      );
    });

    test("is not the same as a response which holds another answer", () {
      const response = TbRequestResponse<int>(status: RequestStatus.success, requestResponse: 1);

      expect(
        response,
        isNot(const TbRequestResponse<int>(status: RequestStatus.success, requestResponse: 2)),
      );
    });
  });
}
