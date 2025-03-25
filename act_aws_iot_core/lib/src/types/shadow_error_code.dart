// SPDX-FileCopyrightText: 2024 Théo Magne <theo.magne@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'dart:io';

/// This enum is used to represent the error codes that can be returned by the AWS IoT Device Shadow
/// service. Check the documentation to understand the following error codes:
/// https://docs.aws.amazon.com/iot/latest/developerguide/device-shadow-error-messages.html
enum ShadowErrorCode {
  /// This is a success code, when no error occurred
  ok(HttpStatus.ok),

  /// Possible reeaons for this error:
  /// - Invalid JSON
  /// - Missing required node: state
  /// - State node must be an object
  /// - Desired node must be an object
  /// - Reported node must be an object
  /// - Invalid version
  /// - Invalid clientToken
  /// - JSON contains too many levels of nesting; maximum is 6
  /// - State contains an invalid node
  badRequest(HttpStatus.badRequest),

  /// Possible reeaons for this error:
  /// - The request is not authorized
  unauthorized(HttpStatus.unauthorized),

  /// Possible reeaons for this error:
  /// - The request is forbidden
  forbidden(HttpStatus.forbidden),

  /// Possible reeaons for this error:
  /// - The requested device does not exist
  /// - The requested shadow does not exist
  notFound(HttpStatus.notFound),

  /// Possible reeaons for this error:
  /// - The version of the shadow is not the latest
  conflict(HttpStatus.conflict),

  /// Possible reeaons for this error:
  /// - The payload exceeds the maximum size allowed
  payloadTooLarge(HttpStatus.requestEntityTooLarge),

  /// Possible reeaons for this error:
  /// - Unsupported encoding, only UTF-8 is supported
  unsupportedMediaType(HttpStatus.unsupportedMediaType),

  /// Possible reeaons for this error:
  /// - The request rate is too high: more than 10 requests are being processed
  tooManyRequests(HttpStatus.tooManyRequests),

  /// Possible reeaons for this error:
  /// - The server encountered an internal error
  internalServerError(HttpStatus.internalServerError);

  /// The error code
  final int code;

  /// Class constructor
  const ShadowErrorCode(this.code);

  /// Get an instance of [ShadowErrorCode] from a given [code]
  static ShadowErrorCode? fromCode(int code) {
    for (final value in values) {
      if (value.code == code) {
        return value;
      }
    }

    return null;
  }
}
