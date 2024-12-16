// SPDX-FileCopyrightText: 2023 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:flutter/foundation.dart';

/// Abstract class for all the component of material layers
abstract class AbstractHaloComponentMaterial {
  /// Manage the close of all the resources at the end of the class
  /// Need to be called by the owner of the class
  @mustCallSuper
  Future<void> close();
}
