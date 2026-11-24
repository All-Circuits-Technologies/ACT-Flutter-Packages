// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:equatable/equatable.dart';

/// An event a storage singleton emits on its event stream, each time it is written to.
sealed class StorageWriteEvent extends Equatable {
  /// Class constructor
  const StorageWriteEvent();
}

/// The value of [key] has been written: stored, or deleted when [value] is null.
class StorageValueEvent extends StorageWriteEvent {
  /// The key which has been written
  final String key;

  /// The value which has been stored under [key], null when the key has been deleted.
  ///
  /// It is the value given to the storage, before the storage converts it to the format it keeps.
  final Object? value;

  /// Class constructor
  const StorageValueEvent({required this.key, required this.value});

  /// Class properties
  @override
  List<Object?> get props => [key, value];
}

/// The storage has been cleared: every key has been deleted.
class StorageClearedEvent extends StorageWriteEvent {
  /// Class constructor
  const StorageClearedEvent();

  /// Class properties
  @override
  List<Object?> get props => const [];
}
