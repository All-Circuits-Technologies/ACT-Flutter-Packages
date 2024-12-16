// SPDX-FileCopyrightText: 2024 Théo Magne <theo.magne@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_aws_iot_core/src/mixins/mixin_aws_iot_shadow_enum.dart';
import 'package:equatable/equatable.dart';

/// This models is used by the AwsIotShadowsService to know which shadows are required for each
/// devices
class AwsIotShadowsConfigModel extends Equatable {
  /// This list of shadows contains all the shadows that are required for a device
  final List<MixinAwsIotShadowEnum> shadowsList;

  /// Class constructor
  const AwsIotShadowsConfigModel({
    required this.shadowsList,
  });

  /// Get the properties of the class
  @override
  List<Object?> get props => [
        shadowsList,
      ];
}
