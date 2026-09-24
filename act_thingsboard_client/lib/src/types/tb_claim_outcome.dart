// SPDX-FileCopyrightText: 2026 Dorian Benech <dorian.benech@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

/// What one claim attempt amounts to, once the answer of Thingsboard has been read.
enum TbClaimOutcome {
  /// The device is bound to the customer of the user
  success,

  /// The device is already bound to a customer
  alreadyClaimed,

  /// The server refused the claim
  refused,

  /// The server knows no device of that name
  unknownDevice,

  /// The secret matches no claim the device is waiting for
  secretRefused,

  /// The session of the user is over
  loginError,

  /// Anything else: the server could not be reached, or it answered something unreadable
  communicationError,
}
