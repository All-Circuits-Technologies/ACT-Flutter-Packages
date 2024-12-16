// SPDX-FileCopyrightText: 2023 Anthony Loiseau <anthony.loiseau@allcircuits.com>
// SPDX-FileCopyrightText: 2023 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:flutter/widgets.dart';

/// Abstract class for all the application managers
abstract class AbstractService {
  /// Class constructor
  const AbstractService();

  /// Asynchronous initialization of the service
  @mustCallSuper
  Future<void> initService();

  /// Method called asynchronously after the view is initialised
  ///
  /// This [BuildContext] is above the Navigator (therefore it can't be used to access it)
  @mustCallSuper
  Future<void> initAfterView(BuildContext context) async {}

  /// Default dispose for service
  @mustCallSuper
  Future<void> dispose() async {}
}
