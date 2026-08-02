// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_config_manager/act_config_manager.dart';
import 'package:act_licenses_manager/act_licenses_manager.dart';
import 'package:act_test_utility/act_test_utility.dart';

/// The folder the configuration of the application under test is read from.
const configPath = "assets/config/";

/// The configuration of the application under test.
class FakeLicensesConfig extends AbstractConfigManager with MixinLicensesConfig {
  /// Class constructor
  FakeLicensesConfig({super.logger = const SilentLogger()});

  /// Builds the configuration of an application from the [licenses] section given.
  ///
  /// The section is served as the configuration file of the application, so the manager reads it
  /// the way it reads the one of a real application. The [assets] are served alongside it, which
  /// is where the license files of an application live.
  static Future<FakeLicensesConfig> build(
    String licenses, {
    Map<String, String> assets = const {},
  }) async {
    FakeAssets.serve({"${configPath}default.yaml": licenses, ...assets});

    final config = FakeLicensesConfig();
    await config.initLifeCycle();

    return config;
  }
}
