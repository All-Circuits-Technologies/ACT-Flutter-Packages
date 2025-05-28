// SPDX-FileCopyrightText: 2020 - 2023 Sami Kouatli <sami.kouatli@allcircuits.com>
// SPDX-FileCopyrightText: 2023 Anthony Loiseau <anthony.loiseau@allcircuits.com>
// SPDX-FileCopyrightText: 2023 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'dart:async';

import 'package:act_abstract_manager/act_abstract_manager.dart';
import 'package:act_global_manager/act_global_manager.dart';
import 'package:act_logger_manager/act_logger_manager.dart';
import 'package:act_music_player_manager/src/music_sound.dart';
import 'package:audioplayers/audioplayers.dart';

/// Builder for creating the MusicPlayerManager
class MusicPlayerBuilder<T> extends AbsManagerBuilder<MusicPlayerManager> {
  /// Class constructor with the class construction
  MusicPlayerBuilder({
    required String audioFilePrefix,
    required AbstractMusicSoundHelper<T> musicSoundsHelper,
  }) : super(() => MusicPlayerManager<T>(
              audioFilePrefix: audioFilePrefix,
              musicSoundsHelper: musicSoundsHelper,
            ));

  /// List of manager dependence
  @override
  Iterable<Type> dependsOn() => [LoggerManager];
}

/// The [MusicPlayerManager] is a wrapper of the `audioplayers` plugin and simplifies
/// how it works
///
/// The [MusicPlayerManager] can only play known sounds.
/// It's recommended to use this class as a singleton with a global manager
class MusicPlayerManager<T> extends AbsWithLifeCycle {
  /// This is the path inside the assets folder where your files lie.
  final String audioFilePrefix;

  /// This is the music sounds helper used to manage the musics
  final AbstractMusicSoundHelper<T> _musicSoundsHelper;

  /// This is the audio players used in the manager
  final Map<String, AudioPlayerHelper> _audioPlayers;

  /// Class constructor
  MusicPlayerManager({
    required this.audioFilePrefix,
    required AbstractMusicSoundHelper<T> musicSoundsHelper,
  })  : _musicSoundsHelper = musicSoundsHelper,
        _audioPlayers = {},
        super();

  /// The [initLifeCycle] method has to be called to initialize the class
  /// The method will load all sounds in cache
  @override
  Future<void> initLifeCycle() async {
    await super.initLifeCycle();
    AudioCache.instance.prefix = audioFilePrefix;
    await AudioPlayer.global.setAudioContext(AudioContextConfig(
      respectSilence: true,
    ).build());

    if (AudioCache.instance.loadedFiles.isNotEmpty) {
      appLogger().i('The class has already be initialized');
      return;
    }

    await _initAndLoadAudioPlayers();
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
    Duration? doNotPlayIfPrevSameSoundStartedBefore,
  }) async {
    final tmpMusicSound = _musicSoundsHelper.musicSounds[musicSound];

    if (tmpMusicSound == null) {
      appLogger().w("The music sound $musicSound doesn't exist in manager, "
          "can't play the wanted sound");
      return;
    }

    final helper = _audioPlayers[tmpMusicSound.filePath];

    if (helper == null) {
      // The sound doesn't exist, we cannot play it
      return;
    }

    if (doNotPlayIfPrevSameSoundStartedBefore != null &&
        !helper.isElapsedEqOrAfterDuration(doNotPlayIfPrevSameSoundStartedBefore)) {
      // Do not play the sound if not enough time passed
      return;
    }

    final elementsToStop = <String>[];

    if (stopAllTheOthersSounds) {
      elementsToStop.addAll(_audioPlayers.keys);
      elementsToStop.remove(tmpMusicSound.filePath);
    } else {
      elementsToStop.add(tmpMusicSound.filePath);
    }

    await _stopAllElements(musicFilesPath: elementsToStop);

    // The result of access can't be null, because we have created all the sound in the init manager
    final releaseMode = loop ? ReleaseMode.loop : ReleaseMode.stop;

    try {
      if (releaseMode != helper.audioPlayer.releaseMode) {
        await helper.audioPlayer.setReleaseMode(releaseMode);
      }
      await helper.audioPlayer.play(
        helper.audioPlayer.source!,
        volume: volume,
      );
    } catch (error) {
      appLogger().e("A crash occurred when calling audio player music sound: $musicSound, error: "
          "$error");
    }

    helper.elapsedTimer.start();
    helper.elapsedTimer.reset();
  }

  /// Call the [stop] method to stop a particular sound played
  ///
  /// Set [stopAllSounds] to true, to stop all the sounds
  Future<void> stop(
    T musicSound, {
    bool stopAllSounds = false,
  }) async {
    final tmpMusicSound = _musicSoundsHelper.musicSounds[musicSound];

    if (tmpMusicSound == null) {
      appLogger().w("The music sound $musicSound doesn't exist in manager, "
          "can't stop the wanted sound");
      return;
    }

    final elementsToStop = <String>[];

    if (stopAllSounds) {
      elementsToStop.addAll(_audioPlayers.keys);
    } else {
      elementsToStop.add(tmpMusicSound.filePath);
    }

    return _stopAllElements(musicFilesPath: elementsToStop);
  }

  /// Get the wanted music duration
  ///
  /// Returns null if the sound doesn't exist or a problem occurred
  // TODO(aloiseau): Player duration is always returned as zero (bug). Maybe linked to file format?
  Future<Duration?> getDuration(T musicSound) async {
    Duration? duration;
    final player = _accessInnerPlayer(musicSound);

    try {
      duration = await player?.getDuration();
    } catch (error) {
      appLogger().e("An error occurred when tried to get the duration of: $musicSound, "
          "error: $error");
    }

    return duration;
  }

  /// Get a stream notifying all play complete events of a given sound.
  ///
  /// Note: playing in a loop may generate complete events between each loops (at least for iOS)
  // TODO(aloiseau): No events are never posted to the stream (bug)
  Stream<void>? onPlayerComplete(T musicSound) => _accessInnerPlayer(musicSound)?.onPlayerComplete;

  /// Init and load all the audio files in cache memory
  Future<void> _initAndLoadAudioPlayers() async {
    for (final musicSound in _musicSoundsHelper.musicSounds.values) {
      final filePath = musicSound.filePath;

      if (_audioPlayers.containsKey(filePath)) {
        // Another music sound use the same file; therefore, no need to create a new AudioPlayer
        continue;
      }

      final audioPlayer = AudioPlayer(playerId: filePath);
      try {
        final deviceUri = await AudioCache.instance.fetchToMemory(filePath);
        await audioPlayer.setSourceDeviceFile(deviceUri.toString());
        await audioPlayer.setPlayerMode(PlayerMode.lowLatency);
        await audioPlayer.setReleaseMode(ReleaseMode.stop);
      } catch (error) {
        appLogger().e("A crash occurred when fetching a sound from memory: $musicSound, "
            "error: $error");
      }

      _audioPlayers[filePath] = AudioPlayerHelper(audioPlayer: audioPlayer);
    }
  }

  /// Private method to stop the music wanted
  ///
  /// Stop all the music in the [musicFilesPath] list
  Future<void> _stopAllElements({
    required List<String> musicFilesPath,
  }) async {
    if (musicFilesPath.isEmpty) {
      // Nothing to do
      return;
    }

    for (final filePath in musicFilesPath) {
      final help = _audioPlayers[filePath];

      if (help == null || (help.audioPlayer.state == PlayerState.stopped)) {
        // This player doesn't exist or it already stops; therefore we don't need to stop it
        continue;
      }

      try {
        await help.audioPlayer.stop();
      } catch (error) {
        appLogger().e("An error occurred when tried to stop the audio player: $filePath");
      }

      if (help.audioPlayer.state != PlayerState.stopped) {
        appLogger().w("The sound $filePath can't be stopped, current state: "
            "${help.audioPlayer.state}");
      }

      help.elapsedTimer.stop();

      if (help.audioPlayer.releaseMode != ReleaseMode.stop) {
        await help.audioPlayer.setReleaseMode(ReleaseMode.stop);
      }
    }
  }

  /// Shared code to access given sound backend player
  AudioPlayer? _accessInnerPlayer(T musicSound) {
    final tmpMusicSound = _musicSoundsHelper.musicSounds[musicSound];

    if (tmpMusicSound == null) {
      appLogger().w("The music sound $musicSound doesn't exist in manager, "
          "can't get its backend player");
      return null;
    }

    return _audioPlayers[tmpMusicSound.filePath]?.audioPlayer;
  }

  /// To call in order to stop all sounds played and free the cache memory
  ///
  /// After calling  [disposeLifeCycle], you have to call the [initLifeCycle] method if you want
  /// to reuse the class.
  @override
  Future<void> disposeLifeCycle() async {
    final futures = <Future>[super.disposeLifeCycle()];

    for (final player in _audioPlayers.entries) {
      final help = player.value;
      if (help.audioPlayer.state != PlayerState.stopped) {
        try {
          await help.audioPlayer.stop();
        } catch (error) {
          appLogger().e("An error occurred when tried to stop the audio player: ${player.key}, "
              "while disposing the audio manager");
        }

        if (help.audioPlayer.state != PlayerState.stopped) {
          appLogger().w("The sound ${player.key} can't be stopped, current state: "
              "${help.audioPlayer.state}, while disposing");
        }
      }

      futures.add(help.audioPlayer.dispose());
    }

    await Future.wait(futures);
    _audioPlayers.clear();
    await AudioCache.instance.clearAll();
  }
}

/// Helper which contains all the needed elements for extending the AudioPlayer
class AudioPlayerHelper {
  /// The used audio player
  AudioPlayer audioPlayer;

  /// This is used to get the time elapsed since the last `start`
  Stopwatch elapsedTimer;

  /// Class constructor
  AudioPlayerHelper({required this.audioPlayer}) : elapsedTimer = Stopwatch();

  /// Test if the elapsed timer value is equals or more than the duration given
  bool isElapsedEqOrAfterDuration(Duration durationToTest) =>
      elapsedTimer.elapsed.compareTo(durationToTest) >= 0;

  /// Only useful in iOS to prevent fatal errors
  static void monitorNotifications(PlayerState value) {}
}
