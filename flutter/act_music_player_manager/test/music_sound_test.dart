// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_music_player_manager/act_music_player_manager.dart';
import 'package:flutter_test/flutter_test.dart';

/// The sounds an application plays.
enum _Sound {
  /// The sound of a button being pressed.
  click,

  /// The sound of an alarm going off.
  alarm,

  /// Another sound, which is the same file as the alarm.
  warning,
}

/// The sounds of the application under test.
class _SoundHelper extends AbstractMusicSoundHelper<_Sound> {
  /// Class constructor
  _SoundHelper(Map<_Sound, MusicSound<_Sound>> sounds) : super(musicSounds: sounds);
}

void main() {
  group("MusicSound", () {
    test("equals another sound of the same value", () {
      expect(
        const MusicSound(value: _Sound.click, filePath: "click.mp3"),
        const MusicSound(value: _Sound.click, filePath: "click.mp3"),
      );
    });

    test("equals a sound of the same value which comes from another file", () {
      // A sound is named by its value, which is what an application asks to play
      expect(
        const MusicSound(value: _Sound.click, filePath: "click.mp3"),
        const MusicSound(value: _Sound.click, filePath: "another.mp3"),
      );
    });

    test("differs from a sound of another value", () {
      expect(
        const MusicSound(value: _Sound.click, filePath: "click.mp3"),
        isNot(const MusicSound(value: _Sound.alarm, filePath: "click.mp3")),
      );
    });
  });

  group("AbstractMusicSoundHelper.getFilesList", () {
    test("returns the file of every sound", () {
      final helper = _SoundHelper(const {
        _Sound.click: MusicSound(value: _Sound.click, filePath: "click.mp3"),
        _Sound.alarm: MusicSound(value: _Sound.alarm, filePath: "alarm.mp3"),
      });

      expect(helper.getFilesList(), ["click.mp3", "alarm.mp3"]);
    });

    test("returns the file of two sounds which share one, once per sound", () {
      final helper = _SoundHelper(const {
        _Sound.alarm: MusicSound(value: _Sound.alarm, filePath: "alarm.mp3"),
        _Sound.warning: MusicSound(value: _Sound.warning, filePath: "alarm.mp3"),
      });

      expect(helper.getFilesList(), ["alarm.mp3", "alarm.mp3"]);
    });

    test("returns nothing for an application which plays no sound", () {
      expect(_SoundHelper(const {}).getFilesList(), isEmpty);
    });

    test("builds the list once and keeps it", () {
      final helper = _SoundHelper(const {
        _Sound.click: MusicSound(value: _Sound.click, filePath: "click.mp3"),
      });

      expect(helper.getFilesList(), same(helper.getFilesList()));
    });
  });
}
