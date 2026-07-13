// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_foundation/act_foundation.dart';

/// This exception is thrown when we failed to load a config related file (yaml config file, env
/// config mapping file, etc.), for instance because of an I/O error or a missing asset.
class ActConfigLoadException extends ActException {
  /// Class constructor
  ActConfigLoadException(super.message);
}
