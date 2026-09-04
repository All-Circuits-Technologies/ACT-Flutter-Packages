// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_foundation/act_foundation.dart';
import 'package:act_jwt_utilities/act_jwt_utilities.dart';
import 'package:act_test_utility/act_test_utility.dart';
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fakes/fake_jwt_handler.dart';

void main() {
  late FakeExternalLogger logs;

  setUp(() => logs = FakeExternalLogger());

  /// Builds a handler which owns the keys given, and initializes it.
  Future<FakeJwtHandler> aHandler({
    JWTKey? privateKey,
    JWTKey? publicKey,
    JwtOptions? options,
  }) async {
    final handler = FakeJwtHandler(
      name: "aHandler",
      logsHelper: logs.buildHelper(category: "jwt"),
      privateKey: privateKey,
      publicKey: publicKey,
      options: options,
    );
    await handler.initHandler();

    return handler;
  }

  group("AbstractJwtHandler.initHandler", () {
    test("returns what the implementation answers", () async {
      final handler = FakeJwtHandler(
        name: "aHandler",
        logsHelper: logs.buildHelper(),
        initResult: false,
      );

      expect(await handler.initHandler(), isFalse);
    });

    test("initializes the implementation once", () async {
      final handler = await aHandler();

      expect(handler.initCount, 1);
    });
  });

  group("AbstractJwtHandler.canSignAndVerify", () {
    test("returns true when the handler owns both keys", () async {
      final handler = await aHandler(privateKey: aKey, publicKey: aKey);

      expect(handler.canSignAndVerify, isTrue);
    });

    test("returns false when the handler cannot sign", () async {
      final handler = await aHandler(publicKey: aKey);

      expect(handler.canSignAndVerify, isFalse);
    });

    test("returns false when the handler cannot verify", () async {
      final handler = await aHandler(privateKey: aKey);

      expect(handler.canSignAndVerify, isFalse);
    });
  });

  group("AbstractJwtHandler.signImpl", () {
    test("returns a token which carries the payload", () async {
      final handler = await aHandler(privateKey: aKey, publicKey: aKey);

      final result = await handler.signImpl({"aClaim": "a value"});

      final payload = JWT.decode(result!.jwt).payload as Map<String, dynamic>;
      expect(payload["aClaim"], "a value");
    });

    test("returns the expiration time of the options of the handler", () async {
      final handler = await aHandler(privateKey: aKey, publicKey: aKey);

      final result = await handler.signImpl(const {});

      expect(result?.expirationTime, defaultOptions.expirationTime);
    });

    test("writes the claims of the options in the token", () async {
      final handler = await aHandler(privateKey: aKey, publicKey: aKey);

      final result = await handler.signImpl(const {});

      final jwt = JWT.decode(result!.jwt);
      expect(jwt.issuer, defaultOptions.issuer);
      expect(jwt.subject, defaultOptions.subject);
    });

    test("writes the identifier of the token when the caller gives one", () async {
      final handler = await aHandler(privateKey: aKey, publicKey: aKey);

      final result = await handler.signImpl(const {}, jwtId: "anId");

      expect(JWT.decode(result!.jwt).jwtId, "anId");
    });

    test("returns null when the handler has no key to sign with", () async {
      final handler = await aHandler(publicKey: aKey);

      expect(await handler.signImpl(const {}), isNull);
    });

    test("warns when the handler has no key to sign with", () async {
      final handler = await aHandler(publicKey: aKey);

      await handler.signImpl(const {});

      expect(logs.recordsAtLevel(LogsLevel.warn).length, 1);
    });

    test("returns null when the options carry no expiration time", () async {
      final handler = await aHandler(
        privateKey: aKey,
        publicKey: aKey,
        options: JwtOptions(
          algorithm: JWTAlgorithm.HS256,
          audience: Audience.one("an audience"),
          issuer: "an issuer",
        ),
      );

      expect(await handler.signImpl(const {}), isNull);
    });

    test("returns null when the options carry no issuer", () async {
      final handler = await aHandler(
        privateKey: aKey,
        publicKey: aKey,
        options: JwtOptions(
          algorithm: JWTAlgorithm.HS256,
          audience: Audience.one("an audience"),
          expirationTime: const Duration(hours: 1),
        ),
      );

      expect(await handler.signImpl(const {}), isNull);
    });

    test("returns null when the options carry no audience", () async {
      final handler = await aHandler(
        privateKey: aKey,
        publicKey: aKey,
        options: const JwtOptions(
          algorithm: JWTAlgorithm.HS256,
          issuer: "an issuer",
          expirationTime: Duration(hours: 1),
        ),
      );

      expect(await handler.signImpl(const {}), isNull);
    });
  });

  group("AbstractJwtHandler.verify", () {
    test("returns the token it has signed itself", () async {
      final handler = await aHandler(privateKey: aKey, publicKey: aKey);
      final signed = await handler.signImpl({"aClaim": "a value"});

      final jwt = await handler.verify(token: signed!.jwt);

      expect((jwt?.payload as Map?)?["aClaim"], "a value");
    });

    test("returns null for a token signed with another key", () async {
      final signer = await aHandler(privateKey: anotherKey, publicKey: anotherKey);
      final signed = await signer.signImpl(const {});
      final handler = await aHandler(privateKey: aKey, publicKey: aKey);

      expect(await handler.verify(token: signed!.jwt), isNull);
    });

    test("returns null for a string which is not a token", () async {
      final handler = await aHandler(privateKey: aKey, publicKey: aKey);

      expect(await handler.verify(token: "not a token"), isNull);
    });

    test("returns null when the handler has no key to verify with", () async {
      final handler = await aHandler(privateKey: aKey);
      final signed = await handler.signImpl(const {});

      expect(await handler.verify(token: signed!.jwt), isNull);
    });

    test("warns when the handler has no key to verify with", () async {
      final handler = await aHandler(privateKey: aKey);

      await handler.verify(token: "aToken");

      expect(logs.recordsAtLevel(LogsLevel.warn).length, 1);
    });
  });

  group("AbstractJwtHandler.decode", () {
    test("returns the token without verifying its signature", () async {
      final signer = await aHandler(privateKey: anotherKey, publicKey: anotherKey);
      final signed = await signer.signImpl({"aClaim": "a value"});
      final handler = await aHandler(privateKey: aKey, publicKey: aKey);

      final jwt = await handler.decode(token: signed!.jwt);

      expect((jwt?.payload as Map?)?["aClaim"], "a value");
    });

    test("returns null for a string which is not a token", () async {
      final handler = await aHandler(privateKey: aKey, publicKey: aKey);

      expect(await handler.decode(token: "not a token"), isNull);
    });
  });

  group("AbstractJwtHandler.testSignAndVerifyImpl", () {
    test("returns true when the handler signs and verifies its own token", () async {
      final handler = await aHandler(privateKey: aKey, publicKey: aKey);

      expect(await handler.testSignAndVerify(), isTrue);
    });

    test("returns false when the handler cannot sign", () async {
      final handler = await aHandler(publicKey: aKey);

      expect(await handler.testSignAndVerify(), isFalse);
    });

    test("returns false when the handler cannot verify", () async {
      final handler = await aHandler(privateKey: aKey);

      expect(await handler.testSignAndVerify(), isFalse);
    });

    test("warns about the step which failed", () async {
      final handler = await aHandler(privateKey: aKey);

      await handler.testSignAndVerify();

      // One warning for the missing key, one for the step of the test which failed
      expect(logs.recordsAtLevel(LogsLevel.warn).length, 2);
    });
  });
}
