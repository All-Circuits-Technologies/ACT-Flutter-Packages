// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'dart:ui';

import 'package:act_remote_local_vers_file_manager/act_remote_local_vers_file_manager.dart';
import 'package:act_test_utility/act_test_utility.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUp(FakeGlobalManager.install);

  group("RemoteLocalDirOptions.parseFromJson", () {
    test("reads the locales, and whether the files and the versions are kept", () {
      final options = RemoteLocalDirOptions.parseFromJson(const {
        "locales": ["fr_FR", "en_GB"],
        "cacheVersion": true,
        "cacheFile": false,
      })!;

      expect(options.locales, [const Locale("fr", "FR"), const Locale("en", "GB")]);
      expect(options.cacheVersion, isTrue);
      expect(options.cacheFile, isFalse);
    });

    test("leaves every option undecided when the configuration names none", () {
      final options = RemoteLocalDirOptions.parseFromJson(const {})!;

      expect(options.locales, isNull);
      expect(options.cacheVersion, isNull);
      expect(options.cacheFile, isNull);
    });

    test("refuses an option which is not of the type its key carries", () {
      expect(RemoteLocalDirOptions.parseFromJson(const {"cacheFile": "yes"}), isNull);
    });

    test("refuses locales which are not written as locales", () {
      expect(
        RemoteLocalDirOptions.parseFromJson(const {
          "locales": ["fr_FR_extra"],
        }),
        isNull,
      );
    });
  });

  group("RemoteLocalDirOptions.copyWith", () {
    test("keeps what is not named", () {
      const options = RemoteLocalDirOptions(
        locales: [Locale("fr", "FR")],
        cacheVersion: true,
        cacheFile: false,
      );

      final copy = options.copyWith();

      expect(copy.locales, options.locales);
      expect(copy.cacheVersion, options.cacheVersion);
      expect(copy.cacheFile, options.cacheFile);
    });

    test("replaces what is named", () {
      const options = RemoteLocalDirOptions(locales: [Locale("fr", "FR")], cacheVersion: true);

      final copy = options.copyWith(locales: const [Locale("en", "GB")], cacheVersion: false);

      expect(copy.locales, [const Locale("en", "GB")]);
      expect(copy.cacheVersion, isFalse);
    });

    test("forgets what the copy is asked to force", () {
      const options = RemoteLocalDirOptions(
        locales: [Locale("fr", "FR")],
        cacheVersion: true,
        cacheFile: true,
      );

      final copy = options.copyWith(
        forceLocalesValue: true,
        forceCacheVersionValue: true,
        forceCacheFileValue: true,
      );

      expect(copy.locales, isNull);
      expect(copy.cacheVersion, isNull);
      expect(copy.cacheFile, isNull);
    });

    test("keeps the way of naming a file the copy is given", () {
      const options = RemoteLocalDirOptions();

      final copy = options.copyWith(versionToFileName: (version) => "$version.md");

      expect(copy.versionToFileName?.call("v2"), "v2.md");
    });
  });

  group("RemoteLocalDirOptions", () {
    test("is the same options as another one which decides the same", () {
      expect(
        const RemoteLocalDirOptions(locales: [Locale("fr", "FR")], cacheFile: true),
        const RemoteLocalDirOptions(locales: [Locale("fr", "FR")], cacheFile: true),
      );
    });

    test("is another options as soon as one of them differs", () {
      expect(
        const RemoteLocalDirOptions(cacheFile: true),
        isNot(const RemoteLocalDirOptions(cacheFile: false)),
      );
    });
  });
}
