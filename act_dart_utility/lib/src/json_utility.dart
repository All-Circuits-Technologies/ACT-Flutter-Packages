// SPDX-FileCopyrightText: 2023 Anthony Loiseau <anthony.loiseau@allcircuits.com>
// SPDX-FileCopyrightText: 2023 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'dart:convert';

import 'package:act_logger_manager/act_logger_manager.dart';

/// Contains useful methods to manage JSON object
abstract class JsonUtility {
  /// Get one element from JSON object
  ///
  /// Find the element thanks to the [key] given. If the element can be not present in the JSON set
  /// [canBeUndefined] to true.
  ///
  /// A cast function can be given: [castValueFunc] to transform the value got to the expected type
  ///
  /// Returns true in first item if no problem occurred
  static (bool, T?) getOneElement<T, Y>({
    required Map<String, dynamic> json,
    required String key,
    bool canBeUndefined = false,
    T? Function(Y)? castValueFunc,
    required LoggerManager loggerManager,
  }) {
    final tmpValue = json[key];

    if (tmpValue == null) {
      if (!canBeUndefined) {
        loggerManager
            .w("The element you want to get from JSON isn't present: $key");
      }

      return (canBeUndefined, null);
    }

    if (castValueFunc == null) {
      if (tmpValue is! T) {
        loggerManager
            .w("The JSON element: $key, hasn't been stored in the $T type");
        return const (false, null);
      }

      return (true, tmpValue);
    }

    if (tmpValue is! Y) {
      loggerManager.w(
          "The JSON element: $key, hasn't been stored in the $Y type, it can't "
          "be casted");
      return const (false, null);
    }

    final castValue = castValueFunc(tmpValue);
    if (castValue == null) {
      loggerManager.w("The cast of the JSON element: $key, failed");
      return const (false, null);
    }

    return (true, castValue);
  }

  /// Parse the response body to a Json
  static Map<String, dynamic>? parseJsonBodyToObj(
    String? strJson, {
    required LoggerManager loggerManager,
  }) =>
      _parseJsonBody(strJson, loggerManager: loggerManager);

  /// Parse the response body to a Json Array
  static List<dynamic>? parseJsonBodyToArray(
    String? strJson, {
    required LoggerManager loggerManager,
  }) =>
      _parseJsonBody(strJson, loggerManager: loggerManager);

  /// Parse the response body from an object or list to a Json
  static T? _parseJsonBody<T>(
    String? strJson, {
    required LoggerManager loggerManager,
  }) {
    if (strJson == null) {
      return null;
    }

    T? data;

    try {
      data = jsonDecode(strJson) as T;
    } catch (error) {
      loggerManager.w("Cannot parse to json, the response body: $strJson");
    }

    return data;
  }
}
