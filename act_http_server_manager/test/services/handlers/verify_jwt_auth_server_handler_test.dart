// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_http_core/act_http_core.dart';
import 'package:act_http_server_manager/act_http_server_manager.dart';
import 'package:act_test_utility/act_test_utility.dart';
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../fakes/fake_server.dart';

/// The key the server signs and verifies the tokens with.
final _key = SecretKey("a secret which is long enough for the algorithm");

/// A key the server knows nothing about.
final _anotherKey = SecretKey("another secret which is long enough too");

void main() {
  late FakeHttpLogging logging;
  late FakeExternalLogger logs;
  late VerifyJwtAuthServerHandler handler;
  late FakeJwtHandler jwtHandler;

  setUp(() async {
    FakeGlobalManager.install();
    logging = FakeHttpLogging();
    await logging.initLifeCycle();
    logs = FakeExternalLogger();
    jwtHandler = FakeJwtHandler(
      logsHelper: logs.buildHelper(category: "jwt"),
      key: _key,
    );
    await jwtHandler.initHandler();
    handler = VerifyJwtAuthServerHandler(httpLoggingManager: logging, jwtHandler: jwtHandler);
  });

  /// The request the tests send to the server, with the [authorization] header when it has one.
  Request aRequest({String? authorization}) => Request(
    "GET",
    Uri.parse("http://a.host/api/item"),
    headers: authorization == null ? null : {HeaderConstants.authorizationHeaderKey: authorization},
  );

  /// A request which carries a token the server signed.
  Future<Request> aSignedRequest() async {
    final signed = await jwtHandler.signToken(const {"aClaim": "a value"});

    return aRequest(authorization: "${HeaderConstants.authBearerKey} ${signed!.jwt}");
  }

  group("VerifyJwtAuthServerHandler.beforeHandler", () {
    test("turns away a request which carries no authentication", () async {
      final result = await handler.beforeHandler(request: aRequest());

      expect(result.forceResponse?.statusCode, 401);
    });

    test("writes why it turned away a request which carries no authentication", () async {
      await handler.beforeHandler(request: aRequest());

      expect(logging.messages, hasLength(1));
    });

    test("turns away a request whose authentication carries no bearer", () async {
      final result = await handler.beforeHandler(request: aRequest(authorization: "a token"));

      expect(result.forceResponse?.statusCode, 401);
    });

    test("turns away a request whose token the server did not sign", () async {
      final signed = JWT(const {"aClaim": "a value"}).sign(_anotherKey);

      final result = await handler.beforeHandler(
        request: aRequest(authorization: "${HeaderConstants.authBearerKey} $signed"),
      );

      expect(result.forceResponse?.statusCode, 401);
    });

    test("lets a request which carries a token the server signed through", () async {
      final result = await handler.beforeHandler(request: await aSignedRequest());

      expect(result.forceResponse, isNull);
      expect(result.overrideRequest, isNotNull);
    });

    test("hands the route the token it read", () async {
      final result = await handler.beforeHandler(request: await aSignedRequest());

      final jwt = VerifyJwtAuthServerHandler.extractJwt(result.overrideRequest!);
      expect((jwt.payload as Map?)?["aClaim"], "a value");
    });

    test("reads the token from the header the server was told to read", () async {
      final other = VerifyJwtAuthServerHandler(
        httpLoggingManager: logging,
        jwtHandler: jwtHandler,
        headerKey: "X-Token",
      );
      final signed = await jwtHandler.signToken(const {"aClaim": "a value"});

      final result = await other.beforeHandler(
        request: Request(
          "GET",
          Uri.parse("http://a.host/api/item"),
          headers: {"X-Token": "${HeaderConstants.authBearerKey} ${signed!.jwt}"},
        ),
      );

      expect(result.forceResponse, isNull);
    });
  });

  group("VerifyJwtAuthServerHandler.afterHandler", () {
    test("lets the response of the route through as it is", () async {
      final response = Response.ok("from the route");

      final answered = await handler.afterHandler(request: aRequest(), response: response);

      expect(answered, response);
    });
  });

  group("VerifyJwtAuthServerHandler.tryToExtractJwt", () {
    test("reads the token the handler put in the request", () async {
      final result = await handler.beforeHandler(request: await aSignedRequest());

      expect(VerifyJwtAuthServerHandler.tryToExtractJwt(result.overrideRequest!), isNotNull);
    });

    test("reads nothing from a request which went through no handler", () {
      expect(VerifyJwtAuthServerHandler.tryToExtractJwt(aRequest()), isNull);
    });
  });
}
