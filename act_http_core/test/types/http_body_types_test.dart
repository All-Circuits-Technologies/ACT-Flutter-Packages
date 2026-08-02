// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_http_core/act_http_core.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group("HttpBodyTypes", () {
    test("tells the absence of a body from the other kinds", () {
      expect(HttpBodyTypes.values.first, HttpBodyTypes.none);
    });

    test("names every shape a body can take", () {
      expect(HttpBodyTypes.values, [
        HttpBodyTypes.none,
        HttpBodyTypes.string,
        HttpBodyTypes.binary,
        HttpBodyTypes.mapStringString,
        HttpBodyTypes.json,
        HttpBodyTypes.files,
      ]);
    });
  });
}
