// SPDX-FileCopyrightText: 2025 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:equatable/equatable.dart';

/// Adds a method to merge an object with this model and create a new model
mixin MixinOtherToMergeWithModel<M extends MixinOtherToMergeWithModel<M, OtherToMergeWith>,
    OtherToMergeWith> on Equatable {
  /// Merges the current model with another one of type [OtherToMergeWith]
  M mergeWith(OtherToMergeWith mergeWith);
}
