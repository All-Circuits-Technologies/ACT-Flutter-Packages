// SPDX-FileCopyrightText: 2025 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'dart:typed_data';

import 'package:act_abstract_manager/act_abstract_manager.dart';
import 'package:act_global_manager/act_global_manager.dart';
import 'package:act_logger_manager/act_logger_manager.dart';
import 'package:file_saver/file_saver.dart';

/// Builder for the file saver manager
class FileSaverBuilder extends AbsManagerBuilder<FileSaverManager> {
  /// Class constructor
  const FileSaverBuilder() : super(FileSaverManager.new);

  /// {@macro act_abstract_manager.AbsManagerBuilder.dependsOn}
  @override
  Iterable<Type> dependsOn() => [LoggerManager];
}

/// This manager helps to save a file in the device
///
/// When you use iOS or macOS, some additional configuration is required,
/// please refer to the documentation of the package used to save files:
/// https://pub.dev/packages/file_saver#storage-permissions--network-permissions
class FileSaverManager extends AbsWithLifeCycle {
  /// Class constructor
  const FileSaverManager();

  /// The method save the file in the device from the given [bytes]
  ///
  /// It returns the file path or null if a problem occurred.
  Future<String?> saveFileFromBytes({required String fileName, required Uint8List bytes}) async {
    String? filePath;

    try {
      filePath = await FileSaver.instance.saveFile(name: fileName, bytes: bytes);
    } catch (error) {
      appLogger().e("A problem occurred when tried to save the file: $fileName, error: $error");
    }

    return filePath;
  }
}
