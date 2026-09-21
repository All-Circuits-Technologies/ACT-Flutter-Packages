// SPDX-FileCopyrightText: 2026 Dorian Benech <dorian.benech@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'dart:convert';

import 'package:act_tb_extender_auth/act_tb_extender_auth.dart';
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

void main() {
  late FakeGlobalManager globalManager;

  setUp(() => globalManager = FakeGlobalManager.install());

  tearDown(() => globalManager.reset());

  /// The client of an application whose broker is served at [baseUrl] and answers what [answer]
  /// says.
  TbExtenderBrokerClient aClient(
    Future<http.Response> Function(http.Request request) answer, {
    String? baseUrl = _baseUrl,
  }) => TbExtenderBrokerClient(baseUrlGetter: () => baseUrl, httpClient: MockClient(answer));

  group("TbExtenderBrokerClient.login", () {
    test("asks the login endpoint with the Keycloak token and no body", () async {
      late http.Request captured;
      final client = aClient((request) async {
        captured = request;
        return http.Response(jsonEncode(_successBody()), 200);
      });

      await client.login("kc-access-token");

      expect(captured.method, "POST");
      expect(captured.url.toString(), _loginUri);
      expect(captured.headers["Authorization"], "Bearer kc-access-token");
      expect(captured.body, isEmpty);
    });

    test("removes the trailing slash of the configured base URL", () async {
      late Uri capturedUri;
      final client = aClient((request) async {
        capturedUri = request.url;
        return http.Response(jsonEncode(_successBody()), 200);
      }, baseUrl: "$_baseUrl/");

      await client.login("kc");

      expect(capturedUri.toString(), _loginUri);
    });

    test("reads a 200 as a success carrying the parsed payload", () async {
      final client = aClient((_) async => http.Response(jsonEncode(_successBody()), 200));

      final result = await client.login("kc");

      expect(result, isA<BrokerLoginSuccess>());
      final success = result as BrokerLoginSuccess;
      expect(success.response.tbToken, "tb-access-jwt");
      expect(success.response.tbRefreshToken, "tb-refresh-jwt");
      expect(success.response.expiresIn, 3600);
      expect(success.response.user.tbUserId, "11111111-1111-1111-1111-111111111111");
      expect(success.response.user.email, "user@example.test");
      expect(success.response.user.firstName, "Ada");
      expect(success.response.user.lastName, "Lovelace");
    });

    test("reads a success payload which names no first and last name", () async {
      final body = _successBody();
      (body["user"] as Map<String, dynamic>)
        ..remove("firstName")
        ..remove("lastName");
      final client = aClient((_) async => http.Response(jsonEncode(body), 200));

      final result = await client.login("kc");

      expect(result, isA<BrokerLoginSuccess>());
      final user = (result as BrokerLoginSuccess).response.user;
      expect(user.firstName, isNull);
      expect(user.lastName, isNull);
    });

    test("reads a 200 whose body isn't a JSON object as an unknown failure", () async {
      final client = aClient((_) async => http.Response("not-a-json", 200));

      final result = await client.login("kc");

      expect(result, isA<BrokerLoginFailure>());
      final failure = result as BrokerLoginFailure;
      expect(failure.error, BrokerAuthError.unknown);
      expect(failure.statusCode, 200);
    });

    test("reads a 200 whose payload misses a mandatory field as an unknown failure", () async {
      final body = _successBody()..remove("tbToken");
      final client = aClient((_) async => http.Response(jsonEncode(body), 200));

      final result = await client.login("kc");

      expect(result, isA<BrokerLoginFailure>());
      expect((result as BrokerLoginFailure).error, BrokerAuthError.unknown);
    });

    /// Each documented error, the status it comes with and whether it is worth another call.
    const errorCases = <({int status, String code, BrokerAuthError expected, bool retryable})>[
      (
        status: 401,
        code: "invalid_token",
        expected: BrokerAuthError.invalidToken,
        retryable: false,
      ),
      (
        status: 403,
        code: "invalid_audience",
        expected: BrokerAuthError.invalidAudience,
        retryable: false,
      ),
      (
        status: 403,
        code: "email_not_verified",
        expected: BrokerAuthError.emailNotVerified,
        retryable: false,
      ),
      (
        status: 409,
        code: "provisioning_conflict",
        expected: BrokerAuthError.provisioningConflict,
        retryable: false,
      ),
      (
        status: 502,
        code: "thingsboard_unavailable",
        expected: BrokerAuthError.thingsboardUnavailable,
        retryable: true,
      ),
      (
        status: 500,
        code: "internal_error",
        expected: BrokerAuthError.internalError,
        retryable: true,
      ),
    ];

    for (final testCase in errorCases) {
      test("reads a ${testCase.status} ${testCase.code} as ${testCase.expected.name}", () async {
        final client = aClient(
          (_) async => http.Response(
            jsonEncode({"error": testCase.code, "message": "boom"}),
            testCase.status,
          ),
        );

        final result = await client.login("kc");

        expect(result, isA<BrokerLoginFailure>());
        final failure = result as BrokerLoginFailure;
        expect(failure.error, testCase.expected);
        expect(failure.retryable, testCase.retryable);
        expect(failure.message, "boom");
        expect(failure.statusCode, testCase.status);
      });
    }

    test("reads an error code which isn't documented as an unknown failure", () async {
      final client = aClient((_) async => http.Response(jsonEncode({"error": "teapot"}), 418));

      final result = await client.login("kc");

      expect((result as BrokerLoginFailure).error, BrokerAuthError.unknown);
    });

    test("reads an answer which isn't a 200 and carries no body as an unknown failure", () async {
      final client = aClient((_) async => http.Response("", 503));

      final result = await client.login("kc");

      expect((result as BrokerLoginFailure).error, BrokerAuthError.unknown);
    });

    test("reads a transport error as a network failure worth another call", () async {
      final client = aClient((_) async => throw const _FakeSocketException());

      final result = await client.login("kc");

      expect(result, isA<BrokerLoginFailure>());
      final failure = result as BrokerLoginFailure;
      expect(failure.error, BrokerAuthError.network);
      expect(failure.retryable, isTrue);
    });

    test("fails without asking anything when no base URL is configured", () async {
      var called = false;
      final client = aClient((_) async {
        called = true;
        return http.Response("", 200);
      }, baseUrl: null);

      final result = await client.login("kc");

      expect((result as BrokerLoginFailure).error, BrokerAuthError.unknown);
      expect(called, isFalse);
    });
  });

  group("TbExtenderBrokerClient.deleteAccount", () {
    test("asks the account endpoint with the Keycloak token and reads a 204 as gone", () async {
      late http.Request captured;
      final client = aClient((request) async {
        captured = request;
        return http.Response("", 204);
      });

      expect(await client.deleteAccount("kc-access-token"), isNull);
      expect(captured.method, "DELETE");
      expect(captured.url.toString(), _accountUri);
      expect(captured.headers["Authorization"], "Bearer kc-access-token");
    });

    test("reads the error code of a deletion the broker refused", () async {
      final client = aClient(
        (_) async => http.Response(
          jsonEncode({"error": "deletion_not_configured", "message": "nope"}),
          501,
        ),
      );

      expect(await client.deleteAccount("kc"), BrokerAuthError.deletionNotConfigured);
    });

    test("reads a transport error as a network failure", () async {
      final client = aClient((_) async => throw const _FakeSocketException());

      expect(await client.deleteAccount("kc"), BrokerAuthError.network);
    });

    test("fails when no base URL is configured", () async {
      final client = aClient((_) async => http.Response("", 204), baseUrl: "");

      expect(await client.deleteAccount("kc"), BrokerAuthError.unknown);
    });
  });

  group("TbExtenderBrokerClient.acceptTerms", () {
    test("posts the version as JSON with the Keycloak token", () async {
      late http.Request captured;
      final client = aClient((request) async {
        captured = request;
        return http.Response("", 204);
      });

      final error = await client.acceptTerms("kc-token", version: "2026-09-16");

      expect(error, isNull);
      expect(captured.method, "POST");
      expect(captured.url.toString(), _termsUri);
      expect(captured.headers["Authorization"], "Bearer kc-token");
      expect(captured.headers["Content-Type"], startsWith("application/json"));
      expect(jsonDecode(captured.body), {"version": "2026-09-16"});
    });

    test("reads the error code the broker answers", () async {
      final client = aClient(
        (_) async => http.Response(jsonEncode({"error": "admin_not_configured"}), 501),
      );

      expect(
        await client.acceptTerms("kc-token", version: "v1"),
        BrokerAuthError.adminNotConfigured,
      );
    });

    test("answers a network error when the transport fails", () async {
      final client = aClient((_) async => throw const _FakeSocketException());

      expect(await client.acceptTerms("kc-token", version: "v1"), BrokerAuthError.network);
    });

    test("answers unknown without a configured base URL", () async {
      final client = aClient((_) async => http.Response("", 204), baseUrl: null);

      expect(await client.acceptTerms("kc-token", version: "v1"), BrokerAuthError.unknown);
    });
  });
}

/// A transport exception which stands in for a connection failure.
class _FakeSocketException implements Exception {
  /// Class constructor
  const _FakeSocketException();
}
