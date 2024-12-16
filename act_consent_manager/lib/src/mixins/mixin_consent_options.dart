// SPDX-FileCopyrightText: 2024 Théo Magne <theo.magne@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

/// Mixin to add the `isOptional` getter to an enum
mixin MixinConsentOptions on Enum {
  /// true if the option is not mandatory for the consent to be valid
  bool get isOptional;
}
