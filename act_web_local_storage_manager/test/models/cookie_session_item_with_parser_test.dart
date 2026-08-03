@TestOn('browser')
// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1
library;

import 'package:act_test_utility/act_test_utility.dart';
import 'package:act_web_local_storage_manager/act_web_local_storage_manager.dart';
import 'package:act_web_local_storage_manager/src/services/cookie_session_singleton.dart';
import 'package:flutter_test/flutter_test.dart';

/// The moment a test writes to the cookies.
final _aMoment = DateTime.utc(2026, 5, 17, 10, 30);

/// An item which keeps a moment as the number of milliseconds since the epoch.
CookieSessionItemWithParser<DateTime, int> _aMomentItem(String key) =>
    CookieSessionItemWithParser<DateTime, int>(
      key,
      parser: (value) => DateTime.fromMillisecondsSinceEpoch(value, isUtc: true),
      castTo: (value) => value.millisecondsSinceEpoch,
    );

void main() {
  setUp(() {
    FakeGlobalManager.install();
    CookieSessionSingleton.createInstance();
  });

  group("CookieSessionItemWithParser", () {
    test("reads back the value it wrote, in the type of the application", () async {
      final item = _aMomentItem("aMoment");

      await item.store(_aMoment);

      expect(await item.load(), _aMoment);
    });

    test("keeps the value in the type the cookies hold", () async {
      final item = _aMomentItem("aStoredMoment");

      await item.store(_aMoment);

      expect(
        await const CookieSessionItem<int>("aStoredMoment").load(),
        _aMoment.millisecondsSinceEpoch,
      );
    });

    test("reads nothing before anything was written under its key", () async {
      expect(await _aMomentItem("nothingHere").load(), isNull);
    });

    test("reads nothing when the parser refuses what was written", () async {
      final item = CookieSessionItemWithParser<DateTime, int>(
        "aRefusedMoment",
        parser: (value) => null,
        castTo: (value) => value.millisecondsSinceEpoch,
      );
      await item.store(_aMoment);

      expect(await item.load(), isNull);
    });

    test("reads nothing once it was deleted", () async {
      final item = _aMomentItem("aDeletedMoment");
      await item.store(_aMoment);

      await item.delete();

      expect(await item.load(), isNull);
    });
  });
}
