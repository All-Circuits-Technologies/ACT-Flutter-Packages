// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_thingsboard_client/act_thingsboard_client.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fakes/fake_thingsboard.dart';

void main() {
  group("TbExtAttributeData", () {
    test("is the same as an attribute of the same scope which holds the same value", () {
      final attribute = TbExtAttributeData(
        data: anAttribute(key: "a key", ts: 42, value: "a value"),
        scope: AttributeScope.SHARED_SCOPE,
      );

      expect(
        attribute,
        TbExtAttributeData(
          data: anAttribute(key: "a key", ts: 42, value: "a value"),
          scope: AttributeScope.SHARED_SCOPE,
        ),
      );
    });

    test("is not the same as the same attribute read in another scope", () {
      final attribute = TbExtAttributeData(
        data: anAttribute(key: "a key", ts: 42, value: "a value"),
        scope: AttributeScope.SHARED_SCOPE,
      );

      expect(
        attribute,
        isNot(
          TbExtAttributeData(
            data: anAttribute(key: "a key", ts: 42, value: "a value"),
            scope: AttributeScope.CLIENT_SCOPE,
          ),
        ),
      );
    });

    test("is not the same as an attribute which was updated later", () {
      final attribute = TbExtAttributeData(
        data: anAttribute(key: "a key", ts: 42, value: "a value"),
        scope: AttributeScope.SHARED_SCOPE,
      );

      expect(
        attribute,
        isNot(
          TbExtAttributeData(
            data: anAttribute(key: "a key", ts: 43, value: "a value"),
            scope: AttributeScope.SHARED_SCOPE,
          ),
        ),
      );
    });

    test("is not the same as an attribute of another key", () {
      final attribute = TbExtAttributeData(
        data: anAttribute(key: "a key", ts: 42, value: "a value"),
        scope: AttributeScope.SHARED_SCOPE,
      );

      expect(
        attribute,
        isNot(
          TbExtAttributeData(
            data: anAttribute(key: "another key", ts: 42, value: "a value"),
            scope: AttributeScope.SHARED_SCOPE,
          ),
        ),
      );
    });
  });
}
