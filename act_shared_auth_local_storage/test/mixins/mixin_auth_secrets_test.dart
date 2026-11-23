// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:flutter_test/flutter_test.dart';

import '../fakes/fake_auth_storage_app.dart';

void main() {
  group("MixinAuthSecrets", () {
    test("ends the streams of the tokens and of the ids once the secrets are disposed", () async {
      final properties = FakeAuthProperties();
      final config = FakeAuthConfig();
      final secrets = FakeAuthSecrets(propertiesGetter: () => properties, confGetter: () => config);
      final ended = Future.wait([
        expectLater(secrets.authTokens.updateStream, emitsDone),
        expectLater(secrets.authIds.updateStream, emitsDone),
      ]);

      await secrets.disposeLifeCycle();

      await ended;
    });
  });
}
