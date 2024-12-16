// SPDX-FileCopyrightText: 2024 Théo Magne <theo.magne@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_consent_manager/act_consent_manager.dart';
import 'package:act_global_manager/act_global_manager.dart';
import 'package:act_shared_auth/act_shared_auth.dart';

/// [ConsentObserverAuth] is a [ConsentObserver] that listens to the authentication status.
/// Check [ConsentObserver] for more information.
class ConsentObserverAuth<A extends AbsAuthManager> extends ConsentObserver<AuthStatus> {
  /// Factory constructor to create a [ConsentObserverAuth] instance.
  factory ConsentObserverAuth({
    required AbstractConsentService consentService,
  }) {
    // Get the auth service
    final authService = globalGetIt().get<A>().authService;

    AuthStatus get() => authService.authStatus;

    return ConsentObserverAuth._(
      stream: authService.authStatusStream,
      get: get,
    );
  }

  /// Private class constructor.
  ConsentObserverAuth._({
    required super.stream,
    required super.get,
  });

  /// Evalute the validity of the new [AuthStatus] value.
  @override
  bool isNewValueValid(AuthStatus value) {
    return value == AuthStatus.signedIn;
  }
}
