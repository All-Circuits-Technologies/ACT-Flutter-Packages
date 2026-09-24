// SPDX-FileCopyrightText: 2026 Dorian Benech <dorian.benech@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_tb_extender_auth/act_tb_extender_auth.dart';
import 'package:act_test_utility/act_test_utility.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fakes/fake_tb_extender_app.dart';

void main() {
  setUpAll(FakeGlobalManager.install);

  group("BrokerUser.tryFromTbToken", () {
    test("reads the user a ThingsBoard token names", () {
      final token = fakeJwt({
        "sub": "ada@example.test",
        "userId": "user-id",
        "customerId": "customer-id",
        "firstName": "Ada",
      });

      expect(
        BrokerUser.tryFromTbToken(token),
        const BrokerUser(
          tbUserId: "user-id",
          customerId: "customer-id",
          email: "ada@example.test",
          firstName: "Ada",
        ),
      );
    });

    test("reads nobody out of a token which misses the user", () {
      expect(BrokerUser.tryFromTbToken(fakeJwt({"sub": "ada@example.test"})), isNull);
    });

    test("reads nobody out of a token which isn't a JWT", () {
      expect(BrokerUser.tryFromTbToken("tb-access"), isNull);
    });
  });
}
