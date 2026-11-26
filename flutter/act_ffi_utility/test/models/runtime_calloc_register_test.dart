// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'dart:ffi' as ffi;

import 'package:act_ffi_utility/act_ffi_utility.dart';
import 'package:ffi/ffi.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late RuntimeCallocRegister register;

  setUp(() => register = RuntimeCallocRegister());

  tearDown(() => register.freeAll());

  group("RuntimeCallocRegister.add", () {
    test("returns the pointer it is given, so it can be used inline", () {
      final pointer = calloc<ffi.Int32>();

      expect(register.add(pointer), same(pointer));
    });

    test("keeps the pointer so it can be freed later", () {
      register.add(calloc<ffi.Int32>());

      expect(register, isNot(RuntimeCallocRegister()));
    });

    test("keeps every pointer it is given", () {
      final other = RuntimeCallocRegister();
      register
        ..add(calloc<ffi.Int32>())
        ..add(calloc<ffi.Int32>());
      other.add(calloc<ffi.Int32>());

      expect(register, isNot(other));

      other.freeAll();
    });
  });

  group("RuntimeCallocRegister.freeAll", () {
    test("forgets the pointers it has freed", () {
      register.add(calloc<ffi.Int32>());

      register.freeAll();

      expect(register, RuntimeCallocRegister());
    });

    test("accepts to free a register which holds nothing", () {
      expect(register.freeAll, returnsNormally);
    });

    test("frees nothing twice", () {
      register.add(calloc<ffi.Int32>());
      register.freeAll();

      expect(register.freeAll, returnsNormally);
    });
  });
}
