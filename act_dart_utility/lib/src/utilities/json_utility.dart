// SPDX-FileCopyrightText: 2023 Anthony Loiseau <anthony.loiseau@allcircuits.com>
// SPDX-FileCopyrightText: 2023 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'dart:convert';

import 'package:act_foundation/act_foundation.dart';

/// Contains useful methods to manage JSON object
sealed class JsonUtility {
  /// Get one element from JSON object
  ///
  /// Find the element thanks to the [key] given. If the element can be not present in the JSON set
  /// [canBeUndefined] to true.
  ///
  /// A cast function can be given: [castValueFunc] to transform the value retrieved to the expected
  /// type
  ///
  /// Returns true in `isOk` parameter if no problem occurred
  static ({bool isOk, T? value}) getOneElement<T, Y>({
    required Map<String, dynamic> json,
    required String key,
    bool canBeUndefined = false,
    T? Function(Y toCast)? castValueFunc,
    required MixinActLogger logger,
  }) {
    final tmpValue = json[key];

    if (tmpValue == null) {
      if (!canBeUndefined) {
        logger.w("The element you want to get from JSON isn't present: $key");
      }

      return (isOk: canBeUndefined, value: null);
    }

    final result = _castValueIfNeeded(
      value: tmpValue,
      castValueFunc: castValueFunc,
      logger: logger,
    );

    if (!result.isOk || result.value == null) {
      logger.w("The cast of the JSON element: $key, failed");
      return (isOk: false, value: null);
    }

    return (isOk: true, value: result.value);
  }

  /// Get one primary element (number, String or boolean) from JSON object
  ///
  /// Find the element thanks to the [key] given. If the element can be not present in the JSON set
  /// [canBeUndefined] to true.
  ///
  /// Returns true in `isOk` parameter if no problem occurred
  static ({bool isOk, T? value}) getOnePrimaryElement<T>({
    required Map<String, dynamic> json,
    required String key,
    bool canBeUndefined = false,
    required MixinActLogger logger,
  }) => getOneElement<T, T>(json: json, key: key, canBeUndefined: canBeUndefined, logger: logger);

  /// Get one element from JSON object
  ///
  /// Find the element thanks to the [key] given. We expect to find the element, if it's not
  /// present we return null.
  ///
  /// A cast function can be given: [castValueFunc] to transform the value retrieved to the expected
  /// type
  ///
  /// Returns null if the element hasn't been found or it hasn't the right type
  static T? getNotNullOneElement<T, Y>({
    required Map<String, dynamic> json,
    required String key,
    T? Function(Y toCast)? castValueFunc,
    required MixinActLogger logger,
  }) {
    final result = getOneElement<T, Y>(
      json: json,
      key: key,
      castValueFunc: castValueFunc,
      logger: logger,
    );

    if (!result.isOk) {
      return null;
    }

    return result.value;
  }

  /// Get one primary element (number, String or boolean) from JSON object
  ///
  /// Find the element thanks to the [key] given. We expect to find the element, if it's not
  /// present we return null.
  ///
  /// Returns null if the element hasn't been found or it hasn't the right type
  static T? getNotNullOnePrimaryElement<T>({
    required Map<String, dynamic> json,
    required String key,
    required MixinActLogger logger,
  }) => getNotNullOneElement<T, T>(json: json, key: key, logger: logger);

  /// Get a list of elements from JSON object
  ///
  /// Find the list thanks to the [key] given. If the element can be not present in the JSON set
  /// [canBeUndefined] to true.
  ///
  /// A cast function can be given: [castElemValueFunc] to transform the elements list retrieved to
  /// the expected type.
  ///
  /// Returns true in `isOk` parameter if no problem occurred
  static ({bool isOk, List<T>? value}) getElementsList<T, Y>({
    required Map<String, dynamic> json,
    required String key,
    bool canBeUndefined = false,
    T? Function(Y toCast)? castElemValueFunc,
    required MixinActLogger logger,
  }) => getOneElement<List<T>, List<dynamic>>(
    json: json,
    key: key,
    canBeUndefined: canBeUndefined,
    logger: logger,
    castValueFunc: (toCast) {
      final finalList = <T>[];
      for (final elem in toCast) {
        final result = _castValueIfNeeded(
          value: elem,
          castValueFunc: castElemValueFunc,
          logger: logger,
        );

        final value = result.value;
        if (!result.isOk || value == null) {
          return null;
        }

        finalList.add(value);
      }

      return finalList;
    },
  );

  /// Get a list of primary elements (number, String or boolean) from JSON object
  ///
  /// Find the list thanks to the [key] given. If the element can be not present in the JSON set
  /// [canBeUndefined] to true.
  ///
  /// Returns true in `isOk` parameter if no problem occurred
  static ({bool isOk, List<T>? value}) getPrimaryElementsList<T>({
    required Map<String, dynamic> json,
    required String key,
    bool canBeUndefined = false,
    required MixinActLogger logger,
  }) => getElementsList<T, T>(json: json, key: key, canBeUndefined: canBeUndefined, logger: logger);

  /// Get a list of not null elements from JSON object
  ///
  /// Find the list thanks to the [key] given. We expect to find the element, if it's not present
  /// we return null.
  ///
  /// A cast function can be given: [castElemValueFunc] to transform the elements list retrieved to
  /// the expected type.
  ///
  /// Returns null if the element hasn't been found or it hasn't the right type
  static List<T>? getNotNullElementsList<T, Y>({
    required Map<String, dynamic> json,
    required String key,
    T? Function(Y toCast)? castElemValueFunc,
    required MixinActLogger logger,
  }) {
    final result = getElementsList<T, Y>(
      json: json,
      key: key,
      castElemValueFunc: castElemValueFunc,
      logger: logger,
    );

    if (!result.isOk) {
      return null;
    }

    return result.value;
  }

  /// Get a list of not null primary elements (number, String or boolean) from JSON object
  ///
  /// Find the list thanks to the [key] given. We expect to find the element, if it's not present
  /// we return null.
  ///
  /// Returns null if the element hasn't been found or it hasn't the right type
  static List<T>? getNotNullPrimaryElementsList<T>({
    required Map<String, dynamic> json,
    required String key,
    required MixinActLogger logger,
  }) => getNotNullElementsList<T, T>(json: json, key: key, logger: logger);

  /// Get one child JSON object from a given JSON object
  ///
  /// Find the JSON object thanks to the [key] given. If the JSON object can be not present in the
  /// JSON set [canBeUndefined] to true.
  ///
  /// Returns true in `isOk` parameter if no problem occurred
  static ({bool isOk, Map<String, dynamic>? value}) getJsonObject({
    required Map<String, dynamic> json,
    required String key,
    bool canBeUndefined = false,
    required MixinActLogger logger,
  }) => getOneElement<Map<String, dynamic>, Object?>(
    json: json,
    key: key,
    canBeUndefined: canBeUndefined,
    logger: logger,
  );

  /// Get one child JSON object from a given JSON object
  ///
  /// Find the JSON object thanks to the [key] given. We expect to find the element, if it's not
  /// present we return null.
  ///
  /// Returns null if the element hasn't been found or it hasn't the right type
  static Map<String, dynamic>? getNotNullJsonObject({
    required Map<String, dynamic> json,
    required String key,
    required MixinActLogger logger,
  }) {
    final result = getOneElement<Map<String, dynamic>, Object?>(
      json: json,
      key: key,
      logger: logger,
    );

    if (!result.isOk) {
      return null;
    }

    return result.value;
  }

  /// Get a list of JSON objects from a given JSON object
  ///
  /// Find the list thanks to the [key] given. If the element can be not present in the JSON set
  /// [canBeUndefined] to true.
  ///
  /// Returns true in `isOk` parameter if no problem occurred
  static ({bool isOk, List<Map<String, dynamic>>? value}) getJsonObjectsList({
    required Map<String, dynamic> json,
    required String key,
    bool canBeUndefined = false,
    required MixinActLogger logger,
  }) => getElementsList<Map<String, dynamic>, Object?>(
    json: json,
    key: key,
    canBeUndefined: canBeUndefined,
    logger: logger,
  );

  /// Get a list of JSON objects from a given JSON object
  ///
  /// Find the list thanks to the [key] given. We expect to find the element, if it's not present
  /// we return null.
  ///
  /// Returns null if the element hasn't been found or it hasn't the right type
  static List<Map<String, dynamic>>? getNotNullJsonObjectsList({
    required Map<String, dynamic> json,
    required String key,
    required MixinActLogger logger,
  }) {
    final result = getElementsList<Map<String, dynamic>, Object?>(
      json: json,
      key: key,
      logger: logger,
    );

    if (!result.isOk) {
      return null;
    }

    return result.value;
  }

  /// Parse the response body to a Json
  static Map<String, dynamic>? parseJsonBodyToObj(
    String? strJson, {
    required MixinActLogger logger,
  }) => _parseJsonBody(strJson, logger: logger);

  /// Parse the response body to a Json Array
  static List<dynamic>? parseJsonBodyToArray(String? strJson, {required MixinActLogger logger}) =>
      _parseJsonBody(strJson, logger: logger);

  /// Parse the response body to a Json Array
  static List<Map<String, dynamic>>? parseJsonArrayBodyToArray(
    String? strJson, {
    required MixinActLogger logger,
  }) {
    final tmpList = _parseJsonBody<List<dynamic>>(strJson, logger: logger);

    if (tmpList == null) {
      return null;
    }

    try {
      return List<Map<String, dynamic>>.from(tmpList, growable: false);
    } catch (_) {
      logger.w("The JSON element hasn't been stored in the Map<String, dynamic> type");
      return null;
    }
  }

  /// The method merges two json together in cascades, it takes [baseJson] as base and overrides
  /// the values with [jsonToOverrideWith].
  ///
  /// The does the merge in deep. However, if, for a given key, the value key isn't the same, the
  /// [jsonToOverrideWith] overrides the [baseJson] value.
  ///
  /// We don't merge list together: the [jsonToOverrideWith] value is used.
  ///
  /// If a key of [baseJson] doesn't exist in [jsonToOverrideWith], the key and its value are kept
  /// in the final map.
  static Map<String, dynamic> mergeJson({
    required Map<String, dynamic> baseJson,
    required Map<String, dynamic> jsonToOverrideWith,
  }) {
    final newJson = Map<String, dynamic>.from(baseJson);
    for (final overrideEntry in jsonToOverrideWith.entries) {
      final overKey = overrideEntry.key;
      final overValue = overrideEntry.value;
      if (!newJson.containsKey(overKey)) {
        // The override key is not in the base json; therefore, we can add all the json tree in the
        // returned JSON
        newJson[overKey] = overValue;
        continue;
      }

      newJson[overKey] = _mergeJsonValue(baseValue: baseJson[overKey], toOverrideValue: overValue);
    }

    return newJson;
  }

  /// The method merge two json value together.
  ///
  /// If the values are Map\<String, dynamic\> we try to merge the value together by calling
  /// [mergeJson] method.
  ///
  /// If the values have a different type, the [toOverrideValue] is used.
  static dynamic _mergeJsonValue({
    // We deal with json value, so we need to work with dynamic values
    // ignore: avoid_annotating_with_dynamic
    required dynamic baseValue,
    // We deal with json value, so we need to work with dynamic values
    // ignore: avoid_annotating_with_dynamic
    required dynamic toOverrideValue,
  }) {
    if (toOverrideValue is Map<String, dynamic> && baseValue is Map<String, dynamic>) {
      return mergeJson(baseJson: baseValue, jsonToOverrideWith: toOverrideValue);
    }

    if (toOverrideValue == null) {
      // If toOverrideValue value is equal to null, we use baseValue
      return baseValue;
    }

    return toOverrideValue;
  }

  /// Parse the response body from an object or list to a Json
  static T? _parseJsonBody<T>(String? strJson, {required MixinActLogger logger}) {
    if (strJson == null) {
      return null;
    }

    T? data;

    try {
      data = jsonDecode(strJson) as T;
    } catch (error) {
      logger.w("Cannot parse to json, the response body: $strJson, the error: $error");
    }

    return data;
  }

  /// Cast the given [value] with the [castValueFunc] method, if the method is not null.
  ///
  /// Returns true in `isOk` parameter if no problem occurred
  static ({bool isOk, T? value}) _castValueIfNeeded<T, Y>({
    // This method manipulates JSON value; therefore, it's ok to have dynamic here
    // ignore: avoid_annotating_with_dynamic
    required dynamic value,
    T? Function(Y toCast)? castValueFunc,
    required MixinActLogger logger,
  }) {
    if (castValueFunc == null) {
      if (value is! T) {
        logger.w("The JSON element hasn't been stored in the $T type");
        return const (isOk: false, value: null);
      }

      return (isOk: true, value: value);
    }

    if (value is! Y) {
      logger.w(
        "The JSON element hasn't been stored in the $Y type, it can't "
        "be casted",
      );
      return const (isOk: false, value: null);
    }

    final castValue = castValueFunc(value);
    if (castValue == null) {
      logger.w("The cast of the JSON element failed");
      return const (isOk: false, value: null);
    }

    return (isOk: true, value: castValue);
  }
}
