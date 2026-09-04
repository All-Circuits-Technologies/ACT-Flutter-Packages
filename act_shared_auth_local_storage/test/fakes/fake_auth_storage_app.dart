// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_config_manager/act_config_manager.dart';
import 'package:act_local_storage_manager/act_local_storage_manager.dart';
import 'package:act_shared_auth_local_storage/act_shared_auth_local_storage.dart';
import 'package:act_test_utility/act_test_utility.dart';

/// The folder the configuration of the application under test is read from.
const configPath = "assets/config/";

/// The configuration of the application under test.
class FakeAuthConfig extends AbstractConfigManager
    with MixinStoresConf, MixinAuthLocalStorageConf {
  /// Class constructor
  FakeAuthConfig() : super(logger: const SilentLogger());
}

/// The properties of the application under test, which hold the tokens in clear text.
class FakeAuthProperties extends AbstractPropertiesManager with MixinAuthNotSecuredSecrets {}

/// The secrets of the application under test, which hold the tokens where the platform keeps its
/// secrets.
class FakeAuthSecrets extends AbstractSecretsManager with MixinAuthSecrets {
  /// Class constructor
  FakeAuthSecrets({required super.propertiesGetter, required super.confGetter});
}
