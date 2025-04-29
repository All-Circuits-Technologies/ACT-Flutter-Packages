import 'dart:convert';

import 'package:act_global_manager/act_global_manager.dart';
import 'package:act_shared_auth/act_shared_auth.dart';
import 'package:act_shared_auth_local_storage/src/models/auth_user_ids.dart';

sealed class MemoryStorageUtility {
  static String convertAuthTokensForStorage(AuthTokens tokens) => jsonEncode(tokens.toJson());

  static AuthTokens? convertAuthTokensFromStorage(String? value) => _convertFromStorage(
    value: value,
    elementName: "auth tokens",
    classFactory: AuthTokens.fromJson,
  );

  static String convertAuthUserIdsForStorage(AuthUserIds userIds) => jsonEncode(userIds.toJson());

  static AuthUserIds? convertAuthUserIdsFromStorage(String? value) => _convertFromStorage(
    value: value,
    elementName: "auth user ids",
    classFactory: AuthUserIds.fromJson,
  );

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
          "The $elementName stored in the secured storage is not a JSON object, we can't convert it",
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
