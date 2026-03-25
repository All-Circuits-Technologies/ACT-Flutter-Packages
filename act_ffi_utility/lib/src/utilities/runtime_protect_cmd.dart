// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_ffi_utility/src/models/runtime_calloc_register.dart';
import 'package:act_global_manager/act_global_manager.dart';

/// This utility class provides common functionality for protecting runtime command calls.
sealed class RuntimeProtectCmd {
  /// {@template act_ffi_utility.RuntimeProtectCmd.protect}
  /// Helper to safely call a runtime command that returns a value, catching any exceptions.
  /// {@endtemplate}
  static T? protect<T>(T Function() cmd, {String? description}) {
    T? result;
    try {
      result = cmd();
    } catch (error) {
      appLogger().w(
        "An exception occurred during a runtime command call"
        "${description != null ? ' ($description)' : ''}: $error",
      );
    }

    return result;
  }

  /// {@macro act_ffi_utility.RuntimeProtectCmd.protect}
  ///
  /// Call [protect] and Returns [defaultValue] if an exception occurs.
  static T protectWithDefault<T>(
    T Function() cmd, {
    required T defaultValue,
    String? description,
  }) => RuntimeProtectCmd.protect<T>(cmd, description: description) ?? defaultValue;

  /// {@macro act_ffi_utility.RuntimeProtectCmd.protect}
  ///
  /// {@template act_ffi_utility.RuntimeProtectCmd.protectWithCalloc}
  /// Add a [RuntimeCallocRegister] to the command, allowing it to allocate memory with calloc and
  /// ensuring it is freed after the call.
  /// {@endtemplate}
  static T? protectWithCalloc<T>(
    T Function(RuntimeCallocRegister register) cmd, {
    String? description,
  }) {
    final register = RuntimeCallocRegister();
    T? result;
    try {
      result = cmd(register);
    } catch (error) {
      appLogger().w(
        "An exception occurred during a runtime command call with calloc"
        "${description != null ? ' ($description)' : ''}: $error",
      );
    }

    register.freeAll();

    return result;
  }

  /// {@macro act_ffi_utility.RuntimeProtectCmd.protect}
  ///
  /// {@macro act_ffi_utility.RuntimeProtectCmd.protectWithCalloc}
  ///
  /// Call [protectWithCalloc] and Returns [defaultValue] if an exception occurs.
  static T protectWithCallocAndDefault<T>(
    T Function(RuntimeCallocRegister register) cmd, {
    required T defaultValue,
    String? description,
  }) => RuntimeProtectCmd.protectWithCalloc<T>(cmd, description: description) ?? defaultValue;

  /// {@template act_ffi_utility.RuntimeProtectCmd.protectAsync}
  /// Async variant of [protect]. Safely calls an async runtime command,
  /// catching any exceptions.
  /// {@endtemplate}
  ///
  /// {@macro act_ffi_utility.RuntimeProtectCmd.protectWithCalloc}
  static Future<T?> protectAsyncWithCalloc<T>(
    Future<T> Function(RuntimeCallocRegister register) cmd, {
    String? description,
  }) async {
    final register = RuntimeCallocRegister();
    T? result;
    try {
      result = await cmd(register);
    } catch (error) {
      appLogger().w(
        "An exception occurred during an async runtime command call with calloc"
        "${description != null ? ' ($description)' : ''}: $error",
      );
    }

    register.freeAll();

    return result;
  }

  /// {@macro act_ffi_utility.RuntimeProtectCmd.protectAsync}
  ///
  /// {@macro act_ffi_utility.RuntimeProtectCmd.protectWithCalloc}
  ///
  /// Call [protectAsyncWithCalloc] and returns [defaultValue] if an exception occurs.
  static Future<T> protectAsyncWithCallocAndDefault<T>(
    Future<T> Function(RuntimeCallocRegister register) cmd, {
    required T defaultValue,
    String? description,
  }) async =>
      await RuntimeProtectCmd.protectAsyncWithCalloc<T>(cmd, description: description) ??
      defaultValue;
}
