// SPDX-FileCopyrightText: 2024 Théo Magne <theo.magne@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

/// Mixin to add a `isSuccess` getter to an enum and a `canBeRetried` getter
mixin MixinResultStatus on Enum {
  /// {@template act_dart_result.MixinResultStatus.isSuccess}
  /// Getter to know if the request is a success
  /// {@endtemplate}
  bool get isSuccess;

  /// {@template act_dart_result.MixinResultStatus.isError}
  /// Getter to know if the request is an error
  ///
  /// This is the opposite of [isSuccess].
  /// {@endtemplate}
  bool get isError => !isSuccess;

  /// {@template act_dart_result.MixinResultStatus.canBeRetried}
  /// Getter to know if the request can be tried/retried
  /// {@endtemplate}
  bool get canBeRetried;
}
