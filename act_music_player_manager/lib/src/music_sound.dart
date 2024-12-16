// Copyright (c) 2020. BMS Circuits

import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';

/// Represents a music sound to play
@immutable
class MusicSound<T> extends Equatable {
  final T value;
  final String filePath;

  MusicSound({
    @required this.value,
    @required this.filePath,
  })  : assert(value != null),
        assert(filePath != null);

  @override
  List<Object> get props => [value];
}

/// Utility methods to manage [MusicSound] enum
abstract class AbstractMusicSoundHelper<T> {
  List<String> _filesList;

  final Set<MusicSound<T>> musicSounds;

  /// Class constructor
  ///
  /// [musicSounds] is the different [MusicSound] which can be played
  AbstractMusicSoundHelper({
    @required this.musicSounds,
  })  : assert(musicSounds != null),
        super();

  /// Get the files list of all the [MusicSound] available
  List<String> getFilesList() {
    if (_filesList == null) {
      _filesList = [];

      for (MusicSound sound in this.musicSounds) {
        _filesList.add(sound.filePath);
      }
    }

    return _filesList;
  }
}
