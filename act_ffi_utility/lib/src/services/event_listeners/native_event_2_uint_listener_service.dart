// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'dart:async';
import 'dart:ffi' as ffi;

import 'package:act_dart_result/act_dart_result.dart';
import 'package:act_ffi_utility/src/services/event_listeners/abs_native_event_listener_service.dart';
import 'package:act_ffi_utility/src/utilities/runtime_protect_cmd.dart';
import 'package:ffi/ffi.dart';

/// Callback signature for a native event that provides two unsigned int parameters.
typedef Native2UintCallback =
    ffi.Void Function(ffi.UnsignedInt firstParam, ffi.UnsignedInt secondParam);

/// Service for listening to native events that provide two unsigned int parameters.
///
/// This service extends [AbsNativeEventListenerService] and provides a way to parse the two
/// unsigned int parameters into a Dart object of type [ParsedObject].
class NativeEvent2UintListenerService<Result extends MixinResultStatus, ParsedObject>
    extends AbsNativeEventListenerService<Result, Native2UintCallback, ParsedObject> {
  /// This is the function that will be called to get the current value of the object from the
  /// native library. It should return a [Result] indicating success or failure, and fill the
  /// provided pointers with the two unsigned int parameters that will be parsed into a
  /// [ParsedObject].
  Result Function(
    ffi.Pointer<ffi.UnsignedInt> firstParam,
    ffi.Pointer<ffi.UnsignedInt> secondParam,
  )?
  valueGetter;

  /// This is the function that will be called to parse the two unsigned int parameters received
  /// from the native callback into a [ParsedObject].
  ///
  /// It should return null if the parameters cannot be parsed into a valid object.
  ParsedObject? Function(int firstParam, int secondParam) parseParamsToObject;

  /// Class constructor
  NativeEvent2UintListenerService({
    required super.logsCategory,
    required super.registerNativeCallback,
    required this.parseParamsToObject,
    super.parentLogsHelper,
    super.emitUnchangedValue,
    this.valueGetter,
  });

  /// {@macro act_ffi_utility.AbsNativeEventListenerService.getNativeCallback}
  @override
  ffi.NativeCallable<Native2UintCallback> getNativeCallback() =>
      ffi.NativeCallable<Native2UintCallback>.listener(_onNativeEvent);

  /// {@macro act_ffi_utility.AbsNativeEventListenerService.getValueGetter}
  @override
  FutureOr<ParsedObject?> Function()? getValueGetter() {
    if (valueGetter == null) {
      return null;
    }

    return _getValueFromGetter;
  }

  /// Get the current value from the value getter, protected with [RuntimeProtectCmd] to catch any
  /// exceptions and log them.
  ParsedObject? _getValueFromGetter() =>
      RuntimeProtectCmd.protectWithCalloc<ParsedObject?>((register) {
        final firstParamPtr = register.add(calloc<ffi.UnsignedInt>());
        final secondParamPtr = register.add(calloc<ffi.UnsignedInt>());
        return handleGetterResult(
          result: valueGetter!(firstParamPtr, secondParamPtr),
          extract: () => parseParamsToObject(firstParamPtr.value, secondParamPtr.value),
        );
      }, description: getDescriptionForRuntimeProtectCmd("getValueFromGetter"));

  /// Callback that gets called from the native code with two unsigned int parameters. It parses the
  /// parameters into a [ParsedObject] and adds it to the stream.
  void _onNativeEvent(int firstParam, int secondParam) => setParsedValue(
    parsedObject: parseParamsToObject(firstParam, secondParam),
    debugDescription: 'params: $firstParam, $secondParam',
  );
}
