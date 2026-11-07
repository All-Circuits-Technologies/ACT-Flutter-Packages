// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

/// This enum represents the state of the global manager
enum GlobalManagerState {
  /// The global manager is not created yet
  notCreated,

  /// The global manager is created but not all the managers are ready yet
  created,

  /// The global manager is initializing the managers
  startInit,

  /// All the managers are ready
  allReady,
}
