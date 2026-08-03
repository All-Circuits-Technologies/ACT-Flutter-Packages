// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_test_utility/act_test_utility.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fakes/fake_auth_storage_app.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  tearDown(FakeAssets.stop);

  /// The configuration of an application whose file says [content].
  Future<FakeAuthConfig> aConfig([String content = "logs:\n  level: warning"]) async {
    FakeAssets.serve({"${configPath}default.yaml": content});

    final config = FakeAuthConfig();
    await config.initLifeCycle();
    addTearDown(config.disposeLifeCycle);

    return config;
  }

  group("MixinAuthLocalStorageConf", () {
    test("reads that an application keeps the credentials of its users", () async {
      final config = await aConfig(
        "auth:\n  secrets:\n    localStorage:\n      saveUserIds: true",
      );

      expect(config.saveUserIdsInStorage.load(), isTrue);
    });

    test("keeps no credentials for an application which says nothing", () async {
      final config = await aConfig();

      expect(config.saveUserIdsInStorage.load(), isFalse);
    });
  });
}
