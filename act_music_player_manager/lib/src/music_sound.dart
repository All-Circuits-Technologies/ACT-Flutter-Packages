// SPDX-FileCopyrightText: 2020 - 2023 Sami Kouatli <sami.kouatli@allcircuits.com>
// SPDX-FileCopyrightText: 2023 Anthony Loiseau <anthony.loiseau@allcircuits.com>
// SPDX-FileCopyrightText: 2023 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';

/// Represents a music sound to play
@immutable
class MusicSound<T> extends Equatable {
  final T value;
  final String filePath;

  const MusicSound({
    required this.value,
    required this.filePath,
  });

  @override
  List<Object?> get props => [value];
}

/// Utility methods to manage [MusicSound] enum
abstract class AbstractMusicSoundHelper<T> {
  List<String>? _filesList;

  final Map<T, MusicSound<T>> musicSounds;

  /// Class constructor
  ///
  /// [musicSounds] is the different [MusicSound] which can be played
  AbstractMusicSoundHelper({
    required this.musicSounds,
  }) : super();

  /// Get the files list of all the [MusicSound] available
  List<String> getFilesList() {
    if (_filesList == null) {
      _filesList = [];

      for (final sound in this.musicSounds.values) {
        _filesList!.add(sound.filePath);
      }
    }

    return _filesList!;
  }
}
