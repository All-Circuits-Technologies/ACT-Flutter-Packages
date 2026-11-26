// SPDX-FileCopyrightText: 2023 Anthony Loiseau <anthony.loiseau@allcircuits.com>
// SPDX-FileCopyrightText: 2023 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

/// Device 's state of bond/pair
enum BondState {
  /// When we don't know the current pairing/bonding state
  unknown,

  /// When we are pairing/bonding with the device
  bonding,

  /// When the pairing/bonding has failed
  bondingFailed,

  /// When the device is paired/bonded
  bonded,
}
