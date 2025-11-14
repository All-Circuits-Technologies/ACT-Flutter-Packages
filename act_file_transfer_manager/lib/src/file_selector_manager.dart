// SPDX-FileCopyrightText: 2025 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'dart:typed_data';

import 'package:act_abstract_manager/act_abstract_manager.dart';
import 'package:act_dart_utility/act_dart_utility.dart';
import 'package:act_global_manager/act_global_manager.dart';
import 'package:file_selector/file_selector.dart';

/// Builder for the [FileSelectorManager]
class FileSelectorBuilder extends AbsManagerBuilder<FileSelectorManager> {
  /// Class constructor
  const FileSelectorBuilder() : super(FileSelectorManager.new);

  /// {@macro act_abstract_manager.AbsManagerBuilder.dependsOn}
  @override
  Iterable<Type> dependsOn() => [];
}

/// Manager for file selection operations
class FileSelectorManager extends AbsWithLifeCycle {
  /// Class constructor
  const FileSelectorManager();

  /// Open a file selector dialog
  Future<ResultWithBoolStatus<XFile>> openSelector({
    required List<String> allowedExtensions,
    required String label,
  }) async {
    XFile? file;
    var anErrorOccurred = false;
    try {
      file = await openFile(
        acceptedTypeGroups: <XTypeGroup>[XTypeGroup(label: label, extensions: allowedExtensions)],
      );
    } catch (error) {
      appLogger().e("An error occurred when tried to open file selector: $error");
      anErrorOccurred = true;
    }

    if (anErrorOccurred) {
      return const ResultWithBoolStatus(status: BoolResultStatus.error);
    }

    return ResultWithBoolStatus(status: BoolResultStatus.success, value: file);
  }

  /// Open a file selector dialog and get the selected file bytes
  Future<ResultWithBoolStatus<Uint8List>> openSelectorAndGetBytes({
    required List<String> allowedExtensions,
    required String label,
  }) async {
    final result = await openSelector(allowedExtensions: allowedExtensions, label: label);
    if (!result.status.isSuccess || result.value == null) {
      // We propagate the error or cancellation
      return ResultWithBoolStatus(status: result.status);
    }

    final file = result.value!;
    Uint8List? bytes;
    try {
      bytes = await file.readAsBytes();
    } catch (error) {
      appLogger().e(
        "An error occurred when tried to read file bytes: $error, from file: ${file.name}",
      );
    }

    if (bytes == null) {
      return const ResultWithBoolStatus(status: BoolResultStatus.error);
    }

    return ResultWithBoolStatus(status: BoolResultStatus.success, value: bytes);
  }
}
