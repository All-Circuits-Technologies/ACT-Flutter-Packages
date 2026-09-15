// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_life_cycle/act_life_cycle.dart';

/// A class representing additional information for a manager.
class ManagerExtraInfo {
  /// Manager type
  final Type managerType;

  /// Manager dependencies
  final List<Type> dependencies;

  /// Manager registration function
  final void Function(int order) register;

  /// The manager instance that has been registered, if any.
  AbsWithLifeCycle? registeredManager;

  /// The order in which the manager was registered.
  int? registrationOrder;

  /// Class constructor for initializing with default null values for registeredManager and
  /// registrationOrder.
  ManagerExtraInfo.init({
    required this.managerType,
    required this.dependencies,
    required this.register,
  }) : registeredManager = null,
       registrationOrder = null;
}
