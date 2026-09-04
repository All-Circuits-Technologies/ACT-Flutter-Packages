// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'dart:ffi' as ffi;

import 'package:act_ffi_utility/act_ffi_utility.dart';
import 'package:act_foundation/act_foundation.dart';
import 'package:act_test_utility/act_test_utility.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../fakes/fake_native_library.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeExternalLogger logs;

  setUp(() {
    FakeGlobalManager.install();
    logs = FakeExternalLogger();
  });

  group("NativeEvent1UintListenerService", () {
    late FakeNativeLibrary<Native1UintCallback> library;

    setUp(() => library = FakeNativeLibrary<Native1UintCallback>());

    /// Builds the service of an application which reads a count from the library.
    NativeEvent1UintListenerService<FakeResult, int> aService({
      FakeResult Function(ffi.Pointer<ffi.UnsignedInt> param)? valueGetter,
      int? Function(int param)? parse,
    }) => NativeEvent1UintListenerService<FakeResult, int>(
      logsCategory: "count",
      registerNativeCallback: library.register,
      parseParamToObject: parse ?? (param) => param,
      parentLogsHelper: logs.buildHelper(category: "runtime"),
      valueGetter: valueGetter,
    );

    test("gives the library a callback to call", () async {
      final service = aService();

      await service.initLifeCycle();
      addTearDown(service.disposeLifeCycle);

      expect(library.callback, isNotNull);
    });

    test("reports the event the library announces", () async {
      final service = aService();
      await service.initLifeCycle();
      addTearDown(service.disposeLifeCycle);
      final announced = expectLater(service.valueStream, emits(42));

      library.callback!.asFunction<void Function(int)>()(42);

      await announced;
    });

    test("drops an event the application cannot read", () async {
      final service = aService(parse: (param) => (param == 0) ? null : param);
      await service.initLifeCycle();
      addTearDown(service.disposeLifeCycle);

      library.callback!.asFunction<void Function(int)>()(0);
      await pumpEventQueue();

      expect(service.value, isNull);
      expect(logs.recordsAtLevel(LogsLevel.warn).length, 1);
    });

    test("reads the value the library already holds when it is initialized", () async {
      final service = aService(
        valueGetter: (param) {
          param.value = 7;

          return FakeResult.ok;
        },
      );

      await service.initLifeCycle();
      addTearDown(service.disposeLifeCycle);

      expect(service.value, 7);
    });

    test("knows no value when the library refuses to give the one it holds", () async {
      final service = aService(valueGetter: (param) => FakeResult.failed);

      await service.initLifeCycle();
      addTearDown(service.disposeLifeCycle);

      expect(service.value, isNull);
      expect(logs.recordsAtLevel(LogsLevel.error).length, 1);
    });

    test("knows no value when the application asks the library for none", () async {
      final service = aService();

      await service.initLifeCycle();
      addTearDown(service.disposeLifeCycle);

      expect(service.value, isNull);
    });

    test("reports the registration the library refuses", () async {
      library.registerResult = FakeResult.failed;
      final service = aService();

      await service.initLifeCycle();
      addTearDown(service.disposeLifeCycle);

      expect(logs.recordsAtLevel(LogsLevel.error).length, 1);
    });

    test("survives a library which throws when it is given a callback", () async {
      library.throwsOnRegister = true;
      final service = aService();

      await expectLater(service.initLifeCycle(), completes);

      library.throwsOnRegister = false;
      await service.disposeLifeCycle();
    });

    test("takes its callback back when it is disposed", () async {
      final service = aService();
      await service.initLifeCycle();

      await service.disposeLifeCycle();

      expect(library.callback, isNull);
    });
  });

  group("NativeEvent2UintListenerService", () {
    late FakeNativeLibrary<Native2UintCallback> library;

    setUp(() => library = FakeNativeLibrary<Native2UintCallback>());

    /// Builds the service of an application which reads a pair from the library.
    NativeEvent2UintListenerService<FakeResult, String> aService({
      FakeResult Function(
        ffi.Pointer<ffi.UnsignedInt> first,
        ffi.Pointer<ffi.UnsignedInt> second,
      )?
      valueGetter,
    }) => NativeEvent2UintListenerService<FakeResult, String>(
      logsCategory: "pair",
      registerNativeCallback: library.register,
      parseParamsToObject: (first, second) => "$first:$second",
      parentLogsHelper: logs.buildHelper(category: "runtime"),
      valueGetter: valueGetter,
    );

    test("reports the two values the library announces", () async {
      final service = aService();
      await service.initLifeCycle();
      addTearDown(service.disposeLifeCycle);
      final announced = expectLater(service.valueStream, emits("1:2"));

      library.callback!.asFunction<void Function(int, int)>()(1, 2);

      await announced;
    });

    test("reads the two values the library already holds", () async {
      final service = aService(
        valueGetter: (first, second) {
          first.value = 3;
          second.value = 4;

          return FakeResult.ok;
        },
      );

      await service.initLifeCycle();
      addTearDown(service.disposeLifeCycle);

      expect(service.value, "3:4");
    });
  });

  group("NativeEvent1FloatListenerService", () {
    late FakeNativeLibrary<Native1FloatCallback> library;

    setUp(() => library = FakeNativeLibrary<Native1FloatCallback>());

    /// Builds the service of an application which reads a measure from the library.
    NativeEvent1FloatListenerService<FakeResult, double> aService({
      FakeResult Function(ffi.Pointer<ffi.Float> param)? valueGetter,
    }) => NativeEvent1FloatListenerService<FakeResult, double>(
      logsCategory: "measure",
      registerNativeCallback: library.register,
      parseParamToObject: (value) => value,
      parentLogsHelper: logs.buildHelper(category: "runtime"),
      valueGetter: valueGetter,
    );

    test("reports the measure the library announces", () async {
      final service = aService();
      await service.initLifeCycle();
      addTearDown(service.disposeLifeCycle);
      final announced = expectLater(service.valueStream, emits(closeTo(1.5, 0.001)));

      library.callback!.asFunction<void Function(double)>()(1.5);

      await announced;
    });

    test("reads the measure the library already holds", () async {
      final service = aService(
        valueGetter: (param) {
          param.value = 2.5;

          return FakeResult.ok;
        },
      );

      await service.initLifeCycle();
      addTearDown(service.disposeLifeCycle);

      expect(service.value, closeTo(2.5, 0.001));
    });
  });
}
