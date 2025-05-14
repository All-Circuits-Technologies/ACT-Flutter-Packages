// SPDX-FileCopyrightText: 2023 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:equatable/equatable.dart';
import 'package:thingsboard_client/thingsboard_client.dart';

/// Helpful class to link an [AttributeData] and its [AttributeScope]
class TbExtAttributeData extends Equatable {
  /// The attribute data
  final AttributeData data;

  /// The scope of the attribute data
  final AttributeScope scope;

  /// Class constructor
  const TbExtAttributeData({required this.data, required this.scope});

  /// Class properties
  @override
  List<Object?> get props => [data.lastUpdateTs, data.key, data.value, scope];
}
