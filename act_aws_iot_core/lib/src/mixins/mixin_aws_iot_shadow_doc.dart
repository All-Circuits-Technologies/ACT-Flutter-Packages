// SPDX-FileCopyrightText: 2024 Théo Magne <theo.magne@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'dart:convert';

import 'package:act_aws_iot_core/src/types/shadow_error_code.dart';
import 'package:act_dart_utility/act_dart_utility.dart';
import 'package:act_global_manager/act_global_manager.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';

/// This mixin is used to add some utility functions to a class that manipulates shadow documents
/// Shadow documents are json documents that are used to interact with the AWS IoT shadow service
/// Refer to the AWS IoT shadow document here:
/// https://docs.aws.amazon.com/iot/latest/developerguide/device-shadow-document.html
mixin MixinAwsIotShadowDoc on Equatable {
  /// This is the tag that is used to identify an error code in an error document
  @protected
  static const errorCodeTag = 'code';

  /// This is the tag that is used to identify an error message in an error document
  @protected
  static const errorMessageTag = 'message';

  /// This is the tag that is used to identify the version of the shadow
  @protected
  static const versionTag = 'version';

  /// This is the tag that is used to identify the client token of the response/request
  @protected
  static const clientTokenTag = 'clientToken';

  /// This is the tag that is used to identify the timestamp of the document
  @protected
  static const timestampTag = 'timestamp';

  /// This is the tag that is used to identify the state field in a document
  @protected
  static const stateTag = 'state';

  /// This is the tag that is used to identify the desired field in a document
  @protected
  static const desiredTag = 'desired';

  /// This is the tag that is used to identify the reported field in a document
  @protected
  static const reportedTag = 'reported';

  /// Get the error code of the document
  @protected
  static ShadowErrorCode? getErrorCode(Map<String, dynamic> json) {
    final code = _getInt(json, errorCodeTag);

    if (code == null) {
      return null;
    }

    return ShadowErrorCode.fromCode(code);
  }

  /// Get the version of the document
  @protected
  static int? getVersion(Map<String, dynamic> json) => _getInt(json, versionTag);

  /// Get the client token of the document
  @protected
  static String? getClientToken(Map<String, dynamic> json) => _getString(json, clientTokenTag);

  /// Get the timestamp of the document
  @protected
  static int? getTimestamp(Map<String, dynamic> json) => _getInt(json, timestampTag);

  /// Get the desired state of the document
  ///
  /// The desired state got from shadow can be null
  @protected
  static Map<String, dynamic>? getDesiredState(Map<String, dynamic> json) {
    final (result, desiredJson) = _getNullableJsonObject(json, desiredTag);
    if (!result) {
      return null;
    }

    return desiredJson ?? {};
  }

  /// Get the reported state of the document
  @protected
  static Map<String, dynamic>? getReportedState(Map<String, dynamic> json) =>
      _getJsonObject(json, reportedTag);

  /// Get the state of the document
  @protected
  static Map<String, dynamic>? getState(Map<String, dynamic> json) =>
      _getJsonObject(json, stateTag);

  /// Get the json object for an update request
  @protected
  static Map<String, dynamic> getJsonForUpdateRequest(
    Map<String, dynamic> desiredState,
    int version,
    String clientToken,
  ) =>
      {
        stateTag: {
          desiredTag: desiredState,
        },
        versionTag: version,
        clientTokenTag: clientToken,
      };

  /// Get a json from a string
  @protected
  static Map<String, dynamic>? getJsonFromString(String jsonStr) =>
      JsonUtility.parseJsonBodyToObj(jsonStr, loggerManager: appLogger());

  /// Get the error message of the document
  @protected
  static String? getErrorMessage(Map<String, dynamic> json) => _getString(json, errorMessageTag);

  /// Get a json string from a json
  @protected
  static String getJsonAsString(Map<String, dynamic> json) => jsonEncode(json);

  /// Get an integer from a json
  @protected
  static int? _getInt(Map<String, dynamic> json, String key) => JsonUtility.getNotNullOneElement(
        json: json,
        key: key,
        loggerManager: appLogger(),
      );

  /// Get a string from a json
  @protected
  static String? _getString(Map<String, dynamic> json, String key) =>
      JsonUtility.getNotNullOneElement(
        json: json,
        key: key,
        loggerManager: appLogger(),
      );

  /// Get a json object from a json
  @protected
  static Map<String, dynamic>? _getJsonObject(Map<String, dynamic> json, String key) =>
      JsonUtility.getNotNullJsonObject(
        json: json,
        key: key,
        loggerManager: appLogger(),
      );

  /// Get a nullabel json object from a json
  @protected
  static (bool, Map<String, dynamic>?) _getNullableJsonObject(
          Map<String, dynamic> json, String key) =>
      JsonUtility.getJsonObject(
        json: json,
        key: key,
        canBeUndefined: true,
        loggerManager: appLogger(),
      );
}
