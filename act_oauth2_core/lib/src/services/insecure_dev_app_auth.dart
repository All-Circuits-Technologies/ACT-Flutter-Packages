// SPDX-FileCopyrightText: 2026 Dorian Benech <dorian.benech@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_oauth2_core/src/utils/insecure_connections.dart';
import 'package:flutter_appauth/flutter_appauth.dart';

/// A [FlutterAppAuth] which allows the insecure connections on every request before delegating it
/// to the one it wraps.
///
/// The native library behind [FlutterAppAuth] on Android refuses any OpenID endpoint which isn't
/// served over `https`, which stops the flow at the discovery. A development stack which serves
/// its realm over plain `http` can't be signed in to without opting into the insecure
/// connections.
///
/// This exists for those stacks only: an application asks
/// [shouldAllowInsecureAppAuthConnections] of the configuration it loaded, and wraps its
/// [FlutterAppAuth] in this one only when the answer is yes. Because the library only honours the
/// flag on Android, this changes nothing on the other platforms.
class InsecureDevAppAuth implements FlutterAppAuth {
  /// This is the [FlutterAppAuth] every call is delegated to, once the request has been flagged as
  /// allowing the insecure connections
  final FlutterAppAuth _delegate;

  /// Class constructor
  const InsecureDevAppAuth(this._delegate);

  /// Allow the insecure connections on [request] and delegate the authorization and the exchange
  @override
  Future<AuthorizationTokenResponse> authorizeAndExchangeCode(AuthorizationTokenRequest request) {
    request.allowInsecureConnections = true;

    return _delegate.authorizeAndExchangeCode(request);
  }

  /// Allow the insecure connections on [request] and delegate the authorization
  @override
  Future<AuthorizationResponse> authorize(AuthorizationRequest request) {
    request.allowInsecureConnections = true;

    return _delegate.authorize(request);
  }

  /// Allow the insecure connections on [request] and delegate the token asking
  @override
  Future<TokenResponse> token(TokenRequest request) {
    request.allowInsecureConnections = true;

    return _delegate.token(request);
  }

  /// Allow the insecure connections on [request] and delegate the session ending
  @override
  Future<EndSessionResponse> endSession(EndSessionRequest request) {
    request.allowInsecureConnections = true;

    return _delegate.endSession(request);
  }
}
