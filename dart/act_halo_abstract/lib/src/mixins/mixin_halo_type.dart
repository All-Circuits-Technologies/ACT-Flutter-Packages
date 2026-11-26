// SPDX-FileCopyrightText: 2024 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

/// This mixin describes an enum type which can be exchanged through HALO
mixin MixinHaloType on Enum {
  /// Return the raw value representation of the enum element
  int get rawValue;
}
