// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-CEVA

import 'dart:async';
import 'dart:ffi' as ffi;

import 'package:act_dart_result/act_dart_result.dart';
import 'package:act_ffi_utility/src/services/event_listeners/abs_native_event_listener_service.dart';
import 'package:act_ffi_utility/src/utilities/runtime_protect_cmd.dart';
import 'package:ffi/ffi.dart';

/// Callback signature for a native event that provides one float parameter.
typedef Native1FloatCallback = ffi.Void Function(ffi.Float value);

/// Service for listening to native events that provide one float parameter.
///
/// This service extends [AbsNativeEventListenerService] and provides a way to parse one
/// float parameter into a Dart object of type [ParsedObject].
class NativeEvent1FloatListenerService<Result extends MixinResultStatus, ParsedObject>
    extends AbsNativeEventListenerService<Result, Native1FloatCallback, ParsedObject> {
  /// This is the function that will be called to get the current value of the object from the
  /// native library. It should return a [Result] indicating success or failure, and fill the
  /// provided pointers with one float parameter that will be parsed into a [ParsedObject].
  Result Function(ffi.Pointer<ffi.Float> param)? valueGetter;

  /// This is the function that will be called to parse one float parameter received
  /// from the native callback into a [ParsedObject].
  ///
  /// It should return null if the parameters cannot be parsed into a valid object.
  ParsedObject? Function(double value) parseParamToObject;

  /// Class constructor
  NativeEvent1FloatListenerService({
    required super.logsCategory,
    required super.registerNativeCallback,
    required this.parseParamToObject,
    super.parentLogsHelper,
    super.emitUnchangedValue,
    this.valueGetter,
  });

  /// {@macro act_ffi_utility.AbsNativeEventListenerService.getNativeCallback}
  @override
  ffi.NativeCallable<Native1FloatCallback> getNativeCallback() =>
      ffi.NativeCallable<Native1FloatCallback>.listener(_onNativeEvent);

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
        final paramPtr = register.add(calloc<ffi.Float>());
        return handleGetterResult(
          result: valueGetter!(paramPtr),
          extract: () => parseParamToObject(paramPtr.value),
        );
      }, description: getDescriptionForRuntimeProtectCmd("getValueFromGetter"));

  /// Callback that gets called from the native code with one float parameter. It parses the
  /// parameter into a [ParsedObject] and adds it to the stream.
  void _onNativeEvent(double param) =>
      setParsedValue(parsedObject: parseParamToObject(param), debugDescription: 'param: $param');
}
