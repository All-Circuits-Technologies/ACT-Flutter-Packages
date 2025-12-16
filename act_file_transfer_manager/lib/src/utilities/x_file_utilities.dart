// SPDX-FileCopyrightText: 2025 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'dart:typed_data';

import 'package:act_file_transfer_manager/act_file_transfer_manager.dart';
import 'package:act_global_manager/act_global_manager.dart';

/// Contains utilities methods linked to [XFile]
sealed class XFileUtilities {
  /// Get the content binary of the given [xFile]
  static Future<Uint8List?> getBinaryFileContent({required XFile xFile}) async {
    Uint8List? bytes;
    try {
      bytes = await xFile.readAsBytes();
    } catch (error) {
      appLogger().e(
        "An error occurred when tried to read file bytes: $error, from file: ${xFile.name}",
      );
    }

    return bytes;
  }
}
