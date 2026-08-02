// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_config_manager/act_config_manager.dart';
import 'package:act_test_utility/act_test_utility.dart';

/// The configuration of an application, built on the environment the test wants.
///
/// A real configuration reads its environment from the value the application was built with, and
/// a test cannot build itself twice. This one takes the environment as an argument and drops the
/// one the build gives it.
class FakeAppConfig extends AbstractConfigManager {
  /// The environment the test wants the application to run in.
  final Environment _env;

  @override
  Environment get env => _env;

  @override
  set env(Environment value) {
    // The environment of the build is dropped: the test decides which one the application runs in.
  }

  /// Class constructor
  FakeAppConfig({Environment env = Environment.development})
    : _env = env,
      super(logger: const SilentLogger());
}
