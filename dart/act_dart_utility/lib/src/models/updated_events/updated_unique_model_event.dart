// SPDX-FileCopyrightText: 2025 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_dart_utility/act_dart_utility.dart';

/// {@macro act_dart_utility.UpdatedModelEvent.description}
///
/// The model is a [MixinUniqueModel] and the unique id is the unique id property of
/// [MixinUniqueModel]
class UpdatedUniqueModelEvent<M extends MixinUniqueModel> extends UpdatedModelEvent<M, String> {
  /// Used as constructor when an object is created
  const UpdatedUniqueModelEvent.newObjectCreated({required super.current})
      : super.newObjectCreated();

  /// Used as constructor when an object is updated
  UpdatedUniqueModelEvent.objectUpdated({
    required super.current,
  }) : super.objectUpdated(previousUniqueId: current.uniqueId);

  /// Used as constructor when an object is deleted
  const UpdatedUniqueModelEvent.objectDeleted({
    required super.previousUniqueId,
  }) : super.objectDeleted();
}
