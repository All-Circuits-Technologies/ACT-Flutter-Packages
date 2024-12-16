// SPDX-FileCopyrightText: 2023 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

/// The error we can encounter in the process of the [TbTelemetriesUiBloc]
enum TbTelemetriesUiError {
  noError(isError: false),
  noInternetAtStart,
  unknownDevice,
  serverError;

  /// True if the linked enum is an error
  final bool isError;

  /// Class constructor
  const TbTelemetriesUiError({
    this.isError = true,
  });
}
