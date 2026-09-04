// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_config_manager/act_config_manager.dart';
import 'package:act_local_storage_manager/act_local_storage_manager.dart';
import 'package:act_local_storage_manager/src/constants/storage_constants.dart'
    as storage_constants;
import 'package:act_local_storage_manager/src/services/properties_singleton.dart';
import 'package:act_local_storage_manager/src/services/secrets_singleton.dart';
import 'package:act_logger_manager/act_logger_manager.dart';
import 'package:act_test_utility/act_test_utility.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

/// The folder the configuration of the application is read from.
const _configPath = "assets/config/";

/// The properties of the application under test.
class _PropertiesManager extends AbstractPropertiesManager {}

/// The builder of the properties of the application under test.
class _PropertiesBuilder extends AbstractPropertiesBuilder<_PropertiesManager> {
  /// Class constructor
  const _PropertiesBuilder() : super(_PropertiesManager.new);
}

/// The configuration of the application under test.
class _ConfigManager extends AbstractConfigManager with MixinStoresConf {
  /// Class constructor
  _ConfigManager({required super.logger});
}

/// The secrets of the application under test.
class _SecretsManager extends AbstractSecretsManager {
  /// Class constructor
  const _SecretsManager({required super.propertiesGetter, required super.confGetter});
}

/// The builder of the secrets of the application under test.
class _SecretsBuilder
    extends AbstractSecretsBuilder<_PropertiesManager, _ConfigManager, _SecretsManager> {
  /// Class constructor
  const _SecretsBuilder(super.factory);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() => SharedPreferencesAsyncPlatform.instance = InMemorySharedPreferencesAsync.empty());

  setUp(() async {
    FakeGlobalManager.install();
    FlutterSecureStorage.setMockInitialValues({});
    await PropertiesSingleton.createInstance().deleteAll();
    SecretsSingleton.createInstance();
  });

  tearDown(FakeAssets.stop);

  /// Builds the configuration of the application, with the value the test decides.
  Future<_ConfigManager> aConfig({required bool cleanWhenReInstall}) async {
    FakeAssets.serve({
      "${_configPath}default.yaml":
          "stores:\n  secrets:\n    cleanWhenReInstall: $cleanWhenReInstall",
    });
    final config = _ConfigManager(logger: const SilentLogger());
    await config.initLifeCycle();
    addTearDown(config.disposeLifeCycle);

    return config;
  }

  group("AbstractPropertiesBuilder", () {
    test("depends on the logger manager", () {
      expect(const _PropertiesBuilder().dependsOn(), [LoggerManager]);
    });
  });

  group("AbstractPropertiesManager", () {
    test("says the application is starting for the first time", () async {
      final manager = _PropertiesManager();

      await manager.initLifeCycle();

      expect(manager.isFirstStart, isTrue);
    });

    test("says the application has already been started the next time", () async {
      await _PropertiesManager().initLifeCycle();

      final manager = _PropertiesManager();
      await manager.initLifeCycle();

      expect(manager.isFirstStart, isFalse);
    });

    test("says it is the first start again once the properties are gone", () async {
      final manager = _PropertiesManager();
      await manager.initLifeCycle();

      await manager.deleteAll();
      final reinstalled = _PropertiesManager();
      await reinstalled.initLifeCycle();

      expect(reinstalled.isFirstStart, isTrue);
    });

    test("makes the properties reachable by the items", () async {
      await _PropertiesManager().initLifeCycle();

      expect(PropertiesSingleton.instance, isNotNull);
    });
  });

  group("AbstractSecretsBuilder", () {
    test("depends on the logger, on the properties and on the configuration", () {
      expect(const _SecretsBuilder(_secretsFactory).dependsOn(), [
        LoggerManager,
        _PropertiesManager,
        _ConfigManager,
      ]);
    });
  });

  group("AbstractSecretsManager", () {
    test("forgets the secrets of a previous install on the first start", () async {
      final properties = _PropertiesManager();
      await properties.initLifeCycle();
      final config = await aConfig(cleanWhenReInstall: true);
      await const SecretItem<String>("aKey").store("a value");

      await _SecretsManager(propertiesGetter: () => properties, confGetter: () => config)
          .initLifeCycle();

      expect(await const SecretItem<String>("aKey").load(), isNull);
    });

    test("keeps the secrets when the application has already been started", () async {
      await _PropertiesManager().initLifeCycle();
      final properties = _PropertiesManager();
      await properties.initLifeCycle();
      final config = await aConfig(cleanWhenReInstall: true);
      await const SecretItem<String>("aKey").store("a value");

      await _SecretsManager(propertiesGetter: () => properties, confGetter: () => config)
          .initLifeCycle();

      expect(await const SecretItem<String>("aKey").load(), "a value");
    });

    test("keeps the secrets when the configuration asks it to", () async {
      final properties = _PropertiesManager();
      await properties.initLifeCycle();
      final config = await aConfig(cleanWhenReInstall: false);
      await const SecretItem<String>("aKey").store("a value");

      await _SecretsManager(propertiesGetter: () => properties, confGetter: () => config)
          .initLifeCycle();

      expect(await const SecretItem<String>("aKey").load(), "a value");
    });

    test("forgets every secret when it is asked to", () async {
      final properties = _PropertiesManager();
      await properties.initLifeCycle();
      final config = await aConfig(cleanWhenReInstall: false);
      final manager = _SecretsManager(
        propertiesGetter: () => properties,
        confGetter: () => config,
      );
      await manager.initLifeCycle();
      await const SecretItem<String>("aKey").store("a value");

      await manager.deleteAll();

      expect(await const SecretItem<String>("aKey").load(), isNull);
    });
  });

  group("MixinStoresConf", () {
    test("reads whether the secrets are cleaned from the configuration", () async {
      final config = await aConfig(cleanWhenReInstall: false);

      expect(config.cleanSecretStorageWhenReinstall.load(), isFalse);
    });

    test("cleans the secrets when the configuration says nothing", () async {
      FakeAssets.serve({"${_configPath}default.yaml": "logs:\n  level: warning"});
      final config = _ConfigManager(logger: const SilentLogger());
      await config.initLifeCycle();
      addTearDown(config.disposeLifeCycle);

      expect(
        config.cleanSecretStorageWhenReinstall.load(),
        storage_constants.defaultCleanSecretStorageWhenReinstallValue,
      );
    });
  });
}

/// Builds the secrets of the application, for the test which only reads the dependencies.
_SecretsManager _secretsFactory() => _SecretsManager(
  propertiesGetter: _PropertiesManager.new,
  confGetter: () => _ConfigManager(logger: const SilentLogger()),
);
