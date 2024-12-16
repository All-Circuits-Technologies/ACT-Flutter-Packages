// SPDX-FileCopyrightText: 2024 Théo Magne <theo.magne@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_dart_utility/act_dart_utility.dart';
import 'package:act_global_manager/act_global_manager.dart';
import 'package:act_shared_auth/act_shared_auth.dart';

/// [AuthStreamObserver] is a [StreamObserver] that listens to the authentication status.
/// Check [StreamObserver] for more information.
class AuthStreamObserver<A extends AbsAuthManager> extends StreamObserver<AuthStatus> {
  /// Factory constructor to create a [AuthStreamObserver] instance.
  factory AuthStreamObserver() {
    // Get the auth service
    final authService = globalGetIt().get<A>().authService;

    AuthStatus get() => authService.authStatus;

    return AuthStreamObserver._(
      stream: authService.authStatusStream,
      get: get,
    );
  }

  /// Private class constructor.
  AuthStreamObserver._({
    required super.stream,
    required super.get,
  });

  /// Evalute the validity of the new [AuthStatus] value.
  @override
  bool isNewValueValid(AuthStatus value) => value == AuthStatus.signedIn;
}
