// SPDX-FileCopyrightText: 2026 Dorian Benech <dorian.benech@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_config_manager/act_config_manager.dart';
import 'package:act_local_storage_manager/act_local_storage_manager.dart';
import 'package:act_oauth2_keycloak/act_oauth2_keycloak.dart';
import 'package:act_shared_auth/act_shared_auth.dart';
import 'package:act_shared_auth_local_storage/act_shared_auth_local_storage.dart';
import 'package:act_tb_extender_auth/act_tb_extender_auth.dart';
import 'package:act_test_utility/act_test_utility.dart';

/// The folder the configuration of the application under test is read from.
const configPath = "assets/config/";

/// The configuration of an application which signs its users in through Keycloak and exchanges
/// their tokens at the broker.
class FakeTbExtenderConfig extends AbstractConfigManager
    with MixinStoresConf, MixinKeycloakOAuth2Conf, MixinAuthLocalStorageConf, MixinTbExtenderConf {
  /// Class constructor
  FakeTbExtenderConfig() : super(logger: const SilentLogger());

  /// Serves [content] as the configuration file of the application and returns the manager which
  /// reads it.
  ///
  /// The caller has to stop serving the assets and to dispose the manager once the test is over.
  static Future<FakeTbExtenderConfig> withContent(String content) async {
    FakeAssets.serve({"${configPath}default.yaml": content});

    final manager = FakeTbExtenderConfig();
    await manager.initLifeCycle();

    return manager;
  }
}

/// The properties of the application under test.
class FakeTbExtenderProperties extends AbstractPropertiesManager {}

/// The secrets of that application, which hold its two sets of tokens.
class FakeTbExtenderSecrets extends AbstractSecretsManager
    with MixinAuthSecrets, MixinKeycloakAuthSecrets {
  /// Class constructor
  FakeTbExtenderSecrets({required super.propertiesGetter, required super.confGetter});
}

/// The tokens kept in memory rather than where the platform keeps its secrets.
class FakeAuthStorage with MixinAuthStorageService {
  /// The tokens the service stored, if it stored any.
  AuthTokens? stored;

  @override
  Future<AuthTokens?> loadTokens() async => stored;

  @override
  Future<bool> storeTokens({required AuthTokens tokens}) async {
    stored = tokens;
    return true;
  }

  @override
  Future<void> clearTokens() async => stored = null;
}
