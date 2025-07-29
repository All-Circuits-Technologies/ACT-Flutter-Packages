// SPDX-FileCopyrightText: 2025 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:equatable/equatable.dart';

/// This mixin is used to represent an object which is unique among a type of objects
mixin MixinUniqueModel on Equatable {
  /// {@template MixinUniqueModel.uniqueId}
  /// This is the unique which represents the object. It must be unique for the object type
  /// {@endtemplate}
  String get uniqueId;
}
