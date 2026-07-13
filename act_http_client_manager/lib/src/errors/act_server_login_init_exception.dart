// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_foundation/act_foundation.dart';

/// This exception is thrown when we failed to initialize the login of the abstract server
/// requester.
class ActServerLoginInitException extends ActException {
  /// Class constructor
  ActServerLoginInitException(super.message);
}
