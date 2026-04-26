// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'dart:async';
import 'dart:ffi' as ffi;

import 'package:act_dart_result/act_dart_result.dart';
import 'package:act_dart_value_keeper/act_dart_value_keeper.dart';
import 'package:act_ffi_utility/src/utilities/runtime_protect_cmd.dart';
import 'package:act_life_cycle/act_life_cycle.dart';
import 'package:act_logger_manager/act_logger_manager.dart';
import 'package:flutter/foundation.dart';

/// This is the callback signature for the method used to register the native callback in the C
/// library.
typedef RegisterCallback<Result extends MixinResultStatus, Callback extends Function> =
    Result Function(ffi.Pointer<ffi.NativeFunction<Callback>>);

/// Abstract service for listening to native events.
///
/// This service provides a way to listen to native events and parse them into Dart objects.
///
/// The service is designed to be extended by specific implementations for different types of native
/// events.
abstract class AbsNativeEventListenerService<
  Result extends MixinResultStatus,
  Callback extends Function,
  ParsedObject
>
    extends ValueKeeperWithStreamAndNullInit<ParsedObject>
    with MixinWithLifeCycle {
  /// Logs helper for this service.
  final LogsHelper logsHelper;

  /// The callback used to register the native callback in the C library.
  ///
  /// It is provided by the subclass through the `registerNativeCallback` constructor parameter and
  /// stored in [_registerNativeCallback].
  final RegisterCallback<Result, Callback> _registerNativeCallback;

  /// The native callable registered with the C library.
  ffi.NativeCallable<Callback>? _nativeCallable;

  /// Class constructor
  AbsNativeEventListenerService({
    required String logsCategory,
    required RegisterCallback<Result, Callback> registerNativeCallback,
    LogsHelper? parentLogsHelper,
    super.emitUnchangedValue = false,
  }) : logsHelper =
           parentLogsHelper?.createSubLogger(subCategory: logsCategory) ??
           LogsHelper(category: logsCategory),
       _registerNativeCallback = registerNativeCallback,
       super(value: null);

  /// {@macro act_life_cycle.MixinWithLifeCycle.initLifeCycle}
  @override
  Future<void> initLifeCycle() async {
    await super.initLifeCycle();

    _registerNativeCallbackProtectCmd();

    await _getValueFromGetterAndSetObject();
  }

  /// {@template act_ffi_utility.AbsNativeEventListenerService.getValueGetter}
  /// Get a function that can be used to get the current value.
  ///
  /// If the method returns null, it means that we can't get the current value and we will only
  /// update the value when we receive an event from the native callback.
  /// {@endtemplate}
  @protected
  FutureOr<ParsedObject?> Function()? getValueGetter() => null;

  /// {@template act_ffi_utility.AbsNativeEventListenerService.getNativeCallback}
  /// Get the native callback to register in the C library. This callback will be called from the C
  /// library when an event occurs. It should parse the event and update the current value using
  /// the [value] setter.
  /// {@endtemplate}
  @protected
  ffi.NativeCallable<Callback> getNativeCallback();

  /// Helper to get a description for the runtime protect command, including the logs category and a
  /// specific action description.
  @protected
  String getDescriptionForRuntimeProtectCmd(String descriptionAction) =>
      "${logsHelper.categories} - $descriptionAction";

  /// Helper to register the native callback in the C library, protected with [RuntimeProtectCmd] to
  /// catch any exceptions and log them.
  Result? _registerNativeCallbackProtectCmd() => RuntimeProtectCmd.protect<Result>(() {
    _nativeCallable ??= getNativeCallback();

    final result = _registerNativeCallback(_nativeCallable!.nativeFunction);
    if (result.isError) {
      logsHelper.e("Failed to register native callback: $result");
    }

    return result;
  }, description: getDescriptionForRuntimeProtectCmd("registerNativeCallback"));

  /// If a value getter is provided, use it to get the current value and set it in the service.
  Future<void> _getValueFromGetterAndSetObject() async {
    final valueGetter = getValueGetter();
    if (valueGetter == null) {
      return;
    }

    final initValue = await valueGetter();

    if (initValue == null) {
      // Nothing to do
      return;
    }

    value = initValue;
  }

  /// {@macro act_life_cycle.MixinWithLifeCycleDispose.disposeLifeCycle}
  @override
  Future<void> disposeLifeCycle() async {
    // Unregister the native callback
    _registerNativeCallback(ffi.nullptr.cast<ffi.NativeFunction<Callback>>());

    _nativeCallable?.close();
    _nativeCallable = null;

    return super.disposeLifeCycle();
  }
}
