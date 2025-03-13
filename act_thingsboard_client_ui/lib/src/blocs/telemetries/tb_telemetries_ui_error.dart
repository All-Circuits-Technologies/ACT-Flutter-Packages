// SPDX-FileCopyrightText: 2023 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

/// The error we can encounter in the process of the TbTelemetriesUiBloc
enum TbTelemetriesUiError {
  /// No error
  noError(isError: false),

  /// There is not internet at bloc start
  noInternetAtStart,

  /// The device is unknown
  unknownDevice,

  /// A generic server error happened
  serverError;

  /// True if the linked enum is an error
  final bool isError;

  /// Class constructor
  const TbTelemetriesUiError({
    this.isError = true,
  });
}
