// SPDX-FileCopyrightText: 2025 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'dart:convert' show LineSplitter, base64Decode;
import 'dart:typed_data';

/// This class provides a set of helpers to manage base64 string, not provided by Dart.
sealed class Base64Utility {
  /// Try to parse a base64 string to a byte array
  static Uint8List? tryToParse(String base64Value) {
    // We merge the new lines in the base64 value (if there is any) and remove them
    final tmpJoinValues = LineSplitter.split(base64Value).join();

    Uint8List? tmpDecoded;
    try {
      tmpDecoded = base64Decode(tmpJoinValues);
    } catch (error) {
      // A problem occurred while we tried to decode the base64 given
    }

    return tmpDecoded;
  }
}
