// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'dart:ffi' show NativeType, Pointer;

import 'package:equatable/equatable.dart';
import 'package:ffi/ffi.dart' show calloc;

/// A register to keep track of allocated memory using calloc.
class RuntimeCallocRegister extends Equatable {
  /// The list of pointers used for calloc allocations.
  final List<Pointer<NativeType>> _pointers;

  /// Class constructor
  RuntimeCallocRegister() : _pointers = [];

  /// Add a pointer allocated with calloc to the register, so it can be freed later.
  ///
  /// It returns the same pointer for convenience, so you can use it inline with your allocations,
  /// e.g.:
  ///
  /// ```dart
  /// final pointer = register.add(calloc<YourType>());
  /// // or with count:
  /// final pointer = register.add(calloc<YourType>(count));
  /// ```
  Pointer<T> add<T extends NativeType>(Pointer<T> pointer) {
    _pointers.add(pointer);
    return pointer;
  }

  /// Free all allocated memory.
  void freeAll() {
    for (final pointer in _pointers) {
      calloc.free(pointer);
    }
    _pointers.clear();
  }

  /// Class properties
  @override
  List<Object?> get props => [_pointers];
}
