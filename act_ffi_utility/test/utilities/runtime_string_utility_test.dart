// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'dart:ffi' as ffi;

import 'package:act_ffi_utility/act_ffi_utility.dart';
import 'package:act_test_utility/act_test_utility.dart';
import 'package:ffi/ffi.dart';
import 'package:flutter_test/flutter_test.dart';

/// The size of the fixed buffer the native library writes its names in.
const _nameLength = 8;

/// A structure of a native library, which holds a name in a fixed buffer.
final class _NativeDevice extends ffi.Struct {
  /// The name of the device, which the null character ends.
  @ffi.Array(_nameLength)
  external ffi.Array<ffi.Char> name;
}

void main() {
  setUp(FakeGlobalManager.install);

  /// Builds a structure whose name holds [codeUnits].
  ffi.Pointer<_NativeDevice> aDevice(List<int> codeUnits) {
    final pointer = calloc<_NativeDevice>();
    for (var idx = 0; idx < codeUnits.length; idx++) {
      pointer.ref.name[idx] = codeUnits[idx];
    }

    return pointer;
  }

  group("RuntimeStringUtility.charArrayToString", () {
    test("reads the characters up to the one which ends the name", () {
      final device = aDevice("abc".codeUnits);
      addTearDown(() => calloc.free(device));

      expect(
        RuntimeStringUtility.charArrayToString(array: device.ref.name, maxLength: _nameLength),
        "abc",
      );
    });

    test("reads an empty name from a buffer which starts with the end character", () {
      final device = aDevice(const []);
      addTearDown(() => calloc.free(device));

      expect(
        RuntimeStringUtility.charArrayToString(array: device.ref.name, maxLength: _nameLength),
        isEmpty,
      );
    });

    test("stops at the size of the buffer when nothing ends the name", () {
      final device = aDevice(List.filled(_nameLength, "a".codeUnitAt(0)));
      addTearDown(() => calloc.free(device));

      expect(
        RuntimeStringUtility.charArrayToString(array: device.ref.name, maxLength: _nameLength),
        "aaaaaaaa",
      );
    });

    test("reads no further than the length the caller gives", () {
      final device = aDevice("abcdefgh".codeUnits);
      addTearDown(() => calloc.free(device));

      expect(
        RuntimeStringUtility.charArrayToString(array: device.ref.name, maxLength: 3),
        "abc",
      );
    });
  });

  group("RuntimeStringUtility.charPointerToUtf8String", () {
    test("reads the text the buffer holds", () {
      final buffer = "a name".toNativeUtf8();
      addTearDown(() => calloc.free(buffer));

      expect(
        RuntimeStringUtility.charPointerToUtf8String(buffer: buffer.cast<ffi.Char>()),
        "a name",
      );
    });

    test("reads the characters which take more than one byte", () {
      final buffer = "a nàme".toNativeUtf8();
      addTearDown(() => calloc.free(buffer));

      expect(
        RuntimeStringUtility.charPointerToUtf8String(buffer: buffer.cast<ffi.Char>()),
        "a nàme",
      );
    });

    test("returns null when the library gave no buffer at all", () {
      expect(RuntimeStringUtility.charPointerToUtf8String(buffer: ffi.nullptr), isNull);
    });
  });
}
