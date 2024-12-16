// SPDX-FileCopyrightText: 2024 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_shared_auth/src/types/auth_sign_up_status.dart';
import 'package:equatable/equatable.dart';

/// This is the result of the sign up methods
class AuthSignUpResult extends Equatable {
  /// This is the status of the auth sign up method
  final AuthSignUpStatus status;

  /// Contains extra information about the method call result.
  ///
  /// It may contain the Exception raised in case of errors or the object returned by the third
  /// party service authentication. To have more details, read the third party service
  /// authentication documentation.
  final Object? extra;

  /// Class constructor
  const AuthSignUpResult({
    required this.status,
    this.extra,
  });

  /// Class properties
  @override
  List<Object?> get props => [status, extra];
}
