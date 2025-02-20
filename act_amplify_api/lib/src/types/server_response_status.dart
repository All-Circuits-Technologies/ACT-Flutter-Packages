// SPDX-FileCopyrightText: 2024 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'dart:io';

/// The response status after a server request
enum ServerResponseStatus {
  ok(HttpStatus.ok, genericSuccess),
  incorrectParams(HttpStatus.badRequest, genericClientError),
  paymentRequired(HttpStatus.paymentRequired, genericClientError),
  forbidden(HttpStatus.forbidden, genericClientError),
  notFound(HttpStatus.notFound, genericClientError),
  // Too early doesn't exist in the HttpStatus values
  tooEarly(425, genericClientError),
  internalServerError(HttpStatus.internalServerError, genericServerError),
  genericSuccess.generic(isOk: true),
  genericClientError.generic(),
  genericServerError.generic(),
  genericError.generic();

  /// List all the values linked to a http status code
  static final nonGenericValues = values.where((element) => element.httpStatus != null);

  /// This is the linked http status
  final int? httpStatus;

  /// True if the server response is ok and we can continue
  ///
  /// Null if we don't know and need to check with the linked generic value
  final bool? _isOk;

  /// True if the server response is ok and we can continue
  bool get isOk => _isOk ?? _linkedGeneric!._isOk!;

  /// This is the linked generic status
  ///
  /// It's always null for the generic errors and not null for the errors linked to a http status
  /// code
  final ServerResponseStatus? _linkedGeneric;

  /// This is the generic status linked to this one.
  ///
  /// If the status is already a generic, this returns itself
  ServerResponseStatus get linkedGeneric => _linkedGeneric ?? this;

  /// Class constructor when the error is linked to a http status
  const ServerResponseStatus(
    int this.httpStatus,
    ServerResponseStatus this._linkedGeneric,
  ) : _isOk = null;

  /// Class constructor for the generic errors
  const ServerResponseStatus.generic({
    bool isOk = false,
  })  : _isOk = isOk,
        httpStatus = null,
        _linkedGeneric = null;

  /// Parse the error from the http status
  ///
  /// First the method tries to find the non generic values (those linked to a http statuses).
  /// Second the method tries to guess the generic value linked to particular sections (such as
  /// success, client error, server error, etc.).
  /// Finally, if nothing is found [ServerResponseStatus.genericError] is returned
  static ServerResponseStatus parseFromHttpStatus(int httpStatus) {
    for (final nonGenericValue in nonGenericValues) {
      if (nonGenericValue.httpStatus == httpStatus) {
        return nonGenericValue;
      }
    }

    if (HttpStatus.continue_ <= httpStatus && httpStatus < HttpStatus.multipleChoices) {
      return ServerResponseStatus.genericSuccess;
    }

    if (HttpStatus.badRequest <= httpStatus && httpStatus < HttpStatus.internalServerError) {
      return ServerResponseStatus.genericClientError;
    }

    if (HttpStatus.internalServerError <= httpStatus &&
        httpStatus <= HttpStatus.networkConnectTimeoutError) {
      return ServerResponseStatus.genericServerError;
    }

    return ServerResponseStatus.genericError;
  }
}
