// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'dart:convert';
import 'dart:ffi';

import 'package:act_global_manager/act_global_manager.dart';
import 'package:ffi/ffi.dart';

/// Utility class for runtime string operations.
sealed class RuntimeStringUtility {
  /// Convert a fixed-size null-terminated `Array<Char>` to a Dart [String].
  ///
  /// [maxLength] is the maximum number of elements in the array (i.e. the
  /// compile-time size of the C `char[]` field).
  ///
  /// The bytes are decoded as UTF-8. A multi-byte character which [maxLength] cuts in the middle
  /// is replaced by the replacement character U+FFFD.
  static String charArrayToUtf8String({required Array<Char> array, required int maxLength}) {
    final bytes = <int>[];
    for (var idx = 0; idx < maxLength; idx++) {
      final charValue = array[idx];
      if (charValue == 0) {
        // Null terminator found, stop reading the array
        break;
      }

      // Dart FFI reads a `Char` as a signed byte: get back its unsigned value
      bytes.add(charValue & 0xFF);
    }

    return utf8.decode(bytes, allowMalformed: true);
  }

  /// Convert a `Pointer<Char>` buffer to a Dart [String], returning null if the pointer equals
  /// [nullptr].
  ///
  /// This cast to `Utf8` String.
  static String? charPointerToUtf8String({required Pointer<Char> buffer}) {
    if (buffer == nullptr) {
      return null;
    }

    String? value;
    try {
      value = buffer.cast<Utf8>().toDartString();
    } catch (error) {
      appLogger().w("Failed to convert Pointer<Char> to Utf8 String: $error. Returning null.");
    }

    return value;
  }
}
