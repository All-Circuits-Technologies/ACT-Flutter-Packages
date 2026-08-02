// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_amplify_core/act_amplify_core.dart';
import 'package:act_logger_manager/act_logger_manager.dart';
import 'package:act_test_utility/act_test_utility.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:flutter_test/flutter_test.dart';

/// A service which brings nothing of its own beyond what the base class asks for.
class _PlainService extends AbsAmplifyService {
  /// {@macro act_amplify_core.AbsAmplifyService.initLifeCycle}
  @override
  Future<void> initLifeCycle({LogsHelper? parentLogsHelper}) async =>
      super.initLifeCycle();

  @override
  Future<List<AmplifyPluginInterface>> getLinkedPluginsList() async => const [];

  /// Builds the helper of a service the way the base class offers it.
  static LogsHelper buildHelper({required String category, LogsHelper? parentLogsHelper}) =>
      AbsAmplifyService.createLogsHelper(
        logCategory: category,
        parentLogsHelper: parentLogsHelper,
      );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeExternalLogger logs;

  setUp(() {
    FakeGlobalManager.install();
    logs = FakeExternalLogger();
  });

  group("AbsAmplifyService.createLogsHelper", () {
    test("logs under the category of the service", () {
      final helper = _PlainService.buildHelper(
        category: "aService",
        parentLogsHelper: logs.buildHelper(),
      );

      helper.i("something happened");

      expect(logs.records.single.categories, ["aService"]);
    });

    test("logs under the category of the manager and its own", () {
      final helper = _PlainService.buildHelper(
        category: "aService",
        parentLogsHelper: logs.buildHelper(category: "amplify"),
      );

      helper.i("something happened");

      expect(logs.records.single.categories, ["amplify", "aService"]);
    });

    test("logs under its own category when the manager gives no helper", () {
      final helper = _PlainService.buildHelper(category: "aService");

      expect(helper.categories, ["aService"]);
    });
  });

  group("AbsAmplifyService.updateAmplifyConfig", () {
    test("completes nothing unless the service says otherwise", () async {
      final config = AmplifyConfig.fromJson(const {});

      expect(await _PlainService().updateAmplifyConfig(config), same(config));
    });
  });

  group("AmplifyManagerConfig", () {
    test("carries no service unless the application declares one", () {
      const config = AmplifyManagerConfig(loggerEnabled: false, amplifyConfig: "{}");

      expect(config.amplifyServices, isEmpty);
      expect(config.parentLogsHelper, isNull);
    });

    test("equals another configuration which carries the same values", () {
      expect(
        const AmplifyManagerConfig(loggerEnabled: true, amplifyConfig: "{}"),
        const AmplifyManagerConfig(loggerEnabled: true, amplifyConfig: "{}"),
      );
    });

    test("differs from a configuration whose logs are off", () {
      expect(
        const AmplifyManagerConfig(loggerEnabled: true, amplifyConfig: "{}"),
        isNot(const AmplifyManagerConfig(loggerEnabled: false, amplifyConfig: "{}")),
      );
    });
  });
}
