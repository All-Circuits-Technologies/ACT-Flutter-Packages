// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_http_client_manager/act_http_client_manager.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group("RequestStatus.isOk", () {
    test("says that a request which succeeded is the only one which is ok", () {
      expect(
        RequestStatus.values.where((status) => status.isOk),
        [RequestStatus.success],
      );
    });
  });
}
