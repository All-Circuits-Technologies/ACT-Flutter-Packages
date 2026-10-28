// SPDX-FileCopyrightText: 2026 Dorian Benech <dorian.benech@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'dart:async';
import 'dart:convert';

import 'package:act_foundation/act_foundation.dart';
import 'package:act_tb_extender_client/act_tb_extender_client.dart';
import 'package:act_test_utility/act_test_utility.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

/// The base URL the broker of the tests is served at.
const _baseUrl = "https://broker.example.test";

/// The URL the login endpoint of that broker is reached at.
const _loginUri = "$_baseUrl/api/v1/auth/login";

/// The URL the account endpoint of that broker is reached at.
const _accountUri = "$_baseUrl/api/v1/account";

/// The URL the terms endpoint of that broker is reached at.
const _termsUri = "$_baseUrl/api/v1/terms/accept";

/// The URL the release endpoint of that broker is reached at, for the serial "AB 12".
const _releaseUri = "$_baseUrl/api/v1/devices/AB%2012/release";

/// The URL the claim endpoint of that broker is reached at, for the serial "AB 12".
const _claimUri = "$_baseUrl/api/v1/devices/AB%2012/claim";

/// A success payload which follows the contract of tb-extender.
Map<String, dynamic> _successBody() => {
  "tbToken": "tb-access-jwt",
  "tbRefreshToken": "tb-refresh-jwt",
  "expiresIn": 3600,
  "user": {
    "tbUserId": "11111111-1111-1111-1111-111111111111",
    "customerId": "22222222-2222-2222-2222-222222222222",
    "email": "user@example.test",
    "firstName": "Ada",
    "lastName": "Lovelace",
  },
};

/// The headers of an answer of the broker which carries a JSON body.
const _jsonHeaders = {"content-type": "application/json"};

/// An answer of the broker which carries [json] as a JSON body, with the [status] given.
http.Response _json(Object? json, [int status = 200]) =>
    http.Response(jsonEncode(json), status, headers: _jsonHeaders);

void main() {
  late FakeGlobalManager globalManager;

  setUp(() => globalManager = FakeGlobalManager.install());

  tearDown(() => globalManager.reset());

  /// Have [call] ask a client of the broker served at [baseUrl], which answers what [answer] says
  /// and is given [requestTimeout] to do so.
  ///
  /// The requester of act_http_client_manager opens its own HTTP client: the one it opens in the
  /// zone of [http.runWithClient] is the stubbed one.
  Future<T> ask<T>(
    Future<http.Response> Function(http.Request request) answer,
    Future<T> Function(TbExtenderBrokerClient client) call, {
    String? baseUrl = _baseUrl,
    Duration requestTimeout = TbExtenderBrokerClient.defaultRequestTimeout,
  }) => http.runWithClient(() async {
    final client = TbExtenderBrokerClient(
      baseUrlGetter: () => baseUrl,
      requestTimeout: requestTimeout,
    );
    await client.initLifeCycle();

    try {
      return await call(client);
    } finally {
      await client.disposeLifeCycle();
    }
  }, () => MockClient(answer));

  group("TbExtenderBrokerClient.initLifeCycle", () {
    test("refuses to start without a base URL", () async {
      final client = TbExtenderBrokerClient(baseUrlGetter: () => null);

      await expectLater(client.initLifeCycle(), throwsA(isA<ActMissingConfigException>()));
    });

    test("refuses to start with an empty base URL", () async {
      final client = TbExtenderBrokerClient(baseUrlGetter: () => "");

      await expectLater(client.initLifeCycle(), throwsA(isA<ActMissingConfigException>()));
    });

    test("reads the base URL when it starts, not when it is built", () async {
      String? baseUrl;
      late Uri capturedUri;
      final client = TbExtenderBrokerClient(baseUrlGetter: () => baseUrl);
      baseUrl = _baseUrl;

      await http.runWithClient(() async {
        await client.initLifeCycle();
        await client.deleteAccount("kc");
        await client.disposeLifeCycle();
      }, () => MockClient((request) async {
        capturedUri = request.url;
        return http.Response("", 204);
      }));

      expect(capturedUri.toString(), _accountUri);
    });
  });

  group("TbExtenderBrokerClient.login", () {
    test("asks the login endpoint with the token of the identity provider and no body", () async {
      late http.Request captured;

      await ask((request) async {
        captured = request;
        return _json(_successBody());
      }, (client) => client.login("kc-access-token"));

      expect(captured.method, "POST");
      expect(captured.url.toString(), _loginUri);
      expect(captured.headers["Authorization"], "Bearer kc-access-token");
      expect(captured.body, isEmpty);
    });

    test("removes the trailing slash of the configured base URL", () async {
      late Uri capturedUri;

      await ask(
        (request) async {
          capturedUri = request.url;
          return _json(_successBody());
        },
        (client) => client.login("kc"),
        baseUrl: "$_baseUrl/",
      );

      expect(capturedUri.toString(), _loginUri);
    });

    test("keeps the scheme, the port and the path of the configured base URL", () async {
      late Uri capturedUri;

      await ask(
        (request) async {
          capturedUri = request.url;
          return _json(_successBody());
        },
        (client) => client.login("kc"),
        baseUrl: "http://broker.example.test:8080/tenant/",
      );

      expect(capturedUri.toString(), "http://broker.example.test:8080/tenant/api/v1/auth/login");
    });

    test("reads a 200 as a success carrying the parsed payload", () async {
      final result = await ask((_) async => _json(_successBody()), (client) => client.login("kc"));

      expect(result.status, BrokerAuthError.success);
      final response = result.value!;
      expect(response.tbToken, "tb-access-jwt");
      expect(response.tbRefreshToken, "tb-refresh-jwt");
      expect(response.expiresIn, 3600);
      expect(response.user.tbUserId, "11111111-1111-1111-1111-111111111111");
      expect(response.user.email, "user@example.test");
      expect(response.user.firstName, "Ada");
      expect(response.user.lastName, "Lovelace");
    });

    test("reads a success payload which names no first and last name", () async {
      final body = _successBody();
      (body["user"] as Map<String, dynamic>)
        ..remove("firstName")
        ..remove("lastName");

      final result = await ask((_) async => _json(body), (client) => client.login("kc"));

      expect(result.isSuccess, isTrue);
      final user = result.value!.user;
      expect(user.firstName, isNull);
      expect(user.lastName, isNull);
    });

    test("reads a 200 whose body isn't a JSON object as an unknown failure", () async {
      final result = await ask(
        (_) async => http.Response("not-a-json", 200, headers: _jsonHeaders),
        (client) => client.login("kc"),
      );

      expect(result.status, BrokerAuthError.unknown);
      expect(result.value, isNull);
    });

    test("reads a 200 whose payload misses a mandatory field as an unknown failure", () async {
      final body = _successBody()..remove("tbToken");

      final result = await ask((_) async => _json(body), (client) => client.login("kc"));

      expect(result.status, BrokerAuthError.unknown);
    });

    /// Each documented error and the status it comes with.
    const errorCases = <({int status, String code, BrokerAuthError expected})>[
      (
        status: 401,
        code: "invalid_token",
        expected: BrokerAuthError.invalidToken,
      ),
      (
        status: 403,
        code: "invalid_audience",
        expected: BrokerAuthError.invalidAudience,
      ),
      (
        status: 403,
        code: "email_not_verified",
        expected: BrokerAuthError.emailNotVerified,
      ),
      (
        status: 409,
        code: "provisioning_conflict",
        expected: BrokerAuthError.provisioningConflict,
      ),
      (
        status: 502,
        code: "thingsboard_unavailable",
        expected: BrokerAuthError.thingsboardUnavailable,
      ),
      (
        status: 500,
        code: "internal_error",
        expected: BrokerAuthError.internalError,
      ),
    ];

    for (final testCase in errorCases) {
      test("reads a ${testCase.status} ${testCase.code} as ${testCase.expected.name}", () async {
        final result = await ask(
          (_) async => _json({"error": testCase.code, "message": "boom"}, testCase.status),
          (client) => client.login("kc"),
        );

        expect(result.status, testCase.expected);
        expect(result.extraInfo, "boom");
      });
    }

    test("reads an error code which isn't documented as an unknown failure", () async {
      final result = await ask(
        (_) async => _json({"error": "teapot"}, 418),
        (client) => client.login("kc"),
      );

      expect(result.status, BrokerAuthError.unknown);
    });

    test("reads an answer which isn't a 200 and carries no body as an unknown failure", () async {
      final result = await ask(
        (_) async => http.Response("", 503),
        (client) => client.login("kc"),
      );

      expect(result.status, BrokerAuthError.unknown);
    });

    test("reads a transport error as a network failure", () async {
      final result = await ask(
        (_) async => throw http.ClientException("connection refused"),
        (client) => client.login("kc"),
      );

      expect(result.status, BrokerAuthError.network);
    });
  });

  group("TbExtenderBrokerClient.deleteAccount", () {
    test("asks the account endpoint with the identity provider token, reads 204 as gone", () async {
      late http.Request captured;

      final error = await ask((request) async {
        captured = request;
        return http.Response("", 204);
      }, (client) => client.deleteAccount("kc-access-token"));

      expect(error, BrokerAuthError.success);
      expect(captured.method, "DELETE");
      expect(captured.url.toString(), _accountUri);
      expect(captured.headers["Authorization"], "Bearer kc-access-token");
    });

    test("reads the error code of a deletion the broker refused", () async {
      final error = await ask(
        (_) async => _json({"error": "not_configured", "message": "nope"}, 501),
        (client) => client.deleteAccount("kc"),
      );

      expect(error, BrokerAuthError.notConfigured);
    });

    test("reads a transport error as a network failure", () async {
      final error = await ask(
        (_) async => throw http.ClientException("connection refused"),
        (client) => client.deleteAccount("kc"),
      );

      expect(error, BrokerAuthError.network);
    });
  });

  group("TbExtenderBrokerClient.acceptTerms", () {
    test("posts the version as JSON with the token of the identity provider", () async {
      late http.Request captured;

      final error = await ask((request) async {
        captured = request;
        return http.Response("", 204);
      }, (client) => client.acceptTerms("kc-token", version: "2026-09-16"));

      expect(error, BrokerAuthError.success);
      expect(captured.method, "POST");
      expect(captured.url.toString(), _termsUri);
      expect(captured.headers["Authorization"], "Bearer kc-token");
      expect(captured.headers["content-type"], startsWith("application/json"));
      expect(jsonDecode(captured.body), {"version": "2026-09-16"});
    });

    test("reads the error code the broker answers", () async {
      final error = await ask(
        (_) async => _json({"error": "not_configured"}, 501),
        (client) => client.acceptTerms("kc-token", version: "v1"),
      );

      expect(error, BrokerAuthError.notConfigured);
    });

    test("answers a network error when the transport fails", () async {
      final error = await ask(
        (_) async => throw http.ClientException("connection refused"),
        (client) => client.acceptTerms("kc-token", version: "v1"),
      );

      expect(error, BrokerAuthError.network);
    });
  });

  group("TbExtenderBrokerClient.releaseDevice", () {
    test("posts to the release endpoint of the serial, with no body without a secret", () async {
      late http.Request captured;

      final error = await ask((request) async {
        captured = request;
        return http.Response("", 204);
      }, (client) => client.releaseDevice("kc-token", serial: "AB 12"));

      expect(error, BrokerAuthError.success);
      expect(captured.method, "POST");
      expect(captured.url.toString(), _releaseUri);
      expect(captured.headers["Authorization"], "Bearer kc-token");
      expect(captured.body, isEmpty);
    });

    test("sends the claim secret as JSON when one is given", () async {
      late http.Request captured;

      await ask((request) async {
        captured = request;
        return http.Response("", 204);
      }, (client) => client.releaseDevice("kc-token", serial: "AB 12", secret: "cafe"));

      expect(captured.headers["content-type"], startsWith("application/json"));
      expect(jsonDecode(captured.body), {"secret": "cafe"});
    });

    test("reads a release the broker refused", () async {
      final error = await ask(
        (_) async => _json({"error": "release_refused"}, 403),
        (client) => client.releaseDevice("kc-token", serial: "AB 12"),
      );

      expect(error, BrokerAuthError.releaseRefused);
    });

    test("answers a network error when the transport fails", () async {
      final error = await ask(
        (_) async => throw http.ClientException("connection refused"),
        (client) => client.releaseDevice("kc-token", serial: "AB 12"),
      );

      expect(error, BrokerAuthError.network);
    });
  });

  group("TbExtenderBrokerClient.claimDevice", () {
    test("posts the secret as JSON to the claim endpoint of the serial", () async {
      late http.Request captured;

      await ask((request) async {
        captured = request;
        return _json({"deviceId": "dev-1", "serial": "AB 12"});
      }, (client) => client.claimDevice("kc-token", serial: "AB 12", secret: "cafe"));

      expect(captured.method, "POST");
      expect(captured.url.toString(), _claimUri);
      expect(captured.headers["Authorization"], "Bearer kc-token");
      expect(captured.headers["content-type"], startsWith("application/json"));
      expect(jsonDecode(captured.body), {"secret": "cafe"});
    });

    test("reads a 200 as a success naming the device", () async {
      final result = await ask(
        (_) async => _json({"deviceId": "dev-1", "serial": "AB 12"}),
        (client) => client.claimDevice("kc-token", serial: "AB 12", secret: "cafe"),
      );

      expect(result.status, BrokerAuthError.success);
      expect(result.value, "dev-1");
    });

    test("reads a 200 which names no device as an unknown failure", () async {
      final result = await ask(
        (_) async => _json({"serial": "AB 12"}),
        (client) => client.claimDevice("kc-token", serial: "AB 12", secret: "cafe"),
      );

      expect(result.status, BrokerAuthError.unknown);
    });

    test("reads a claim the broker refused", () async {
      final result = await ask(
        (_) async => _json({"error": "claim_refused"}, 403),
        (client) => client.claimDevice("kc-token", serial: "AB 12", secret: "cafe"),
      );

      expect(result.status, BrokerAuthError.claimRefused);
    });

    test("answers a network error when the transport fails", () async {
      final result = await ask(
        (_) async => throw http.ClientException("connection refused"),
        (client) => client.claimDevice("kc-token", serial: "AB 12", secret: "cafe"),
      );

      expect(result.status, BrokerAuthError.network);
    });
  });

  group("TbExtenderBrokerClient, the broker which doesn't answer", () {
    /// Have [call] ask a broker which never answers, and which is given little time to do so.
    Future<T> askSilent<T>(Future<T> Function(TbExtenderBrokerClient client) call) => ask(
      (_) => Completer<http.Response>().future,
      call,
      requestTimeout: const Duration(milliseconds: 10),
    );

    test("reads a login which timed out as a network failure", () async {
      final result = await askSilent((client) => client.login("kc"));

      expect(result.status, BrokerAuthError.network);
    });

    test("reads a deletion which timed out as a network failure", () async {
      expect(await askSilent((client) => client.deleteAccount("kc")), BrokerAuthError.network);
    });

    test("reads a terms acceptance which timed out as a network failure", () async {
      expect(
        await askSilent((client) => client.acceptTerms("kc", version: "2026-09-16")),
        BrokerAuthError.network,
      );
    });

    test("reads a release which timed out as a network failure", () async {
      expect(
        await askSilent((client) => client.releaseDevice("kc", serial: "AB 12")),
        BrokerAuthError.network,
      );
    });

    test("reads a claim which timed out as a network failure", () async {
      final result = await askSilent(
        (client) => client.claimDevice("kc", serial: "AB 12", secret: "cafe"),
      );

      expect(result.status, BrokerAuthError.network);
    });
  });
}
