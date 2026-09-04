// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_config_manager/act_config_manager.dart';
import 'package:act_internet_connectivity_manager/act_internet_connectivity_manager.dart';
import 'package:act_test_utility/act_test_utility.dart';

/// The folder the configuration of the application under test is read from.
const configPath = "assets/config/";

/// A host which always answers, without any network.
const reachableHost = "https://localhost";

/// A host which never answers, whatever the network is.
const unreachableHost = "https://nothing.invalid";

/// The configuration of the application under test.
class FakeInternetConfig extends AbstractConfigManager with MixinInternetTestConfig {
  /// Class constructor
  FakeInternetConfig({super.logger = const SilentLogger()});

  /// Builds the configuration of an application which tests [host].
  ///
  /// The test waits for two answers which agree, and does not pause between them, so that a test
  /// never waits on a real delay.
  static Future<FakeInternetConfig> build({
    String host = reachableHost,
    String extra = "",
  }) async {
    FakeAssets.serve({
      "${configPath}default.yaml":
          "internetConnectivity:\n"
          "  serverUriToTest: $host\n"
          "  testPeriodInMs: 0\n"
          "  constantValueNb: 1\n"
          "$extra",
    });

    final config = FakeInternetConfig();
    await config.initLifeCycle();

    return config;
  }
}
