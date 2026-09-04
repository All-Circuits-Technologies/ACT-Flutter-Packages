@TestOn('browser')
// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1
library;

import 'package:act_foundation/act_foundation.dart';
import 'package:act_local_storage_manager/act_local_storage_manager.dart';
import 'package:act_test_utility/act_test_utility.dart';
import 'package:act_web_local_storage_manager/act_web_local_storage_manager.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

/// The properties of an application which keeps some of them in the cookies of the session.
class _Properties extends AbstractPropertiesManager with MixinSessionProperties {
  /// The value the application keeps for as long as the session lasts.
  final aSessionValue = const CookieSessionItem<String>("aSessionValue");

  /// The value the application keeps from one session to the next.
  final aStoredValue = SharedPreferencesItem<String>("aStoredValue");
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() => SharedPreferencesAsyncPlatform.instance = InMemorySharedPreferencesAsync.empty());

  late FakeLogger logger;
  late _Properties properties;

  setUp(() async {
    logger = FakeLogger();
    FakeGlobalManager.install(logger: logger);
    properties = _Properties();
    await properties.initLifeCycle();
  });

  group("MixinSessionProperties.initLifeCycle", () {
    test("opens the cookies of the session to the application", () async {
      await properties.aSessionValue.store("a value");

      expect(await properties.aSessionValue.load(), "a value");
    });
  });

  group("MixinSessionProperties.deleteAll", () {
    test("clears what the application keeps from one session to the next", () async {
      await properties.aStoredValue.store("a value");

      await properties.deleteAll();

      expect(await properties.aStoredValue.load(), isNull);
    });

    test("keeps the cookies of the page, which are not all its own", () async {
      await properties.aSessionValue.store("a value");

      await properties.deleteAll();

      expect(await properties.aSessionValue.load(), "a value");
      expect(logger.recordsAtLevel(LogsLevel.warn), hasLength(1));
    });
  });
}
