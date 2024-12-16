// SPDX-FileCopyrightText: 2024 Théo Magne <theo.magne@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

/// Enum representing the state of a consent
enum ConsentStateEnum {
  accepted,
  notAccepted,
  unknown;

  /// Returns true if the consent can be considered as not accepted
  bool get isNotAccepted => this == notAccepted;

  /// Returns true if the consent can be considered as accepted. This includes
  /// the case where the consent is unknown.
  bool get isAccepted => this == accepted || this == unknown;
}
