// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_global_manager/act_global_manager.dart';
import 'package:act_logger_manager/act_logger_manager.dart';
// The global manager this package defines is the one under test, so its own fake is the one to
// drive here, not the shared one which stands in for it elsewhere
import 'package:act_test_utility/act_test_utility.dart' hide FakeGlobalManager;
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';

import '../fakes/fake_app_config_manager.dart';
import '../fakes/fake_global_managers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeAppConfigManager config;
  late FlutterExceptionHandler? initialFlutterHandler;

  setUp(() => initialFlutterHandler = FlutterError.onError);

  tearDown(() async {
    FlutterError.onError = initialFlutterHandler;
    await config.disposeLifeCycle();
    FakeAssets.stop();
    await GetIt.instance.reset();
  });

  /// Registers the config manager of the application and the global manager the builder reads it
  /// through.
  Future<void> registerConfig() async {
    FakeGlobalManager();
    config = await FakeAppConfigManager.withContent("logs:\n  level: trace");
    globalGetIt().registerSingleton<FakeAppConfigManager>(config);
  }

  group("ExtDefaultLoggerBuilder", () {
    test("depends on the config manager it reads the level of the logs from", () async {
      await registerConfig();

      final builder = ExtDefaultLoggerBuilder<FakeAppConfigManager>();

      expect(builder.dependsOn(), [FakeAppConfigManager]);
    });

    test("builds a logger manager which reads the configuration of the application", () async {
      await registerConfig();

      final manager = await ExtDefaultLoggerBuilder<FakeAppConfigManager>().asyncFactory();

      expect(manager, isA<DefaultLoggerManager>());

      await manager.disposeLifeCycle();
    });
  });
}
