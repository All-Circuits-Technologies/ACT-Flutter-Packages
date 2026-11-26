// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_test_utility/act_test_utility.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fakes/fake_api.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeApiConfigManager config;

  setUp(FakeGlobalManager.install);

  tearDown(() async {
    await config.disposeLifeCycle();
    FakeAssets.stop();
  });

  group("MixinAmplifyApiConfig.amplifyApiConfig", () {
    test("reads the endpoints the application declared", () async {
      config = await FakeApiConfigManager.withContent(anApiConf);

      final endpoints = config.amplifyApiConfig.load()?.awsPlugin?.endpoints;

      expect(endpoints?["anApi"]?.endpoint, "https://an.api/prod");
    });

    test("reads how the endpoint of the application is authorized", () async {
      config = await FakeApiConfigManager.withContent(anApiConf);

      final endpoints = config.amplifyApiConfig.load()?.awsPlugin?.endpoints;

      expect(endpoints?["anApi"]?.authorizationType, APIAuthorizationType.none);
    });

    test("reads nothing from an application which declares no endpoint", () async {
      config = await FakeApiConfigManager.withContent("anotherKey: aValue");

      expect(config.amplifyApiConfig.load(), isNull);
    });
  });
}
