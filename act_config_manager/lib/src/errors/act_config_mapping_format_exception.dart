// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_foundation/act_foundation.dart';

/// This exception is thrown when the content of a config or env config mapping file isn't
/// correctly formatted (e.g. unexpected type, missing property, unknown value, etc.).
class ActConfigMappingFormatException extends ActException {
  /// Class constructor
  ActConfigMappingFormatException(super.message);
}
