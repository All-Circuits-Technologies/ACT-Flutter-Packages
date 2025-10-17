// SPDX-FileCopyrightText: 2024 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

/// The response status after a server request
///
/// The enum contains two kinds of values:
///
/// - Some HTTP statuses,
/// - Groups of HTTP statuses (generic).
///
/// The first elements are linked to one of the generic or group statuses.
enum ServerResponseStatus {
  /// This is a `Continue` status with code: 100
  ///
  /// For more details, read: https://developer.mozilla.org/en-US/docs/Web/HTTP/Reference/Status/100
  continue_(100, genericSuccess),

  /// This is a `OK` status with code: 200
  ///
  /// For more details, read: https://developer.mozilla.org/en-US/docs/Web/HTTP/Reference/Status/200
  ok(200, genericSuccess),

  /// This is a `Multiple choices` status with code: 300
  ///
  /// For more details, read: https://developer.mozilla.org/en-US/docs/Web/HTTP/Reference/Status/300
  multipleChoices(300, genericSuccess),

  /// This is a `Bad Request` status with code: 400
  ///
  /// For more details, read: https://developer.mozilla.org/en-US/docs/Web/HTTP/Reference/Status/400
  badRequest(400, genericClientError),

  /// This is a `Unauthorized` status with code: 401
  ///
  /// For more details, read: https://developer.mozilla.org/en-US/docs/Web/HTTP/Reference/Status/401
  unauthorized(401, genericClientError),

  /// This is a `Payment Required` status with code: 402
  ///
  /// For more details, read: https://developer.mozilla.org/en-US/docs/Web/HTTP/Reference/Status/402
  paymentRequired(402, genericClientError),

  /// This is a `Forbidden` status with code: 403
  ///
  /// For more details, read: https://developer.mozilla.org/en-US/docs/Web/HTTP/Reference/Status/403
  forbidden(403, genericClientError),

  /// This is a `Not Found` status with code: 404
  ///
  /// For more details, read: https://developer.mozilla.org/en-US/docs/Web/HTTP/Reference/Status/404
  notFound(404, genericClientError),

  /// This is a `Conflict` status with code: 409
  ///
  /// For more details, read: https://developer.mozilla.org/en-US/docs/Web/HTTP/Reference/Status/409
  conflict(409, genericClientError),

  /// This is a `Locked` status with code: 423
  ///
  /// For more details, read: https://developer.mozilla.org/en-US/docs/Web/HTTP/Reference/Status/423
  locked(423, genericClientError),

  /// This is a `Too Early` status with code: 425
  ///
  /// For more details, read: https://developer.mozilla.org/en-US/docs/Web/HTTP/Reference/Status/425
  tooEarly(425, genericClientError),

  /// This is a `Internal Server Error` status with code: 500
  ///
  /// For more details, read: https://developer.mozilla.org/en-US/docs/Web/HTTP/Reference/Status/500
  internalServerError(500, genericServerError),

  /// This is a `Network connect timeout error` status with code: 599
  ///
  /// For more details, read: https://developer.mozilla.org/en-US/docs/Web/HTTP/Reference/Status/599
  networkConnectTimeoutError(599, genericServerError),

  /// This enum represents all the 2xx statuses for success
  genericSuccess.generic(isOk: true),

  /// This enum represents all the 4xx statuses for the client errors
  genericClientError.generic(),

  /// This enum represents all the 5xx status for the server errors
  genericServerError.generic(),

  /// This enum represents all the other errors which are not linked to the previous generics
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
  const ServerResponseStatus(int this.httpStatus, ServerResponseStatus this._linkedGeneric)
    : _isOk = null;

  /// Class constructor for the generic errors
  const ServerResponseStatus.generic({bool isOk = false})
    : _isOk = isOk,
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

    if (ServerResponseStatus.continue_.httpStatus! <= httpStatus &&
        httpStatus < ServerResponseStatus.multipleChoices.httpStatus!) {
      return ServerResponseStatus.genericSuccess;
    }

    if (ServerResponseStatus.badRequest.httpStatus! <= httpStatus &&
        httpStatus < ServerResponseStatus.internalServerError.httpStatus!) {
      return ServerResponseStatus.genericClientError;
    }

    if (ServerResponseStatus.internalServerError.httpStatus! <= httpStatus &&
        httpStatus <= ServerResponseStatus.networkConnectTimeoutError.httpStatus!) {
      return ServerResponseStatus.genericServerError;
    }

    return ServerResponseStatus.genericError;
  }
}
