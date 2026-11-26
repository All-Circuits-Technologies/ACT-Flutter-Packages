// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'dart:ui';

import 'package:act_remote_local_vers_file_manager/act_remote_local_vers_file_manager.dart';
import 'package:act_test_utility/act_test_utility.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fakes/fake_remote_dir.dart';

/// Reads the configuration of the folders of an application from [json].
RemoteLocalDirConfig<FakeDirType>? _parse(Map<String, dynamic> json) =>
    RemoteLocalDirConfig.parseFromJson<FakeDirType>(json, dirTypes: FakeDirType.values);

void main() {
  setUp(FakeGlobalManager.install);

  group("RemoteLocalDirConfig.parseFromJson", () {
    test("reads the options of every folder of the application", () {
      final config = _parse(const {
        "terms": {"cacheFile": false},
        "release_notes": {
          "locales": ["en_GB"],
        },
      })!;

      expect(config.options[FakeDirType.terms]?.cacheFile, isFalse);
      expect(config.options[FakeDirType.releaseNotes]?.locales, [const Locale("en", "GB")]);
    });

    test("drops a folder the application does not know", () {
      final config = _parse(const {
        "terms": {"cacheFile": false},
        "aFolderWhichDoesNotExist": {"cacheFile": true},
      })!;

      expect(config.options.keys, [FakeDirType.terms]);
    });

    test("drops a folder whose options are not written as options", () {
      final config = _parse(const {"terms": "cacheFile"})!;

      expect(config.options, isEmpty);
    });

    test("drops a folder whose options cannot be read", () {
      final config = _parse(const {
        "terms": {"cacheFile": "yes"},
      })!;

      expect(config.options, isEmpty);
    });

    test("reads a configuration which names no folder", () {
      expect(_parse(const {})?.options, isEmpty);
    });
  });

  group("RemoteLocalDirConfig.copyWith", () {
    test("keeps the options it is not given new ones for", () {
      final config = _parse(const {
        "terms": {"cacheFile": false},
      })!;

      expect(config.copyWith().options, config.options);
    });

    test("replaces the options it is given", () {
      final config = _parse(const {
        "terms": {"cacheFile": false},
      })!;

      final copy = config.copyWith(
        options: {FakeDirType.terms: const RemoteLocalDirOptions(cacheFile: true)},
      );

      expect(copy.options[FakeDirType.terms]?.cacheFile, isTrue);
    });
  });
}
