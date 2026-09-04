// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_jwt_utilities/act_jwt_utilities.dart';
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';

/// The key the handlers of the tests sign and verify with.
final aKey = SecretKey("a secret which is long enough for the algorithm");

/// Another key, which no handler of the tests signs with.
final anotherKey = SecretKey("another secret which is long enough too");

/// The options a handler is given unless the test asks for others.
final defaultOptions = JwtOptions(
  algorithm: JWTAlgorithm.HS256,
  audience: Audience.one("an audience"),
  issuer: "an issuer",
  subject: "a subject",
  expirationTime: const Duration(hours: 1),
);

/// A handler of the kind of JWT a test asks for.
class FakeJwtHandler extends AbstractJwtHandler {
  /// The key the handler signs with, if it has one.
  final JWTKey? privateKey;

  /// The key the handler verifies with, if it has one.
  final JWTKey? publicKey;

  /// The options the handler reads its claims from.
  final JwtOptions options;

  /// What the implementation of the initialization answers.
  final bool initResult;

  /// The number of times the handler has been initialized.
  int initCount = 0;

  /// Class constructor
  FakeJwtHandler({
    required super.name,
    required super.logsHelper,
    this.privateKey,
    this.publicKey,
    JwtOptions? options,
    this.initResult = true,
  }) : options = options ?? defaultOptions;

  /// {@macro act_jwt_utilities.AbstractJwtHandler.initHandlerImpl}
  @override
  Future<bool> initHandlerImpl() async {
    initCount++;
    await initKeys(publicKey: publicKey, privateKey: privateKey);

    return initResult;
  }

  /// {@macro act_jwt_utilities.AbstractJwtHandler.getJwtOptions}
  @override
  Future<JwtOptions> getJwtOptions() async => options;

  /// {@macro act_jwt_utilities.AbstractJwtHandler.testSignAndVerify}
  @override
  Future<bool> testSignAndVerify() => testSignAndVerifyImpl(const {"aClaim": "a value"});
}
