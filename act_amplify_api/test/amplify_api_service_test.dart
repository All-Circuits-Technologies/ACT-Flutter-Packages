// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'dart:convert';

import 'package:act_amplify_api/act_amplify_api.dart';
import 'package:act_foundation/act_foundation.dart';
import 'package:act_test_utility/act_test_utility.dart';
import 'package:amplify_api/amplify_api.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fakes/fake_api.dart';

/// An error the cloud throws which has nothing to do with the credentials of the user.
class _AFailure implements Exception {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeApiPlugin cloud;
  late FakeGlobalManager globalManager;
  late FakeExternalLogger logs;
  late FakeApiConfigManager config;

  setUp(() async {
    cloud = await FakeApiPlugin.install();
    globalManager = FakeGlobalManager.install();
    logs = FakeExternalLogger();
  });

  tearDown(() async {
    await Amplify.API.reset();
    await globalManager.reset();
    await config.disposeLifeCycle();
    FakeAssets.stop();
  });

  /// Builds the API service of an application which reads [content] as its configuration, and
  /// initializes it.
  ///
  /// The service announces the failures of the types named in [authFailureTypes].
  Future<AmplifyApiService<FakeApiConfigManager>> aService({
    String content = "anotherKey: aValue",
    Set<Type>? authFailureTypes,
  }) async {
    config = await FakeApiConfigManager.withContent(content);
    globalManager.managers.registerSingleton<FakeApiConfigManager>(config);

    final service = AmplifyApiService<FakeApiConfigManager>(
      nonTransientAuthFailureTypes: authFailureTypes,
    );
    await service.initLifeCycle(parentLogsHelper: logs.buildHelper(category: "amplify"));
    addTearDown(service.disposeLifeCycle);

    return service;
  }

  group("AmplifyApiService.getLinkedPluginsList", () {
    test("brings the API plugin of Amplify along", () async {
      final service = await aService();

      expect(await service.getLinkedPluginsList(), [isA<AmplifyAPI>()]);
    });
  });

  group("AmplifyApiService.updateAmplifyConfig", () {
    test("leaves the configuration alone when the application declares no endpoint", () async {
      final service = await aService();
      final amplifyConfig = AmplifyConfig.fromJson(const {});

      expect(await service.updateAmplifyConfig(amplifyConfig), same(amplifyConfig));
    });

    test("completes the configuration with the endpoints the application declared", () async {
      final service = await aService(content: anApiConf);

      final completed = await service.updateAmplifyConfig(AmplifyConfig.fromJson(const {}));

      expect(completed?.api?.awsPlugin?.endpoints["anApi"]?.endpoint, "https://an.api/prod");
    });
  });

  group("AmplifyApiService requests", () {
    test("asks the cloud for the path with a get", () async {
      final service = await aService();

      await service.get("items");

      expect(cloud.calls.single.method, "get");
    });

    test("asks the cloud for the path with a head", () async {
      final service = await aService();

      await service.head("items");

      expect(cloud.calls.single.method, "head");
    });

    test("asks the cloud for the path with a put", () async {
      final service = await aService();

      await service.put("items");

      expect(cloud.calls.single.method, "put");
    });

    test("asks the cloud for the path with a post", () async {
      final service = await aService();

      await service.post("items");

      expect(cloud.calls.single.method, "post");
    });

    test("asks the cloud for the path with a delete", () async {
      final service = await aService();

      await service.delete("items");

      expect(cloud.calls.single.method, "delete");
    });

    test("names the path the request is about", () async {
      final service = await aService();

      await service.get("items");

      expect(cloud.calls.single.path, "items");
    });

    test("hands the headers, the query and the name of the api to the cloud", () async {
      final service = await aService();

      await service.get(
        "items",
        headers: const {"aHeader": "aValue"},
        queryParameters: const {"aParameter": "aValue"},
        apiName: "anApi",
      );

      expect(cloud.calls.single.headers, {"aHeader": "aValue"});
      expect(cloud.calls.single.queryParameters, {"aParameter": "aValue"});
      expect(cloud.calls.single.apiName, "anApi");
    });

    test("sends the body of a request which carries one", () async {
      final service = await aService();
      final body = HttpPayload.json(const {"aField": "aValue"});

      await service.post("items", body: body);

      expect(cloud.calls.single.body, same(body));
    });

    test("sends no body with a request which carries none", () async {
      final service = await aService();

      await service.get("items");

      expect(cloud.calls.single.body, isNull);
    });

    test("answers with the response of the cloud", () async {
      final service = await aService();
      cloud.response = AWSHttpResponse(statusCode: 200, body: utf8.encode("a body"));

      final response = await service.get("items");

      expect(response?.decodeBody(), "a body");
    });
  });

  group("AmplifyApiService failures", () {
    test("answers with the response the cloud refused the request with", () async {
      final service = await aService();
      cloud.error = HttpStatusException(AWSHttpResponse(statusCode: 404, body: const []));

      final response = await service.get("items");

      expect(response?.statusCode, 404);
    });

    test("answers nothing when the cloud could not be reached", () async {
      final service = await aService();
      cloud.error = _AFailure();

      expect(await service.get("items"), isNull);
    });

    test("logs the request which failed under the logs of the manager", () async {
      final service = await aService();
      cloud.error = _AFailure();

      await service.get("items");

      expect(logs.recordsAtLevel(LogsLevel.error).single.categories, ["amplify", "api"]);
    });

    test("announces a failure of a type the application named", () async {
      final service = await aService(authFailureTypes: {_AFailure});
      cloud.error = _AFailure();
      final announced = expectLater(service.authFailuresStream, emits(isA<_AFailure>()));

      await service.get("items");

      await announced;
    });

    test("announces nothing for a failure of a type the application did not name", () async {
      final service = await aService(authFailureTypes: {HttpStatusException});
      cloud.error = _AFailure();
      final announced = expectLater(service.authFailuresStream, neverEmits(anything));

      await service.get("items");
      await service.disposeLifeCycle();

      await announced;
    });

    test("announces nothing to an application which named no type at all", () async {
      final service = await aService();
      cloud.error = _AFailure();
      final announced = expectLater(service.authFailuresStream, neverEmits(anything));

      await service.get("items");
      await service.disposeLifeCycle();

      await announced;
    });
  });

  group("AmplifyApiService.disposeLifeCycle", () {
    test("closes the stream of the failures it announces", () async {
      final service = await aService();

      await service.disposeLifeCycle();

      await expectLater(service.authFailuresStream, emitsDone);
    });
  });
}
