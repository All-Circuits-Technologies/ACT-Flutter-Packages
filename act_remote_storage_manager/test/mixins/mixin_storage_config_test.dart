// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_test_utility/act_test_utility.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fakes/fake_storage.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(FakeGlobalManager.install);

  tearDown(FakeAssets.stop);

  /// Builds the configuration of an application from the [storage] section given.
  Future<FakeStorageConfig> aConfig([String? storage]) async {
    final config = await (storage == null
        ? FakeStorageConfig.build()
        : FakeStorageConfig.build(storage));
    addTearDown(config.disposeLifeCycle);

    return config;
  }

  group("MixinStorageConfig", () {
    test("uses no cache unless the application asks for one", () async {
      expect((await aConfig()).storageCacheUseConf.load(), isFalse);
    });

    test("keeps the files of the cache for two weeks by default", () async {
      expect(
        (await aConfig()).storageCacheStalePeriodConf.load(),
        const Duration(days: 14),
      );
    });

    test("reads the days the files are kept for from the configuration", () async {
      final config = await aConfig("storage:\n  cache:\n    stalePeriod: 3");

      expect(config.storageCacheStalePeriodConf.load(), const Duration(days: 3));
    });

    test("keeps a hundred files in the cache by default", () async {
      expect((await aConfig()).storageCacheNumberOfObjectsCached.load(), 100);
    });

    test("reads the name of the cache from the configuration", () async {
      final config = await aConfig("storage:\n  cache:\n    key: my_cache");

      expect(config.storageCacheKeyConf.load(), "my_cache");
    });

    test("reads whether the cache is used from the configuration", () async {
      final config = await aConfig("storage:\n  cache:\n    use: true");

      expect(config.storageCacheUseConf.load(), isTrue);
    });
  });
}
