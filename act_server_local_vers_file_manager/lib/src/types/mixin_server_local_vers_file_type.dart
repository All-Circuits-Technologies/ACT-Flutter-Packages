// SPDX-FileCopyrightText: 2025 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

/// This mixin provides a type for the server local directory configuration.
mixin MixinServerLocalVersFileType on Enum {
  /// The unique identifier for the directory type.
  /// This identifier is used to store and retrieve the directory options in the configuration.
  String get dirId;
}
