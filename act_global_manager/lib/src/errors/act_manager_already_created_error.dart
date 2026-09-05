// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_foundation/act_foundation.dart';

/// This error is thrown when an attempt is made to create a manager that has already been created.
class ActManagerAlreadyCreatedError extends ActError {
  /// Class constructor
  ActManagerAlreadyCreatedError({required Type managerType})
    : super("The manager of type $managerType has already been created");

  /// This trap forcibly crashes the app (in debug mode) when an attempt is made to create a manager
  /// that has already been created, and throws an [ActManagerAlreadyCreatedError] in release mode.
  ///
  /// [managerType] is the type of the manager that was attempted to be created again.
  static Never crash({required Type managerType}) {
    final error = ActManagerAlreadyCreatedError(managerType: managerType);
    assert(false, error.message);
    throw error;
  }
}
