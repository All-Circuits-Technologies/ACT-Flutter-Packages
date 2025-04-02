// SPDX-FileCopyrightText: 2025 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:equatable/equatable.dart';
import 'package:thingsboard_client/thingsboard_client.dart';

/// This allow to transform the [TsValue] model to an equatable.
class TbTsValue extends Equatable {
  /// This is the unix timestamp linked to the [value] reception
  final int ts;

  /// This is the [value] received
  final String? value;

  /// Class constructor
  const TbTsValue({required this.ts, this.value});

  /// Build the object from a [TsValue]
  TbTsValue.fromTsValue(TsValue tsValue)
      : ts = tsValue.ts,
        value = tsValue.value;

  /// Class properties
  @override
  List<Object?> get props => [ts, value];
}
