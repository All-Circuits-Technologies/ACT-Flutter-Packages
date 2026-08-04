// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'dart:io';

import 'package:act_aws_iot_core/act_aws_iot_core.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group("ShadowErrorCode.fromCode", () {
    test("reads the code of a request the server turned down", () {
      expect(ShadowErrorCode.fromCode(HttpStatus.notFound), ShadowErrorCode.notFound);
    });

    test("reads the code of a request which went through", () {
      expect(ShadowErrorCode.fromCode(HttpStatus.ok), ShadowErrorCode.ok);
    });

    test("says nothing of a code it does not know", () {
      // 418 is not one of the codes the shadows service of the server answers with
      expect(ShadowErrorCode.fromCode(418), isNull);
    });

    test("knows one code per error the shadows service answers", () {
      final codes = ShadowErrorCode.values.map((value) => value.code);

      expect(codes.toSet().length, ShadowErrorCode.values.length);
    });
  });
}
