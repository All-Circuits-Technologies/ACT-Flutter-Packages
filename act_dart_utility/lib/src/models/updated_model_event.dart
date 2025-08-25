// SPDX-FileCopyrightText: 2025 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';

/// {@template act_dart_utility.UpdatedModelEvent.description}
/// This event is emitted when a model object is created, updated or deleted.
///
/// - When [previousUniqueId] is null and [current] is not null, it means that an object has been
///   created.
/// - When [previousUniqueId] is not null and [current] is not null, it means that an object has
///   been updated.
/// - When [previousUniqueId] is not null and [current] is null, it means that an object has been
///   deleted.
/// {@endtemplate}
class UpdatedModelEvent<M extends Equatable, U extends Object> extends Equatable {
  /// The [previousUniqueId] of the object updated or deleted
  final U? previousUniqueId;

  /// The [current] object information retrieved after a modification
  final M? current;

  /// Used as constructor when an object is created
  const UpdatedModelEvent.newObjectCreated({
    required M this.current,
  }) : previousUniqueId = null;

  /// Used as constructor when an object is updated
  const UpdatedModelEvent.objectUpdated({
    required M this.current,
    required U this.previousUniqueId,
  });

  /// Used as constructor when an object is deleted
  const UpdatedModelEvent.objectDeleted({
    required U this.previousUniqueId,
  }) : current = null;

  /// Class properties
  @override
  @mustCallSuper
  List<Object?> get props => [previousUniqueId, current];
}
