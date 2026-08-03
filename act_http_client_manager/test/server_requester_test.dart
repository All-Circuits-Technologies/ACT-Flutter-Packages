// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_foundation/act_foundation.dart';
import 'package:act_http_client_manager/act_http_client_manager.dart';
import 'package:act_http_client_manager/src/models/server_urls.dart';
import 'package:act_http_core/act_http_core.dart';
import 'package:act_test_utility/act_test_utility.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fakes/fake_server.dart';

void main() {
  late FakeServer server;
  late FakeExternalLogger logs;

  setUp(() async {
    logs = FakeExternalLogger();
    server = await FakeServer.start();
    addTearDown(server.close);
  });

  /// The requester of an application which reaches the server of the test.
  ServerRequester aRequester({
    Duration defaultTimeout = const Duration(seconds: 10),
    int? maxParallelRequestsNb,
  }) {
    final requester = ServerRequester(
      logsHelper: logs.buildHelper(category: "aRequester"),
      serverUrls: ServerUrls(
        defaultUrl: Uri.parse("http://${server.host}:${server.port}"),
        byRelRoute: const {},
      ),
      defaultTimeout: defaultTimeout,
      maxParallelRequestsNb: maxParallelRequestsNb,
    );
    addTearDown(requester.disposeLifeCycle);

    return requester;
  }

  /// Asks [route] of the server of the test, through [requester].
  Future<RequestResponse<Body>> ask<Body>(
    ServerRequester requester, {
    String route = "items",
    HttpMethods httpMethod = HttpMethods.get,
    Object? body,
    HttpMimeTypes? expectedMimeType,
    Duration? timeout,
    Body? Function(Body body)? parseRespBody,
  }) => requester.executeRequestWithoutAuth<Body, Body>(
    requestParam: RequestParam(
      httpMethod: httpMethod,
      relativeRoute: route,
      body: body,
      expectedMimeType: expectedMimeType,
      timeout: timeout,
    ),
    parseRespBody: parseRespBody,
  );

  group("ServerRequester.executeRequestWithoutAuth", () {
    test("sends the request to the server on the route which was asked", () async {
      final response = await ask<String>(aRequester(), route: "items/7");

      expect(response.status, RequestStatus.success);
      expect(server.received.single.method, "GET");
      expect(server.received.single.url.path, "/items/7");
    });

    test("sends the body of the request to the server", () async {
      await ask<String>(
        aRequester(),
        httpMethod: HttpMethods.post,
        body: <String, dynamic>{"name": "a name"},
      );

      expect(server.received.single.body, '{"name":"a name"}');
      expect(server.received.single.contentType, startsWith("application/json"));
    });

    test("gives back the body the server answered with", () async {
      server.answers.add(ServerAnswer.json({"name": "a name"}));

      final response = await ask<Map<String, dynamic>>(
        aRequester(),
        expectedMimeType: HttpMimeTypes.json,
      );

      expect(response.castedBody, {"name": "a name"});
    });

    test("gives back an error for a request the server refused", () async {
      server.answers.add(const ServerAnswer(statusCode: 500));

      final response = await ask<String>(aRequester());

      expect(response.status, RequestStatus.globalError);
      expect(response.response?.statusCode, 500);
    });

    test("gives back a login error for a request the server did not let through", () async {
      server.answers.add(const ServerAnswer(statusCode: 401));

      final response = await ask<String>(aRequester());

      expect(response.status, RequestStatus.loginError);
    });

    test("gives back an error for a request whose body it cannot even build", () async {
      final response = await ask<String>(aRequester(), body: 42);

      expect(response.status, RequestStatus.globalError);
      expect(server.requestsNb, 0);
    });

    test("gives back a timeout error for a server which took too long to answer", () async {
      server.answers.add(const ServerAnswer(held: true));

      final response = await ask<String>(
        aRequester(),
        timeout: const Duration(milliseconds: 200),
      );

      expect(response.status, RequestStatus.timeoutError);
      expect(logs.recordsAtLevel(LogsLevel.error), isNotEmpty);
    });

    test("waits as long as the requester says when the request names no timeout", () async {
      server.answers.add(const ServerAnswer(held: true));

      final response = await ask<String>(
        aRequester(defaultTimeout: const Duration(milliseconds: 200)),
      );

      expect(response.status, RequestStatus.timeoutError);
    });

    test("waits as long as the requester says when the request names a timeout of zero", () async {
      server.answers.add(const ServerAnswer(held: true));

      final response = await ask<String>(
        aRequester(defaultTimeout: const Duration(milliseconds: 200)),
        timeout: Duration.zero,
      );

      expect(response.status, RequestStatus.timeoutError);
    });

    test("gives back an error for a server which is not there", () async {
      final requester = aRequester();
      await server.close();

      final response = await ask<String>(requester);

      expect(response.status, RequestStatus.globalError);
    });

    test("sends the requests one after another when only one is allowed at a time", () async {
      server.answers.add(const ServerAnswer(held: true));
      final requester = aRequester(maxParallelRequestsNb: 1);

      final requests = Future.wait([ask<String>(requester), ask<String>(requester)]);
      await Future<void>.delayed(const Duration(milliseconds: 100));

      expect(server.requestsNb, 1);

      server.release();
      await requests;

      expect(server.requestsNb, 2);
    });

    test("sends the requests together when nothing limits them", () async {
      server.answers.add(const ServerAnswer(held: true));
      final requester = aRequester();

      final requests = Future.wait([ask<String>(requester), ask<String>(requester)]);
      await Future<void>.delayed(const Duration(milliseconds: 100));

      expect(server.requestsNb, 2);

      server.release();
      await requests;
    });
  });

  group("ServerRequester.disposeLifeCycle", () {
    test("closes the client it opened, which a request opens again", () async {
      final requester = aRequester();
      await ask<String>(requester);

      await requester.disposeLifeCycle();

      expect((await ask<String>(requester)).status, RequestStatus.success);
    });
  });
}
