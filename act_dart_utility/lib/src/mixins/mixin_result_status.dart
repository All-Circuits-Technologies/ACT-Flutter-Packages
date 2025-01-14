// SPDX-FileCopyrightText: 2024 Théo Magne <theo.magne@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

/// Mixin to add a `isSuccess` getter to an enum and a `canBeRetried` getter
mixin MixinResultStatus on Enum {
  /// Getter to know if the request is a success
  bool get isSuccess;

  /// Getter to know if the request can be tried/retried
  bool get canBeRetried;
}
