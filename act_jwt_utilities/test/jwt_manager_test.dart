// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_jwt_utilities/act_jwt_utilities.dart';
import 'package:act_logger_manager/act_logger_manager.dart';
import 'package:act_test_utility/act_test_utility.dart';
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fakes/fake_jwt_handler.dart';

void main() {
  late FakeExternalLogger logs;
  late JwtManager manager;

  setUp(() async {
    FakeGlobalManager.install();
    logs = FakeExternalLogger();
    manager = JwtManager();
    await manager.initLifeCycle();
  });

  /// Builds a handler which owns the keys given.
  FakeJwtHandler aHandler({JWTKey? privateKey, JWTKey? publicKey, bool initResult = true}) =>
      FakeJwtHandler(
        name: "aHandler",
        logsHelper: logs.buildHelper(category: "jwt"),
        privateKey: privateKey,
        publicKey: publicKey,
        initResult: initResult,
      );

  group("JwtBuilder", () {
    test("depends on the logger manager", () {
      expect(JwtBuilder().dependsOn(), [LoggerManager]);
    });

    test("builds a JWT manager", () {
      expect(JwtBuilder().factory(), isA<JwtManager>());
    });
  });

  group("JwtManager.addAndInitJwtHandler", () {
    test("initializes the handler it is given", () async {
      final handler = aHandler(privateKey: aKey, publicKey: aKey);

      await manager.addAndInitJwtHandler(handler);

      expect(handler.initCount, 1);
    });

    test("accepts a handler which signs and verifies its own token", () async {
      expect(
        await manager.addAndInitJwtHandler(aHandler(privateKey: aKey, publicKey: aKey)),
        isTrue,
      );
    });

    test("refuses a handler whose initialization fails", () async {
      expect(
        await manager.addAndInitJwtHandler(
          aHandler(privateKey: aKey, publicKey: aKey, initResult: false),
        ),
        isFalse,
      );
    });

    test("accepts a handler which owns neither of the keys", () async {
      // Such a handler can neither sign nor verify, so there is nothing to test on it
      expect(await manager.addAndInitJwtHandler(aHandler()), isTrue);
    });

    test("accepts a handler which can only verify", () async {
      expect(await manager.addAndInitJwtHandler(aHandler(publicKey: aKey)), isTrue);
    });
  });
}
