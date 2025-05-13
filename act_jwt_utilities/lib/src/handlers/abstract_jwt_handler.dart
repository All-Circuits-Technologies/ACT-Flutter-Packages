// SPDX-FileCopyrightText: 2023 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_jwt_utilities/src/models/jwt_options.dart';
import 'package:act_jwt_utilities/src/models/sign_result.dart';
import 'package:act_logger_manager/act_logger_manager.dart';
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:flutter/foundation.dart';

/// This class is useful to handle the creation and verification of specific JWT (those created and
/// verified with the same asymetric key pair)
abstract class AbstractJwtHandler {
  /// The name of the JWT handler
  final String name;

  /// The logs helper linked to the handler
  final LogsHelper logsHelper;

  /// The options linked to the sign and verify methods
  late final JwtOptions _jwtOptions;

  /// The private key to sign the JWT
  JWTKey? _privateKey;

  /// The public key to verify the JWT
  JWTKey? _publicKey;

  /// Check if we have the public and private keys to sign and verify the received JWT
  bool get canSignAndVerify => _privateKey != null && _publicKey != null;

  /// Class constructor
  AbstractJwtHandler({
    required this.name,
    required this.logsHelper,
  });

  /// This method is called to init the JWT handler.
  ///
  /// Returns true if no problem occurred
  Future<bool> initHandler() async {
    _jwtOptions = await getJwtOptions();

    return initHandlerImpl();
  }

  /// This method is called to init the JWT handler
  ///
  /// This is the implementation of the [initHandler] method
  ///
  /// Returns true if no problem occurred
  @protected
  Future<bool> initHandlerImpl();

  /// Get the options linked to the JWT
  ///
  /// Returns the JWT options set by the derived class
  @protected
  Future<JwtOptions> getJwtOptions();

  /// This method initializes the class instance keys pair
  ///
  /// If [publicKey] is undefined, the handler won't be able to sign new JWT
  /// If [privateKey] is undefined, the handler won't be able to verify received JWT
  @protected
  Future<void> initKeys({required JWTKey? publicKey, required JWTKey? privateKey}) async {
    _publicKey = publicKey;
    _privateKey = privateKey;
  }

  /// Validate if the handler sign and verify methods are working
  ///
  /// The method isn't class if [_publicKey] or [_privateKey] aren't defined
  ///
  /// Returns true if the test has succeeded
  Future<bool> testSignAndVerify();

  /// This is the implementation of the method: [testSignAndVerify]
  ///
  /// The [payload] given is added in the temporary JWT to test the handler
  Future<bool> testSignAndVerifyImpl(Map<String, dynamic> payload) async {
    final signResult = await signImpl(payload);

    if (signResult == null) {
      logsHelper.w("A problem occurred when tried to test the signing of the JWT process.");
      return false;
    }

    final verifyResult = await verify(token: signResult.jwt);

    if (verifyResult == null) {
      logsHelper.w("A problem occurred when tried to test the verification of the JWT process");
      return false;
    }

    return true;
  }

  /// Creates a new JWT thanks to the [payload] given.
  ///
  /// [jwtId] is the "jti" (JWT ID) claim, to add in the JWT payload.
  Future<SignResult?> signImpl(
    Map<String, dynamic> payload, {
    String? jwtId,
    Map<String, dynamic>? header,
  }) async {
    if (_privateKey == null) {
      logsHelper.w("Can't sign a JWT token without the private key");
      return null;
    }

    if (_jwtOptions.issuer == null ||
        _jwtOptions.expirationTime == null ||
        _jwtOptions.audience == null) {
      logsHelper.w("Can't sign a JWT token, the issuer, expiration time and audience information "
          "haven't been given");
      return null;
    }

    final jwt = JWT(
      payload,
      audience: _jwtOptions.audience,
      subject: _jwtOptions.subject,
      issuer: _jwtOptions.issuer,
      jwtId: jwtId,
      header: header,
    );

    final token = jwt.trySign(
      _privateKey!,
      algorithm: _jwtOptions.algorithm,
      expiresIn: _jwtOptions.expirationTime,
      notBefore: _jwtOptions.notBefore,
    );

    if (token == null) {
      logsHelper.e("A problem occurred when trying to create a JWT");
      return null;
    }

    return SignResult(expirationTime: _jwtOptions.expirationTime!, jwt: token);
  }

  /// Verify the given [token] thanks to the [_publicKey]
  Future<JWT?> verify({required String token}) async {
    if (_publicKey == null) {
      logsHelper.w("We can't verify the JWT given, the public key is unknown");
      return null;
    }

    final jwt = JWT.tryVerify(
      token,
      _publicKey!,
      issueAt: _jwtOptions.expirationTime,
      audience: _jwtOptions.audience,
      issuer: _jwtOptions.issuer,
      subject: _jwtOptions.subject,
    );

    if (jwt == null) {
      logsHelper.d("The signature verification has failed");
      return null;
    }

    return jwt;
  }

  /// Decode the given [token]. No verification of the expiration date is done, the method only
  /// decodes the JWT.
  Future<JWT?> decode({required String token}) async {
    final jwt = JWT.tryDecode(token);

    if (jwt == null) {
      logsHelper.d("The token decode has failed");
      return null;
    }

    return jwt;
  }
}
