// SPDX-FileCopyrightText: 2025 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'dart:convert';

import 'package:act_global_manager/act_global_manager.dart';
import 'package:act_shared_auth/act_shared_auth.dart';
import 'package:act_shared_auth_local_storage/src/models/auth_user_ids.dart';

/// Utility class to manage memory storage for the auth local storage
sealed class MemoryStorageUtility {
  /// This is used to identify the auth tokens element in logs
  static const _authTokensLogName = "auth tokens";

  /// This is used to identify the auth user ids element in logs
  static const _authUserIdsLogName = "auth user ids";

  /// Convert the given [tokens] to a string representation
  ///
  /// The string result can be used to store data in the secure storage
  static String convertAuthTokensForStorage(AuthTokens tokens) => jsonEncode(tokens.toJson());

  /// Try to convert the [AuthTokens] from a given string [value]
  ///
  /// Return null if the [value] is null or if we failed to convert the value.
  static AuthTokens? convertAuthTokensFromStorage(String? value) => _convertFromStorage(
    value: value,
    elementName: _authTokensLogName,
    classFactory: AuthTokens.fromJson,
  );

  /// Convert [AuthUserIds] to a string which can be stored in memory
  static String convertAuthUserIdsForStorage(AuthUserIds userIds) => jsonEncode(userIds.toJson());

  /// Try to convert the [AuthUserIds] from a given string [value]
  ///
  /// Return null if the [value] is null or if we failed to convert the value.
  static AuthUserIds? convertAuthUserIdsFromStorage(String? value) => _convertFromStorage(
    value: value,
    elementName: _authUserIdsLogName,
    classFactory: AuthUserIds.fromJson,
  );

  /// Convert the string [value] got from storage to a T value thanks to the [classFactory] method.
  ///
  /// We consider that the [value] contains stringified JSON object. [elementName] is the name
  /// used for logging
  ///
  /// Return null if the [value] is null or if we failed to convert the value.
  static T? _convertFromStorage<T>({
    required String? value,
    required String elementName,
    required T? Function(Map<String, dynamic> json) classFactory,
  }) {
    if (value == null) {
      // Nothing to convert
      return null;
    }

    Map<String, dynamic>? json;
    try {
      final tmpJson = jsonDecode(value);
      if (tmpJson is Map<String, dynamic>) {
        json = tmpJson;
      } else {
        appLogger().w(
          "The $elementName stored in the secured storage is not a JSON object, we can't convert "
          "it",
        );
      }
    } catch (error) {
      appLogger().w(
        "The $elementName stored in the secured storage is not a JSON, we can't convert it: $error",
      );
    }

    if (json == null) {
      return null;
    }

    return classFactory(json);
  }
}
