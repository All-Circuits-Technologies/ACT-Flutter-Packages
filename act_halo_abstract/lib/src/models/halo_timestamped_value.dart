// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:equatable/equatable.dart';

/// A value decoded from a HALO payload packet element, with the optional timestamp which was
/// attached to it
class HaloTimestampedValue<T> extends Equatable {
  /// The decoded value
  final T data;

  /// The timestamp attached to the value, null if the element didn't carry one
  final DateTime? timestamp;

  /// Class constructor
  const HaloTimestampedValue({required this.data, this.timestamp});

  @override
  List<Object?> get props => [data, timestamp];
}
