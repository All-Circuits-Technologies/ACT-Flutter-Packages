// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_http_core/act_http_core.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group("HeaderConstants separators", () {
    test("adds a space to the separator of the values", () {
      expect(
        HeaderConstants.headerValueSeparator,
        "${HeaderConstants.headerValueSeparatorChar} ",
      );
    });
  });

  group("HeaderConstants authentication values", () {
    test("builds the bearer value from its key and its placeholder", () {
      expect(HeaderConstants.authBearer, "Bearer {token}");
      expect(HeaderConstants.authLowBearer, "bearer {token}");
    });

    test("builds the basic value from its key and its placeholder", () {
      expect(HeaderConstants.authBasic, "Basic {creds}");
    });

    test("holds the placeholder the credentials replace", () {
      expect(
        HeaderConstants.authBasic.contains(HeaderConstants.credsBasicKey),
        isTrue,
      );
      expect(
        HeaderConstants.authBearer.contains(HeaderConstants.tokenBearerKey),
        isTrue,
      );
    });
  });
}
