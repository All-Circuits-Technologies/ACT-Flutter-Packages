// SPDX-FileCopyrightText: 2024 Théo Magne <theo.magne@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

/// Mixin to add shadow name to an enum.
mixin MixinAwsIotShadowEnum on Enum {
  /// This is the shadow name that is used to interact with the shadow
  String get shadowName;
}
