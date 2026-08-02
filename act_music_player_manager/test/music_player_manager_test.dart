// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_foundation/act_foundation.dart';
import 'package:act_logger_manager/act_logger_manager.dart';
import 'package:act_music_player_manager/act_music_player_manager.dart';
import 'package:act_test_utility/act_test_utility.dart';
import 'package:flutter_test/flutter_test.dart';

/// The sounds an application plays.
enum _Sound {
  /// The sound of a button being pressed.
  click,

  /// A sound the application knows nothing about.
  unknown,
}

/// The sounds of the application under test.
class _SoundHelper extends AbstractMusicSoundHelper<_Sound> {
  /// Class constructor
  _SoundHelper()
    : super(
        musicSounds: const {
          _Sound.click: MusicSound(value: _Sound.click, filePath: "click.mp3"),
        },
      );
}

void main() {
  late FakeLogger logger;
  late MusicPlayerManager<_Sound> manager;

  setUp(() {
    logger = FakeLogger();
    FakeGlobalManager.install(logger: logger);
    manager = MusicPlayerManager<_Sound>(
      audioFilePrefix: "assets/sounds/",
      musicSoundsHelper: _SoundHelper(),
    );
  });

  group("MusicPlayerBuilder", () {
    test("depends on the logger manager", () {
      expect(
        MusicPlayerBuilder<_Sound>(
          audioFilePrefix: "assets/sounds/",
          musicSoundsHelper: _SoundHelper(),
        ).dependsOn(),
        [LoggerManager],
      );
    });

    test("builds a manager which reads its sounds from the folder it is given", () {
      final built = MusicPlayerBuilder<_Sound>(
        audioFilePrefix: "assets/sounds/",
        musicSoundsHelper: _SoundHelper(),
      ).factory();

      expect(built.audioFilePrefix, "assets/sounds/");
    });
  });

  group("MusicPlayerManager.play", () {
    test("refuses a sound the application never declared", () async {
      await manager.play(_Sound.unknown);

      expect(logger.recordsAtLevel(LogsLevel.warn).length, 1);
    });

    test("plays nothing when the sounds have not been loaded yet", () async {
      await expectLater(manager.play(_Sound.click), completes);
    });
  });

  group("MusicPlayerManager.stop", () {
    test("refuses a sound the application never declared", () async {
      await manager.stop(_Sound.unknown);

      expect(logger.recordsAtLevel(LogsLevel.warn).length, 1);
    });

    test("stops nothing when the sounds have not been loaded yet", () async {
      await expectLater(manager.stop(_Sound.click, stopAllSounds: true), completes);
    });
  });

  group("MusicPlayerManager.getDuration", () {
    test("returns nothing for a sound the application never declared", () async {
      expect(await manager.getDuration(_Sound.unknown), isNull);
      expect(logger.recordsAtLevel(LogsLevel.warn).length, 1);
    });

    test("returns nothing for a sound which has not been loaded yet", () async {
      expect(await manager.getDuration(_Sound.click), isNull);
    });
  });

  group("MusicPlayerManager.onPlayerComplete", () {
    test("returns no stream for a sound the application never declared", () {
      expect(manager.onPlayerComplete(_Sound.unknown), isNull);
      expect(logger.recordsAtLevel(LogsLevel.warn).length, 1);
    });

    test("returns no stream for a sound which has not been loaded yet", () {
      expect(manager.onPlayerComplete(_Sound.click), isNull);
    });
  });
}
