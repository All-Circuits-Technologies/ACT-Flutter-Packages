// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_amplify_core/act_amplify_core.dart';
import 'package:act_config_manager/act_config_manager.dart';
import 'package:act_logger_manager/act_logger_manager.dart';
import 'package:act_test_utility/act_test_utility.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fakes/fake_amplify_service.dart';

/// A configuration of the cloud which can be read.
const _validConfig = '{"UserAgent": "aws-amplify-cli/2.0", "Version": "1.0"}';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(FakeGlobalManager.install);

  group("AbsAmplifyBuilder", () {
    test("depends on the logger manager and on the configuration", () {
      final builder = FakeAmplifyBuilder(
        () => FakeAmplifyManager(
          const AmplifyManagerConfig(loggerEnabled: false, amplifyConfig: _validConfig),
        ),
      );

      expect(builder.dependsOn(), [LoggerManager, AbstractConfigManager]);
    });
  });

  group("AbsAmplifyManager.initLifeCycle", () {
    test("asks every service to complete the configuration of the cloud", () async {
      final first = FakeAmplifyService();
      final second = FakeAmplifyService();
      final manager = FakeAmplifyManager(
        AmplifyManagerConfig(
          loggerEnabled: false,
          amplifyConfig: _validConfig,
          amplifyServices: [first, second],
        ),
      );

      await manager.initLifeCycle();

      expect(first.updatedConfigs.length, 1);
      expect(second.updatedConfigs.length, 1);
    });

    test("hands each service the configuration the previous one completed", () async {
      final first = FakeAmplifyService();
      final second = FakeAmplifyService();
      final manager = FakeAmplifyManager(
        AmplifyManagerConfig(
          loggerEnabled: false,
          amplifyConfig: _validConfig,
          amplifyServices: [first, second],
        ),
      );

      await manager.initLifeCycle();

      expect(second.updatedConfigs.single, same(first.updatedConfigs.single));
    });

    test("gives up when the configuration of the cloud cannot be read", () async {
      final service = FakeAmplifyService();
      final manager = FakeAmplifyManager(
        AmplifyManagerConfig(
          loggerEnabled: false,
          amplifyConfig: "not a configuration",
          amplifyServices: [service],
        ),
      );

      await manager.initLifeCycle();

      expect(service.updatedConfigs, isEmpty);
      expect(service.initCount, 0);
    });

    test("gives up when a service refuses to complete the configuration", () async {
      final service = FakeAmplifyService(refusesTheConfig: true);
      final manager = FakeAmplifyManager(
        AmplifyManagerConfig(
          loggerEnabled: false,
          amplifyConfig: _validConfig,
          amplifyServices: [service],
        ),
      );

      await manager.initLifeCycle();

      expect(service.initCount, 0);
    });

    test("reads the configuration as it is when the application has no service", () async {
      final manager = FakeAmplifyManager(
        const AmplifyManagerConfig(loggerEnabled: false, amplifyConfig: "not a configuration"),
      );

      // The configuration is only read to be completed, which nothing asks for here
      await expectLater(manager.initLifeCycle(), completes);
    });

    test("initializes no service when the cloud refuses the configuration", () async {
      // No cloud answers in a test, so configuring it always fails here
      final service = FakeAmplifyService();
      final manager = FakeAmplifyManager(
        AmplifyManagerConfig(
          loggerEnabled: false,
          amplifyConfig: _validConfig,
          amplifyServices: [service],
        ),
      );

      await manager.initLifeCycle();

      expect(service.initCount, 0);
    });
  });

  group("AbsAmplifyManager.disposeLifeCycle", () {
    test("disposes every service of the application", () async {
      final first = FakeAmplifyService();
      final second = FakeAmplifyService();
      final manager = FakeAmplifyManager(
        AmplifyManagerConfig(
          loggerEnabled: false,
          amplifyConfig: _validConfig,
          amplifyServices: [first, second],
        ),
      );
      await manager.initLifeCycle();

      await manager.disposeLifeCycle();

      expect(first.disposeCount, 1);
      expect(second.disposeCount, 1);
    });
  });
}
