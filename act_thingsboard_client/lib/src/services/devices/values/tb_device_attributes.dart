// SPDX-FileCopyrightText: 2023 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_thingsboard_client/src/services/devices/values/a_tb_telemetry.dart';
import 'package:thingsboard_client/thingsboard_client.dart';

/// Allows to manage and get values from attributes
class TbDeviceAttributes extends ATbTelemetry<AttributeData> {
  /// The [AttributeScope] linked to this class
  final AttributeScope scope;

  /// Class constructor
  TbDeviceAttributes({
    required super.requestService,
    required super.logsHelper,
    required super.deviceId,
    required this.scope,
  }) : super(telemetryName: scope.logName);

  /// Create a subscription command linked to attributes
  @override
  SubscriptionCmd createSubCmd(String keys) => AttributesSubscriptionCmd(
        entityType: EntityType.DEVICE,
        entityId: deviceId,
        scope: scope,
        keys: keys,
      );

  /// Called to parse the subscription update received and get the [AttributeData] linked
  @override
  Future<Map<String, AttributeData>> onUpdateValuesImpl(SubscriptionUpdate subUpdate) async {
    final attrValues = <AttributeData>[];
    subUpdate.updateAttributeData(attrValues);

    final elements = <String, AttributeData>{};

    for (final value in attrValues) {
      elements[value.key] = value;
    }

    return elements;
  }

  /// Get the timestamp value linked to the last update value
  @override
  int? getTimestamp(AttributeData? value) => value?.lastUpdateTs;
}

/// Extension of [AttributeScope]
extension _AttributeScopeExtension on AttributeScope {
  /// Allows to get a log category linked to the [AttributeScope]
  String get logName {
    switch (this) {
      case AttributeScope.SHARED_SCOPE:
        return "sharedAttr";
      case AttributeScope.CLIENT_SCOPE:
        return "clientAttr";
      case AttributeScope.SERVER_SCOPE:
        return "serverAttr";
    }
  }
}
