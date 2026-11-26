// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_thingsboard_client/act_thingsboard_client.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:thingsboard_client/thingsboard_client.dart';

void main() {
  group("TbTsValue.fromTsValue", () {
    test("holds the timestamp and the value the server sent", () {
      final value = TbTsValue.fromTsValue(TsValue(ts: 42, value: "a value"));

      expect(value.ts, 42);
      expect(value.value, "a value");
    });

    test("holds no value when the server sent none", () {
      final value = TbTsValue.fromTsValue(TsValue(ts: 42));

      expect(value.value, isNull);
    });
  });

  group("TbTsValue", () {
    test("is the same as a value which holds the same timestamp and value", () {
      expect(const TbTsValue(ts: 42, value: "a value"), const TbTsValue(ts: 42, value: "a value"));
    });

    test("is not the same as a value which holds another timestamp", () {
      expect(
        const TbTsValue(ts: 42, value: "a value"),
        isNot(const TbTsValue(ts: 43, value: "a value")),
      );
    });

    test("is not the same as a value which holds another value", () {
      expect(
        const TbTsValue(ts: 42, value: "a value"),
        isNot(const TbTsValue(ts: 42, value: "another value")),
      );
    });
  });
}
