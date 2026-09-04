// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_config_manager/act_config_manager.dart';
import 'package:act_intl/act_intl.dart';
import 'package:act_local_storage_manager/act_local_storage_manager.dart';
import 'package:act_test_utility/act_test_utility.dart';

/// The loggers the tests read the messages of the manager from.
enum FakeLoggers {
  /// The only logger of the tests.
  records,
}

/// The configuration of the application under test.
///
/// A real configuration reads its environment from the value the application was built with, and
/// a test cannot build itself twice. This one takes the environment as an argument and drops the
/// one the build gives it.
class FakeLocaleConfig extends AbstractConfigManager with MixinLocaleConfig {
  /// The environment the test wants the application to run in.
  final Environment _env;

  @override
  Environment get env => _env;

  @override
  set env(Environment value) {
    // The environment of the build is dropped: the test decides which one the application runs in.
  }

  /// Class constructor
  FakeLocaleConfig({Environment env = Environment.development})
    : _env = env,
      super(logger: const SilentLogger());
}

/// The properties of the application under test.
class FakeLocaleProperties extends AbstractPropertiesManager with MixinLocaleProperties {}
