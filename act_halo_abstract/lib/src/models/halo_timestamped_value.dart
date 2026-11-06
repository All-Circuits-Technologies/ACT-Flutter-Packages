// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
// SPDX-FileCopyrightText: 2026 Damien Manceau <damien.manceau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:equatable/equatable.dart';

/// A value decoded from a HALO payload packet element, with the timestamp which was attached to it
///
/// [Ts] is the type of the timestamp: [DateTime?] when the element may not carry one, [DateTime]
/// when it is required. Use the derived classes [HaloTimestampedValue] and
/// [HaloRequiredTimestampedValue].
class BaseHaloTimestampedValue<T, Ts extends DateTime?> extends Equatable {
  /// The decoded value
  final T data;

  /// The timestamp attached to the value
  final Ts timestamp;

  /// Class constructor
  const BaseHaloTimestampedValue({required this.data, required this.timestamp});

  @override
  List<Object?> get props => [data, timestamp];
}

/// A value decoded from a HALO payload packet element, with the optional timestamp which was
/// attached to it
class HaloTimestampedValue<T> extends BaseHaloTimestampedValue<T, DateTime?> {
  /// Class constructor, without timestamp when the element didn't carry one
  const HaloTimestampedValue({required super.data, super.timestamp});

  /// The value with its timestamp required, null if the element didn't carry one
  HaloRequiredTimestampedValue<T>? toRequired() {
    final timestamp = this.timestamp;

    return (timestamp == null)
        ? null
        : HaloRequiredTimestampedValue(data: data, timestamp: timestamp);
  }
}

/// A value decoded from a HALO payload packet element, with the timestamp which is required with it
class HaloRequiredTimestampedValue<T> extends BaseHaloTimestampedValue<T, DateTime> {
  /// Class constructor
  const HaloRequiredTimestampedValue({required super.data, required super.timestamp});
}
