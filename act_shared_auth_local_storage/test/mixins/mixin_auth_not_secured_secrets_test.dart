// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:flutter_test/flutter_test.dart';

import '../fakes/fake_auth_storage_app.dart';

void main() {
  group("MixinAuthNotSecuredSecrets", () {
    test("ends the stream of the tokens once the properties are disposed", () async {
      final properties = FakeAuthProperties();
      final ended = expectLater(properties.authTokens.updateStream, emitsDone);

      await properties.disposeLifeCycle();

      await ended;
    });
  });
}
