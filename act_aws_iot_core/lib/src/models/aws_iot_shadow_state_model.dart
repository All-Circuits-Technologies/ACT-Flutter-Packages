// SPDX-FileCopyrightText: 2024 Théo Magne <theo.magne@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_aws_iot_core/src/mixins/mixin_aws_iot_shadow_doc.dart';
import 'package:act_global_manager/act_global_manager.dart';
import 'package:equatable/equatable.dart';

/// This models is based on the AWS IoT Device Shadow service and represents the data that is stored
/// in the shadow. It is used by the AwsIotNamedShadow class to store the state of the shadow.
/// Some fields are ignored (like the delta field) since we have no use of them.
class AwsIotShadowStateModel extends Equatable with MixinAwsIotShadowDoc {
  /// This is the latest known version of the shadow
  final int version;

  /// This is the desired state of the shadow
  final Map<String, dynamic> desiredState;

  /// This is the reported state of the shadow
  final Map<String, dynamic> reportedState;

  /// Class constructor
  const AwsIotShadowStateModel({
    required this.version,
    required this.desiredState,
    required this.reportedState,
  });

  /// Class contructor with empty values
  AwsIotShadowStateModel.empty()
      : version = 0,
        desiredState = {},
        reportedState = {};

  /// Copy with method
  AwsIotShadowStateModel copyWith({
    int? version,
    Map<String, dynamic>? desiredState,
    Map<String, dynamic>? reportedState,
  }) =>
      AwsIotShadowStateModel(
        version: version ?? this.version,
        desiredState: desiredState ?? this.desiredState,
        reportedState: reportedState ?? this.reportedState,
      );

  /// This method is used to update the state of the shadow after an accepted get request or an
  /// accepted update request
  ///
  /// [jsonStr] is the json string received from the AWS IoT Device Shadow service
  /// Null will be returned if the json string is invalid or if the version is not above the current
  /// one.
  AwsIotShadowStateModel? copyAfterAcceptedGetUpdate(String jsonStr) {
    final json = MixinAwsIotShadowDoc.getJsonFromString(jsonStr);

    if (json == null) {
      return null;
    }

    // Get the state and the version which are mandatory for an accepted response
    final state = MixinAwsIotShadowDoc.getState(json);
    if (state == null) {
      appLogger().w('The state or the version is missing in the accepted response');
      return null;
    }
    final version = MixinAwsIotShadowDoc.getVersion(json);
    if (version == null) {
      appLogger().w('The version is missing in the accepted response');
      return null;
    }

    // Check if the version is above the current one
    if (version <= this.version) {
      appLogger().w(
        'Received version ($version) of shadow document is '
        'not above the current one (${this.version})',
      );
      return null;
    }

    final desired = MixinAwsIotShadowDoc.getDesiredState(state);
    final reported = MixinAwsIotShadowDoc.getReportedState(state);

    return copyWith(
      version: version,
      desiredState: desired,
      reportedState: reported,
    );
  }

  /// This method generates a jsonString to be sent to the AWS IoT Device Shadow service when
  /// requesting an update. [newDesiredState] is a map that contains the attributes to be updated.
  /// [clientToken] is a unique identifier for the request.
  ///
  /// Null will be returned if there is no change between the current desired state and the new one.
  String? getJsonForUpdateRequest(
    Map<String, dynamic> newDesiredState,
    String clientToken,
  ) {
    // Merge the desired state with the current one and check if there is at least one change
    var hasChange = false;
    final mergedDesiredState = Map<String, dynamic>.from(desiredState);

    newDesiredState.forEach((key, value) {
      if (mergedDesiredState[key] != value) {
        hasChange = true;
        mergedDesiredState[key] = value;
      }
    });

    if (!hasChange) {
      return null;
    }

    final json = MixinAwsIotShadowDoc.getJsonForUpdateRequest(
      mergedDesiredState,
      version,
      clientToken,
    );

    return MixinAwsIotShadowDoc.getJsonAsString(json);
  }

  /// This method checks if the provided accepted response [jsonString] contains the client token
  /// specified in the [expectedClientToken] parameter
  static bool isClientTokenValid(
    String jsonString,
    String expectedClientToken,
  ) {
    // Get the json object from the string
    final json = MixinAwsIotShadowDoc.getJsonFromString(jsonString);
    if (json == null) {
      return false;
    }

    // Get the client token from the json object
    final responseToken = MixinAwsIotShadowDoc.getClientToken(json);

    return responseToken == expectedClientToken;
  }

  @override
  List<Object?> get props => [
        version,
        desiredState,
        reportedState,
      ];
}
