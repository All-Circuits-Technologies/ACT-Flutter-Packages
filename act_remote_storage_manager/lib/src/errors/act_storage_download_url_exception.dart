// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_foundation/act_foundation.dart';

/// This exception is thrown when we failed to get the download url of a file from the storage
/// service.
class ActStorageDownloadUrlException extends ActException {
  /// Class constructor
  ActStorageDownloadUrlException(super.message);
}
