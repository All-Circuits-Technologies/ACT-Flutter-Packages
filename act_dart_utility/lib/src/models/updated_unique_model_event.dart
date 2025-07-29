// SPDX-FileCopyrightText: 2025 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_dart_utility/act_dart_utility.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';

/// This event is emitted when an unique model object is created, updated or deleted.
///
/// - When [previousUniqueId] is null and [current] is not null, it means that an object has been
///   created.
/// - When [previousUniqueId] is not null and [current] is not null, it means that an object has
///   been updated.
/// - When [previousUniqueId] is not null and [current] is null, it means that an object has been
///   deleted.
class UpdatedUniqueModelEvent<M extends MixinUniqueModel> extends Equatable {
  /// The [previousUniqueId] of the object updated or deleted
  final String? previousUniqueId;

  /// The [current] object information retrieved after a modification
  final M? current;

  /// Used as constructor when an object is created
  const UpdatedUniqueModelEvent.newObjectCreated({
    required M this.current,
  }) : previousUniqueId = null;

  /// Used as constructor when an object is updated
  const UpdatedUniqueModelEvent.objectUpdated({
    required String this.previousUniqueId,
    required M this.current,
  });

  /// Used as constructor when an object is deleted
  const UpdatedUniqueModelEvent.objectDeleted({
    required String this.previousUniqueId,
  }) : current = null;

  /// Class properties
  @override
  @mustCallSuper
  List<Object?> get props => [previousUniqueId, current];
}
