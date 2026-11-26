// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'dart:io';

import 'package:act_dart_config_manager/src/loaders/abs_config_reader.dart';

/// This class reads the raw content of the config files from a directory of the file system.
class FileConfigReader extends AbsConfigReader {
  /// The directory which contains the config files.
  final String directory;

  /// Class constructor
  const FileConfigReader({required this.directory});

  /// The location of a config file is its path: the [directory] joined with the [fileName], with
  /// the separator of the platform.
  @override
  String locate(String fileName) {
    if (directory.isEmpty || directory.endsWith(Platform.pathSeparator)) {
      return "$directory$fileName";
    }

    return "$directory${Platform.pathSeparator}$fileName";
  }

  /// Read the file at [location].
  @override
  Future<String?> readRaw(String location) async {
    final file = File(location);

    if (!file.existsSync()) {
      return null;
    }

    return file.readAsString();
  }
}
