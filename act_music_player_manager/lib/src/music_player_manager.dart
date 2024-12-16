// Copyright (c) 2020. BMS Circuits

import 'dart:async';
import 'dart:io';

import 'package:act_abstract_manager/act_abstract_manager.dart';
import 'package:act_global_manager/act_global_manager.dart';
import 'package:act_logger_manager/act_logger_manager.dart';
import 'package:act_music_player_manager/src/music_sound.dart';
import 'package:audioplayers/audio_cache.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

/// Builder for creating the MusicPlayerManager
class MusicPlayerBuilder<T> extends ManagerBuilder<MusicPlayerManager> {
  /// Class constructor with the class construction
  MusicPlayerBuilder({
    @required String audioFilePrefix,
    @required AbstractMusicSoundHelper<T> musicSoundsHelper,
  }) : super(() => MusicPlayerManager<T>(
              audioFilePrefix: audioFilePrefix,
              musicSoundsHelper: musicSoundsHelper,
            ));

  /// List of manager dependence
  @override
  Iterable<Type> dependsOn() => [LoggerManager];
}

/// The [MusicPlayerManager] is a wrapper of the [audioplayers] plugin and simplifies
/// how it works
///
/// The [MusicPlayerManager] can only play known sounds.
/// It's recommended to use this class as a singleton with a global manager
class MusicPlayerManager<T> extends AbstractManager {
  final String audioFilePrefix;
  final AbstractMusicSoundHelper<T> _musicSoundsHelper;

  Map<MusicSound<T>, AudioPlayerHelper> _audioPlayers;
  AudioCache _audioCache;

  /// Class constructor
  MusicPlayerManager({
    @required this.audioFilePrefix,
    @required AbstractMusicSoundHelper<T> musicSoundsHelper,
  })  : assert(audioFilePrefix != null),
        assert(musicSoundsHelper != null),
        _musicSoundsHelper = musicSoundsHelper,
        super() {
    _audioPlayers = {};
    _audioCache = AudioCache(
      prefix: audioFilePrefix,
      respectSilence: true,
    );
  }

  /// The [init] method has to be called to initialize the class
  /// The method will load all sounds in cache
  @override
  Future<void> initManager() async {
    if (_audioCache.loadedFiles.isNotEmpty) {
      AppLogger().i('The class has already be initialized');
      return;
    }

    return _audioCache.loadAll(_musicSoundsHelper.getFilesList());
  }

  /// To call in order to stop all sounds played and free the cache memory
  ///
  /// After calling  [dispose}, you have to call the [init] method if you want
  /// to reuse the class.
  @override
  Future<void> dispose() async {
    final futures = <Future>[];

    _audioPlayers.forEach((MusicSound key, AudioPlayerHelper help) {
      if (help.audioPlayer.state != AudioPlayerState.STOPPED) {
        final completer = Completer<void>();

        help.audioPlayer.stop().then((result) {
          if (help.audioPlayer.state != AudioPlayerState.STOPPED) {
            AppLogger().w("The sound ${key.value.toString()} can't be "
                "stopped, current state: ${help.audioPlayer.state}");
          }

          completer.complete(help.audioPlayer.dispose());
        });

        futures.add(completer.future);
      } else {
        futures.add(help.audioPlayer.dispose());
      }
    });

    return Future.wait(futures).then((value) {
      _audioPlayers.clear();
      _audioCache.clearCache();
    });
  }

  /// Private method to stop the music wanted
  ///
  /// Stop all the music in the [musicSoundFilter] list
  Future<void> _stopAllElements({
    List<MusicSound> musicSoundFilter,
  }) async {
    if (musicSoundFilter.isEmpty) {
      return;
    }

    final futures = <Future>[];

    _audioPlayers.forEach((MusicSound key, AudioPlayerHelper help) {
      if (!musicSoundFilter.contains(key) ||
          (help.audioPlayer.state == AudioPlayerState.STOPPED)) {
        return;
      }

      final completer = Completer<void>();

      help.audioPlayer.stop().then((result) async {
        if (help.audioPlayer.state != AudioPlayerState.STOPPED) {
          AppLogger().w("The sound ${key.value.toString()} hasn't be stopped, "
              "current state: ${help.audioPlayer.state}");
        }

        help.elapsedTimer.stop();

        await help.audioPlayer.setReleaseMode(ReleaseMode.STOP);

        completer.complete();
      });

      futures.add(completer.future);
    });

    return Future.wait(futures);
  }

  /// Play the music targeted, only one sound of a particular type can be played
  /// at once.
  ///
  /// If [loop] is equals to true, the music will be played in loop
  /// If [stopAllTheOthersSounds] is equals to true, the method will stop all
  /// the others sounds
  /// If [doNotPlayIfPrevSameSoundStartedBefore] not null, this say: don't play
  /// this sound, if the same sound is currently being played from less than
  /// this duration. This prevent to have the sound stopped without being played
  /// in a loop
  Future<void> play(
    T musicSound, {
    bool loop = false,
    bool stopAllTheOthersSounds = false,
    double volume = 1.0,
    Duration doNotPlayIfPrevSameSoundStartedBefore,
  }) async {
    if (!_musicSoundsHelper.musicSounds.containsKey(musicSound)) {
      AppLogger().w("The music sound $musicSound doesn't exist in manager, "
          "can't play the wanted sound");
      return;
    }

    final tmpMusicSound = _musicSoundsHelper.musicSounds[musicSound];

    if (doNotPlayIfPrevSameSoundStartedBefore != null &&
        _audioPlayers.containsKey(tmpMusicSound) &&
        !_audioPlayers[tmpMusicSound].isElapsedEqOrAfterDuration(
            doNotPlayIfPrevSameSoundStartedBefore)) {
      // Do not play the sound if not enough time passed
      return;
    }

    final elementsToStop = <MusicSound>[];

    if (stopAllTheOthersSounds) {
      elementsToStop.addAll(_audioPlayers.keys);
      elementsToStop.remove(tmpMusicSound);
    } else {
      elementsToStop.add(tmpMusicSound);
    }

    await _stopAllElements(musicSoundFilter: elementsToStop);

    AudioPlayerHelper helper;

    if (!_audioPlayers.containsKey(tmpMusicSound)) {
      AudioPlayer audioPlayer;

      if (!loop) {
        audioPlayer = await _audioCache.play(
          tmpMusicSound.filePath,
          isNotification: true,
          mode: PlayerMode.LOW_LATENCY,
          volume: volume,
        );
      } else {
        audioPlayer = await _audioCache.loop(
          tmpMusicSound.filePath,
          isNotification: true,
          mode: PlayerMode.LOW_LATENCY,
          volume: volume,
        );
      }

      helper = AudioPlayerHelper(audioPlayer: audioPlayer);
      helper.elapsedTimer.start();

      _audioPlayers[tmpMusicSound] = helper;
    } else {
      helper = _audioPlayers[tmpMusicSound];

      final url = await _audioCache.getAbsoluteUrl(tmpMusicSound.filePath);

      if (loop) {
        await helper.audioPlayer.setReleaseMode(ReleaseMode.LOOP);
      }

      await helper.audioPlayer.play(url, respectSilence: true);
      helper.elapsedTimer.start();
      helper.elapsedTimer.reset();
    }
  }

  /// Call the [stop] method to stop a particular sound played
  ///
  /// Set [stopAllSounds] to true, to stop all the sounds
  Future<void> stop(
    T musicSound, {
    bool stopAllSounds = false,
  }) async {
    if (!_musicSoundsHelper.musicSounds.containsKey(musicSound)) {
      AppLogger().w("The music sound $musicSound doesn't exist in manager, "
          "can't stop the wanted sound");
      return;
    }

    final tmpMusicSound = _musicSoundsHelper.musicSounds[musicSound];

    final elementsToStop = <MusicSound>[];

    if (stopAllSounds) {
      elementsToStop.addAll(_audioPlayers.keys);
    } else {
      elementsToStop.add(tmpMusicSound);
    }

    return _stopAllElements(musicSoundFilter: elementsToStop);
  }
}

/// Helper which contains all the needed elements for extending the AudioPlayer
class AudioPlayerHelper {
  AudioPlayer audioPlayer;
  Stopwatch elapsedTimer;

  /// Class constructor
  AudioPlayerHelper({this.audioPlayer}) : elapsedTimer = Stopwatch() {
    // This is compulsory to avoid fatal error in iOS but doesn't exist on
    // Android and create also a fatal error if present
    if (Platform.isIOS) {
      audioPlayer.monitorNotificationStateChanges(monitorNotifications);
    }
  }

  /// Test if the elapsed timer value is equals or more than the duration given
  bool isElapsedEqOrAfterDuration(Duration durationToTest) =>
      elapsedTimer.elapsed.compareTo(durationToTest) >= 0;

  /// Only useful in iOS to prevent fatal errors
  static void monitorNotifications(AudioPlayerState value) => null;
}
