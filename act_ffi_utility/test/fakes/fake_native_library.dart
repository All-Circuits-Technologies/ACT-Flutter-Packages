// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'dart:ffi' as ffi;

import 'package:act_dart_result/act_dart_result.dart';

/// The result a native library of the tests answers with.
enum FakeResult with MixinResultStatus {
  /// The call went well.
  ok(isSuccess: true),

  /// The call failed.
  failed(isSuccess: false);

  /// {@macro act_dart_result.MixinResultStatus.isSuccess}
  @override
  final bool isSuccess;

  /// {@macro act_dart_result.MixinResultStatus.canBeRetried}
  @override
  bool get canBeRetried => false;

  /// Enum constructor
  const FakeResult({required this.isSuccess});
}

/// A native library which records the callbacks it is given and calls them on demand.
class FakeNativeLibrary<Callback extends Function> {
  /// The result the library answers a registration with.
  FakeResult registerResult = FakeResult.ok;

  /// True when the library is asked to register a callback and throws instead.
  bool throwsOnRegister = false;

  /// The callbacks the library has been given, including the one which unregisters.
  final List<ffi.Pointer<ffi.NativeFunction<Callback>>> registered = [];

  /// The callback the library would call, or null once it has been unregistered.
  ffi.Pointer<ffi.NativeFunction<Callback>>? get callback =>
      (registered.isEmpty || registered.last == ffi.nullptr) ? null : registered.last;

  /// Registers [pointer] the way a native library does.
  FakeResult register(ffi.Pointer<ffi.NativeFunction<Callback>> pointer) {
    if (throwsOnRegister) {
      throw StateError("the library refused the callback");
    }

    registered.add(pointer);

    return registerResult;
  }
}
