// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_http_client_manager/act_http_client_manager.dart';
import 'package:act_http_core/act_http_core.dart';
import 'package:act_logger_manager/act_logger_manager.dart';
import 'package:act_test_utility/act_test_utility.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fakes/fake_client.dart';
import 'fakes/fake_server.dart';

void main() {
  late FakeServer server;
  late FakeExternalLogger logs;

  setUp(() async {
    FakeGlobalManager.install();
    logs = FakeExternalLogger();
    server = await FakeServer.start();
    addTearDown(server.close);
  });

  /// The configuration of a manager which reaches the server of the test.
  RequesterConfig aConfig({
    bool loggerEnabled = true,
    LogsHelper? parentLogsHelper,
    Map<String, RequesterServerUrlConfig>? serverInfoByUrl,
    Duration defaultTimeout = const Duration(seconds: 10),
    int? maxParallelRequestsNb,
  }) => RequesterConfig(
    loggerEnabled: loggerEnabled,
    loggerCategory: "aClient",
    defaultTimeout: defaultTimeout,
    parentLogsHelper: parentLogsHelper,
    defaultServerInfo: RequesterServerUrlConfig(
      isUsingSsl: false,
      hostname: server.host,
      port: server.port,
    ),
    serverInfoByUrl: serverInfoByUrl,
    maxParallelRequestsNb: maxParallelRequestsNb,
  );

  /// The manager of an application which reaches the server of the test.
  ///
  /// The manager has a login as soon as the test asks for one, either by naming what it answers or
  /// by naming the policy it follows.
  Future<FakeClientManager> aManager({
    RequesterConfig? config,
    bool withLogin = true,
    bool initResult = true,
    RequestStatus loginResult = RequestStatus.success,
    LoginFailPolicy loginFailPolicy = LoginFailPolicy.errorIfLoginFails,
  }) async {
    final manager = FakeClientManager(
      config: config ?? aConfig(),
      loginBuilder: !withLogin
          ? null
          : (requester, logsHelper) => FakeClientLogin(
              serverRequester: requester,
              logsHelper: logsHelper,
              loginFailPolicy: loginFailPolicy,
              initResult: initResult,
              defaultResult: loginResult,
            ),
    );
    await manager.initLifeCycle();
    addTearDown(manager.disposeLifeCycle);

    return manager;
  }

  /// Asks the server of the test through [manager].
  Future<RequestResponse<String>> ask(
    FakeClientManager manager, {
    String route = "items",
    bool ifExistUseAuth = true,
    int retryRequestIfErrorNb = 0,
    Duration? retryTimeout,
  }) => manager.executeRequest<String, String>(
    requestParam: RequestParam(httpMethod: HttpMethods.get, relativeRoute: route),
    ifExistUseAuth: ifExistUseAuth,
    retryRequestIfErrorNb: retryRequestIfErrorNb,
    retryTimeout: retryTimeout,
  );

  group("AbsHttpClientBuilder", () {
    test("depends on the logger manager", () {
      final builder = FakeClientBuilder(() => FakeClientManager(config: aConfig()));

      expect(builder.dependsOn(), [LoggerManager]);
    });
  });

  group("AbsHttpClientManager.initLifeCycle", () {
    test("builds the base of the URLs of the server the application requests", () async {
      final manager = await aManager();

      expect(manager.serverUrls.defaultUrl, Uri.parse("http://${server.host}:${server.port}"));
      expect(manager.serverUrls.byRelRoute, isEmpty);
    });

    test("builds the base of the URLs of the servers which answer on their own routes", () async {
      final manager = await aManager(
        config: aConfig(
          serverInfoByUrl: const {
            "items": RequesterServerUrlConfig(
              isUsingSsl: true,
              hostname: "another.server",
              baseUrl: "/api",
            ),
          },
        ),
      );

      expect(manager.serverUrls.byRelRoute, {"items": Uri.parse("https://another.server/api")});
    });

    test("initializes the login of the server", () async {
      final manager = await aManager();

      expect(manager.absServerLogin, isNotNull);
    });

    test("gives up when the login of the server cannot be initialized", () async {
      final manager = FakeClientManager(
        config: aConfig(),
        loginBuilder: (requester, logsHelper) => FakeClientLogin(
          serverRequester: requester,
          logsHelper: logsHelper,
          initResult: false,
        ),
      );

      expect(manager.initLifeCycle, throwsA(isA<ActServerLoginInitException>()));
    });

    test("initializes a manager of a server which asks for no authentication", () async {
      final manager = await aManager(withLogin: false);

      expect(manager.absServerLogin, isNull);
      expect((await ask(manager)).status, RequestStatus.success);
    });

    test("logs under the category of the requester", () async {
      final manager = await aManager(config: aConfig(parentLogsHelper: logs.buildHelper()));

      await ask(manager);

      expect(logs.records.first.categories, ["aClient"]);
    });

    test("logs nothing for a requester whose logger is not enabled", () async {
      final manager = await aManager(
        config: aConfig(loggerEnabled: false, parentLogsHelper: logs.buildHelper()),
      );

      await ask(manager);

      expect(logs.records, isEmpty);
    });
  });

  group("AbsHttpClientManager.executeRequest", () {
    test("has the login sign the request before sending it", () async {
      final manager = await aManager();

      final response = await ask(manager);

      expect(response.status, RequestStatus.success);
      expect(manager.builtLogin!.signed.single.relativeRoute, "items");
    });

    test("sends the request without the login when the caller asked for none", () async {
      final manager = await aManager();

      await ask(manager, ifExistUseAuth: false);

      expect(manager.builtLogin!.signed, isEmpty);
      expect(server.requestsNb, 1);
    });

    test("gives up when the credentials of the login are refused", () async {
      final manager = await aManager(loginResult: RequestStatus.loginError);

      final response = await ask(manager, retryRequestIfErrorNb: 3);

      expect(response.status, RequestStatus.loginError);
      expect(manager.builtLogin!.clearCount, 1);
      expect(server.requestsNb, 0);
    });

    test("tries again when the login failed for another reason", () async {
      final manager = await aManager(loginResult: RequestStatus.timeoutError);

      final response = await ask(manager, retryRequestIfErrorNb: 1);

      expect(response.status, RequestStatus.loginError);
      expect(manager.builtLogin!.signed.length, 2);
      expect(server.requestsNb, 0);
    });

    test("sends the request again as many times as the caller allowed", () async {
      server.defaultAnswer = const ServerAnswer(statusCode: 500);
      final manager = await aManager();

      final response = await ask(manager, retryRequestIfErrorNb: 2);

      expect(response.status, RequestStatus.globalError);
      expect(server.requestsNb, 3);
    });

    test("stops sending the request again once the server answered", () async {
      server.answers.add(const ServerAnswer(statusCode: 500));
      final manager = await aManager();

      final response = await ask(manager, retryRequestIfErrorNb: 3);

      expect(response.status, RequestStatus.success);
      expect(server.requestsNb, 2);
    });

    test("waits between two tries as long as the caller asked", () async {
      server.defaultAnswer = const ServerAnswer(statusCode: 500);
      final manager = await aManager();
      final watch = Stopwatch()..start();

      await ask(
        manager,
        retryRequestIfErrorNb: 1,
        retryTimeout: const Duration(milliseconds: 100),
      );

      expect(watch.elapsed, greaterThanOrEqualTo(const Duration(milliseconds: 200)));
    });

    test("clears the logins when the server refused the request they signed", () async {
      server.defaultAnswer = const ServerAnswer(statusCode: 401);
      final manager = await aManager();

      final response = await ask(manager);

      expect(response.status, RequestStatus.loginError);
      expect(manager.builtLogin!.clearCount, 1);
    });

    test("logs in again once when the policy of the login says so", () async {
      server.answers.add(const ServerAnswer(statusCode: 401));
      final manager = await aManager(loginFailPolicy: LoginFailPolicy.retryOnceIfLoginFails);

      final response = await ask(manager);

      expect(response.status, RequestStatus.success);
      expect(server.requestsNb, 2);
      expect(manager.builtLogin!.clearCount, 1);
    });

    test("logs in again only once, whatever the number of times the server refuses", () async {
      server.defaultAnswer = const ServerAnswer(statusCode: 401);
      final manager = await aManager(loginFailPolicy: LoginFailPolicy.retryOnceIfLoginFails);

      final response = await ask(manager);

      expect(response.status, RequestStatus.loginError);
      expect(server.requestsNb, 2);
    });

    test("does not log in again when the policy of the login says nothing else", () async {
      server.defaultAnswer = const ServerAnswer(statusCode: 401);
      final manager = await aManager();

      await ask(manager);

      expect(server.requestsNb, 1);
    });

    test("gives back the answer of the server", () async {
      server.answers.add(ServerAnswer.text("a body"));
      final manager = await aManager();

      final response = await manager.executeRequest<String, String>(
        requestParam: RequestParam(
          httpMethod: HttpMethods.get,
          relativeRoute: "items",
          expectedMimeType: HttpMimeTypes.plainText,
        ),
      );

      expect(response.castedBody, "a body");
      expect(response.response?.statusCode, 200);
    });
  });

  group("AbsHttpClientManager.executeRequestWithMimeRespBody", () {
    test("reads the body the server answered with", () async {
      server.answers.add(ServerAnswer.json({"name": "a name"}));
      final manager = await aManager();

      final response = await manager.executeRequestWithMimeRespBody<Map<String, dynamic>>(
        requestParam: RequestParam(
          httpMethod: HttpMethods.get,
          relativeRoute: "items",
          expectedMimeType: HttpMimeTypes.json,
        ),
      );

      expect(response.castedBody, {"name": "a name"});
    });
  });

  group("AbsHttpClientManager.executeRequestWithJsonObjRespBody", () {
    test("builds the value the caller parses the json object into", () async {
      server.answers.add(ServerAnswer.json({"name": "a name"}));
      final manager = await aManager();

      final response = await manager.executeRequestWithJsonObjRespBody<String>(
        requestParam: RequestParam(httpMethod: HttpMethods.get, relativeRoute: "items"),
        parseRespBody: (body) => body["name"] as String,
      );

      expect(response.castedBody, "a name");
    });

    test("expects a json body, whatever the request asked for", () async {
      server.answers.add(ServerAnswer.json({"name": "a name"}));
      final manager = await aManager();

      final response = await manager.executeRequestWithJsonObjRespBody<String>(
        requestParam: RequestParam(
          httpMethod: HttpMethods.get,
          relativeRoute: "items",
          expectedMimeType: HttpMimeTypes.plainText,
        ),
        parseRespBody: (body) => body["name"] as String,
      );

      expect(response.castedBody, "a name");
    });
  });

  group("AbsHttpClientManager.executeRequestWithJsonArrayRespBody", () {
    test("builds the value the caller parses the json array into", () async {
      server.answers.add(ServerAnswer.json([1, 2, 3]));
      final manager = await aManager();

      final response = await manager.executeRequestWithJsonArrayRespBody<int>(
        requestParam: RequestParam(httpMethod: HttpMethods.get, relativeRoute: "items"),
        parseRespBody: (body) => body.length,
      );

      expect(response.castedBody, 3);
    });
  });

  group("AbsHttpClientManager.executeRequestWithJsonObjArrayRespBody", () {
    test("builds one value per json object of the array", () async {
      server.answers.add(
        ServerAnswer.json([
          {"name": "a name"},
          {"name": "another name"},
        ]),
      );
      final manager = await aManager();

      final response = await manager.executeRequestWithJsonObjArrayRespBody<String>(
        requestParam: RequestParam(httpMethod: HttpMethods.get, relativeRoute: "items"),
        parseRespBody: (body) => body["name"] as String,
      );

      expect(response.castedBody, ["a name", "another name"]);
    });

    test("builds nothing when the array holds something else than json objects", () async {
      server.answers.add(ServerAnswer.json(["a name"]));
      final manager = await aManager();

      final response = await manager.executeRequestWithJsonObjArrayRespBody<String>(
        requestParam: RequestParam(httpMethod: HttpMethods.get, relativeRoute: "items"),
        parseRespBody: (body) => body["name"] as String,
      );

      expect(response.castedBody, isNull);
    });

    test("builds nothing when one json object of the array cannot be parsed", () async {
      server.answers.add(
        ServerAnswer.json([
          {"name": "a name"},
          {"anotherKey": "a value"},
        ]),
      );
      final manager = await aManager();

      final response = await manager.executeRequestWithJsonObjArrayRespBody<String>(
        requestParam: RequestParam(httpMethod: HttpMethods.get, relativeRoute: "items"),
        parseRespBody: (body) => body["name"] as String?,
      );

      expect(response.castedBody, isNull);
    });
  });

  group("AbsHttpClientManager.disposeLifeCycle", () {
    test("closes the requester of the manager", () async {
      final manager = await aManager();
      await ask(manager);

      await manager.disposeLifeCycle();

      expect((await ask(manager)).status, RequestStatus.success);
    });
  });
}
